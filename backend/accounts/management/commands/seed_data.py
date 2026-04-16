from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from random import choice, randint

from accounts.models import (
    Report,
    Feedback,
    RoadType,
    IssueType,
    ReportComment,
    StatusLog,
    UserProfile,
    AdminNote,
)

User = get_user_model()


class Command(BaseCommand):
    help = "Seed dummy data"

    def handle(self, *args, **kwargs):
        self.stdout.write("Seeding data...")

        # ---------------- USERS ----------------
        users = []
        for i in range(3):
            user, created = User.objects.get_or_create(
                email=f"user{i}@test.com",
                defaults={"username": f"user{i}"}
            )
            if created:
                user.set_password("123456")
                user.save()
            users.append(user)

        # ---------------- ROAD TYPES ----------------
        road_types = ["Highway", "City Road", "Village Road"]
        for r in road_types:
            RoadType.objects.get_or_create(name=r)

        # ---------------- ISSUE TYPES ----------------
        issue_types = ["Pothole", "Accident", "Water Logging"]
        for issue in issue_types:
            IssueType.objects.get_or_create(title=issue)

        # ---------------- REPORTS ----------------
        reports = []
        for i in range(5):
            report = Report.objects.create(
                user=choice(users),
                issue_type=choice(issue_types),
                location_text=f"Location {i}",
                description=f"Dummy issue {i}",
                status=choice(["Pending", "Verified", "Resolved"]),
                severity=choice(["Low", "Medium", "High"]),
            )
            reports.append(report)

        # ---------------- FEEDBACK ----------------
        for i in range(5):
            Feedback.objects.create(
                user=choice(users),
                message="This is dummy feedback",
                rating=randint(1, 5)
            )

        # ---------------- COMMENTS ----------------
        for r in reports:
            ReportComment.objects.create(
                report=r,
                user=choice(users),
                comment="Sample comment"
            )

        # ---------------- STATUS LOG ----------------
        for r in reports:
            StatusLog.objects.create(
                report=r,
                old_status="Pending",
                new_status=r.status
            )

        # ---------------- USER PROFILE ----------------
        for u in users:
            UserProfile.objects.get_or_create(
                user=u,
                defaults={
                    "phone": "9999999999",
                    "address": "Dummy Address",
                }
            )

        # ---------------- ADMIN NOTES ----------------
        for r in reports:
            AdminNote.objects.create(
                report=r,
                note="Checked by admin"
            )

        self.stdout.write(self.style.SUCCESS("Dummy data inserted successfully!"))
