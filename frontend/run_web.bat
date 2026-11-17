@echo off
cd /d "%~dp0"
flutter run -d chrome --web-port=12221 --dart-define=CARESYNC_API_BASE_URL=http://localhost:12223
