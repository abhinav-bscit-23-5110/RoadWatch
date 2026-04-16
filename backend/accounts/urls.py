from django.urls import path
from .views import (
    register,
    login_view,
    check_email,
    forgot_password,
    test_api,
    profile,
    logout,
    admin_reports,
    admin_users,
    admin_report_detail,
    admin_report_delete,
    admin_user_detail,
    admin_user_delete,
)

urlpatterns = [
    path('register/', register),
    path('login/', login_view),
    path('profile/', profile),
    path('logout/', logout),
    path('check-email/', check_email),
    path('forgot-password/', forgot_password),
    path('test/', test_api),
    path('admin/reports/', admin_reports),
    path('admin/users/', admin_users),
    path('admin/reports/<int:report_id>/', admin_report_detail),
    path('admin/reports/<int:report_id>/delete/', admin_report_delete),
    path('admin/users/<int:user_id>/', admin_user_detail),
    path('admin/users/<int:user_id>/delete/', admin_user_delete),
]
