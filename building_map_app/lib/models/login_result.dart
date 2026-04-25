/// 로그인 결과를 나타내는 enum
///
/// PRD v2.0 섹션 5.2에 따라 각 실패 케이스별 명확한 에러 메시지를 제공합니다.
enum LoginResult {
  /// 로그인 성공
  success,

  /// 이메일/비밀번호 불일치 (백엔드 에러코드: 1005)
  loginFailed,

  /// 계정 잠금 - 5회 실패 (백엔드 에러코드: 1004)
  accountLocked,

  /// 계정 정지 상태 (백엔드 에러코드: 1006)
  accountSuspended,

  /// 탈퇴한 계정 (백엔드 에러코드: 1007)
  accountWithdrawn,

  /// 카카오 이메일이 기존 이메일 계정과 중복 (백엔드 에러코드: 4010)
  kakaoEmailDuplicate,

  /// 로컬(이메일) 가입자가 동일 이메일로 소셜 로그인 시도 (백엔드 에러코드: 4016)
  kakaoEmailExistsAsLocal,

  /// 카카오 OAuth 인증 실패
  kakaoOAuthFailed,

  /// 카카오 계정 연동 실패
  kakaoConnectionFailed,

  /// 네트워크 오류
  networkError,

  /// 알 수 없는 오류
  unknownError;

  /// PRD에 명시된 사용자 노출 메시지
  String get message {
    switch (this) {
      case LoginResult.success:
        return '';
      case LoginResult.loginFailed:
        return '이메일 또는 비밀번호가 올바르지 않습니다.';
      case LoginResult.accountLocked:
        return '10분간 로그인할 수 없습니다.';
      case LoginResult.accountSuspended:
        return '회원님의 계정이 정지되었습니다.\n고객센터로 문의 부탁드립니다.';
      case LoginResult.accountWithdrawn:
        return '탈퇴한 계정입니다.\n재가입 하시겠습니까?';
      case LoginResult.kakaoEmailDuplicate:
        return '이미 가입된 계정입니다.\n이메일 로그인을 이용해주세요.';
      case LoginResult.kakaoEmailExistsAsLocal:
        return '이미 이메일로 가입된 계정입니다.\n이메일 로그인을 이용해주세요.';
      case LoginResult.kakaoOAuthFailed:
        return '카카오 로그인에 실패했습니다.\n다시 시도해주세요.';
      case LoginResult.kakaoConnectionFailed:
        return '카카오 계정 연동에 실패했습니다.';
      case LoginResult.networkError:
        return '네트워크 연결을 확인해주세요.';
      case LoginResult.unknownError:
        return '로그인 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
    }
  }

  /// 로그인 실패 여부
  bool get isFailure => this != LoginResult.success;
}
