@echo off
REM Run Flutter on a real Android phone. Enter your PC's LAN IP when prompted.
cd %~dp0\..
set /p PC_IP=Enter your PC LAN IP (e.g. 192.168.1.5): 
if "%PC_IP%"=="" (
  echo No IP provided. Exiting.
  exit /b 1
)
flutter run --dart-define=API_BASE_URL=http://%PC_IP%:8000/api
