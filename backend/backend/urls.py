"""
URL configuration for backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

from accounts import views as account_views

urlpatterns = [
    path('admin/', admin.site.urls),
    # API auth endpoints (register, login, profile, etc.)
    path('api/login/', account_views.login_view),  # support Flutter client expecting /api/login/
    path('api/auth/', include('accounts.urls')),

    # Admin endpoints (matches frontend expectations)
    path('api/admin/reports/', account_views.admin_reports),
    path('api/admin/users/', account_views.admin_users),
    path('api/admin/users/<int:user_id>/', account_views.admin_user_detail),
    path('api/admin/users/<int:user_id>/delete/', account_views.admin_user_delete),
    path('api/admin/reports/<int:report_id>/', account_views.admin_report_detail),
    path('api/admin/reports/<int:report_id>/delete/', account_views.admin_report_delete),

    # API data endpoints (user-scoped)
    path('api/dashboard/', account_views.dashboard),
    path('api/reports/', account_views.reports),
    path('api/reports/<int:report_id>/', account_views.report_detail),
    path('api/notifications/', account_views.notifications),
    path('api/upvote/', account_views.upvote),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
