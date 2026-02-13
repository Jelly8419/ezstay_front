## 📋 서비스 정책 준수 (필수)

**모든 코드 구현 시 반드시 서비스 정책을 참조할 것:**

- **정책 문서**: `claudedocs/service-policy.md` — EZStay 전체 도메인 정책 (Domain 0~14)
- **준수 분석**: `claudedocs/policy-compliance-analysis.md` — 현재 구현 상태 및 개선 로드맵

### 코드 구현 시 정책 체크 규칙

1. **계약(Contract) 관련 코드 작성 시**:
   - 상태 전이는 순방향만 허용 (REQUESTED→APPROVED→PAID→IN_PROGRESS→COMPLETED)
   - 상세주소는 결제 완료(PAID) 이후에만 노출
   - 호스트에게 게스트의 옵션/할인 정보 노출 금지
   - 시간 제한 정책: 승인 72h, 결제 24h, 퇴실확인 48h

2. **금액/결제 관련 코드 작성 시**:
   - 보증금 300,000원 고정
   - 호스트 수수료 3.3%, 게스트 수수료 9.9%
   - 금액 계산은 원 단위 절삭 (소수점 버림)
   - 결제 완료 시점 스냅샷 고정 원칙

3. **방 등록/수정 관련 코드 작성 시**:
   - 승인 후 수정 가능: 가격, 편의시설, 설명, 사진, 최대 인원
   - 승인 후 수정 불가 (재심사): 주소, 건물유형, 면적, 방/화장실 수

4. **채팅/알림 관련 코드 작성 시**:
   - 채팅은 유효한 계약 당사자만 가능
   - 취소/종료 계약 채팅방은 읽기 전용
   - 정산/보증금/분쟁 알림 타입 포함

5. **옵션 관련 코드 작성 시**:
   - D-5 정책: 입주 5일 전 기준 추가/취소 제한
   - 결제 전: 추가/수정/취소 자유
   - D-5 이전: 추가/취소 가능 (전액 환불)
   - D-5 이후: 취소만 가능 (환불 정책 적용)
   - 임대 중: 요청만 가능

---

## ⚠️ 중요: Claude 작업 규칙

### 🚫 절대 금지 사항
1. **앱 실행 금지**: 버그 수정이나 기능 추가 후 `flutter run` 명령어를 **절대 실행하지 말 것**
   - 사용자가 디버깅 모드에서 핫 리로드로 직접 확인함
   - 포트 충돌 및 불필요한 프로세스 생성 방지

2. **Git 작업 금지**: 사용자가 명시적으로 요청하기 전까지 다음 작업을 **절대 하지 말 것**
   - git commit - 커밋 생성 금지
   - git push - 원격 저장소로 푸시 금지
   - git add - 스테이징 금지 (명시적 요청 시에만)

### 🎨 UI/UX 개발 최우선 규칙

**사용자가 리액트 코드 또는 PRD를 제공할 때, 반드시 다음 우선순위를 따를 것:**

1. **리액트 UI/UX 최우선 준수** ⭐
   - 사용자가 제공한 **리액트 코드의 UI/UX가 절대적 우선순위**
   - PRD는 기능 요구사항 참고용으로만 사용
   - 리액트 코드와 PRD가 충돌하면 **무조건 리액트 코드를 따름**

2. **UI 기능 제거 vs 비즈니스 로직 유지 구분** 🔐

   **✅ 제거 대상 (UI 레벨 기능):**
   - 사용자에게 보이는 UI 요소 (버튼, 입력 필드, 필터 등)
   - UI 상호작용 (호버 효과, 애니메이션, 드롭다운 등)
   - 화면 레이아웃 및 배치
   - 예시: 리액트에 날짜 검색만 있으면 → Flutter UI에서 금액/인원 검색 **UI만** 제거

   **🔒 절대 제거 금지 (비즈니스 로직):**
   - 사용자 권한 체크 (`user.role`, `hasPermission()` 등)
   - Firebase Analytics 이벤트 로깅
   - API 호출 및 에러 핸들링
   - 데이터 검증 및 보안 로직
   - 상태 관리 및 데이터 흐름
   - 토큰 관리, 인증/인가 로직
   - 예시: UI에서 금액 필터 제거해도 → 백엔드 API에 금액 파라미터는 유지

   **⚠️ 판단 기준:**
   ```
   UI 레벨인가? → 리액트 코드 따라 제거
   비즈니스 로직인가? → 기존 Flutter 코드 유지
   애매한가? → 사용자에게 확인 요청
   ```

3. **기존 Flutter UI 기능 제거 규칙**
   - 리액트 **UI**에 없는 **UI 요소**는 과감하게 제거
   - 단, 비즈니스 로직(권한, 분석, 보안)은 **반드시 유지**
   - 사용자에게 확인 요청은 애매한 경우에만 (명확하면 바로 진행)

4. **UI 컴포넌트 구조 완전 복제**
   ```
   리액트 코드 분석 순서:
   1️⃣ 레이아웃 구조 (Flexbox → Column/Row)
   2️⃣ 컴포넌트 계층 (부모-자식 관계)
   3️⃣ 스타일링 (색상, 간격, 폰트, 그림자 등)
   4️⃣ 인터랙션 (호버, 클릭, 애니메이션)
   5️⃣ 반응형 처리 (breakpoints)
   ```

5. **스타일링 완전 매칭**
   - CSS 속성을 Flutter 위젯 속성으로 1:1 변환
   - Tailwind CSS 클래스명 → AppColors/AppSpacing 매핑
   - 색상 코드, 간격, 폰트 크기 등 **정확히 일치**시킬 것

6. **구현 전 체크리스트**
   ```
   ✅ 리액트 코드의 전체 구조 파악 완료
   ✅ 제거할 기존 Flutter UI 요소 목록 작성 (비즈니스 로직은 제외)
   ✅ 유지할 비즈니스 로직 확인 (권한, Analytics, API 등)
   ✅ 필요한 Flutter 위젯 매핑 완료
   ✅ 디자인 시스템 (AppColors, AppSpacing) 활용 계획
   ✅ 반응형 처리 방법 (ResponsiveUtil) 계획
   ```

**예시 시나리오:**

❌ **잘못된 접근:**
```
사용자: "이 리액트 코드로 게스트홈 개선해줘" (날짜 검색만 있음)
Claude: "기존 금액/인원 검색 기능도 유지할까요?"
→ 사용자에게 되물으면 안 됨!
```

✅ **올바른 접근:**
```
사용자: "이 리액트 코드로 게스트홈 개선해줘" (날짜 검색만 있음)
Claude:
"✅ 리액트 UI 분석 완료:
- 날짜 검색 (체크인/체크아웃)만 존재
- 금액/인원 검색 필터 없음

📝 작업 계획:
1. UI 레벨 변경:
   - 기존 금액/인원 검색 UI 제거
   - 날짜 검색 컴포넌트로 단순화
   - 리액트 코드의 레이아웃/스타일 완전 복제

2. 비즈니스 로직 유지:
   ✅ Firebase Analytics 이벤트 로깅 유지
   ✅ 사용자 권한 체크 로직 유지
   ✅ API 호출 및 에러 핸들링 유지

🚀 구현 시작합니다..."
```

**실전 예시 (권한 체크 + UI 변경):**
```dart
// ❌ 잘못된 방법 - 비즈니스 로직까지 제거
Widget build(BuildContext context) {
  return DateSearchWidget(); // 권한 체크 로직 삭제됨!
}

// ✅ 올바른 방법 - UI만 변경, 비즈니스 로직 유지
Widget build(BuildContext context) {
  // 권한 체크 로직 유지
  final user = Provider.of<AuthService>(context).currentUser;
  if (user == null) return LoginPrompt();

  // Firebase Analytics 이벤트 로깅 유지
  _logPageView();

  // UI만 리액트 코드에 맞게 변경
  return DateSearchWidget(); // 날짜 검색만 표시
}
```

**작업 후 보고 형식 (UI/UX 개선 시):**
```
✅ 리액트 UI 기반 구현 완료

🎨 적용된 UI/UX:
- [리액트 컴포넌트명] → [Flutter 위젯명]
- 제거된 UI 요소: [목록]
- 추가된 UI 요소: [목록]

🔒 유지된 비즈니스 로직:
- Firebase Analytics: ✅ 유지
- 사용자 권한 체크: ✅ 유지
- API 호출 로직: ✅ 유지
- [기타 중요 로직]: ✅ 유지

📊 변경 파일: [파일명:라인번호]

🔄 핫 리로드 대기 중...
```

### ✅ 허용되는 작업
- 코드 읽기 및 분석
- 버그 수정 및 기능 구현 (파일 수정)
- 테스트 코드 작성
- 문서 업데이트
- 코드 리뷰 및 제안
- Git 상태 확인 (git status, git diff, git log 등)

### 📋 작업 후 보고 형식
코드 수정 완료 후 다음 형식으로 보고:
```
✅ 수정 완료: [파일명:라인번호]
- 변경 내용 요약
- 해결된 문제 설명

🔄 핫 리로드 대기 중...
```

# EZStay Front - EZStay

## 프로젝트 개요

EZStay는 숙박 시설 예약 및 호스트 관리 서비스를 제공하는 Flutter 웹/모바일 애플리케이션입니다.

- **프로젝트명**: building_map_app (EZStay)
- **프레임워크**: Flutter 3.9.2+
- **플랫폼**: Web, Android, iOS, Windows, Linux, macOS
- **상태 관리**: Provider
- **라우팅**: GoRouter
- **지도**: Kakao Map API
- **인증**: Kakao Login SDK

## 프로젝트 구조

```
building_map_app/
├── lib/
│   ├── config/           # 설정 파일 (API, Kakao)
│   ├── constants/        # 전역 상수 (색상, 스타일, 설정값)
│   ├── data/            # 더미 데이터 및 데이터 소스
│   ├── models/          # 데이터 모델 (Building, User 등)
│   ├── pages/           # UI 페이지
│   ├── repositories/    # 데이터 저장소 (User 등)
│   ├── router/          # 라우팅 설정 (GoRouter)
│   ├── services/        # 비즈니스 로직 (Auth, API, Room, Token, Image 등)
│   ├── utils/           # 유틸리티 (반응형 등)
│   ├── widgets/         # 재사용 가능한 위젯
│   │   └── common/      # 공통 UI 컴포넌트
│   └── main.dart        # 앱 진입점
├── test/                # 테스트 파일
│   ├── repositories/    # Repository 테스트
│   ├── services/        # Service 테스트
│   └── utils/           # Utility 테스트
├── .env                 # 환경 변수 (API 키 등)
├── pubspec.yaml         # 패키지 의존성
└── README.md
```

## 주요 디렉토리 설명

### `/lib/config/`
- `api_config.dart` - API 엔드포인트 중앙 관리, 환경별 설정
- `kakao_config.dart` - Kakao API 키 관리

### `/lib/constants/`
- `app_constants.dart` - 전역 상수 (색상, 텍스트 스타일, 레이아웃 설정)

### `/lib/models/`
- `building.dart` - 건물/숙박 시설 데이터 모델
- `user.dart` - 사용자 데이터 모델

### `/lib/pages/`
- `welcome_page.dart` - 웰컴 화면
- `login_page.dart` - 로그인 페이지
- `mode_selection_page.dart` - 게스트/호스트 모드 선택
- `guest_home_page.dart` - 게스트 홈
- `host_home_page.dart` - 호스트 홈
- `room_registration_page.dart` - 방 등록 페이지
- `pricing_page.dart` - 요금 설정 페이지
- `room_amenities_page.dart` - 편의시설 설정 페이지
- `free_services_page.dart` - 무료 부가서비스 설정 페이지
- `room_description_page.dart` - 방 소개 페이지
- `user_info_popup.dart` - 사용자 정보 팝업

### `/lib/repositories/`
- `user_repository.dart` - 사용자 정보 CRUD (SecureStorage 관리)

### `/lib/services/`
- `auth_service.dart` - 인증 서비스 (Kakao 로그인, 사용자 관리)
- `token_service.dart` - JWT 토큰 관리 및 검증
- `api_client.dart` - HTTP API 클라이언트 (타입 안전 에러 핸들링)
- `room_service.dart` - 방 등록/관리 서비스
- `image_service.dart` - 이미지 압축 및 최적화
- `error_handler_service.dart` - 전역 에러 핸들링

### `/lib/utils/`
- `responsive_util.dart` - 반응형 디자인 유틸리티

### `/lib/widgets/`
- `kakao_map_web.dart` - 웹용 카카오 지도 위젯
- `daum_postcode_widget.dart` - Daum 우편번호 검색 (모바일)
- `daum_postcode_web.dart` - Daum 우편번호 검색 (웹)
- `registration_flow_indicator.dart` - 등록 진행 상태 표시

### `/lib/widgets/common/` (공통 컴포넌트)
- `custom_text_field.dart` - 재사용 가능한 텍스트 입력 필드
- `custom_button.dart` - 재사용 가능한 버튼 (로딩 상태 지원, 그림자 효과)
- `custom_dropdown.dart` - 재사용 가능한 드롭다운
- `custom_card.dart` - 재사용 가능한 카드 (떠있는 느낌, 호버 효과)
- `responsive_page_layout.dart` - 반응형 페이지 레이아웃 래퍼 (카드 스타일 옵션 지원)

### `/lib/router/`
- `app_router.dart` - GoRouter 기반 앱 라우팅 설정

## 주요 기능

### 1. 인증 시스템
- Kakao 소셜 로그인
- 자동 로그인 (토큰 기반)
- flutter_secure_storage를 통한 안전한 토큰 저장

### 2. 사용자 모드
- **게스트 모드**: 숙박 시설 검색 및 예약
- **호스트 모드**: 숙박 시설 등록 및 관리

### 3. 지도 기능
- Kakao Map API 통합
- 웹/네이티브 플랫폼별 지도 구현
- 마커 표시 및 클릭 이벤트

### 4. 방 등록 프로세스
- 다단계 등록 플로우 (주소 → 요금 → 편의시설 → 부가서비스 → 소개)
- 등록 진행 상태 추적
- 이미지 업로드 (image_picker)

## 기술 스택

### 핵심 패키지
- `provider: ^6.1.2` - 상태 관리
- `go_router: ^16.2.4` - 선언적 라우팅
- `kakao_map_plugin: ^0.3.1` - 카카오 지도
- `kakao_flutter_sdk_user: ^1.9.1+2` - 카카오 로그인
- `flutter_secure_storage: ^9.2.2` - 보안 저장소
- `flutter_dotenv: ^5.1.0` - 환경 변수 관리
- `http: ^1.1.0` - HTTP 요청
- `image_picker: ^1.2.0` - 이미지 선택
- `webview_flutter: ^4.4.2` - 웹뷰 (우편번호 검색)
- `jwt_decode: ^0.3.1` - JWT 토큰 디코딩 및 검증
- `flutter_image_compress: ^2.3.0` - 이미지 압축
- `cached_network_image: ^3.4.1` - 네트워크 이미지 캐싱

## 환경 변수 설정

`.env` 파일에 다음 API 키를 설정해야 합니다:

```env
# Kakao API Keys
KAKAO_REST_API_KEY=your_rest_api_key
KAKAO_JAVASCRIPT_KEY=your_javascript_key

# Backend API URLs
API_BASE_URL=http://localhost:8080
API_TIMEOUT_SECONDS=10

# Environment
IS_PRODUCTION=false
```

`.env.example` 파일을 참고하여 `.env` 파일을 생성하세요.

## 실행 방법

### 웹
```bash
cd building_map_app
flutter run -d chrome
```

### 모바일
```bash
cd building_map_app
flutter run
```

### 패키지 설치
```bash
cd building_map_app
flutter pub get
```

## API 엔드포인트

백엔드 API 기본 URL: `http://localhost:8080`

### 인증 API
- `POST /api/auth/login` - 이메일 로그인
- `POST /api/auth/register` - 회원가입
- `POST /api/auth/logout` - 로그아웃
- `POST /auth/kakao` - 카카오 토큰 백엔드 인증 (모바일)
- `GET /api/auth/kakao?code={code}` - 카카오 인증 코드 처리 (웹)
- `GET /api/auth/profile` - 사용자 프로필 조회 (JWT 토큰 검증)
- `POST /api/auth/refresh` - Access 토큰 갱신

### 방 관리 API (호스트)
- `POST /api/host/rooms` - 방 기본 정보 등록
- `GET /api/host/rooms` - 등록 중인 방 목록 조회
- `GET /api/host/rooms/{roomId}` - 방 정보 조회
- `PATCH /api/host/rooms/{roomId}/pricing` - 요금 설정
- `POST /api/host/rooms/{roomId}/photos` - 사진 업로드
- `PATCH /api/host/rooms/{roomId}/photos/reorder` - 사진 순서 변경
- `DELETE /api/host/rooms/{roomId}/photos/{photoId}` - 사진 삭제
- `PATCH /api/host/rooms/{roomId}/amenities` - 편의시설 설정
- `PATCH /api/host/rooms/{roomId}/free-services` - 무료 부가서비스 설정
- `POST /api/host/rooms/{roomId}/cleaning-tool-image` - 청소도구 이미지 업로드
- `PATCH /api/host/rooms/{roomId}/description` - 방 소개 설정
- `POST /api/host/rooms/{roomId}/submit-review` - 심사 요청

## 라우팅 구조

GoRouter 기반 라우팅:
- `/` - 웰컴 페이지
- `/login` - 로그인
- `/mode-selection` - 모드 선택
- `/guest-home` - 게스트 홈
- `/host-home` - 호스트 홈
- `/room-registration` - 방 등록
  - `/room-registration/pricing` - 요금 설정
  - `/room-registration/amenities` - 편의시설
  - `/room-registration/free-services` - 부가서비스
  - `/room-registration/description` - 방 소개

## 코딩 컨벤션

### 파일명
- 소문자 + 언더스코어 사용 (snake_case)
- 예: `auth_service.dart`, `room_registration_page.dart`

### 클래스명
- PascalCase 사용
- 예: `AuthService`, `RoomRegistrationPage`

### 주석
- Dart 문서 주석(`///`) 사용
- 주요 클래스 및 메서드에 설명 추가

### 상태 관리
- Provider 패턴 사용
- `ChangeNotifier`를 상속받아 상태 관리 클래스 구현

### UI/디자인 가이드라인

#### 1. 디자인 시스템 구조 (중앙화된 테마)

프로젝트는 **모던 부동산 플랫폼 스타일**의 중앙화된 디자인 시스템을 사용합니다.

**디렉토리 구조:**
```
lib/
├── core/theme/              # 중앙화된 디자인 시스템
│   ├── app_colors.dart      # 색상 시스템
│   ├── app_text_styles.dart # 타이포그래피 시스템
│   └── app_spacing.dart     # 간격, 그림자, 애니메이션
├── shared/widgets/          # 재사용 가능한 공통 위젯
│   └── hover_card.dart      # 인터랙티브 호버 카드
└── widgets/                 # 페이지별 위젯
```

#### 2. 테마 시스템 사용 (필수)

**색상 시스템:**
```dart
import '../core/theme/app_colors.dart';

// ✅ 올바른 방법 - 중앙화된 색상 사용
Container(color: AppColors.primary500)
Container(color: AppColors.surface)
Text('텍스트', style: TextStyle(color: AppColors.textPrimary))
Border.all(color: AppColors.border)

// ❌ 잘못된 방법 - 하드코딩 금지
Container(color: Color(0xFF4A90E2))
Text('텍스트', style: TextStyle(color: Colors.black))
```

**타이포그래피:**
```dart
import '../core/theme/app_text_styles.dart';

// ✅ 올바른 방법
Text('제목', style: AppTextStyles.headingLarge)
Text('본문', style: AppTextStyles.bodyMedium)
Text('가격', style: AppTextStyles.priceText)

// 색상 변형
Text('부제목', style: AppTextStyles.bodyMediumSecondary)
Text('에러', style: AppTextStyles.bodySmallError)

// ❌ 잘못된 방법
Text('제목', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))
```

**간격 및 레이아웃:**
```dart
import '../core/theme/app_spacing.dart';

// ✅ 올바른 방법 - 8pt 그리드 시스템
Padding(padding: AppSpacing.paddingMd)  // 16px
SizedBox(height: AppSpacing.lg)         // 24px
SizedBox(width: AppSpacing.xs)          // 4px

// BorderRadius
BorderRadius.circular(AppRadius.md)     // 12px
BorderRadius.circular(AppRadius.lg)     // 16px

// ❌ 잘못된 방법
EdgeInsets.all(16)
BorderRadius.circular(12)
```

#### 3. 그림자 시스템 (중앙화)

**카드 그림자 (3단계):**
```dart
import '../core/theme/app_spacing.dart';

Container(
  decoration: BoxDecoration(
    // 기본 상태 - 미세한 떠있는 느낌
    boxShadow: AppShadows.cardDefault,

    // 호버 상태 - 강조된 느낌 (Primary 색상 혼합)
    boxShadow: AppShadows.cardHover,

    // 선택 상태 - 더 강조된 느낌
    boxShadow: AppShadows.cardSelected,
  ),
)

// 플로팅 버튼, 모달 등
boxShadow: AppShadows.floatingButton
boxShadow: AppShadows.modal
```

#### 4. 애니메이션 시스템 (중앙화)

**Duration & Curve:**
```dart
import '../core/theme/app_spacing.dart';

// ✅ 올바른 방법 - 중앙화된 애니메이션 설정
AnimatedContainer(
  duration: AppDurations.hoverCard,    // 300ms
  curve: AppCurves.hoverCard,          // easeOutCubic
  ...
)

// 다양한 애니메이션 타입
duration: AppDurations.listItem       // 250ms
duration: AppDurations.pageTransition // 400ms
duration: AppDurations.modal          // 350ms

curve: AppCurves.listItem        // easeOutQuart
curve: AppCurves.pageTransition  // easeInOutCubic

// ❌ 잘못된 방법
AnimatedContainer(
  duration: Duration(milliseconds: 300),
  curve: Curves.easeInOut,
)
```

#### 2. 반응형 페이지 레이아웃 (필수)
모든 새 페이지는 **ResponsivePageLayout** 또는 **ResponsiveScaffold**를 사용해야 합니다.

**방법 1: ResponsiveScaffold (권장)**
```dart
import '../widgets/common/responsive_page_layout.dart';

ResponsiveScaffold(
  title: '페이지 제목',
  useCardStyle: true,  // 떠있는 느낌의 카드 스타일
  actions: [
    IconButton(icon: Icon(Icons.settings), onPressed: () {}),
  ],
  body: Column(
    children: [
      Text('컨텐츠'),
    ],
  ),
)
```

**방법 2: ResponsivePageLayout (커스텀 AppBar가 필요한 경우)**
```dart
import '../widgets/common/responsive_page_layout.dart';

Scaffold(
  appBar: AppBar(title: Text('페이지')),
  body: ResponsivePageLayout(
    useCardStyle: true,  // 떠있는 느낌의 카드 스타일
    child: Column(
      children: [
        Text('컨텐츠'),
      ],
    ),
  ),
)
```

**특수 케이스:**
```dart
// 자체 스크롤을 처리하는 경우 (ListView 등)
ResponsivePageLayout(
  scrollable: false,
  usePadding: false,
  useCardStyle: false,  // 카드 스타일 비활성화
  child: ListView(...),
)

// 최대 너비 커스터마이징
ResponsivePageLayout(
  maxWidth: 800,  // 기본값: 1200
  useCardStyle: true,  // 카드 스타일 적용
  child: Column(...),
)
```

**❌ 하지 말아야 할 것:**
```dart
// 직접 레이아웃 래퍼 작성 금지
Center(
  child: ConstrainedBox(
    constraints: BoxConstraints(maxWidth: 1200),
    child: SingleChildScrollView(...),
  ),
)
```

#### 5. 재사용 가능한 공통 위젯 (일반화)

**기본 UI 컴포넌트:**
```dart
// CustomButton (그림자 효과 자동 적용)
CustomButton(
  text: '버튼',
  onPressed: () {},
  isLoading: false,
)

// CustomTextField
CustomTextField(
  label: '이메일',
  hint: 'email@example.com',
  controller: controller,
)

// CustomDropdown
CustomDropdown(
  label: '선택',
  value: selectedValue,
  items: items,
  onChanged: (value) {},
)
```

**인터랙티브 카드 위젯 (lib/shared/widgets/hover_card.dart):**

```dart
import '../shared/widgets/hover_card.dart';

// 1. HoverCard - 완전한 기능의 호버 카드
HoverCard(
  onTap: () => print('탭됨'),
  isSelected: false,
  enableHoverLift: true,      // 호버 시 위로 올라감
  liftHeight: 8.0,             // 올라가는 높이 (기본 8px)
  borderRadius: AppRadius.radiusMd,
  padding: AppSpacing.paddingMd,
  animationDuration: AppDurations.hoverCard,
  animationCurve: AppCurves.hoverCard,
  child: Column(
    children: [
      Text('제목'),
      Text('내용'),
    ],
  ),
)

// 2. HoverEffect - 기존 위젯에 호버 효과만 추가
HoverEffect(
  onTap: () {},
  enableLift: true,
  liftHeight: 8.0,
  child: PropertyCard(...),  // 기존 위젯
)

// 3. ImageInfoCard - 이미지 + 정보 카드
ImageInfoCard(
  imageUrl: 'https://...',
  imageHeight: 200,
  title: '강남역 도보 5분',
  subtitle: '서울시 강남구',
  badge: '신규',              // 선택사항
  trailing: Row(...),         // 하단 추가 위젯
  onTap: () {},
  isSelected: false,
)
```

**HoverCard 사용 예시:**

```dart
// ✅ 매물 카드
HoverCard(
  child: PropertyCard(room: room),
)

// ✅ 리스트 아이템
HoverEffect(
  child: ListTile(
    title: Text('아이템'),
  ),
)

// ✅ 커스텀 카드
HoverCard(
  padding: AppSpacing.paddingLg,
  child: Column(
    children: [
      Icon(Icons.home),
      Text('제목'),
      Text('설명'),
    ],
  ),
)
```

**주요 특징:**
- ✅ 호버 시 자동으로 위로 8px 상승
- ✅ 3단계 그림자 (기본/호버/선택)
- ✅ 부드러운 300ms 애니메이션
- ✅ Primary 색상 테두리 강조
- ✅ 완전히 커스터마이징 가능

#### 6. 반응형 값 가져오기
화면 크기에 따라 다른 값을 사용해야 할 때:

```dart
import '../utils/responsive_util.dart';

// 화면 크기 확인
if (ResponsiveUtil.isDesktop(context)) { ... }
if (ResponsiveUtil.isTablet(context)) { ... }
if (ResponsiveUtil.isMobile(context)) { ... }

// 반응형 값
final padding = ResponsiveUtil.getPadding(context);  // 24/20/16
final maxWidth = ResponsiveUtil.getMaxContentWidth(context);  // 1200/900/screen
final gridColumns = ResponsiveUtil.getGridCrossAxisCount(context);  // 4/3/2
```

## Git 브랜치 전략

- `main` - 프로덕션 브랜치
- `feature/*` - 기능 개발 브랜치
- 현재 브랜치: `feature/host-room-registration`

## 최근 작업 내역

### 2025-10-26: 모던 디자인 시스템 일반화 및 중앙화
- ✅ 3단계 카드 그림자 시스템 추가 (AppShadows.cardDefault/cardHover/cardSelected)
- ✅ 애니메이션 Duration/Curve 중앙화 (AppDurations, AppCurves)
- ✅ 재사용 가능한 HoverCard, HoverEffect, ImageInfoCard 위젯 생성
- ✅ PropertyCard에 모던 인터랙션 적용 (호버 시 8px 상승, 부드러운 300ms 애니메이션)
- ✅ 모든 하드코딩된 값을 디자인 시스템으로 교체
- ✅ CLAUDE.md에 디자인 시스템 일반화/중앙화 가이드 추가

### 2025-10-23: 디자인 시스템 통합 및 반응형 레이아웃 적용
- ✅ 디자인 테마 시스템 통합 (AppTheme.lightTheme())
- ✅ 전역 색상, 텍스트 스타일, 위젯 테마를 AppConstants에 중앙화
- ✅ ResponsivePageLayout 위젯 생성 (최대 너비 제한, 반응형 패딩)
- ✅ 모든 페이지에 ResponsivePageLayout 적용 (11개 페이지)
- ✅ CLAUDE.md에 UI/디자인 가이드라인 추가

### 2025-10-05: 대규모 코드 품질 개선
- ✅ 하드코딩된 URL 및 API 키를 환경 변수로 이동
- ✅ 에러 핸들링 개선 (타입 안전성, 구체적인 예외 처리)
- ✅ 보안 강화 (JWT 토큰 만료 검증, 프로덕션 로그 제거)
- ✅ TokenService 분리 (JWT 검증 기능)
- ✅ UserRepository 분리 (사용자 정보 관리)
- ✅ 공통 UI 컴포넌트 생성 (CustomTextField, CustomButton, CustomDropdown)
- ✅ 이미지 최적화 서비스 추가 (압축, 캐싱)
- ✅ 반응형 디자인 유틸리티 추가
- ✅ 테스트 코드 작성 (8개 유닛/위젯 테스트)

### 이전 작업
- 구글맵 API → 카카오맵 API로 변경
- 전역 API 에러 핸들링 및 라우팅 개선
- 방 등록 API 연동 및 등록 진행 상태 추적 기능 추가
- 요금설정, 사진 및 편의시설, 무료 부가서비스, 방 소개 페이지 추가
- go_router 적용

## 주의사항

### 플랫폼별 처리
- `kIsWeb` 플래그를 사용하여 웹/네이티브 분기 처리
- 지도, 우편번호 검색 등은 플랫폼별로 다른 구현 사용

### 보안
- API 키는 절대 커밋하지 말 것
- `.env` 파일은 `.gitignore`에 추가됨
- 토큰은 flutter_secure_storage에 저장
- JWT 토큰 자동 만료 검증 (TokenService)
- 프로덕션 환경에서 디버그 로그 자동 비활성화
- 민감한 정보(토큰 값) 로그 제거

### 웹 라우팅
- `usePathUrlStrategy()`를 사용하여 URL에서 `#` 제거
- 깔끔한 URL 구조 (예: `/login` 대신 `/#/login`)

## 아키텍처 및 설계 원칙

### 레이어 분리
- **Presentation Layer**: Pages, Widgets
- **Business Logic Layer**: Services
- **Data Layer**: Repositories, Models
- **Infrastructure**: Config, Utils

### 설계 원칙
- **단일 책임 원칙 (SRP)**: 각 클래스는 하나의 책임만
- **관심사 분리 (SoC)**: TokenService, UserRepository 분리
- **의존성 역전 (DIP)**: Repository 패턴 사용
- **테스트 가능성**: 모든 서비스는 테스트 가능

## 디버깅

### 로그 확인
- `debugPrint()` 사용
- 프로덕션 환경에서는 `ApiConfig.isProduction` 체크
- API 에러는 `ErrorHandlerService`에서 처리

### 주요 체크포인트
1. `.env` 파일 존재 여부 및 올바른 값 설정
2. Kakao API 키 유효성
3. JWT 토큰 만료 여부 (TokenService가 자동 검증)
4. 네트워크 요청 응답 확인
5. 이미지 크기 및 포맷 (5MB 이하, jpg/png/webp)

## 테스트

### 테스트 실행
```bash
cd building_map_app
flutter test
```

### 작성된 테스트
- `test/services/token_service_test.dart` - JWT 토큰 검증 테스트
- `test/repositories/user_repository_test.dart` - 사용자 저장소 테스트
- `test/services/image_service_test.dart` - 이미지 서비스 테스트
- `test/utils/responsive_util_test.dart` - 반응형 유틸리티 테스트

### 테스트 커버리지 목표
- Unit 테스트: 70% 이상
- Widget 테스트: 주요 UI 컴포넌트
- Integration 테스트: 핵심 사용자 플로우

## 코드 품질 개선 사항 (완료)

### ✅ High Priority (완료)
1. ✅ 하드코딩된 URL 및 API 키를 환경 변수로 이동
2. ✅ 에러 핸들링 개선 (타입 안전성, 구체적인 예외 처리)
3. ✅ 토큰 보안 강화 및 JWT 만료 시간 검증
4. ✅ 테스트 코드 작성 시작 (8개 테스트)
5. ✅ 서비스 계층 분리 (TokenService, UserRepository)

### ✅ Medium Priority (완료)
1. ✅ 코드 중복 제거 (공통 UI 컴포넌트)
2. ✅ 이미지 최적화 (압축, 캐싱)
3. ✅ 반응형 디자인 (모바일/태블릿/데스크톱)
4. ✅ 전역 상수 관리 (AppConstants)
5. ✅ 디자인 시스템 통합 (AppTheme, AppColors, AppTextStyles)
6. ✅ 반응형 페이지 레이아웃 표준화 (ResponsivePageLayout)

## 향후 개선 사항

### 기능 추가
- [ ] 방 수정 기능
- [ ] 방 삭제 기능
- [ ] 예약 시스템
- [ ] 결제 시스템
- [ ] 리뷰 시스템
- [ ] 푸시 알림
- [ ] 다국어 지원
- [ ] 다크모드

### 추가 최적화
- [ ] 위젯 리빌드 최적화 (Selector 사용)
- [ ] 번들 크기 최적화
- [ ] 코드 스플리팅 (Deferred Loading)
- [ ] CI/CD 파이프라인 구축

## 성능 최적화

### Flutter 웹 번들 크기 최적화

#### 현재 상황
Flutter 웹은 기본적으로 **전체 앱을 하나의 JavaScript 번들로 빌드**합니다. 따라서:
- 첫 로드 시 모든 Dart 파일이 JavaScript로 컴파일되어 다운로드됩니다
- 이후 페이지 이동은 실제 네트워크 요청 없이 클라이언트 측에서만 처리됩니다
- 개발 모드(`flutter run -d chrome`)에서는 번들이 최적화되지 않아 더 많은 파일이 보입니다

#### 최적화 방법

##### 1. 프로덕션 빌드 사용
개발 모드가 아닌 **프로덕션 빌드**를 사용하면 번들 크기가 크게 줄어듭니다:

```bash
# 프로덕션 빌드 생성
flutter build web --release

# 로컬 서버로 테스트
cd build/web
python -m http.server 8000
# 또는
npx serve
```

**프로덕션 빌드 최적화:**
- 트리 쉐이킹 (사용하지 않는 코드 제거)
- 코드 난독화 및 압축
- 번들 크기 최소화

##### 2. Deferred Loading (지연 로딩) 적용

자주 사용하지 않는 페이지를 나중에 로드하도록 설정:

**router/app_router.dart 수정 예시:**
```dart
// 1. deferred import 사용
import 'package:building_map_app/pages/room_detail_page.dart' deferred as room_detail;
import 'package:building_map_app/pages/host_home_page.dart' deferred as host_home;
import 'package:building_map_app/pages/chat_detail_page.dart' deferred as chat_detail;

// 2. 라우트에서 loadLibrary() 호출
GoRoute(
  path: '/guest/room/detail/:roomId',
  builder: (context, state) async {
    await room_detail.loadLibrary();  // 필요할 때만 로드
    final roomId = int.tryParse(state.pathParameters['roomId'] ?? '');
    return room_detail.RoomDetailPage(roomId: roomId!);
  },
)
```

**지연 로딩 대상 페이지:**
- 호스트 전용 페이지 (방 등록, 요금 설정 등)
- 상세 페이지 (RoomDetailPage, ContractDetailPage)
- 채팅 페이지
- 자주 사용하지 않는 설정 페이지

**주의사항:**
- 게스트 홈, 로그인, 지도 등 자주 사용하는 페이지는 즉시 로딩
- deferred loading은 웹에서만 동작 (모바일에서는 무시됨)

##### 3. 이미지 최적화

**이미지 최적화 체크리스트:**
```dart
// ✅ CachedNetworkImage 사용 (이미 적용됨)
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => Shimmer(...),
  errorWidget: (context, url, error) => Icon(Icons.error),
  maxHeightDiskCache: 800,  // 캐시 이미지 최대 높이
  maxWidthDiskCache: 1200,   // 캐시 이미지 최대 너비
)

// ✅ WebP 포맷 사용 (용량 30-50% 감소)
// ✅ 적절한 이미지 크기 (썸네일 300x300, 상세 1200x800)
// ✅ ImageService로 업로드 전 압축 (이미 적용됨)
```

##### 4. 외부 라이브러리 최적화

**index.html에서 불필요한 스크립트 제거:**
```html
<!-- ❌ 모든 Material Icons 변형 제거 -->
<link href="https://fonts.googleapis.com/css2?family=Material+Icons+Outlined" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Material+Icons+Round" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Material+Icons+Sharp" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Material+Icons+Two+Tone" rel="stylesheet">

<!-- ✅ 기본 Material Icons만 사용 -->
<link href="https://fonts.googleapis.com/css2?family=Material+Icons" rel="stylesheet">
```

**Firebase SDK 최적화:**
```html
<!-- ❌ 사용하지 않는 Firebase 서비스 제거 -->
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-storage-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js"></script>

<!-- ✅ 필요한 서비스만 로드 -->
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-auth-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-firestore-compat.js"></script>
```

##### 5. 번들 분석

프로덕션 빌드 후 번들 크기 분석:

```bash
# 번들 크기 분석
flutter build web --release --analyze-size

# 결과 확인
cat .dart_tool/flutter_build/*/app.dill.size-analysis.json
```

#### 성능 측정

**Chrome DevTools로 성능 측정:**
1. Chrome DevTools → Performance 탭
2. 녹화 시작 → 페이지 새로고침 → 녹화 중지
3. 확인 항목:
   - **FCP (First Contentful Paint)**: 첫 콘텐츠 표시 시간
   - **LCP (Largest Contentful Paint)**: 최대 콘텐츠 표시 시간
   - **TTI (Time to Interactive)**: 인터랙션 가능 시간

**목표 지표:**
- FCP < 1.8초
- LCP < 2.5초
- TTI < 3.8초

## 참고 문서

- [Flutter 공식 문서](https://docs.flutter.dev/)
- [Kakao Developers](https://developers.kakao.com/)
- [GoRouter 문서](https://pub.dev/packages/go_router)
- [Provider 문서](https://pub.dev/packages/provider)
