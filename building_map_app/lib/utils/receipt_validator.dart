/// 영수증 관련 입력값 검증 유틸리티
///
/// 현금영수증/세금계산서 번호 유효성 검사를 제공합니다.
/// [PasswordValidator]와 동일한 static class 패턴을 따릅니다.
class ReceiptValidator {
  ReceiptValidator._();

  /// 휴대폰 번호 형식 검증 (숫자만 10~11자리, 01로 시작)
  static String? validatePhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10 || digits.length > 11) {
      return '휴대폰 번호는 10~11자리 숫자로 입력해주세요.';
    }
    if (!digits.startsWith('01')) {
      return '올바른 휴대폰 번호를 입력해주세요.';
    }
    return null;
  }

  /// 현금영수증 카드 번호 검증 (숫자만 13~16자리)
  static String? validateCardNumber(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 13 || digits.length > 16) {
      return '현금영수증 카드 번호는 13~16자리 숫자로 입력해주세요.';
    }
    return null;
  }

  /// 사업자 등록번호 검증 (숫자만 10자리)
  static String? validateBusinessNumber(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 10) {
      return '사업자 등록번호는 10자리 숫자로 입력해주세요.';
    }
    return null;
  }

  /// 이메일 형식 검증
  static String? validateEmail(String value) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) {
      return '올바른 이메일 주소를 입력해주세요.';
    }
    return null;
  }
}
