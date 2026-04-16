from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

User = get_user_model()

class Command(BaseCommand):
    help = 'Create default test accounts'

    def handle(self, *args, **options):
        # Admin account
        if not User.objects.filter(email='admin@roadwatch.com').exists():
            User.objects.create_user(
                username='admin@roadwatch.com',
                email='admin@roadwatch.com',
                password='admin123',
                name='Admin User',
                role='admin'
            )
            self.stdout.write(self.style.SUCCESS('Admin account created'))

        # User account
        if not User.objects.filter(email='user@roadwatch.com').exists():
            User.objects.create_user(
                username='user@roadwatch.com',
                email='user@roadwatch.com',
                password='user123',
                name='Test User',
                role='user'
            )
            self.stdout.write(self.style.SUCCESS('User account created'))