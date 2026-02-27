/// 비밀번호 검증 유틸리티
///
/// 회원가입, 비밀번호 변경 등 모든 비밀번호 입력에 통일된 정책을 적용합니다.
/// 정책: 8~16자, 영문(대소문자 무관) + 숫자 필수
class PasswordValidator {
  PasswordValidator._();

  static const int minLength = 8;
  static const int maxLength = 16;

  static const String hintText = '8~16자, 영문과 숫자 포함';
  static const String policyDescription = '영문과 숫자를 포함한 8~16자로 입력해주세요.';

  static final RegExp _letterRegex = RegExp(r'[a-zA-Z]');
  static final RegExp _digitRegex = RegExp(r'\d');

  /// 비밀번호 유효성 검사. 유효하면 null, 아니면 에러 메시지 반환.
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }
    if (value.length < minLength) {
      return '비밀번호는 $minLength자 이상이어야 합니다';
    }
    if (value.length > maxLength) {
      return '비밀번호는 $maxLength자 이하여야 합니다';
    }
    if (!_letterRegex.hasMatch(value)) {
      return '영문을 포함해야 합니다';
    }
    if (!_digitRegex.hasMatch(value)) {
      return '숫자를 포함해야 합니다';
    }
    return null;
  }

  /// 비밀번호 확인 검사. 일치하면 null, 아니면 에러 메시지 반환.
  static String? validateConfirm(String? value, String password) {
    if (value == null || value.isEmpty) {
      return '비밀번호 확인을 입력해주세요';
    }
    if (value != password) {
      return '비밀번호가 일치하지 않습니다';
    }
    return null;
  }
}
