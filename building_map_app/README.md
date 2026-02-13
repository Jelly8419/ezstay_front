# EZStay - Flutter Web Application

EZStay는 숙박 시설 예약 및 호스트 관리 서비스를 제공하는 Flutter 웹/모바일 애플리케이션입니다.

## 프로젝트 구조

자세한 프로젝트 구조 및 개발 가이드는 [CLAUDE.md](../CLAUDE.md)를 참고하세요.

## 빠른 시작

### 환경 설정

1. **Flutter SDK 설치**
   ```bash
   # Flutter 3.9.2 이상 필요
   flutter --version
   ```

2. **의존성 설치**
   ```bash
   flutter pub get
   ```

3. **환경 변수 설정**
   ```bash
   # .env 파일 생성 (또는 .env.example 복사)
   cp .env.example .env
   ```

   `.env` 파일 예시:
   ```env
   KAKAO_REST_API_KEY=your_rest_api_key
   KAKAO_JAVASCRIPT_KEY=your_javascript_key
   API_BASE_URL=http://localhost:8080
   ```

### 로컬 실행

```bash
# 웹 개발 서버 실행
flutter run -d chrome

# 또는 특정 포트 지정
flutter run -d chrome --web-port=3000
```

### 빌드

```bash
# 프로덕션 웹 빌드
flutter build web --release --base-href=/app/

# 빌드 결과물 확인
ls -lh build/web/
```

## 배포

### 자동 배포 (권장)

GitHub Actions를 통한 자동 배포가 설정되어 있습니다.

```bash
# develop 브랜치에 push → 자동으로 test 환경 배포
git add .
git commit -m "feat: 새로운 기능"
git push origin develop
```

**배포 상태 확인:**
- GitHub → Actions 탭에서 워크플로우 진행 상황 확인
- 약 5-8분 소요

**자세한 배포 가이드:** [DEPLOYMENT.md](DEPLOYMENT.md)

### 수동 배포

**Windows:**
```powershell
.\deploy_to_ec2.ps1 test
```

**Linux/Mac:**
```bash
bash deploy_to_ec2.sh test
```

## 테스트

```bash
# 모든 테스트 실행
flutter test

# 특정 테스트 실행
flutter test test/services/token_service_test.dart

# 커버리지 확인
flutter test --coverage
```

## 주요 기능

- 🔐 Kakao 소셜 로그인
- 🏠 게스트/호스트 듀얼 모드
- 🗺️ Kakao Map API 통합
- 📸 이미지 업로드 및 최적화
- 🎨 반응형 디자인 (모바일/태블릿/데스크톱)
- 🔄 자동 배포 (GitHub Actions)

## 기술 스택

- **프레임워크:** Flutter 3.9.2+
- **상태 관리:** Provider
- **라우팅:** GoRouter
- **인증:** Kakao Login SDK
- **배포:** GitHub Actions + EC2

## 프로젝트 문서

- [CLAUDE.md](../CLAUDE.md) - 전체 프로젝트 구조 및 개발 가이드
- [DEPLOYMENT.md](DEPLOYMENT.md) - 배포 가이드 및 트러블슈팅

## 환경

- **Test:** `https://ezstay-api.duckdns.org`
- **Production:** `https://api.ezstay.com`

## 지원

문제가 발생하면 [GitHub Issues](https://github.com/your-repo/issues)에 등록해주세요.
