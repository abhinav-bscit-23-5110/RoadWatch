# RoadWatch 🛣️

**AI Powered Road Condition Detection & Community Verification System**

RoadWatch is a cross-platform mobile application that bridges the gap between citizens and government authorities for real-time road issue reporting and resolution. Citizens can photograph and GPS-tag a road hazard in under 45 seconds; the backend classifies the issue by type and severity, and the community can upvote reports to validate authenticity before escalation to a government dashboard.

---

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [API Endpoints](#api-endpoints)
- [Modules](#modules)
- [Database Schema](#database-schema)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Running the App](#running-the-app)
- [Platform Support](#platform-support)
- [Security](#security)
- [Non-Functional Requirements](#non-functional-requirements)
- [Future Enhancements](#future-enhancements)
- [Author](#author)

---

## Features

- **AI Issue Classification** — Detects and classifies road problems (potholes, cracks, flooding, debris, damaged signage) using computer vision and image analysis.
- **Instant GPS-Tagged Reporting** — Submit a photo and location in under 45 seconds with automatic reverse geocoding.
- **Community Verification** — Upvote/downvote system for crowdsourced report validation before escalation.
- **Government Admin Dashboard** — Real-time analytics and full report management (view, update status, add notes, delete).
- **Report Status Tracking** — Full lifecycle: `Pending → Verified → In Progress → Resolved / Rejected`.
- **In-App Notifications** — Alerts for nearby hazards and status changes with read/unread state.
- **PDF Report Export** — Export any report as a downloadable PDF.
- **Dark / Light Theme** — System-aware theme toggle, persisted across sessions.
- **Demo Mode** — Explore the full app without a backend connection using seeded mock data.
- **JWT Authentication** — Secure, stateless sessions for both citizens and admin users.

---

## Tech Stack

### Frontend — Flutter (Dart)

| Package | Version | Purpose |
|---|---|---|
| flutter / dart | SDK >=3.3.0 | Core framework |
| google_maps_flutter | ^2.7.0 | Interactive map & GPS display |
| geolocator | ^14.0.2 | Real-time GPS coordinate acquisition |
| geocoding | ^4.0.0 | Reverse geocoding (coordinates → address) |
| image_picker | ^1.1.2 | Camera/gallery photo capture |
| http | ^1.2.1 | REST API communication |
| provider | ^6.1.2 | State management (Theme Provider) |
| shared_preferences | ^2.2.3 | Persistent local storage |
| flutter_secure_storage | ^9.2.4 | Secure JWT token storage |
| google_fonts | ^8.0.1 | Poppins typeface |
| pdf + printing | ^3.10.4 / ^5.12.0 | Report PDF export |
| lottie | ^3.3.2 | Animated illustrations |
| shimmer | ^3.0.0 | Loading skeleton animations |

### Backend — Django REST Framework (Python)

| Package | Version | Purpose |
|---|---|---|
| Django | 5.0.6 | Core web framework |
| djangorestframework | 3.16.1 | RESTful API toolkit |
| djangorestframework-simplejwt | 5.5.1 | JWT authentication |
| django-cors-headers | 4.9.0 | Cross-origin request handling |
| Pillow | 12.1.0 | Image processing for uploaded photos |
| PyJWT | 2.11.0 | JWT token generation & validation |
| sqlparse | 0.5.5 | SQL query formatting |
| asgiref | 3.11.0 | ASGI/WSGI compatibility |

---

## Architecture

RoadWatch follows a client-server architecture with a clean separation between the mobile frontend and the backend API.

```
Mobile App (Flutter)
        │
        ▼
REST API (Django REST Framework)
        │
        ▼
Database (SQLite / PostgreSQL)
        │
        ▼
Analytics & Notifications
```

| Layer | Technology | Responsibility |
|---|---|---|
| Frontend | Flutter 3.22, Dart, Material UI 3, Google Maps SDK | UI rendering, GPS capture, photo upload, state management, offline caching |
| Backend API | Django 5.0.6, DRF 3.16.1 | Business logic, authentication, report processing, admin functions |
| Authentication | SimpleJWT 5.5.1, bcrypt, PyJWT | JWT token generation, refresh, validation; password hashing |
| Database | SQLite (dev) / PostgreSQL (prod) | Persistent storage of users, reports, votes, notifications |
| Maps & Geolocation | Google Maps SDK, Geocoding API | Interactive maps, reverse geocoding, GPS coordinate tagging |
| Media Storage | Django `media/` directory | Uploaded report images stored as `ImageField` files |
| CORS Handling | django-cors-headers 4.9.0 | Cross-origin requests from Flutter web to Django |

---

## API Endpoints

### Auth & User

| Endpoint | Method | Auth | Description |
|---|---|---|---|
| `/api/register/` | POST | None | New user registration, returns JWT |
| `/api/login/` | POST | None | Login, returns access + refresh tokens |
| `/api/logout/` | POST | JWT | Server-side logout acknowledgement |
| `/api/profile/` | GET | JWT | Fetch authenticated user profile |
| `/api/forgot-password/` | POST | None | Initiate password reset flow |
| `/api/dashboard/` | GET | JWT | User stats: total reports, verified, upvotes |

### Reports

| Endpoint | Method | Auth | Description |
|---|---|---|---|
| `/api/reports/` | GET / POST | JWT | List user reports / Create new report |
| `/api/reports/<id>/` | DELETE / PUT | JWT | Delete report or update status |
| `/api/upvote/` | POST | JWT | Upvote a report (unique per user-report pair) |

### Notifications

| Endpoint | Method | Auth | Description |
|---|---|---|---|
| `/api/notifications/` | GET | JWT | List notifications for authenticated user |

### Admin

| Endpoint | Method | Auth | Description |
|---|---|---|---|
| `/api/admin/reports/` | GET | JWT (Admin) | List all reports across all users |
| `/api/admin/reports/<id>/` | PATCH | JWT (Admin) | Partially update any report |
| `/api/admin/reports/<id>/delete/` | DELETE | JWT (Admin) | Delete any report |
| `/api/admin/users/` | GET | JWT (Admin) | List all registered users |
| `/api/admin/users/<id>/` | PATCH / DELETE | JWT (Admin) | Update or delete a user |

---

## Modules

### Module 1 — Authentication
**Files:** `LoginScreen.dart`, `registration_screen.dart`, `forgot_password_screen.dart`, `reset_password_screen.dart`, `auth_service.dart`, `storage_service.dart`

Handles the complete authentication lifecycle: registration, login, JWT storage via `flutter_secure_storage`, role-based routing (admin/user), forgot/reset password flows, and demo mode.

### Module 2 — Home / Dashboard
**Files:** `home_screen.dart`, `splash_screen.dart`, `api_service.dart`

Main post-login entry point. Fetches real-time stats (total reports, verified reports, upvotes received), displays recent reports as scrollable cards, and provides bottom navigation to all five main screens.

### Module 3 — Report Submission *(Core Module)*
**Files:** `report_screen.dart`, `services/api_service.dart`, `services/google_maps_loader.dart`

Users select issue type, severity, description, and photo; GPS is auto-detected and shown on an interactive map with a draggable pin. Reverse geocoding converts coordinates to a human-readable address. Submits as a multipart POST in under 45 seconds.

**Issue Types:** Pothole · Crack · Flooding · Debris · Signage · Other  
**Severity Levels:** Low · Medium · High

### Module 4 — Reports
**Files:** `reports_screen.dart`, `issue_detailed_screen.dart`, `report_print_screen.dart`

Lists all user-submitted reports with status filtering. Detail view shows full info, photo, upvote count, and status badge. Includes PDF export via the `pdf + printing` packages.

### Module 5 — Alerts / Notifications
**Files:** `alerts_screen.dart`

Fetches notifications from `/api/notifications/` and displays read/unread indicators. Auto-refreshes; supports marking as read. Notifications are triggered by backend events (e.g., status changes).

### Module 6 — Profile
**Files:** `profile_screen.dart`

Displays account info and report statistics. Provides theme toggle (Light / Dark / System), edit profile, settings, help & support, and logout.

### Module 7 — Admin Dashboard
**Files:** `admin_dashboard.dart`, `backend/accounts/views.py`

Admin-only module. Full CRUD over all reports: view, update status, add notes, delete. Also manages users: list, update, delete. Accessible only to users with `role='admin'`.

### Module 8 — Theme
**Files:** `theme/app_theme.dart`, `theme/theme_provider.dart`, `theme_manager.dart`

Full light/dark/system theme system using `ThemeProvider` with `ChangeNotifier`. Preference persisted via `shared_preferences` with smooth animated transitions.

---

## Database Schema

The database is built around five primary entities:

- **User** — `id`, `email` (unique), `name`, `role` (admin/user), `password` (bcrypt), `date_joined`
- **Report** — `id`, `user_id` (FK), `issue_type`, `description`, `latitude`, `longitude`, `location_text`, `severity`, `image`, `status`, `created_at`
- **Upvote** — `id`, `user_id` (FK), `report_id` (FK), `created_at` — unique constraint on `(user_id, report_id)`
- **Notification** — `id`, `user_id` (FK), `title`, `message`, `read`, `created_at`
- **ReportComment** — `id`, `report_id` (FK), `user_id` (FK), `comment`, `created_at`

Supporting entities: `AdminNote`, `StatusLog`, `UserProfile`, `Feedback`, `IssueType`, `RoadType`

---

## Prerequisites

### User Device
- Android 8.0+ (API 26) or iOS 14+
- Minimum 2 GB RAM
- Rear-facing camera (5 MP minimum)
- GPS / Location Services enabled
- Active internet connection (Wi-Fi or 4G/5G)
- Minimum 50 MB free storage

### Development Machine
- Processor: Intel Core i5 / AMD Ryzen 5 or higher
- RAM: 8 GB minimum
- Storage: 50 GB SSD minimum

### Software
| Component | Version |
|---|---|
| Flutter | 3.22 |
| Dart SDK | >=3.3.0 |
| Python | 3.11+ |
| Django | 5.0.6 |
| Node.js | (for tooling, optional) |
| Git | Latest |

---

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/<your-username>/road_watch_14.04.2026.git
cd road_watch_14.04.2026
```

### 2. Backend Setup (Django)

```bash
cd backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate

pip install -r requirements.txt

python manage.py migrate
python manage.py createsuperuser  # Create your admin account

python manage.py runserver
```

The API will be available at `http://127.0.0.1:8000/`.

### 3. Frontend Setup (Flutter)

```bash
cd frontend
flutter pub get
```

Configure your API base URL and Google Maps API key. Open `lib/services/api_service.dart` and update:

```dart
const String baseUrl = 'http://127.0.0.1:8000';
```

Add your Google Maps API key in:
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/AppDelegate.swift`
- `web/index.html` (for PWA)

---

## Running the App

```bash
# Run on a connected device or emulator
flutter run

# Run for a specific platform
flutter run -d android
flutter run -d ios
flutter run -d chrome      # Web PWA

# Build a release APK
flutter build apk --release
```

---

## Platform Support

| Platform | Minimum Version | Status |
|---|---|---|
| Android | 8.0 (API 26) | ✅ Fully Supported |
| iOS | 14+ | ✅ Fully Supported |
| Web (PWA) | Modern browsers | ✅ Supported |
| Windows Desktop | Windows 10+ | ⚙️ Build configured |

---

## Security

- **Password Hashing** — bcrypt with a minimum of 10 rounds
- **JWT Tokens** — Access tokens expire in 24 hours; refresh tokens handled via SimpleJWT
- **Secure Token Storage** — `flutter_secure_storage` (AES-256 on Android, Keychain on iOS)
- **Data Encryption** — AES-256 for data at rest
- **CORS** — `django-cors-headers` restricts cross-origin requests to allowed origins
- **Role-Based Access Control** — Admin endpoints are gated by `role='admin'` check on every request
- **Input Validation** — Django REST Framework serializers validate all incoming data

---

## Non-Functional Requirements

| Requirement | Specification |
|---|---|
| API Response Time | < 300 ms for standard queries |
| Availability | 99.9% server uptime (production target) |
| Concurrent Users | Designed for 10,000+ simultaneous users |
| Offline Support | Cached data viewable without connection |
| Battery Usage | Optimised GPS; debounced updates; < 5% battery/hour |
| App Size | Under 25 MB installed |
| Scalability | Horizontal scaling via Django + PostgreSQL in production |
| Accessibility | Material Design 3 compliant; semantic labels for screen readers |

---

## Future Enhancements

- **Full AI/ML Integration** — On-device TensorFlow Lite model for real-time pothole detection from live camera feed
- **Heatmap Analytics** — Geospatial heatmap overlays on the government dashboard for hotspot identification
- **Multi-language Support** — Localisation for Hindi and other regional Indian languages
- **Push Notifications** — Firebase Cloud Messaging (FCM) for real-time push alerts
- **Offline Report Queue** — Queue reports locally and sync when connectivity is restored
- **PostgreSQL Migration** — Switch from SQLite to PostgreSQL for production scalability
- **CI/CD Pipeline** — Automated testing and deployment via GitHub Actions

---

## Author

**Abhinav Krishna**  
Registration No.: 202344400145 · Roll No.: 2444440050002  
B.Sc. Information Technology (3rd Year, 2023–2026)  
Department of Computer Science & Applications  
SSSAPTM, Patna — Patliputra University, Patna

**Project Guides:** Prof. Niraj Kumar Singh & Prof. Anjesh Kumar  
Department of Computer Science & Applications, SSSAPTM, Patna

---

*RoadWatch — Making India's roads safer, one report at a time.*
