from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Report, Notification, Upvote

User = get_user_model()


class RegisterSerializer(serializers.ModelSerializer):
    name = serializers.CharField(required=True, allow_blank=False)
    email = serializers.EmailField(required=True)
    password = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = User
        fields = ("id", "name", "email", "password", "role")

    def validate_email(self, value):
        # Prevent duplicate registration
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("Email already registered")
        return value

    def create(self, validated_data):
        password = validated_data.pop("password")
        email = validated_data.get("email")
        user = User(**validated_data)
        user.username = email if email else ''
        user.set_password(password)
        user.save()
        return user


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("id", "name", "email", "role")


class ReportSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    location = serializers.CharField(source='location_text', read_only=True)
    upvotes = serializers.IntegerField(source='upvotes.count', read_only=True)

    class Meta:
        model = Report
        fields = (
            "id",
            "user",
            "issue_type",
            "description",
            "latitude",
            "longitude",
            "location",
            "location_text",
            "severity",
            "image",
            "status",
            "created_at",
            "upvotes",
        )
        read_only_fields = ("id", "user", "created_at", "upvotes")


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ("id", "title", "message", "created_at", "read")
        read_only_fields = ("id", "created_at")


class UpvoteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Upvote
        fields = ("id", "user", "report", "created_at")
        read_only_fields = ("id", "created_at")
