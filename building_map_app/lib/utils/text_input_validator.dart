/// 한글·영어·숫자만 허용하는 입력 검증 유틸리티
///
/// 닉네임, 이름 등 한글/영어/숫자 텍스트만 입력받아야 하는 필드에 공통 적용합니다.
/// - 허용: 한글(가-힣), 영어(a-zA-Z), 숫자(0-9)
/// - 불허: 공백, 특수문자
class TextInputValidator {
  TextInputValidator._();

  static final RegExp _regex = RegExp(r'^[가-힣a-zA-Z0-9]+$');

  static const String hintText = '한글, 영어, 숫자만 입력 가능 (공백·특수문자 불가)';

  /// 유효하면 null, 아니면 에러 메시지 반환.
  ///
  /// [minLength], [maxLength]로 길이 범위를 지정합니다 (기본 1~50자).
  static String? validate(
    String? value, {
    int minLength = 1,
    int maxLength = 50,
  }) {
    if (value == null || value.isEmpty) return null;
    if (value.length < minLength || value.length > maxLength) {
      return '$minLength~$maxLength자로 입력해주세요.';
    }
    if (!_regex.hasMatch(value)) {
      return '한글, 영어, 숫자만 입력 가능합니다. (공백·특수문자 불가)';
    }
    return null;
  }

  /// [TextFormField.validator] 형태로 바로 사용할 수 있는 래퍼.
  static String? Function(String?) fieldValidator({
    int minLength = 1,
    int maxLength = 50,
  }) {
    return (value) => validate(value?.trim(), minLength: minLength, maxLength: maxLength);
  }

  /// 입력값이 규칙을 통과하는지 여부만 반환.
  static bool isValid(String value, {int minLength = 1, int maxLength = 50}) {
    return validate(value, minLength: minLength, maxLength: maxLength) == null;
  }
}
