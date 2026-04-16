from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser
from django.contrib.auth import authenticate, get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from django.views.decorators.csrf import csrf_exempt

from .models import Report, Notification, Upvote
from .serializers import (
    RegisterSerializer,
    UserSerializer,
    ReportSerializer,
    NotificationSerializer,
)

User = get_user_model()


def get_tokens(user):
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }


@api_view(['GET'])
@permission_classes([AllowAny])
def test_api(request):
    return Response({
        "message": "API is working fine ðŸš€"
    })


# REGISTER
@api_view(['POST', 'OPTIONS'])
@permission_classes([AllowAny])
@csrf_exempt
def register(request):
    serializer = RegisterSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response({
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': UserSerializer(user).data,
        }, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# PROFILE (secured)
@api_view(['GET', 'OPTIONS'])
@permission_classes([IsAuthenticated])
def profile(request):
    user = request.user
    return Response(UserSerializer(user).data)


# LOGIN
@api_view(['POST'])
@permission_classes([AllowAny])
@csrf_exempt
def login_view(request):
    email = request.data.get("email")
    password = request.data.get("password")

    if not email or not password:
        return Response({
            "success": False,
            "message": "Email and password are required"
        }, status=401)

    # Handle hardcoded test accounts
    if email == "admin@roadwatch.com" and password == "admin123":
        # Create or get the admin user
        user, created = User.objects.get_or_create(
            email=email,
            defaults={
                'username': 'admin',
                'first_name': 'Admin',
                'last_name': 'User',
                'is_staff': True,
                'is_superuser': True
            }
        )
        if created:
            user.set_password(password)
            user.save()

        tokens = get_tokens(user)
        return Response({
            "success": True,
            "role": "admin",
            "email": email,
            "access": tokens['access'],
            "refresh": tokens['refresh'],
            "user": UserSerializer(user).data,
        })

    elif email == "user@roadwatch.com" and password == "user123":
        # Create or get the regular user
        user, created = User.objects.get_or_create(
            email=email,
            defaults={
                'username': 'user',
                'first_name': 'Regular',
                'last_name': 'User'
            }
        )
        if created:
            user.set_password(password)
            user.save()

        tokens = get_tokens(user)
        return Response({
            "success": True,
            "role": "user",
            "email": email,
            "access": tokens['access'],
            "refresh": tokens['refresh'],
            "user": UserSerializer(user).data,
        })

    # Regular authentication for other users
    user = authenticate(email=email, password=password)
    if user is not None:
        tokens = get_tokens(user)
        return Response({
            "success": True,
            "role": "user",  # Default role, could be extended
            "email": email,
            "access": tokens['access'],
            "refresh": tokens['refresh'],
            "user": UserSerializer(user).data,
        })

    return Response({
        "success": False,
        "message": "Invalid credentials"
    }, status=401)


# CHECK EMAIL
@api_view(['POST'])
@permission_classes([AllowAny])
@csrf_exempt
def check_email(request):
    email = request.data.get('email')

    if User.objects.filter(email=email).exists():
        return Response({'detail': 'Email already registered'}, status=status.HTTP_400_BAD_REQUEST)

    return Response({'detail': 'Email available'}, status=status.HTTP_200_OK)


# FORGOT PASSWORD (basic)
@api_view(['POST'])
@permission_classes([AllowAny])
@csrf_exempt
def forgot_password(request):
    email = request.data.get('email')

    if not User.objects.filter(email=email).exists():
        return Response({'detail': 'Email not found'}, status=status.HTTP_400_BAD_REQUEST)

    return Response({'detail': 'Reset link sent (demo)'}, status=status.HTTP_200_OK)


# LOGOUT (client clears token; server responds OK)
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout(request):
    return Response({'detail': 'Logged out'}, status=status.HTTP_200_OK)


# DASHBOARD (user-scoped stats)
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def dashboard(request):
    reports_qs = Report.objects.filter(user=request.user)
    total_reports = reports_qs.count()
    verified_reports = reports_qs.filter(status='Verified').count()
    upvotes_count = Upvote.objects.filter(report__user=request.user).count()

    return Response({
        'reports': total_reports,
        'verified': verified_reports,
        'upvotes': upvotes_count,
    })


# REPORTS (list + create)
@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser])
def reports(request):
    if request.method == 'GET':
        reports_qs = Report.objects.filter(user=request.user)
        serializer = ReportSerializer(reports_qs, many=True)
        return Response(serializer.data)

    serializer = ReportSerializer(data=request.data)
    if serializer.is_valid():
        report = serializer.save(user=request.user)
        return Response(ReportSerializer(report).data, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# REPORTS (delete + update status)
@api_view(['DELETE', 'PUT'])
@permission_classes([IsAuthenticated])
def report_detail(request, report_id):
    try:
        # Allow admin to access any report, regular users only their own
        if hasattr(request.user, 'role') and request.user.role == 'admin':
            report = Report.objects.get(id=report_id)
        else:
            report = Report.objects.get(id=report_id, user=request.user)
    except Report.DoesNotExist:
        return Response({'detail': 'Report not found'}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'PUT':
        report.status = request.data.get('status')
        report.save()
        return Response({"message": "Updated"})

    if report.image:
        report.image.delete(save=False)
    report.delete()
    return Response(status=status.HTTP_204_NO_CONTENT)


# NOTIFICATIONS (list)
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def notifications(request):
    notifications_qs = Notification.objects.filter(user=request.user)
    serializer = NotificationSerializer(notifications_qs, many=True)
    return Response(serializer.data)


# UPVOTE (create)
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def upvote(request):
    report_id = request.data.get('report_id')
    if not report_id:
        return Response({'detail': 'report_id is required'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        report = Report.objects.get(id=report_id)
    except Report.DoesNotExist:
        return Response({'detail': 'Report not found'}, status=status.HTTP_404_NOT_FOUND)

    upvote_obj, created = Upvote.objects.get_or_create(
        user=request.user,
        report=report,
    )

    if not created:
        return Response({'detail': 'Already upvoted'}, status=status.HTTP_200_OK)

    return Response({
        'detail': 'Upvoted',
        'upvotes': report.upvotes.count(),
    }, status=status.HTTP_201_CREATED)


# ADMIN VIEWS
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def admin_reports(request):
    if request.user.role != 'admin':
        return Response({'detail': 'Access denied'}, status=status.HTTP_403_FORBIDDEN)

    reports_qs = Report.objects.all()
    serializer = ReportSerializer(reports_qs, many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def admin_users(request):
    if request.user.role != 'admin':
        return Response({'detail': 'Access denied'}, status=status.HTTP_403_FORBIDDEN)

    users_qs = User.objects.all()
    serializer = UserSerializer(users_qs, many=True)
    return Response(serializer.data)


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def admin_report_detail(request, report_id):
    if request.user.role != 'admin':
        return Response({'detail': 'Access denied'}, status=status.HTTP_403_FORBIDDEN)

    try:
        report = Report.objects.get(id=report_id)
    except Report.DoesNotExist:
        return Response({'detail': 'Report not found'}, status=status.HTTP_404_NOT_FOUND)

    serializer = ReportSerializer(report, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def admin_report_delete(request, report_id):
    if request.user.role != 'admin':
        return Response({'detail': 'Access denied'}, status=status.HTTP_403_FORBIDDEN)

    try:
        report = Report.objects.get(id=report_id)
    except Report.DoesNotExist:
        return Response({'detail': 'Report not found'}, status=status.HTTP_404_NOT_FOUND)

    if report.image:
        report.image.delete(save=False)
    report.delete()
    return Response(status=status.HTTP_204_NO_CONTENT)


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def admin_user_detail(request, user_id):
    if request.user.role != 'admin':
        return Response({'detail': 'Access denied'}, status=status.HTTP_403_FORBIDDEN)

    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response({'detail': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

    # Allow admins to rename users.
    serializer = UserSerializer(user, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def admin_user_delete(request, user_id):
    if request.user.role != 'admin':
        return Response({'detail': 'Access denied'}, status=status.HTTP_403_FORBIDDEN)

    if request.user.id == user_id:
        return Response({'detail': 'Cannot delete yourself'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response({'detail': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

    # Delete all report images to avoid orphaned files
    for report in Report.objects.filter(user=user):
        if report.image:
            report.image.delete(save=False)
    user.delete()
    return Response(status=status.HTTP_204_NO_CONTENT)
