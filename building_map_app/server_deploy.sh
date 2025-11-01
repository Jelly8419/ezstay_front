#!/bin/bash
# EZStay 서버 측 배포 스크립트 (EC2에서 실행)
# 사용법: sudo bash server_deploy.sh

set -e  # 에러 시 즉시 중단

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 설정
UPLOAD_PATH="/opt/ezstay/frontend/flutter"
NGINX_PATH="/var/www/flutter"
BACKUP_PATH="/opt/ezstay/backups/flutter"

echo -e "${CYAN}======================================"
echo "  EZStay Server Deployment"
echo -e "======================================${NC}"
echo ""

# Root 권한 확인
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ This script must be run as root (use sudo)${NC}"
    exit 1
fi

# 1. 백업 생성 (기존 파일이 있는 경우)
if [ -d "$NGINX_PATH" ] && [ "$(ls -A $NGINX_PATH)" ]; then
    echo -e "${YELLOW}📦 Creating backup...${NC}"
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    mkdir -p "$BACKUP_PATH"
    tar -czf "$BACKUP_PATH/flutter_backup_$TIMESTAMP.tar.gz" -C "$NGINX_PATH" . 2>/dev/null || true
    echo -e "${GREEN}✅ Backup created: flutter_backup_$TIMESTAMP.tar.gz${NC}"
else
    echo -e "${YELLOW}⚠️  No existing files to backup${NC}"
fi

echo ""

# 2. 기존 파일 삭제
echo -e "${YELLOW}🧹 Cleaning old files...${NC}"
rm -rf "$NGINX_PATH"/*
echo -e "${GREEN}✅ Old files removed${NC}"

echo ""

# 3. 새 파일 배포
echo -e "${YELLOW}🚀 Deploying new build...${NC}"

if [ ! -d "$UPLOAD_PATH/web" ]; then
    echo -e "${RED}❌ Build files not found at $UPLOAD_PATH/web${NC}"
    echo -e "${YELLOW}Please upload files first using SCP${NC}"
    exit 1
fi

# Nginx 디렉토리로 복사
mkdir -p "$NGINX_PATH"
cp -r "$UPLOAD_PATH/web/"* "$NGINX_PATH/"

# 권한 설정
chown -R nginx:nginx "$NGINX_PATH"
chmod -R 755 "$NGINX_PATH"

echo -e "${GREEN}✅ Files deployed${NC}"

echo ""

# 4. Nginx 설정 확인
echo -e "${YELLOW}🔍 Checking Nginx configuration...${NC}"
nginx -t

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Nginx configuration is valid${NC}"
else
    echo -e "${RED}❌ Nginx configuration error${NC}"
    exit 1
fi

echo ""

# 5. Nginx 재시작
echo -e "${YELLOW}🔄 Reloading Nginx...${NC}"
systemctl reload nginx

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Nginx reloaded successfully${NC}"
else
    echo -e "${RED}❌ Failed to reload Nginx${NC}"
    exit 1
fi

echo ""

# 6. 배포 확인
echo -e "${YELLOW}📊 Deployment verification...${NC}"
echo "Files in $NGINX_PATH:"
ls -lh "$NGINX_PATH" | head -10

echo ""
echo "Disk usage:"
du -sh "$NGINX_PATH"

echo ""

# 7. 완료 메시지
echo -e "${CYAN}======================================"
echo -e "${GREEN}  🎉 Deployment Successful!"
echo -e "${CYAN}======================================${NC}"
echo ""
echo -e "${CYAN}📁 Deployment path: $NGINX_PATH${NC}"
echo -e "${CYAN}💾 Backup path: $BACKUP_PATH${NC}"
echo -e "${CYAN}🌐 Server IP: $(curl -s ifconfig.me 2>/dev/null || echo 'N/A')${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Test the website in browser"
echo "  2. Check logs: sudo tail -f /var/log/nginx/access.log"
echo "  3. Monitor errors: sudo tail -f /var/log/nginx/error.log"
echo ""

# 8. 백업 목록 표시
if [ -d "$BACKUP_PATH" ]; then
    echo -e "${YELLOW}📋 Available backups:${NC}"
    ls -lht "$BACKUP_PATH" | head -5
    echo ""
fi

echo -e "${GREEN}✨ Deployment completed successfully!${NC}"
