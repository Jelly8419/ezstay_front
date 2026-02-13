import 'package:building_map_app/models/user.dart';

/// 회원가입 플로우 상태 관리 모델
class RegisterState {
  // ========== 기본 정보 ==========
  String? email;
  String? password;
  UserMode mode;
  bool isSocialLogin;

  // ========== 카카오 정보 ==========
  String? kakaoName;
  String? profileImageUrl;

  // ========== 인증 정보 ==========
  bool emailVerified;
  bool phoneVerified;
  String? phoneNumber;
  String? realName; // 본인인증으로 받은 실명

  // ========== 추가 정보 (호스트) ==========
  String? bankCode;
  String? accountNumber;
  String? accountHolder;
  bool accountVerified;

  // ========== 약관 동의 ==========
  bool agreeTerms;
  bool agreeMarketing;

  // ========== 진행 상태 ==========
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

  /// 카카오 가입 초기화
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
      emailVerified: true, // 카카오 이메일은 인증된 것으로 간주
      currentStep: 0, // 본인인증 단계부터 시작 (카카오는 Step 1,2 스킵)
    );
  }

  /// 현재 단계 완료 여부 검증
  bool canProceedToNextStep() {
    if (isSocialLogin) {
      // 카카오 가입: Step 0(본인인증), 1(추가정보), 2(약관)
      switch (currentStep) {
        case 0: // 본인인증
          return phoneVerified && realName != null;
        case 1: // 추가 정보
          if (mode == UserMode.host) {
            return accountVerified;
          }
          return true;
        case 2: // 약관 동의
          return agreeTerms;
        default:
          return false;
      }
    } else {
      // 이메일 가입
      if (mode == UserMode.host) {
        // 호스트: 3단계 (이메일/PW+이메일인증 → 본인인증 → 정산계좌+약관)
        switch (currentStep) {
          case 0: // 이메일/비밀번호 입력 + 이메일 인증
            return email != null && password != null && emailVerified;
          case 1: // 본인인증만
            return phoneVerified && realName != null;
          case 2: // 정산계좌 + 약관동의
            return accountVerified && agreeTerms;
          default:
            return false;
        }
      } else {
        // 게스트: 2단계 (이메일/PW+이메일인증 → 본인인증+약관)
        switch (currentStep) {
          case 0: // 이메일/비밀번호 입력 + 이메일 인증
            return email != null && password != null && emailVerified;
          case 1: // 본인인증 + 약관동의
            return phoneVerified && realName != null && agreeTerms;
          default:
            return false;
        }
      }
    }
  }

  /// 이메일 가입 총 단계 수 (모드별 분리)
  int get totalStepsForEmail {
    // 호스트: 3단계 (이메일/PW → 본인인증 → 정산계좌+약관)
    // 게스트: 2단계 (이메일/PW → 본인인증+약관)
    return mode == UserMode.host ? 3 : 2;
  }

  /// 카카오 가입 총 단계 수 (모드별 분리)
  int get totalStepsForKakao {
    // 호스트: 2단계 (본인인증 → 정산계좌+약관)
    // 게스트: 1단계 (본인인증+약관)
    return mode == UserMode.host ? 2 : 1;
  }

  /// 현재 가입 방식의 총 단계 수
  int get totalSteps => isSocialLogin ? totalStepsForKakao : totalStepsForEmail;

  /// 진행률 (0.0 ~ 1.0)
  double get progress => (currentStep + 1) / totalSteps;

  /// 다음 단계로 이동
  void nextStep() {
    if (canProceedToNextStep() && currentStep < totalSteps - 1) {
      currentStep++;
    }
  }

  /// 이전 단계로 이동
  void prevStep() {
    if (currentStep > 0) {
      currentStep--;
    }
  }

  /// 이메일/비밀번호 설정
  void setEmailPassword(String email, String password) {
    this.email = email;
    this.password = password;
  }

  /// 이메일 인증 완료
  void markEmailVerified() {
    emailVerified = true;
  }

  /// 본인인증 완료
  void markPhoneVerified(String phoneNumber, String realName) {
    this.phoneNumber = phoneNumber;
    this.realName = realName;
    phoneVerified = true;
  }

  /// 계좌 인증 완료
  void markAccountVerified(String bankCode, String accountNumber, String accountHolder) {
    this.bankCode = bankCode;
    this.accountNumber = accountNumber;
    this.accountHolder = accountHolder;
    accountVerified = true;
  }

  /// 약관 동의 설정
  void setTermsAgreement(bool terms, bool marketing) {
    agreeTerms = terms;
    agreeMarketing = marketing;
  }

  /// 상태 초기화
  void reset() {
    email = null;
    password = null;
    mode = UserMode.guest;
    isSocialLogin = false;
    kakaoName = null;
    profileImageUrl = null;
    emailVerified = false;
    phoneVerified = false;
    phoneNumber = null;
    realName = null;
    bankCode = null;
    accountNumber = null;
    accountHolder = null;
    accountVerified = false;
    agreeTerms = false;
    agreeMarketing = false;
    currentStep = 0;
  }

  /// JSON 변환 (디버깅용)
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
      'totalSteps': totalSteps,
      'progress': progress,
    };
  }

  /// 디버그 출력
  @override
  String toString() {
    return 'RegisterState(email: $email, mode: ${mode.name}, '
        'step: $currentStep/$totalSteps, progress: ${(progress * 100).toStringAsFixed(0)}%)';
  }
}
