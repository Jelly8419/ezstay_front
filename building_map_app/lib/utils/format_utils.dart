import 'package:intl/intl.dart';

/// 금액/날짜 포맷 중앙화 유틸리티
///
/// 프로젝트 전체에서 일관된 포맷을 사용하기 위한 유틸리티 클래스입니다.
class FormatUtils {
  FormatUtils._();

  static final NumberFormat _currencyFormat = NumberFormat('#,###');

  // ========== 금액 포맷 ==========

  /// 숫자를 천 단위 콤마로 포맷 (예: 1000000 → "1,000,000")
  static String formatCurrency(num amount) {
    return _currencyFormat.format(amount);
  }

  /// 숫자를 한국 통화 형식으로 포맷 (예: 1000000 → "1,000,000원")
  static String formatKRW(num amount) {
    return '${_currencyFormat.format(amount)}원';
  }

  /// 만원 단위로 포맷 (예: 10000 → "1만원", 15000 → "1.5만원")
  static String formatManWon(num amount) {
    final manWon = amount / 10000;
    if (manWon == manWon.roundToDouble()) {
      return '${manWon.toInt()}만원';
    }
    return '$manWon만원';
  }

  // ========== 날짜 포맷 ==========

  /// 날짜를 기본 형식으로 포맷 (예: "2025.01.15")
  static String formatDate(DateTime date) {
    return DateFormat('yyyy.MM.dd').format(date);
  }

  /// 날짜를 API 형식으로 포맷 (예: "2025-01-15")
  static String formatDateApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// 날짜+시간을 포맷 (예: "2025-01-15 14:30")
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  /// 날짜+요일을 포맷 (예: "2025.01.15(수)")
  static String formatDateWithDay(DateTime date) {
    return DateFormat('yyyy.MM.dd(E)', 'ko_KR').format(date);
  }

  /// 문자열 날짜를 요일 포함 포맷 (예: "2025.01.15(수)")
  /// 파싱 실패 시 원본 문자열 반환
  static String formatDateWithDayString(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return formatDateWithDay(date);
    } catch (e) {
      return dateStr;
    }
  }

  /// 짧은 날짜 포맷 (예: "01.15")
  static String formatDateShort(DateTime date) {
    return DateFormat('MM.dd').format(date);
  }

  /// 시간만 포맷 (예: "14:30")
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// 한국어 날짜 포맷 (예: "1월 15일 (수)")
  static String formatDateKorean(DateTime date) {
    return DateFormat('M월 d일 (E)', 'ko').format(date);
  }

  /// 한국어 날짜+연도 포맷 (예: "2025년 1월 15일 (수)")
  static String formatDateKoreanFull(DateTime date) {
    return DateFormat('yyyy년 M월 d일 (E)', 'ko').format(date);
  }

  /// 날짜+시간 닷 형식 (예: "2025.01.15 14:30")
  static String formatDateTimeDot(DateTime dateTime) {
    return DateFormat('yyyy.MM.dd HH:mm').format(dateTime);
  }

  // ========== 날짜 파싱 ==========

  /// 채팅 메시지 시간 포맷 — 오전/오후 h:mm (예: "오후 2:05")
  static String formatChatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? '오후' : '오전';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$period $displayHour:$minute';
  }

  /// 문자열을 DateTime으로 파싱 (null 안전)
  static DateTime? tryParseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr);
  }
}
