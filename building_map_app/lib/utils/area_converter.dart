/// 면적 단위 변환 유틸리티
///
/// 제곱미터(㎡)와 평(坪) 간의 변환 함수 제공
class AreaConverter {
  /// 1평 = 3.3058 제곱미터
  static const double _pyeongToSqm = 3.3058;

  /// 제곱미터를 평으로 변환
  ///
  /// [sqm] 제곱미터 값
  /// [decimal] 소수점 자리수 (기본값: 1)
  /// 반환값: 평수
  static double sqmToPyeong(double sqm, {int decimal = 1}) {
    final pyeong = sqm / _pyeongToSqm;
    final multiplier = decimal == 0 ? 1 : (10 * decimal);
    return (pyeong * multiplier).round() / multiplier;
  }

  /// 평을 제곱미터로 변환
  ///
  /// [pyeong] 평수 값
  /// [decimal] 소수점 자리수 (기본값: 2)
  /// 반환값: 제곱미터
  static double pyeongToSqm(double pyeong, {int decimal = 2}) {
    final sqm = pyeong * _pyeongToSqm;
    final multiplier = decimal == 0 ? 1 : (10 * decimal);
    return (sqm * multiplier).round() / multiplier;
  }

  /// 제곱미터 String을 평으로 변환 (UI 표시용)
  ///
  /// [sqmString] 제곱미터 문자열
  /// 반환값: "25.3평" 형식의 문자열
  static String sqmStringToPyeongDisplay(String sqmString) {
    final sqm = double.tryParse(sqmString);
    if (sqm == null || sqm <= 0) return '0평';

    final pyeong = sqmToPyeong(sqm);
    return '${pyeong}평';
  }

  /// 평 String을 제곱미터로 변환 (UI 표시용)
  ///
  /// [pyeongString] 평수 문자열
  /// 반환값: "33.06㎡" 형식의 문자열
  static String pyeongStringToSqmDisplay(String pyeongString) {
    final pyeong = double.tryParse(pyeongString);
    if (pyeong == null || pyeong <= 0) return '0㎡';

    final sqm = pyeongToSqm(pyeong);
    return '${sqm}㎡';
  }

  /// 제곱미터를 평으로 변환 (정수 반올림)
  ///
  /// [sqm] 제곱미터 값
  /// 반환값: 반올림된 평수 정수
  static int sqmToPyeongRounded(double sqm) {
    return (sqm / _pyeongToSqm).round();
  }

  /// 평을 제곱미터로 변환 (정수 반올림)
  ///
  /// [pyeong] 평수 값
  /// 반환값: 반올림된 제곱미터 정수
  static int pyeongToSqmRounded(double pyeong) {
    return (pyeong * _pyeongToSqm).round();
  }
}
