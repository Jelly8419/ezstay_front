import 'package:intl/intl.dart';

/// 게스트 입주 준비 화면 공용 포매터
class GuestMoveInFormat {
  /// KST ISO 문자열 → "YYYY.MM.DD (요일)"
  ///
  /// 입력: "2027-08-10T00:00:00+09:00"
  /// 출력: "2027.08.10 (화)"
  /// 파싱 실패 시 원본 반환.
  static String formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(dt);
    } catch (_) {
      return raw;
    }
  }

  /// 날짜 + 시간: "2027.08.10 15:23"
  static String formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('yyyy.MM.dd HH:mm', 'ko_KR').format(dt);
    } catch (_) {
      return raw;
    }
  }

  /// 날짜 + 요일 + 시간: "2027.08.10 (화) 15:23"
  ///
  /// 결제 마감 기한 표시용. 파싱 실패 시 원본 반환.
  static String formatDeadline(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('yyyy.MM.dd (E) HH:mm', 'ko_KR').format(dt);
    } catch (_) {
      return raw;
    }
  }

  /// 1234567 → "1,234,567원"
  static String formatPrice(int value) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(value)}원';
  }
}
