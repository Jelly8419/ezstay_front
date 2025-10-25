# 🏠 단기임대 앱 디자인 시스템 가이드

## 목차
1. [디자인 철학](#디자인-철학)
2. [컬러 시스템](#컬러-시스템)
3. [타이포그래피](#타이포그래피)
4. [간격 시스템](#간격-시스템)
5. [컴포넌트 라이브러리](#컴포넌트-라이브러리)
6. [페이지 구조](#페이지-구조)
7. [구현 가이드](#구현-가이드)

---

## 디자인 철학

### 핵심 가치
- **신뢰성**: 부동산 거래의 안전함을 시각적으로 전달
- **명확성**: 복잡한 정보를 직관적으로 표현
- **효율성**: 빠른 검색과 계약을 위한 최적화
- **친근함**: 따뜻하고 접근하기 쉬운 디자인

### 디자인 원칙
1. **일관성**: 모든 화면에서 동일한 패턴 사용
2. **계층구조**: 중요도에 따른 명확한 시각적 구분
3. **피드백**: 모든 인터랙션에 즉각적인 반응
4. **접근성**: 누구나 쉽게 사용 가능한 UI

---

## 컬러 시스템

### Primary Colors (주요 색상)
```dart
// 브랜드 메인 컬러 - 신뢰감 있는 블루
static const Color primary50 = Color(0xFFE3F2FD);
static const Color primary100 = Color(0xFFBBDEFB);
static const Color primary200 = Color(0xFF90CAF9);
static const Color primary300 = Color(0xFF64B5F6);
static const Color primary400 = Color(0xFF42A5F5);
static const Color primary500 = Color(0xFF2196F3);  // Main
static const Color primary600 = Color(0xFF1E88E5);
static const Color primary700 = Color(0xFF1976D2);
static const Color primary800 = Color(0xFF1565C0);
static const Color primary900 = Color(0xFF0D47A1);
```

### Secondary Colors (보조 색상)
```dart
// 강조 및 액션 - 따뜻한 오렌지/코랄
static const Color secondary50 = Color(0xFFFFF3E0);
static const Color secondary100 = Color(0xFFFFE0B2);
static const Color secondary200 = Color(0xFFFFCC80);
static const Color secondary300 = Color(0xFFFFB74D);
static const Color secondary400 = Color(0xFFFFA726);
static const Color secondary500 = Color(0xFFFF9800);  // Main
static const Color secondary600 = Color(0xFFFB8C00);
static const Color secondary700 = Color(0xFFF57C00);
static const Color secondary800 = Color(0xFFEF6C00);
static const Color secondary900 = Color(0xFFE65100);
```

### Neutral Colors (중립 색상)
```dart
// 텍스트 및 배경
static const Color neutral0 = Color(0xFFFFFFFF);    // 흰색
static const Color neutral50 = Color(0xFFFAFAFA);   // 배경
static const Color neutral100 = Color(0xFFF5F5F5);  // 카드 배경
static const Color neutral200 = Color(0xFFEEEEEE);  // 구분선
static const Color neutral300 = Color(0xFFE0E0E0);  // Border
static const Color neutral400 = Color(0xFFBDBDBD);  // Disabled
static const Color neutral500 = Color(0xFF9E9E9E);  // Secondary text
static const Color neutral600 = Color(0xFF757575);  // Body text
static const Color neutral700 = Color(0xFF616161);  // Title
static const Color neutral800 = Color(0xFF424242);  // Heading
static const Color neutral900 = Color(0xFF212121);  // Primary text
static const Color neutral1000 = Color(0xFF000000); // 검정
```

### Semantic Colors (의미 색상)
```dart
// 상태 및 피드백
static const Color success50 = Color(0xFFE8F5E9);
static const Color success500 = Color(0xFF4CAF50);  // 성공
static const Color success700 = Color(0xFF388E3C);

static const Color error50 = Color(0xFFFFEBEE);
static const Color error500 = Color(0xFFF44336);    // 에러
static const Color error700 = Color(0xFFD32F2F);

static const Color warning50 = Color(0xFFFFF8E1);
static const Color warning500 = Color(0xFFFFC107);  // 경고
static const Color warning700 = Color(0xFFFFA000);

static const Color info50 = Color(0xFFE3F2FD);
static const Color info500 = Color(0xFF2196F3);     // 정보
static const Color info700 = Color(0xFF1976D2);
```

### Special Colors (특수 색상)
```dart
// 배지, 태그 등
static const Color badge = Color(0xFFE91E63);       // 핑크 (새 매물)
static const Color premium = Color(0xFFFFD700);     // 골드 (프리미엄)
static const Color verified = Color(0xFF00BCD4);    // 시안 (인증됨)
static const Color discount = Color(0xFF9C27B0);    // 퍼플 (할인)
```

---

## 타이포그래피

### Font Family
```dart
// Primary: Pretendard (한글 최적화)
// Fallback: Apple SD Gothic Neo, Roboto

static const String fontFamily = 'Pretendard';
```

### Text Styles

#### Display (화면 제목)
```dart
static const TextStyle displayLarge = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.w700,
  height: 1.25,
  letterSpacing: -0.5,
);

static const TextStyle displayMedium = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w700,
  height: 1.29,
  letterSpacing: -0.5,
);

static const TextStyle displaySmall = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w600,
  height: 1.33,
  letterSpacing: -0.25,
);
```

#### Heading (섹션 제목)
```dart
static const TextStyle headingLarge = TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.w600,
  height: 1.36,
  letterSpacing: -0.25,
);

static const TextStyle headingMedium = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  height: 1.4,
  letterSpacing: -0.15,
);

static const TextStyle headingSmall = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  height: 1.44,
  letterSpacing: -0.15,
);
```

#### Body (본문)
```dart
static const TextStyle bodyLarge = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  height: 1.5,
  letterSpacing: 0,
);

static const TextStyle bodyMedium = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  height: 1.43,
  letterSpacing: 0.25,
);

static const TextStyle bodySmall = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  height: 1.5,
  letterSpacing: 0.4,
);
```

#### Label (라벨)
```dart
static const TextStyle labelLarge = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  height: 1.5,
  letterSpacing: 0.1,
);

static const TextStyle labelMedium = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  height: 1.43,
  letterSpacing: 0.25,
);

static const TextStyle labelSmall = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  height: 1.33,
  letterSpacing: 0.5,
);
```

#### Caption (캡션)
```dart
static const TextStyle caption = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w400,
  height: 1.36,
  letterSpacing: 0.4,
);
```

---

## 간격 시스템

### Spacing Scale (8pt 그리드)
```dart
static const double space0 = 0;
static const double space4 = 4;
static const double space8 = 8;
static const double space12 = 12;
static const double space16 = 16;
static const double space20 = 20;
static const double space24 = 24;
static const double space32 = 32;
static const double space40 = 40;
static const double space48 = 48;
static const double space64 = 64;
static const double space80 = 80;
```

### Border Radius
```dart
static const double radiusXs = 4;
static const double radiusSm = 8;
static const double radiusMd = 12;
static const double radiusLg = 16;
static const double radiusXl = 20;
static const double radiusFull = 999;
```

### Elevation (그림자)
```dart
// Card shadows
static const BoxShadow shadowSm = BoxShadow(
  color: Color(0x0D000000),
  offset: Offset(0, 1),
  blurRadius: 2,
  spreadRadius: 0,
);

static const BoxShadow shadowMd = BoxShadow(
  color: Color(0x1A000000),
  offset: Offset(0, 2),
  blurRadius: 8,
  spreadRadius: 0,
);

static const BoxShadow shadowLg = BoxShadow(
  color: Color(0x26000000),
  offset: Offset(0, 4),
  blurRadius: 16,
  spreadRadius: 0,
);

static const BoxShadow shadowXl = BoxShadow(
  color: Color(0x33000000),
  offset: Offset(0, 8),
  blurRadius: 24,
  spreadRadius: 0,
);
```

---

## 컴포넌트 라이브러리

### 1. Buttons (버튼)

#### Primary Button
- **용도**: 주요 액션 (검색, 계약하기, 로그인)
- **스타일**: 
  - 배경: primary500
  - 텍스트: neutral0 (흰색)
  - 높이: 48px (모바일), 52px (태블릿)
  - Border Radius: 12px
  - 패딩: 16px 24px

#### Secondary Button
- **용도**: 보조 액션 (필터, 정렬)
- **스타일**: 
  - 배경: neutral0 (흰색)
  - Border: 1px solid neutral300
  - 텍스트: neutral700
  - 높이: 48px
  - Border Radius: 12px

#### Text Button
- **용도**: 경량 액션 (더보기, 건너뛰기)
- **스타일**: 
  - 배경: 투명
  - 텍스트: primary600
  - 밑줄 없음

#### Icon Button
- **용도**: 좋아요, 공유, 닫기
- **크기**: 40x40px (터치 영역 48x48px)
- **아이콘**: 24px

### 2. Input Fields (입력 필드)

#### Text Field
```dart
// 기본 스타일
- 높이: 48px
- Border: 1px solid neutral300
- Border Radius: 12px
- 패딩: 12px 16px
- 폰트: bodyLarge

// Focus 상태
- Border: 2px solid primary500
- 배경: neutral0

// Error 상태
- Border: 2px solid error500
- 하단 메시지: error500 색상

// Disabled 상태
- 배경: neutral100
- Border: 1px solid neutral200
- 텍스트: neutral400
```

#### Search Bar
```dart
- 높이: 52px
- Border Radius: 26px (완전 둥근 형태)
- 배경: neutral50
- 아이콘: 좌측 돋보기 (neutral600)
- 우측: 필터 버튼
- 그림자: shadowSm
```

#### Date Picker
```dart
- 캘린더 아이콘 + 텍스트 필드
- 범위 선택 가능 (체크인 ~ 체크아웃)
- Primary500 색상으로 선택된 날짜 표시
```

### 3. Cards (카드)

#### Property Card (매물 카드)
```dart
// 구조
- 전체 카드: Container
  - 이미지 영역: AspectRatio(16:9)
    - 배지들 (새 매물, 할인 등)
    - 좋아요 버튼
  - 정보 영역: Padding(16px)
    - 제목: headingSmall
    - 위치: bodyMedium (neutral600)
    - 평점 + 리뷰: Row
    - 가격: headingMedium (primary700)
    - 기간: bodySmall (neutral500)

// 스타일
- Border Radius: 16px
- 그림자: shadowMd
- 배경: neutral0
- 호버: shadowLg + 살짝 올라오는 애니메이션
```

#### Contract Card (계약 카드)
```dart
// 구조
- 상태 배지 (진행 중, 완료 등)
- 숙소 정보 (작은 썸네일 + 이름)
- 계약 기간
- 계약 금액
- 액션 버튼 (상세보기, 취소하기 등)

// 스타일
- Border Radius: 12px
- Border: 1px solid neutral200
- 배경: neutral0
- 패딩: 16px
```

#### Info Card (정보 카드)
```dart
// 용도: 가이드, 안내사항
- 아이콘 + 텍스트
- 배경: info50 또는 warning50
- Border Radius: 12px
- 패딩: 16px
```

### 4. Chips & Tags (칩 & 태그)

#### Filter Chip
```dart
// 비선택
- 배경: neutral0
- Border: 1px solid neutral300
- 텍스트: neutral700
- 높이: 36px
- Border Radius: 18px
- 패딩: 12px 16px

// 선택
- 배경: primary500
- 텍스트: neutral0
- Border 없음
```

#### Status Badge
```dart
// 크기: 작은 원형 또는 캡슐
- 높이: 24px
- Border Radius: 12px
- 패딩: 4px 8px
- 폰트: caption (bold)

// 색상 (상태별)
- 예약 가능: success500
- 예약 중: warning500
- 예약 완료: neutral400
```

### 5. Lists (리스트)

#### Property List Item
```dart
- 수평 레이아웃
- 왼쪽: 썸네일 이미지 (80x80px, radius 12px)
- 오른쪽: 정보
  - 제목
  - 위치
  - 가격 (강조)
- 구분선: neutral200
```

#### Review List Item
```dart
- 사용자 정보 (아바타 + 이름)
- 평점 (별 아이콘)
- 리뷰 내용
- 날짜
- 구분선: neutral200
```

### 6. Navigation (네비게이션)

#### Bottom Navigation Bar
```dart
// 구조
- 5개 탭: 홈, 검색, 찜, 계약, 마이페이지
- 높이: 64px (Safe Area 포함)
- 아이콘 크기: 24px
- 라벨: caption

// 스타일
- 배경: neutral0
- 상단 그림자: shadowSm
- 선택됨: primary600
- 비선택: neutral500
```

#### Top App Bar
```dart
// 높이: 56px (Safe Area 제외)
- 배경: neutral0 (일반) 또는 투명 (스크롤 시 변경)
- 왼쪽: 뒤로가기 버튼
- 중앙: 제목 (headingSmall)
- 오른쪽: 액션 버튼들
- 하단 구분선: neutral200 (선택적)
```

### 7. Modals & Dialogs (모달 & 다이얼로그)

#### Bottom Sheet
```dart
// 용도: 필터, 옵션 선택
- Border Radius: 상단 24px
- 배경: neutral0
- 핸들: 중앙 상단 작은 막대
- 최대 높이: 화면의 90%
- 그림자: shadowXl
```

#### Alert Dialog
```dart
// 구조
- 제목: headingMedium
- 내용: bodyMedium
- 버튼 (1~2개): 수평 배치

// 스타일
- Border Radius: 20px
- 패딩: 24px
- 최대 폭: 320px
```

### 8. Loading & Empty States

#### Loading Indicator
```dart
- Circular Progress: primary500
- Shimmer Effect: neutral100 → neutral200
```

#### Empty State
```dart
- 일러스트레이션
- 제목: headingMedium
- 설명: bodyMedium (neutral600)
- 액션 버튼 (선택적)
```

---

## 페이지 구조

### 1. 로그인 페이지

```
구조:
┌─────────────────────┐
│      로고/제목       │
│                     │
│   환영 메시지/일러스트  │
│                     │
│  [이메일 입력 필드]   │
│  [비밀번호 입력 필드]  │
│                     │
│   [로그인 버튼]      │
│                     │
│  비밀번호 찾기 | 회원가입  │
│                     │
│   ────── 또는 ──────  │
│                     │
│  [소셜 로그인 버튼들]  │
└─────────────────────┘

주요 요소:
- 로고: displayLarge
- 환영 메시지: headingMedium (neutral700)
- 입력 필드: 위 스타일 가이드 참조
- 로그인 버튼: Primary Button (전체 너비)
- 소셜 로그인: Secondary Button (각 플랫폼 색상)
```

### 2. 매물 검색 페이지 (홈)

```
구조:
┌─────────────────────┐
│   [검색 바]          │ ← 고정
├─────────────────────┤
│   [필터 칩들]        │ ← 수평 스크롤
├─────────────────────┤
│                     │
│   [매물 카드 1]      │
│                     │
│   [매물 카드 2]      │
│                     │
│   [매물 카드 3]      │
│                     │
│        ...          │
│                     │
└─────────────────────┘
│  Bottom Nav Bar     │
└─────────────────────┘

주요 요소:
- 검색 바: 고정, shadowMd
- 필터 칩: Filter Chip (active/inactive)
- 매물 카드: Property Card
- 무한 스크롤: 하단 도달 시 로딩
```

### 3. 매물 상세 페이지

```
구조:
┌─────────────────────┐
│   [← 뒤로] [공유♡]   │ ← 상단바 (투명 → 불투명)
├─────────────────────┤
│                     │
│   [이미지 갤러리]     │ ← PageView
│    ● ○ ○ ○          │ ← 인디케이터
│                     │
├─────────────────────┤
│ 제목 및 기본 정보     │
│ ⭐ 4.8 (128)        │
│ 📍 강남구 역삼동      │
├─────────────────────┤
│   [날짜 선택]        │
│   체크인 - 체크아웃   │
├─────────────────────┤
│ 요금 정보            │
│ ₩330,000 / 주       │
├─────────────────────┤
│ 호스트 정보          │
│ [프로필 카드]        │
├─────────────────────┤
│ 시설 및 편의 시설     │
│ [아이콘 + 텍스트]    │
├─────────────────────┤
│ 위치                │
│ [지도 + 주소]        │
├─────────────────────┤
│ 이용 후기            │
│ [리뷰 리스트]        │
├─────────────────────┤
│ 취소 정책 등 상세     │
└─────────────────────┘
│  [예약하기 버튼]     │ ← 하단 고정
└─────────────────────┘

주요 요소:
- 이미지: 전체 너비, 16:9 비율
- 가격: headingLarge (primary700)
- 섹션 제목: headingMedium
- 예약 버튼: Primary Button (고정)
```

### 4. 계약 페이지

```
구조:
┌─────────────────────┐
│ 계약                │ ← 상단바
├─────────────────────┤
│ [진행 중 | 완료됨]    │ ← 탭
├─────────────────────┤
│                     │
│  [계약 카드 1]       │
│  - 숙소 정보         │
│  - 기간              │
│  - 금액              │
│  - 상태              │
│  [상세보기 버튼]     │
│                     │
│  [계약 카드 2]       │
│                     │
│        ...          │
│                     │
└─────────────────────┘
│  Bottom Nav Bar     │
└─────────────────────┘

주요 요소:
- 탭: 하단 border로 선택 표시
- 계약 카드: Contract Card
- 빈 상태: Empty State (계약 없을 때)
```

### 5. 계약 상세/결제 페이지

```
구조:
┌─────────────────────┐
│ [← 뒤로] 계약 확인    │
├─────────────────────┤
│ 단계 인디케이터       │
│ ● ━━ ○ ━━ ○         │
├─────────────────────┤
│ 숙소 요약            │
│ [썸네일 + 정보]      │
├─────────────────────┤
│ 기간 및 게스트        │
│ [날짜 정보]          │
├─────────────────────┤
│ 요금 세부사항         │
│ - 임대료: ₩xxx      │
│ - 관리비: ₩xxx      │
│ - 서비스 수수료: ₩xxx │
│ ────────────────    │
│ 합계: ₩xxx (강조)   │
├─────────────────────┤
│ 결제 수단            │
│ [카드 선택 라디오]   │
├─────────────────────┤
│ 약관 동의            │
│ [ ] 전체 동의        │
│ [ ] 이용약관 (필수)   │
│ [ ] 개인정보 (필수)   │
│ [ ] 마케팅 (선택)     │
├─────────────────────┤
│                     │
└─────────────────────┘
│  [결제하기 버튼]     │ ← 하단 고정
└─────────────────────┘

주요 요소:
- 단계 표시: primary500로 진행 상태
- 합계: displaySmall (primary700)
- 체크박스: primary500
- 결제 버튼: Primary Button (큰 사이즈)
```

---

## 구현 가이드

### 파일 구조
```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart         # 컬러 시스템
│   │   ├── app_text_styles.dart    # 타이포그래피
│   │   ├── app_spacing.dart        # 간격
│   │   └── app_theme.dart          # 전체 테마
│   └── constants/
│       └── app_constants.dart
├── shared/
│   └── widgets/
│       ├── buttons/
│       │   ├── primary_button.dart
│       │   ├── secondary_button.dart
│       │   ├── text_button.dart
│       │   └── icon_button.dart
│       ├── inputs/
│       │   ├── text_field.dart
│       │   ├── search_bar.dart
│       │   └── date_picker.dart
│       ├── cards/
│       │   ├── property_card.dart
│       │   ├── contract_card.dart
│       │   └── info_card.dart
│       ├── chips/
│       │   ├── filter_chip.dart
│       │   └── status_badge.dart
│       └── navigation/
│           ├── bottom_nav_bar.dart
│           └── app_bar.dart
└── features/
    ├── auth/
    ├── home/
    ├── property/
    └── contract/
```

### 사용 예시

```dart
// 1. Primary Button 사용
AppPrimaryButton(
  text: '검색',
  onPressed: () {},
  isLoading: false,
  isDisabled: false,
)

// 2. Property Card 사용
PropertyCard(
  imageUrl: 'https://...',
  title: '강남역 도보 5분 신축 원룸',
  location: '서울시 강남구 역삼동',
  rating: 4.8,
  reviewCount: 128,
  price: '₩330,000',
  period: '주',
  badges: ['신규', '할인'],
  isFavorite: false,
  onTap: () {},
  onFavorite: () {},
)

// 3. Search Bar 사용
AppSearchBar(
  hintText: '지역, 역 이름으로 검색',
  onSearch: (query) {},
  onFilterTap: () {},
)
```

### 애니메이션 가이드

```dart
// 기본 애니메이션 Duration
static const Duration durationFast = Duration(milliseconds: 200);
static const Duration durationMedium = Duration(milliseconds: 300);
static const Duration durationSlow = Duration(milliseconds: 500);

// Curve
static const Curve curveDefault = Curves.easeInOut;
static const Curve curveSmooth = Curves.easeOutCubic;

// 사용 예시: 카드 호버 효과
AnimatedContainer(
  duration: AppDurations.durationFast,
  curve: AppCurves.curveDefault,
  transform: isHovered 
    ? Matrix4.translationValues(0, -4, 0)
    : Matrix4.translationValues(0, 0, 0),
  child: PropertyCard(...),
)
```

### 반응형 가이드

```dart
// Breakpoints
static const double mobileMaxWidth = 600;
static const double tabletMaxWidth = 960;
static const double desktopMinWidth = 961;

// 사용 예시
double getPadding(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < mobileMaxWidth) return 16;
  if (width < tabletMaxWidth) return 24;
  return 32;
}
```

---

## 다음 단계

1. **클로드 코드에서 파일 생성**
   - `app_colors.dart` 생성
   - `app_text_styles.dart` 생성
   - `app_spacing.dart` 생성
   - 등등...

2. **기본 위젯 구현**
   - Primary Button 위젯
   - Property Card 위젯
   - 먼저 자주 쓰이는 것부터

3. **페이지 리팩토링**
   - 로그인 페이지부터 시작
   - 새로운 디자인 시스템 적용

4. **테스트 및 피드백**
   - 실제 디바이스에서 테스트
   - 사용성 개선

---

## 체크리스트

- [ ] 컬러 시스템 구현
- [ ] 타이포그래피 구현
- [ ] 간격 시스템 구현
- [ ] Primary Button 위젯
- [ ] Secondary Button 위젯
- [ ] Text Field 위젯
- [ ] Search Bar 위젯
- [ ] Property Card 위젯
- [ ] Contract Card 위젯
- [ ] Filter Chip 위젯
- [ ] Bottom Navigation 위젯
- [ ] App Bar 위젯
- [ ] 로그인 페이지 리팩토링
- [ ] 홈(검색) 페이지 리팩토링
- [ ] 매물 상세 페이지 리팩토링
- [ ] 계약 페이지 리팩토링
- [ ] 계약 상세 페이지 리팩토링

---

**이 가이드를 기반으로 클로드 코드에서 체계적으로 구현하세요!**
