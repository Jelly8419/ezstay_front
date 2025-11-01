# 회원가입 플로우 및 UI 설계

## 📋 현재 상황 분석

### 문제점
1. **라우팅 문제**: 로그인 페이지 → 모드 선택 → 로그인 페이지 (순환)
2. **회원가입 페이지 부재**: 이메일 회원가입 페이지가 존재하지 않음
3. **소셜 로그인만 지원**: 카카오/구글 로그인만 모드 선택 후 처리됨

### 현재 플로우
```
[로그인 페이지]
    ↓ (회원가입 버튼)
[모드 선택 페이지]
    ↓ (게스트/호스트 선택)
❌ 로그인 페이지로 돌아감 (잘못된 플로우)
```

---

## 🎯 목표 플로우 설계

### 새로운 회원가입 플로우
```
[로그인 페이지]
    ↓ (회원가입 버튼)
[모드 선택 페이지]
    ↓ (게스트/호스트 선택)
✅ [회원가입 페이지] (신규)
    ↓ (회원가입 완료)
[사용자 정보 입력 팝업]
    ↓
[게스트/호스트 홈]
```

### 소셜 로그인 플로우 (기존 유지)
```
[로그인 페이지]
    ↓ (카카오로 계속하기)
[모드 선택 페이지]
    ↓ (게스트/호스트 선택)
[카카오 로그인 처리]
    ↓
[사용자 정보 입력 팝업]
    ↓
[게스트/호스트 홈]
```

---

## 🎨 회원가입 페이지 UI 설계

### 디자인 컨셉
**로그인 페이지와 동일한 미니멀 스타일 적용**

#### 색상 팔레트 (login_page.dart와 동일)
```dart
static const primaryBlack = Color(0xFF000000);      // 주요 텍스트
static const secondaryGray = Color(0xFF808080);     // 보조 텍스트
static const borderGray = Color(0xFFE0E0E0);        // 테두리
static const backgroundWhite = Color(0xFFFFFFFF);   // 배경
static const hintGray = Color(0xFFCCCCCC);          // 힌트 텍스트
static const textGray = Color(0xFF666666);          // 라벨 텍스트
static const primaryBlue = AppColors.primary600;    // 강조 색상
```

### UI 구조

#### 1. 헤더
```
┌─────────────────────────────────────┐
│                                     │
│           회원가입하기                │  (32px, Bold, Center)
│                                     │
└─────────────────────────────────────┘
```

#### 2. 입력 필드
```
이메일 주소                              (14px, Gray)
┌─────────────────────────────────────┐
│ 이메일 주소를 입력해 주세요.            │  (52px Height)
└─────────────────────────────────────┘

비밀번호                                 (14px, Gray)
┌─────────────────────────────────────┐
│ 비밀번호를 입력해 주세요.              │  (52px Height)
│                              [👁]    │  (토글 버튼)
└─────────────────────────────────────┘

비밀번호 확인                            (14px, Gray)
┌─────────────────────────────────────┐
│ 비밀번호를 다시 입력해 주세요.          │  (52px Height)
│                              [👁]    │  (토글 버튼)
└─────────────────────────────────────┘

이름                                    (14px, Gray)
┌─────────────────────────────────────┐
│ 이름을 입력해 주세요.                  │  (52px Height)
└─────────────────────────────────────┘

전화번호                                 (14px, Gray)
┌─────────────────────────────────────┐
│ 전화번호를 입력해 주세요.              │  (52px Height)
└─────────────────────────────────────┘
```

#### 3. 약관 동의
```
☑ 이용약관에 동의합니다 (필수)          (14px, Gray)
☑ 개인정보 처리방침에 동의합니다 (필수)  (14px, Gray)
☐ 마케팅 수신에 동의합니다 (선택)       (14px, Gray)
```

#### 4. 버튼
```
┌─────────────────────────────────────┐
│          회원가입                     │  (56px Height, Primary Blue)
└─────────────────────────────────────┘

                 또는                    (구분선)

┌─────────────────────────────────────┐
│      이미 계정이 있으신가요?           │  (16px, Gray)
│            로그인하기                 │  (16px, Primary Blue, Underline)
└─────────────────────────────────────┘
```

### 상세 스펙

#### 컴포넌트 사이즈
```dart
// 전체 컨테이너
maxWidth: 400px
padding: EdgeInsets.only(
  top: 60,
  left: 24,
  right: 24,
  bottom: 40,
)

// 입력 필드
height: 52px
borderRadius: 8px
contentPadding: EdgeInsets.symmetric(
  horizontal: 16,
  vertical: 14,
)

// 버튼
height: 56px
borderRadius: 8px
fontSize: 16px
fontWeight: FontWeight.w500
```

#### 스타일 세부사항
```dart
// 제목
TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.w700,
  color: primaryBlack,
)

// 라벨
TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: textGray,
)

// 입력 필드
TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  color: primaryBlack,
)

// 힌트 텍스트
TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  color: hintGray,
)

// 에러 텍스트
TextStyle(
  fontSize: 12,
  color: AppColors.error500,
)
```

#### Border 스타일
```dart
// 기본 상태
border: OutlineInputBorder(
  borderRadius: BorderRadius.circular(8),
  borderSide: BorderSide(
    color: borderGray,
    width: 1,
  ),
)

// 포커스 상태
focusedBorder: OutlineInputBorder(
  borderRadius: BorderRadius.circular(8),
  borderSide: BorderSide(
    color: AppColors.primary600,
    width: 1.5,
  ),
)

// 에러 상태
errorBorder: OutlineInputBorder(
  borderRadius: BorderRadius.circular(8),
  borderSide: BorderSide(
    color: AppColors.error500,
    width: 1,
  ),
)
```

---

## 🔄 라우팅 설계

### 1. 라우트 추가 (app_router.dart)

#### 신규 라우트
```dart
GoRoute(
  path: '/register',
  name: 'register',
  builder: (context, state) {
    final userMode = state.extra as UserMode?;
    return RegisterPage(userMode: userMode);
  },
),
```

### 2. 네비게이션 수정

#### login_page.dart (385번 라인)
**변경 전:**
```dart
onPressed: () {
  context.push('/mode-selection');
},
```

**변경 후:**
```dart
onPressed: () {
  context.push('/mode-selection', extra: 'email');
},
```

#### mode_selection_page.dart
**변경 전:**
```dart
onModeSelected: (UserMode mode) async {
  final authService = Provider.of<AuthService>(context, listen: false);

  final loginType = state.extra as String?;

  bool success = false;
  if (loginType == 'google') {
    success = await authService.loginWithGoogle(mode);
  } else if (loginType == 'kakao') {
    success = await authService.loginWithKakao(mode);
  }

  // ... (홈으로 리다이렉트)
}
```

**변경 후:**
```dart
onModeSelected: (UserMode mode) async {
  final authService = Provider.of<AuthService>(context, listen: false);

  final loginType = state.extra as String?;

  if (loginType == 'email') {
    // 이메일 회원가입으로 이동
    context.push('/register', extra: mode);
  } else {
    // 소셜 로그인 처리
    bool success = false;
    if (loginType == 'google') {
      success = await authService.loginWithGoogle(mode);
    } else if (loginType == 'kakao') {
      success = await authService.loginWithKakao(mode);
    }

    if (success && context.mounted) {
      // 사용자 모드에 따라 리다이렉트
      final userMode = authService.currentUser?.mode;
      if (userMode == UserMode.host) {
        context.go('/host');
      } else {
        context.go('/guest');
      }

      // 본인인증 정보 팝업으로 이동
      await user_info.loadLibrary();
      await Future.delayed(const Duration(milliseconds: 100));
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => user_info.UserInfoPopup(isFromSignup: true),
          ),
        );
      }
    } else if (context.mounted) {
      context.pop();
    }
  }
}
```

---

## 🔌 API 연동 설계

### API 엔드포인트
```
POST /api/auth/register
```

### 요청 Body
```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "홍길동",
  "phone": "01012345678",
  "userMode": "GUEST",  // or "HOST"
  "agreeToTerms": true,
  "agreeToPrivacy": true,
  "agreeToMarketing": false
}
```

### 응답 (성공)
```json
{
  "success": true,
  "message": "회원가입이 완료되었습니다.",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "user123",
      "email": "user@example.com",
      "name": "홍길동",
      "phone": "01012345678",
      "mode": "GUEST"
    }
  }
}
```

### 응답 (실패)
```json
{
  "success": false,
  "message": "이미 존재하는 이메일입니다.",
  "errorCode": "EMAIL_ALREADY_EXISTS"
}
```

### AuthService 메서드
```dart
/// 이메일 회원가입
///
/// [email] 이메일 주소
/// [password] 비밀번호
/// [name] 이름
/// [phone] 전화번호
/// [mode] 사용자 모드 (게스트/호스트)
/// [agreeToTerms] 이용약관 동의 여부
/// [agreeToPrivacy] 개인정보 처리방침 동의 여부
/// [agreeToMarketing] 마케팅 수신 동의 여부
Future<bool> registerWithEmail({
  required String email,
  required String password,
  required String name,
  required String phone,
  required UserMode mode,
  required bool agreeToTerms,
  required bool agreeToPrivacy,
  bool agreeToMarketing = false,
}) async {
  try {
    final response = await _apiClient.post(
      ApiConfig.authRegisterUrl,
      body: {
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
        'userMode': mode == UserMode.guest ? 'GUEST' : 'HOST',
        'agreeToTerms': agreeToTerms,
        'agreeToPrivacy': agreeToPrivacy,
        'agreeToMarketing': agreeToMarketing,
      },
    );

    if (response['success'] == true) {
      final accessToken = response['data']['accessToken'];
      final refreshToken = response['data']['refreshToken'];
      final userData = response['data']['user'];

      // 토큰 저장
      await _tokenService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      // 사용자 정보 생성
      final user = User(
        id: userData['id'],
        email: userData['email'],
        name: userData['name'],
        phone: userData['phone'],
        mode: userData['mode'] == 'GUEST' ? UserMode.guest : UserMode.host,
      );

      // 사용자 정보 저장
      await _userRepository.saveUser(user);
      _currentUser = user;
      notifyListeners();

      return true;
    } else {
      _showErrorDialog(response['message'] ?? '회원가입에 실패했습니다.');
      return false;
    }
  } catch (e) {
    debugPrint('❌ [AUTH] 회원가입 실패: $e');
    _showErrorDialog('회원가입 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.');
    return false;
  }
}
```

---

## ✅ 유효성 검증 규칙

### 이메일
```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return '이메일을 입력해주세요';
  }
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    return '올바른 이메일 형식이 아닙니다';
  }
  return null;
}
```

### 비밀번호
```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return '비밀번호를 입력해주세요';
  }
  if (value.length < 8) {
    return '비밀번호는 8자 이상이어야 합니다';
  }
  if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$').hasMatch(value)) {
    return '비밀번호는 영문, 숫자를 포함해야 합니다';
  }
  return null;
}
```

### 비밀번호 확인
```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return '비밀번호 확인을 입력해주세요';
  }
  if (value != _passwordController.text) {
    return '비밀번호가 일치하지 않습니다';
  }
  return null;
}
```

### 이름
```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return '이름을 입력해주세요';
  }
  if (value.length < 2) {
    return '이름은 2자 이상이어야 합니다';
  }
  return null;
}
```

### 전화번호
```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return '전화번호를 입력해주세요';
  }
  if (!RegExp(r'^01[0-9]{8,9}$').hasMatch(value.replaceAll('-', ''))) {
    return '올바른 전화번호 형식이 아닙니다';
  }
  return null;
}
```

### 약관 동의
```dart
if (!_agreeToTerms) {
  _showErrorDialog('이용약관에 동의해주세요.');
  return;
}
if (!_agreeToPrivacy) {
  _showErrorDialog('개인정보 처리방침에 동의해주세요.');
  return;
}
```

---

## 🚀 구현 우선순위

### Phase 1: 기본 구조 (필수)
1. ✅ `register_page.dart` 생성 (UI 구조)
2. ✅ 라우팅 설정 수정 (`app_router.dart`)
3. ✅ 모드 선택 페이지 수정 (`mode_selection_page.dart`)

### Phase 2: 기능 구현 (필수)
1. ✅ 유효성 검증 로직
2. ✅ 약관 동의 체크박스
3. ✅ AuthService 회원가입 메서드 추가

### Phase 3: UX 개선 (선택)
1. ⭕ 비밀번호 강도 표시기
2. ⭕ 이메일 중복 확인 실시간 검증
3. ⭕ 약관 상세보기 다이얼로그

---

## 📝 파일 구조

```
lib/
├── pages/
│   ├── login_page.dart              (수정: 회원가입 버튼 extra 추가)
│   ├── register_page.dart           (신규: 회원가입 페이지)
│   └── mode_selection_page.dart     (수정: 이메일 회원가입 분기 추가)
├── router/
│   └── app_router.dart              (수정: /register 라우트 추가)
└── services/
    └── auth_service.dart            (수정: registerWithEmail 메서드 추가)
```

---

## 🎯 성공 기준

### 기능적 요구사항
- [x] 로그인 페이지 → 모드 선택 → 회원가입 페이지 플로우 정상 동작
- [x] 이메일, 비밀번호, 이름, 전화번호 입력 및 검증
- [x] 약관 동의 체크박스 동작
- [x] 회원가입 성공 시 자동 로그인 및 홈 화면 이동

### UI/UX 요구사항
- [x] 로그인 페이지와 동일한 미니멀 디자인 컨셉
- [x] 400px 최대 너비 제약
- [x] 반응형 레이아웃 (모바일/데스크톱)
- [x] 로딩 상태 표시

### 보안 요구사항
- [x] 비밀번호 암호화 (서버)
- [x] JWT 토큰 안전한 저장 (flutter_secure_storage)
- [x] HTTPS 통신 (프로덕션)

---

## 🔗 관련 문서

- [API 명세서](../backend/api_specification.md)
- [인증 플로우](../backend/auth_flow.md)
- [디자인 시스템](../CLAUDE.md#ui디자인-가이드라인)
