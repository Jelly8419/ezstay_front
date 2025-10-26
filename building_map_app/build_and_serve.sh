#!/bin/bash

# 프로덕션 빌드 및 서버 실행 스크립트
# 사용법: ./build_and_serve.sh

set -e  # 에러 발생 시 스크립트 중단

echo "🚀 EZStay 프로덕션 빌드 시작..."
echo ""

# 1. 의존성 업데이트
echo "📦 의존성 업데이트 중..."
flutter pub get
echo "✅ 의존성 업데이트 완료"
echo ""

# 2. 프로덕션 빌드
echo "🔨 프로덕션 빌드 실행 중..."
flutter build web --release \
  --tree-shake-icons \
  --dart2js-optimization=O4 \
  --no-source-maps \
  --web-renderer auto

echo "✅ 프로덕션 빌드 완료"
echo ""

# 3. 번들 크기 확인
echo "📊 번들 크기 확인..."
BUILD_DIR="build/web"
if [ -d "$BUILD_DIR" ]; then
  MAIN_JS_SIZE=$(du -h "$BUILD_DIR/main.dart.js" 2>/dev/null | cut -f1)
  TOTAL_SIZE=$(du -sh "$BUILD_DIR" | cut -f1)
  echo "   main.dart.js: $MAIN_JS_SIZE"
  echo "   전체 크기: $TOTAL_SIZE"
else
  echo "   빌드 디렉토리를 찾을 수 없습니다."
fi
echo ""

# 4. 로컬 서버 실행 (포트 3000)
echo "🌐 로컬 서버 시작 중 (포트 3000)..."
echo "   URL: http://localhost:3000"
echo ""
echo "⏹️  서버 중지: Ctrl+C"
echo ""

cd build/web

# Python 버전 확인 및 서버 실행
if command -v python3 &> /dev/null; then
  python3 -m http.server 3000
elif command -v python &> /dev/null; then
  python -m http.server 3000
else
  echo "❌ Python이 설치되어 있지 않습니다."
  echo "   대안: npx serve -p 3000"
  exit 1
fi
