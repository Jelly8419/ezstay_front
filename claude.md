# EZStay Frontend - CLAUDE.md

## 프로젝트
Flutter 기반 숙박 예약 앱 (게스트/호스트). Provider + GoRouter + Kakao Map/Login.

## 🚫 항상 적용되는 규칙
- `flutter run` 실행 금지
- `git commit/push/add` 금지 (명시 요청 시에만)
- 하드코딩 금지 → AppColors / AppTextStyles / AppSpacing 사용
- 모든 새 페이지 → ResponsiveScaffold 또는 ResponsivePageLayout 사용

---

## 📂 스킬 자동 매칭 규칙

### policy-skill.md 로드 조건
**키워드**: 계약, contract, 결제, payment, 보증금, 수수료, 채팅, 옵션, D-5, 상태 전이
**의도**: 계약/결제 관련 기능 구현, 상태 변경, 옵션 처리

### claude-rules-skill.md 로드 조건
**키워드**: 리액트 코드, React 코드, UI 변환, 컴포넌트 변환
**의도**: 리액트 → Flutter 변환 작업, UI/UX 개선 요청
**항상 로드**: 모든 작업 시작 전

### design-system-skill.md 로드 조건
**키워드**: UI, 위젯, 컴포넌트, 디자인, 색상, 스타일, 레이아웃, 카드, 버튼, 애니메이션
**파일 경로**: `lib/pages/`, `lib/widgets/`, `lib/shared/`, `lib/core/theme/`
**의도**: 새 화면 개발, UI 수정, 스타일 변경

### architecture-skill.md 로드 조건
**키워드**: 구조, 아키텍처, 서비스, 레포지토리, 라우팅, 인증, 토큰
**파일 경로**: `lib/services/`, `lib/repositories/`, `lib/config/`, `lib/router/`
**의도**: 새 서비스/기능 추가, 구조 파악

---

## API 기본 URL
`http://localhost:8080`

## 환경변수 (.env)
```
KAKAO_REST_API_KEY / KAKAO_JAVASCRIPT_KEY
API_BASE_URL / API_TIMEOUT_SECONDS / IS_PRODUCTION
```
