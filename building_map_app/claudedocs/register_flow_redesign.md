# 회원가입 플로우 재설계 계획서

## 📋 목차
1. [현재 구현 분석](#현재-구현-분석)
2. [새로운 요구사항](#새로운-요구사항)
3. [설계 개요](#설계-개요)
4. [세부 구현 계획](#세부-구현-계획)
5. [API 엔드포인트 명세](#api-엔드포인트-명세)
6. [상태 관리 모델](#상태-관리-모델)
7. [UI 플로우 다이어그램](#ui-플로우-다이어그램)
8. [구현 순서](#구현-순서)

---

## 📊 현재 구현 분석

### 기존 회원가입 플로우
```
[이메일 가입]
1. 이메일/비밀번호 입력
2. 이름/전화번호 입력
3. (호스트만) 계좌 정보 입력
4. 약관 동의
5. 가입 완료 → 백엔드 API 호출

[카카오 가입]
1. 카카오 로그인
2. 이메일/이름 자동 입력 (읽기 전용)
3. 전화번호 입력
4. (호스트만) 계좌 정보 입력
5. 약관 동의
6. 가입 완료
```

### 현재 User 모델
```dart
class User {
  final String id;
  final String email;
  final String name;
  final String? profileImageUrl;
  final UserMode mode;
  final AuthProvider provider;
  final bool phoneVerified;  // 휴대폰 인증 여부
  final bool hasBank;        // 계좌 등록 여부
}
```

### 현재 API 엔드포인트
- `POST /api/auth/register` - 이메일 회원가입
- `POST /auth/kakao` - 카카오 로그인/가입 (모바일)
- `GET /api/auth/kakao?code={code}` - 카카오 로그인/가입 (웹)
- `POST /api/account/verify` - 계좌 인증

---

## 🎯 새로운 요구사항

### 1. 카카오 가입 (변경 없음)
- 이메일, 이름, 프로필사진만 저장

### 2. 이메일 가입 (신규: 이메일 인증 추가)
- 이메일, 비밀번호 입력
- **📧 이메일 인증 단계 추가**
- 이메일 인증 완료 후 다음 단계 진행

### 3. 본인인증 위젯 (두 가입 방식 모두 필수)
- **이메일**: 자동 연동 (읽기 전용)
- **휴대폰번호**: 입력 + 본인인증 버튼
- **본인인증 완료 시**:
  - 실명 자동 입력
  - 카카오 가입의 경우: 카카오 등록 이름과 일치 확인

---

## 🏗️ 설계 개요

### 다단계 회원가입 플로우
```
┌─────────────────────────────────────────────────┐
│              RegisterFlowPage                    │
│  (Stateful Widget - 전체 플로우 관리)             │
└─────────────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
   [이메일 가입]            [카카오 가입]
        │                       │
        ▼                       ▼
┌───────────────┐      ┌───────────────┐
│  Step 1:      │      │  카카오 로그인 │
│  Email/PW 입력│      │  (자동 진행)   │
└───────┬───────┘      └───────┬───────┘
        │                      │
        ▼                      │
┌───────────────┐              │
│  Step 2:      │              │
│  이메일 인증   │              │
└───────┬───────┘              │
        │                      │
        └──────────┬───────────┘
                   ▼
        ┌───────────────────┐
        │  Step 3:          │
        │  본인인증         │
        │  (두 방식 공통)   │
        └─────────┬─────────┘
                  │
                  ▼
        ┌───────────────────┐
        │  Step 4:          │
        │  추가 정보 입력   │
        │  (호스트만 계좌)  │
        └─────────┬─────────┘
                  │
                  ▼
        ┌───────────────────┐
        │  Step 5:          │
        │  약관 동의        │
        └─────────┬─────────┘
                  │
                  ▼
           ┌──────────┐
           │ 가입 완료 │
           └──────────┘
```

---

## 🔧 세부 구현 계획

### 1. 새로운 파일 구조
```
lib/
├── pages/
│   └── auth/
│       ├── register_flow_page.dart           # 메인 플로우 관리
│       └── steps/
│           ├── email_password_step.dart      # Step 1: 이메일/비밀번호 입력
│           ├── email_verification_step.dart  # Step 2: 이메일 인증
│           ├── phone_verification_step.dart  # Step 3: 본인인증
│           ├── additional_info_step.dart     # Step 4: 추가 정보 (계좌)
│           └── terms_agreement_step.dart     # Step 5: 약관 동의
├── models/
│   └── register_state.dart                   # 가입 상태 모델
└── services/
    └── verification_service.dart             # 인증 서비스
```

### 2. 핵심 위젯 설계

#### 2.1 RegisterFlowPage (메인 컨트롤러)
```dart
class RegisterFlowPage extends StatefulWidget {
  final UserMode mode;          // guest or host
  final bool isSocialLogin;     // 카카오 가입 여부
  final String? initialEmail;   // 카카오 이메일
  final String? initialName;    // 카카오 이름
  final String? profileImageUrl; // 카카오 프로필
}

class _RegisterFlowPageState extends State<RegisterFlowPage> {
  RegisterState _state = RegisterState();
  int _currentStep = 0;

  // 단계별 위젯 리스트
  List<Widget> _getSteps() {
    if (widget.isSocialLogin) {
      // 카카오 가입: Step 3부터 시작
      return [
        PhoneVerificationStep(...),
        AdditionalInfoStep(...),
        TermsAgreementStep(...),
      ];
    } else {
      // 이메일 가입: Step 1부터 시작
      return [
        EmailPasswordStep(...),
        EmailVerificationStep(...),
        PhoneVerificationStep(...),
        AdditionalInfoStep(...),
        TermsAgreementStep(...),
      ];
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    setState(() => _currentStep--);
  }
}
```

#### 2.2 EmailVerificationStep (이메일 인증)
```dart
class EmailVerificationStep extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;
}

class _EmailVerificationStepState extends State<EmailVerificationStep> {
  final _codeController = TextEditingController();
  String? _verificationCode;
  int _resendCountdown = 0;

  // 인증 코드 발송
  Future<void> _sendVerificationCode() async {
    final service = VerificationService();
    final code = await service.sendEmailVerification(widget.email);
    setState(() {
      _verificationCode = code;
      _resendCountdown = 180; // 3분
    });
    _startCountdown();
  }

  // 인증 코드 확인
  Future<void> _verifyCode() async {
    final service = VerificationService();
    final success = await service.verifyEmailCode(
      widget.email,
      _codeController.text,
    );
    if (success) {
      widget.onVerified();
    }
  }

  Widget build(BuildContext context) {
    return Column(
      children: [
        // 이메일 표시 (읽기 전용)
        TextField(
          controller: TextEditingController(text: widget.email),
          enabled: false,
        ),
        // 인증 코드 입력
        TextField(
          controller: _codeController,
          decoration: InputDecoration(
            labelText: '인증 코드',
            suffix: TextButton(
              onPressed: _resendCountdown == 0 ? _sendVerificationCode : null,
              child: Text(_resendCountdown > 0
                  ? '$_resendCountdown초'
                  : '재발송'),
            ),
          ),
        ),
        // 인증 확인 버튼
        ElevatedButton(
          onPressed: _verifyCode,
          child: Text('인증하기'),
        ),
      ],
    );
  }
}
```

#### 2.3 PhoneVerificationStep (본인인증)
```dart
class PhoneVerificationStep extends StatefulWidget {
  final String email;
  final String? kakaoName;       // 카카오 가입 시 이름
  final bool isSocialLogin;
  final Function(String phoneNumber, String realName) onVerified;
}

class _PhoneVerificationStepState extends State<PhoneVerificationStep> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String? _verifiedName;
  bool _isVerified = false;

  // 본인인증 코드 발송
  Future<void> _sendPhoneVerification() async {
    final service = VerificationService();
    await service.sendPhoneVerification(_phoneController.text);
    // 타이머 시작
  }

  // 본인인증 확인
  Future<void> _verifyPhone() async {
    final service = VerificationService();
    final result = await service.verifyPhoneCode(
      _phoneController.text,
      _codeController.text,
    );

    if (result.success) {
      final realName = result.realName;

      // 카카오 가입인 경우 이름 일치 확인
      if (widget.isSocialLogin && widget.kakaoName != null) {
        if (realName != widget.kakaoName) {
          _showNameMismatchDialog(realName, widget.kakaoName!);
          return;
        }
      }

      setState(() {
        _verifiedName = realName;
        _isVerified = true;
      });

      widget.onVerified(_phoneController.text, realName);
    }
  }

  void _showNameMismatchDialog(String realName, String kakaoName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('이름 불일치'),
        content: Text(
          '본인인증 이름($realName)과\n'
          '카카오 등록 이름($kakaoName)이 다릅니다.\n'
          '계속 진행하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _verifiedName = realName;
                _isVerified = true;
              });
              widget.onVerified(_phoneController.text, realName);
            },
            child: Text('계속 진행'),
          ),
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    return Column(
      children: [
        // 이메일 표시 (읽기 전용)
        TextField(
          controller: TextEditingController(text: widget.email),
          enabled: false,
          decoration: InputDecoration(labelText: '이메일'),
        ),
        SizedBox(height: 16),

        // 휴대폰번호 입력
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: '휴대폰번호',
                  hintText: '010-0000-0000',
                ),
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: _sendPhoneVerification,
              child: Text('본인인증'),
            ),
          ],
        ),
        SizedBox(height: 16),

        // 인증 코드 입력
        TextField(
          controller: _codeController,
          decoration: InputDecoration(
            labelText: '인증 코드',
          ),
        ),
        SizedBox(height: 16),

        // 인증 확인 버튼
        ElevatedButton(
          onPressed: _verifyPhone,
          child: Text('확인'),
        ),

        // 인증 완료 시 이름 표시
        if (_isVerified && _verifiedName != null)
          Padding(
            padding: EdgeInsets.only(top: 16),
            child: TextField(
              controller: TextEditingController(text: _verifiedName),
              enabled: false,
              decoration: InputDecoration(
                labelText: '이름',
                suffix: Icon(Icons.check_circle, color: Colors.green),
              ),
            ),
          ),
      ],
    );
  }
}
```

---

## 🌐 API 엔드포인트 명세

### 1. 이메일 인증

#### 1.1 이메일 인증 코드 발송
```
POST /api/auth/send-email-verification
Content-Type: application/json

Request:
{
  "email": "user@example.com"
}

Response (200):
{
  "success": true,
  "message": "인증 코드가 발송되었습니다",
  "expiresIn": 180  // 초 (3분)
}

Response (400):
{
  "success": false,
  "message": "이미 가입된 이메일입니다"
}
```

#### 1.2 이메일 인증 코드 확인
```
POST /api/auth/verify-email
Content-Type: application/json

Request:
{
  "email": "user@example.com",
  "code": "123456"
}

Response (200):
{
  "success": true,
  "verified": true,
  "message": "이메일 인증이 완료되었습니다"
}

Response (400):
{
  "success": false,
  "verified": false,
  "message": "인증 코드가 일치하지 않습니다"
}
```

### 2. 본인인증

#### 2.1 휴대폰 본인인증 코드 발송
```
POST /api/auth/send-phone-verification
Content-Type: application/json

Request:
{
  "phoneNumber": "01012345678"
}

Response (200):
{
  "success": true,
  "message": "인증 코드가 발송되었습니다",
  "expiresIn": 180  // 초 (3분)
}
```

#### 2.2 휴대폰 본인인증 코드 확인
```
POST /api/auth/verify-phone
Content-Type: application/json

Request:
{
  "phoneNumber": "01012345678",
  "code": "123456"
}

Response (200):
{
  "success": true,
  "verified": true,
  "realName": "홍길동",  // 통신사에서 받은 실명
  "message": "본인인증이 완료되었습니다"
}

Response (400):
{
  "success": false,
  "verified": false,
  "message": "인증 코드가 일치하지 않습니다"
}
```

### 3. 회원가입 (수정)

#### 3.1 이메일 회원가입
```
POST /api/auth/register
Content-Type: application/json

Request:
{
  "email": "user@example.com",
  "password": "password123",
  "name": "홍길동",                 // 본인인증으로 받은 실명
  "phoneNumber": "01012345678",     // 본인인증한 휴대폰번호
  "phoneVerified": true,            // 본인인증 완료 여부
  "userMode": "guest",              // "guest" or "host"
  "agreeTerms": true,
  "agreeMarketing": false,

  // 호스트인 경우 추가 필드
  "bankCode": "004",
  "accountNumber": "123456789",
  "accountHolder": "홍길동"
}

Response (200):
{
  "success": true,
  "data": {
    "accessToken": "jwt_access_token",
    "refreshToken": "jwt_refresh_token",
    "user": {
      "id": "user_id",
      "email": "user@example.com",
      "name": "홍길동",
      "userMode": "guest",
      "provider": "email",
      "phoneVerified": true,
      "hasBank": false
    }
  }
}
```

#### 3.2 카카오 회원가입 (추가 정보 업데이트)
```
PATCH /api/auth/update-profile
Authorization: Bearer {access_token}
Content-Type: application/json

Request:
{
  "name": "홍길동",                 // 본인인증으로 받은 실명
  "phoneNumber": "01012345678",
  "phoneVerified": true,

  // 호스트인 경우 추가 필드
  "bankCode": "004",
  "accountNumber": "123456789",
  "accountHolder": "홍길동"
}

Response (200):
{
  "success": true,
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "name": "홍길동",
    "userMode": "guest",
    "provider": "kakao",
    "phoneVerified": true,
    "hasBank": false
  }
}
```

---

## 📦 상태 관리 모델

### RegisterState 모델
```dart
class RegisterState {
  // 기본 정보
  String? email;
  String? password;
  UserMode mode;
  bool isSocialLogin;

  // 카카오 정보
  String? kakaoName;
  String? profileImageUrl;

  // 인증 정보
  bool emailVerified;
  bool phoneVerified;
  String? phoneNumber;
  String? realName;  // 본인인증으로 받은 실명

  // 추가 정보 (호스트)
  String? bankCode;
  String? accountNumber;
  String? accountHolder;
  bool accountVerified;

  // 약관 동의
  bool agreeTerms;
  bool agreeMarketing;

  // 진행 상태
  int currentStep;

  RegisterState({
    this.email,
    this.password,
    this.mode = UserMode.guest,
    this.isSocialLogin = false,
    this.kakaoName,
    this.profileImageUrl,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.phoneNumber,
    this.realName,
    this.bankCode,
    this.accountNumber,
    this.accountHolder,
    this.accountVerified = false,
    this.agreeTerms = false,
    this.agreeMarketing = false,
    this.currentStep = 0,
  });

  // 카카오 가입 초기화
  factory RegisterState.fromKakao({
    required String email,
    required String name,
    required UserMode mode,
    String? profileImageUrl,
  }) {
    return RegisterState(
      email: email,
      kakaoName: name,
      profileImageUrl: profileImageUrl,
      mode: mode,
      isSocialLogin: true,
      emailVerified: true,  // 카카오 이메일은 인증된 것으로 간주
      currentStep: 0,        // 본인인증 단계부터 시작
    );
  }

  // 현재 단계 완료 여부 검증
  bool canProceedToNextStep() {
    switch (currentStep) {
      case 0: // 이메일/비밀번호 입력 (이메일 가입) or 카카오 로그인
        if (isSocialLogin) {
          return email != null && kakaoName != null;
        } else {
          return email != null && password != null;
        }
      case 1: // 이메일 인증 (이메일 가입만)
        return isSocialLogin || emailVerified;
      case 2: // 본인인증
        return phoneVerified && realName != null;
      case 3: // 추가 정보 (호스트만)
        if (mode == UserMode.host) {
          return accountVerified;
        }
        return true;
      case 4: // 약관 동의
        return agreeTerms;
      default:
        return false;
    }
  }

  // JSON 변환 (디버깅용)
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'mode': mode.name,
      'isSocialLogin': isSocialLogin,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'phoneNumber': phoneNumber,
      'realName': realName,
      'currentStep': currentStep,
    };
  }
}
```

---

## 🎨 UI 플로우 다이어그램

### 이메일 가입 플로우
```
┌─────────────────────────────────────────────┐
│ Step 1: 이메일/비밀번호 입력                │
│ ┌─────────────────────────────────────────┐ │
│ │ 이메일 주소: _____________________     │ │
│ │ 비밀번호:    _____________________     │ │
│ │ 비밀번호 확인: __________________      │ │
│ │                                         │ │
│ │                       [다음 →]          │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ Step 2: 이메일 인증                         │
│ ┌─────────────────────────────────────────┐ │
│ │ 이메일: user@example.com (읽기 전용)   │ │
│ │                                         │ │
│ │ 인증 코드: ______   [재발송 (180초)]   │ │
│ │                                         │ │
│ │                  [인증하기]             │ │
│ │          [← 이전]         [다음 →]      │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ Step 3: 본인인증                            │
│ ┌─────────────────────────────────────────┐ │
│ │ 이메일: user@example.com (읽기 전용)   │ │
│ │                                         │ │
│ │ 휴대폰번호: _______________  [본인인증] │ │
│ │ 인증 코드: ______                       │ │
│ │                          [확인]         │ │
│ │                                         │ │
│ │ 이름: 홍길동 (자동 입력) ✓             │ │
│ │                                         │ │
│ │          [← 이전]         [다음 →]      │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ Step 4: 추가 정보 (호스트만)                │
│ ┌─────────────────────────────────────────┐ │
│ │ 은행: [국민은행 ▼]                      │ │
│ │ 계좌번호: _______________  [확인하기]   │ │
│ │ 예금주: 홍길동                          │ │
│ │                                         │ │
│ │          [← 이전]         [다음 →]      │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ Step 5: 약관 동의                           │
│ ┌─────────────────────────────────────────┐ │
│ │ ☑ 이용약관 동의 (필수)                  │ │
│ │ ☐ 마케팅 수신 동의 (선택)               │ │
│ │                                         │ │
│ │          [← 이전]      [가입하기]       │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### 카카오 가입 플로우
```
┌─────────────────────────────────────────────┐
│ 카카오 로그인                               │
│ ┌─────────────────────────────────────────┐ │
│ │                                         │ │
│ │  카카오 로그인 진행 중...               │ │
│ │                                         │ │
│ │  이메일, 이름, 프로필 자동 수신         │ │
│ │                                         │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ Step 3: 본인인증                            │
│ ┌─────────────────────────────────────────┐ │
│ │ 이메일: kakao@example.com (읽기 전용)  │ │
│ │                                         │ │
│ │ 휴대폰번호: _______________  [본인인증] │ │
│ │ 인증 코드: ______                       │ │
│ │                          [확인]         │ │
│ │                                         │ │
│ │ 이름: 홍길동 (자동 입력) ✓             │ │
│ │                                         │ │
│ │ ⚠️ 카카오 이름(김철수)과 다릅니다       │ │
│ │                                         │ │
│ │                         [다음 →]        │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
                    ↓
       (Step 4, 5는 이메일 가입과 동일)
```

---

## 🚀 구현 순서

### Phase 1: 모델 및 서비스 구현 (1-2일)
1. ✅ **RegisterState 모델 생성**
   - `lib/models/register_state.dart`
   - 상태 관리 및 검증 로직

2. ✅ **VerificationService 생성**
   - `lib/services/verification_service.dart`
   - 이메일 인증 API 연동
   - 휴대폰 본인인증 API 연동

3. ✅ **User 모델 업데이트**
   - `phoneVerified`, `hasBank` 필드 활용
   - `realName` 필드 추가 고려

### Phase 2: 위젯 구현 (3-4일)
4. ✅ **EmailPasswordStep 구현**
   - 이메일/비밀번호 입력 폼
   - 유효성 검증

5. ✅ **EmailVerificationStep 구현**
   - 이메일 인증 코드 발송
   - 인증 코드 입력 및 확인
   - 타이머 기능

6. ✅ **PhoneVerificationStep 구현**
   - 휴대폰번호 입력
   - 본인인증 코드 발송/확인
   - 실명 자동 입력
   - 카카오 이름 일치 확인 로직

7. ✅ **AdditionalInfoStep 구현**
   - 호스트 계좌 정보 입력
   - 기존 코드 재사용

8. ✅ **TermsAgreementStep 구현**
   - 약관 동의 체크박스
   - 기존 코드 재사용

### Phase 3: 메인 플로우 구현 (2-3일)
9. ✅ **RegisterFlowPage 구현**
   - 단계별 위젯 관리
   - 상태 관리
   - 진행 표시 UI

10. ✅ **진행 상태 표시**
    - 단계 인디케이터
    - 이전/다음 버튼

11. ✅ **라우팅 통합**
    - `app_router.dart` 수정
    - 로그인 페이지에서 진입 경로 설정

### Phase 4: 백엔드 API 연동 (2-3일)
12. ✅ **API Config 업데이트**
    - 새 엔드포인트 추가

13. ✅ **AuthService 수정**
    - `signUpWithEmail` 메서드 수정
    - 본인인증 정보 포함

14. ✅ **에러 핸들링**
    - API 에러 처리
    - 사용자 친화적 에러 메시지

### Phase 5: 테스트 및 검증 (2일)
15. ✅ **이메일 가입 플로우 테스트**
    - 전체 플로우 동작 확인
    - 에러 케이스 처리

16. ✅ **카카오 가입 플로우 테스트**
    - 전체 플로우 동작 확인
    - 이름 불일치 케이스

17. ✅ **UI/UX 개선**
    - 애니메이션 추가
    - 로딩 상태 표시
    - 접근성 개선

### Phase 6: 문서화 및 배포 (1일)
18. ✅ **코드 문서화**
    - 주석 및 README 업데이트

19. ✅ **배포 준비**
    - 환경 변수 설정
    - 프로덕션 빌드 테스트

---

## 📝 참고사항

### 보안 고려사항
1. **이메일 인증 코드**: 6자리 숫자, 3분 만료
2. **본인인증 코드**: 6자리 숫자, 3분 만료
3. **재발송 제한**: 1분 간격, 5회 제한
4. **비밀번호**: 최소 8자, 영문+숫자 포함

### UX 개선사항
1. **자동 포커스**: 각 단계에서 첫 번째 입력 필드에 자동 포커스
2. **키보드 네비게이션**: Enter 키로 다음 단계 진행
3. **진행 상태 저장**: 새로고침 시에도 진행 상태 유지 (로컬 스토리지)
4. **로딩 인디케이터**: API 호출 중 로딩 표시
5. **성공 피드백**: 각 단계 완료 시 체크 마크 표시

### 접근성 고려사항
1. **스크린 리더**: 각 필드에 적절한 레이블 제공
2. **키보드 네비게이션**: Tab 키로 모든 요소 접근 가능
3. **에러 메시지**: 명확하고 구체적인 에러 안내
4. **색상 대비**: WCAG 2.1 AA 기준 준수

---

## 🔄 마이그레이션 전략

### 기존 사용자 대응
1. **기존 회원**: phoneVerified = false로 유지
2. **새 회원**: 본인인증 필수
3. **선택적 본인인증**: 마이페이지에서 추가 인증 가능

### 데이터베이스 마이그레이션
```sql
-- User 테이블 컬럼 추가 (이미 존재하는 경우 스킵)
ALTER TABLE users ADD COLUMN phone_number VARCHAR(20);
ALTER TABLE users ADD COLUMN phone_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN real_name VARCHAR(100);

-- 기존 사용자 phone_verified 초기화
UPDATE users SET phone_verified = FALSE WHERE phone_verified IS NULL;
```

---

## ✅ 체크리스트

### 개발 전 체크
- [ ] 백엔드 API 엔드포인트 준비 완료
- [ ] 본인인증 서비스 (SMS 발송) 계약 완료
- [ ] 이메일 발송 서비스 설정 완료
- [ ] 디자인 시스템 확인 (색상, 폰트, 간격)

### 개발 중 체크
- [ ] RegisterState 모델 구현
- [ ] VerificationService 구현
- [ ] 5개 Step 위젯 구현
- [ ] RegisterFlowPage 구현
- [ ] AuthService 수정
- [ ] API Config 업데이트

### 테스트 체크
- [ ] 이메일 가입 전체 플로우
- [ ] 카카오 가입 전체 플로우
- [ ] 이메일 인증 타이머 동작
- [ ] 본인인증 타이머 동작
- [ ] 에러 케이스 처리
- [ ] 뒤로 가기 동작
- [ ] 새로고침 시 상태 유지

### 배포 전 체크
- [ ] 프로덕션 환경 변수 설정
- [ ] API 엔드포인트 변경
- [ ] 보안 검토 완료
- [ ] 성능 테스트 완료
- [ ] 접근성 검토 완료

---

## 📚 추가 자료

### 참고 링크
- [Flutter Forms](https://docs.flutter.dev/cookbook/forms)
- [Provider State Management](https://pub.dev/packages/provider)
- [GoRouter Navigation](https://pub.dev/packages/go_router)
- [본인인증 가이드](https://www.nice.co.kr/)

### 관련 파일
- `building_map_app/lib/pages/auth/register_page.dart` (현재 구현)
- `building_map_app/lib/services/auth_service.dart`
- `building_map_app/lib/models/user.dart`
- `building_map_app/lib/config/api_config.dart`

---

**문서 작성일**: 2025-01-11
**작성자**: Claude Code
**버전**: 1.0
**상태**: 설계 완료, 구현 대기
