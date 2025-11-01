# EZStay Flutter 웹 빌드 및 EC2 배포 스크립트
# 사용법: .\deploy_to_ec2.ps1 [test|production]

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('test', 'production')]
    [string]$Environment = 'test'
)

# 설정
$PEM_KEY = "C:\study\ezstay_test-key.pem"
$EC2_IP = "98.94.160.132"
$EC2_USER = "ec2-user"
$REMOTE_UPLOAD_PATH = "/opt/ezstay/frontend/flutter"
$REMOTE_NGINX_PATH = "/var/www/flutter"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  EZStay EC2 Deployment Script" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# 1. 환경 설정 확인
Write-Host "🔧 Environment: $Environment" -ForegroundColor Yellow

if ($Environment -eq 'test') {
    $API_URL = "https://ezstay-api.duckdns.org"
} else {
    $API_URL = "https://api.ezstay.com"
}

Write-Host "🌐 API URL: $API_URL" -ForegroundColor Cyan
Write-Host ""

# 2. PEM 키 파일 확인
if (-not (Test-Path $PEM_KEY)) {
    Write-Host "❌ PEM key not found: $PEM_KEY" -ForegroundColor Red
    exit 1
}

Write-Host "✅ PEM key found" -ForegroundColor Green
Write-Host ""

# 3. 환경별 .env 파일 복사
Write-Host "📝 Copying .env.$Environment file..." -ForegroundColor Yellow

$envFile = ".env.$Environment"
if (Test-Path $envFile) {
    Copy-Item $envFile .env -Force
    Write-Host "✅ Using $envFile" -ForegroundColor Green
} else {
    Write-Host "⚠️  Warning: $envFile not found, using default .env" -ForegroundColor Yellow
}

Write-Host ""

# 4. Flutter 웹 빌드
Write-Host "🏗️  Building Flutter web..." -ForegroundColor Yellow
flutter build web --release `
    --base-href=/app/ `
    --dart-define=ENVIRONMENT=$Environment `
    --dart-define=API_BASE_URL=$API_URL

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build completed" -ForegroundColor Green
Write-Host ""

# 4. 서버에서 기존 파일 삭제
Write-Host "🧹 Cleaning old files on server..." -ForegroundColor Yellow

$CLEANUP_SCRIPT = @"
sudo rm -rf $REMOTE_UPLOAD_PATH/web
sudo rm -rf $REMOTE_NGINX_PATH/*
echo 'Cleanup completed'
"@

# SSH로 정리 스크립트 실행
ssh -i $PEM_KEY -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" $CLEANUP_SCRIPT

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Cleanup warning (may be first deployment)" -ForegroundColor Yellow
} else {
    Write-Host "✅ Old files removed" -ForegroundColor Green
}

Write-Host ""

# 5. 빌드 결과물 업로드
Write-Host "📦 Uploading build to EC2..." -ForegroundColor Yellow

# 업로드 디렉토리 생성
ssh -i $PEM_KEY -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" "sudo mkdir -p $REMOTE_UPLOAD_PATH"

# SCP로 파일 전송
scp -i $PEM_KEY -o StrictHostKeyChecking=no -r build\web "$EC2_USER@$EC2_IP`:$REMOTE_UPLOAD_PATH/"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Upload failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Upload completed" -ForegroundColor Green
Write-Host ""

# 6. 서버에서 배포
Write-Host "🚀 Deploying to Nginx..." -ForegroundColor Yellow

$DEPLOY_SCRIPT = @"
# Nginx 디렉토리로 복사
sudo mkdir -p $REMOTE_NGINX_PATH
sudo cp -r $REMOTE_UPLOAD_PATH/web/* $REMOTE_NGINX_PATH/

# 권한 설정
sudo chown -R nginx:nginx $REMOTE_NGINX_PATH
sudo chmod -R 755 $REMOTE_NGINX_PATH

# Nginx 재시작
sudo systemctl reload nginx

echo 'Deployment completed'
"@

ssh -i $PEM_KEY -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" $DEPLOY_SCRIPT

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Deployment completed" -ForegroundColor Green
Write-Host ""

# 7. 완료 메시지
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  🎉 Deployment Successful!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🌐 Test URL: http://$EC2_IP" -ForegroundColor Cyan
Write-Host "📊 API URL: $API_URL" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Open browser: http://$EC2_IP" -ForegroundColor Gray
Write-Host "  2. Test all features" -ForegroundColor Gray
Write-Host "  3. Check browser console for errors" -ForegroundColor Gray
Write-Host ""
