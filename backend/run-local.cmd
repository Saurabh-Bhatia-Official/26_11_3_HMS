@echo off
setlocal
cd /d "%~dp0"
set "SERVER_PORT=12223"
set "SPRING_PROFILES_ACTIVE=local"

if not defined CARESYNC_CORS_ALLOWED_ORIGINS set "CARESYNC_CORS_ALLOWED_ORIGINS=http://localhost:12221"

for /f "delims=" %%S in ('powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$bytes = New-Object byte[] 32; $rng = [Security.Cryptography.RandomNumberGenerator]::Create(); try { $rng.GetBytes($bytes); [Convert]::ToBase64String($bytes) } finally { $rng.Dispose() }"') do set "CARESYNC_JWT_SECRET=%%S"

if not defined CARESYNC_JWT_SECRET (
    echo Failed to generate CARESYNC_JWT_SECRET. 1>&2
    exit /b 1
)

call mvnw.cmd spring-boot:run
exit /b %ERRORLEVEL%
