@echo off
REM Run Flutter on Android emulator with API pointing to host machine
cd %~dp0\..
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
