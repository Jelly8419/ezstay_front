# LiveMoment Front - EZStay

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
- `custom_button.dart` - 재사용 가능한 버튼 (로딩 상태 지원)
- `custom_dropdown.dart` - 재사용 가능한 드롭다운

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

## Git 브랜치 전략

- `main` - 프로덕션 브랜치
- `feature/*` - 기능 개발 브랜치
- 현재 브랜치: `feature/host-room-registration`

## 최근 작업 내역

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
- [ ] 코드 스플리팅
- [ ] CI/CD 파이프라인 구축

## 참고 문서

- [Flutter 공식 문서](https://docs.flutter.dev/)
- [Kakao Developers](https://developers.kakao.com/)
- [GoRouter 문서](https://pub.dev/packages/go_router)
- [Provider 문서](https://pub.dev/packages/provider)
