@echo off
REM EZStay Flutter 웹 빌드 및 EC2 배포 스크립트 (Windows 배치)
REM 사용법: deploy_to_ec2.bat [test|production]

setlocal enabledelayedexpansion

REM 환경 설정
set "ENVIRONMENT=%1"
if "%ENVIRONMENT%"=="" set "ENVIRONMENT=test"

set "PEM_KEY=C:\study\ezstay_test-key.pem"
set "EC2_IP=98.94.160.132"
set "EC2_USER=ec2-user"
set "REMOTE_UPLOAD_PATH=/opt/ezstay/frontend/flutter"
set "REMOTE_NGINX_PATH=/var/www/flutter"

echo ======================================
echo   EZStay EC2 Deployment Script
echo ======================================
echo.

REM API URL 설정
if "%ENVIRONMENT%"=="production" (
    set "API_URL=https://api.ezstay.com"
) else (
    set "API_URL=https://ezstay-api.duckdns.org"
)

echo Environment: %ENVIRONMENT%
echo API URL: %API_URL%
echo.

REM PEM 키 확인
if not exist "%PEM_KEY%" (
    echo [ERROR] PEM key not found: %PEM_KEY%
    exit /b 1
)

echo [OK] PEM key found
echo.

REM 환경별 .env 파일 복사
echo [ENV] Copying .env.%ENVIRONMENT% file...
if exist .env.%ENVIRONMENT% (
    copy /Y .env.%ENVIRONMENT% .env
    echo [OK] Using .env.%ENVIRONMENT%
) else (
    echo [WARNING] .env.%ENVIRONMENT% not found, using default .env
)
echo.

REM Flutter 웹 빌드
echo [BUILD] Building Flutter web...
flutter build web --release --base-href=/app/ --dart-define=ENVIRONMENT=%ENVIRONMENT% --dart-define=API_BASE_URL=%API_URL%

if errorlevel 1 (
    echo [ERROR] Build failed!
    exit /b 1
)

echo [OK] Build completed
echo.

REM 서버에서 기존 파일 삭제
echo [CLEANUP] Cleaning old files on server...
ssh -i "%PEM_KEY%" -o StrictHostKeyChecking=no %EC2_USER%@%EC2_IP% "sudo rm -rf %REMOTE_UPLOAD_PATH%/web && sudo rm -rf %REMOTE_NGINX_PATH%/* && echo Cleanup completed"

echo [OK] Old files removed
echo.

REM 업로드 디렉토리 생성
echo [UPLOAD] Preparing upload directory...
ssh -i "%PEM_KEY%" -o StrictHostKeyChecking=no %EC2_USER%@%EC2_IP% "sudo mkdir -p %REMOTE_UPLOAD_PATH%"

REM 빌드 결과물 업로드
echo [UPLOAD] Uploading build to EC2...
scp -i "%PEM_KEY%" -o StrictHostKeyChecking=no -r build\web %EC2_USER%@%EC2_IP%:%REMOTE_UPLOAD_PATH%/

if errorlevel 1 (
    echo [ERROR] Upload failed!
    exit /b 1
)

echo [OK] Upload completed
echo.

REM 서버에서 배포
echo [DEPLOY] Deploying to Nginx...
ssh -i "%PEM_KEY%" -o StrictHostKeyChecking=no %EC2_USER%@%EC2_IP% "sudo mkdir -p %REMOTE_NGINX_PATH% && sudo cp -r %REMOTE_UPLOAD_PATH%/web/* %REMOTE_NGINX_PATH%/ && sudo chown -R nginx:nginx %REMOTE_NGINX_PATH% && sudo chmod -R 755 %REMOTE_NGINX_PATH% && sudo systemctl reload nginx && echo Deployment completed"

if errorlevel 1 (
    echo [ERROR] Deployment failed!
    exit /b 1
)

echo [OK] Deployment completed
echo.

REM 완료 메시지
echo ======================================
echo   Deployment Successful!
echo ======================================
echo.
echo Test URL: http://%EC2_IP%
echo API URL: %API_URL%
echo.
echo Next steps:
echo   1. Open browser: http://%EC2_IP%
echo   2. Test all features
echo   3. Check browser console for errors
echo.

pause
