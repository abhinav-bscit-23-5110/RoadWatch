@echo off
REM Run Flutter web on Chrome with explicit host/port and API base URL
cd %~dp0\..
flutter run -d chrome --web-hostname=localhost --web-port=49696 --dart-define=API_BASE_URL=http://localhost:8000/api
