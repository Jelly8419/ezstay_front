/// 입주 준비 서비스 결제 마감 정책 (호스트/임차인 공용)
///
/// 정책 정의 — 단일 출처:
///   - 청소 서비스: 입주일의 D-2일 23:59:59 KST 까지
///   - 입주용품/침구류: 입주일의 D-5일 23:59:59 KST 까지
///
/// 백엔드 [calculateCleaningPaymentDeadline] / [calculateOptionPaymentDeadline] 와
/// 정확히 동일한 의미를 갖는다. 백엔드 응답의 `cleaningPaymentDeadline` /
/// `optionPaymentDeadline` 을 우선 사용하고, 케이스 생성 *전* 미리보기 등
/// 응답을 받을 수 없는 시점에만 본 헬퍼로 계산.
class MoveInDeadlinePolicy {
  static const int cleaningDaysBefore = 2;
  static const int optionDaysBefore = 5;

  const MoveInDeadlinePolicy._();

  /// 입주일 [checkInDate] 기준 청소 서비스 결제 마감 (23:59:59).
  static DateTime cleaningDeadline(DateTime checkInDate) =>
      _deadline(checkInDate, cleaningDaysBefore);

  /// 입주일 [checkInDate] 기준 입주용품/침구류 결제 마감 (23:59:59).
  static DateTime optionDeadline(DateTime checkInDate) =>
      _deadline(checkInDate, optionDaysBefore);

  static DateTime _deadline(DateTime checkInDate, int daysBefore) {
    final base = DateTime(checkInDate.year, checkInDate.month, checkInDate.day)
        .subtract(Duration(days: daysBefore));
    return DateTime(base.year, base.month, base.day, 23, 59, 59);
  }
}
