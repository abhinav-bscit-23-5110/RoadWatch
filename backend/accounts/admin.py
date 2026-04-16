from django.contrib import admin
from .models import (
    User, Report, Upvote, Notification,
    Feedback, RoadType, IssueType,
    ReportComment, StatusLog,
    UserProfile, AdminNote,
)

admin.site.register(User)
admin.site.register(Report)
admin.site.register(Upvote)
admin.site.register(Notification)
admin.site.register(Feedback)
admin.site.register(RoadType)
admin.site.register(IssueType)
admin.site.register(ReportComment)
admin.site.register(StatusLog)
admin.site.register(UserProfile)
admin.site.register(AdminNote)
