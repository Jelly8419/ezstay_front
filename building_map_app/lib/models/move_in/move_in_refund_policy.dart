/// 입주 준비 서비스 환불/취소/반품 정책 (호스트/임차인 공용 — 프론트 사전 가드)
///
/// 백엔드 `utils/moveInRefundPolicy.js` 와 동일 정의의 단일 출처.
/// 최종 판정은 항상 서버가 수행하며, 본 유틸은 버튼 enable/disable·안내
/// 문구를 위한 클라이언트 측 사전 판정용. 날짜 비교는 모두 KST 기준
/// (앱은 KST 디바이스 가정 — 로컬 시각 사용).
class MoveInRefundPolicy {
  const MoveInRefundPolicy._();

  /// 왕복배송비(반품 수거비) — 렌탈과 동일 상수.
  static const int returnShippingFee = 7000;

  /// 청소 환불 D-1~당일 구간 차감액.
  static const int cleaningLateDeduction = 10000;

  // ============================================================
  // 임차인 — 옵션 취소 (즉시 환불)
  // ============================================================

  /// 옵션 취소 가능 여부.
  ///
  /// - 결제 전(PENDING): 불가 (미결제 취소는 별도 DELETE 흐름)
  /// - 결제완료 ~ 입주 D-5 23:59:59: 가능 (전액)
  /// - 입주 D-5 이후 ~ 입주일 전: `deliveryStatus == PENDING`(배송 전)만 가능
  /// - 입주일 이후: 불가
  static bool canCancelOrder({
    required DateTime checkInDate,
    required bool isPaid,
    required bool isDeliveryPending,
    DateTime? now,
  }) {
    if (!isPaid) return false;
    final t = now ?? DateTime.now();
    final checkInStart = _dateOnly(checkInDate);
    if (!t.isBefore(checkInStart)) return false; // 입주일 이후 불가

    final d5End = _endOfDay(checkInDate.subtract(const Duration(days: 5)));
    if (!t.isAfter(d5End)) return true; // 결제완료 ~ D-5 23:59:59 전액

    // D-5 이후 ~ 입주일 전 → 배송 전만
    return isDeliveryPending;
  }

  // ============================================================
  // 임차인 — 반품 요청 (관리자 승인)
  // ============================================================

  /// 반품 요청 가능 여부 — 입주일 ~ 퇴실일 + 배송완료.
  static bool canRequestReturn({
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required bool isDelivered,
    DateTime? now,
  }) {
    if (!isDelivered) return false;
    final t = now ?? DateTime.now();
    final checkInStart = _dateOnly(checkInDate);
    final checkOutEnd = _endOfDay(checkOutDate);
    return !t.isBefore(checkInStart) && !t.isAfter(checkOutEnd);
  }

  // ============================================================
  // 임대인 — 청소 결제 환불 (3구간)
  // ============================================================

  /// 청소 환불 시점 구간.
  static CleaningRefundTier cleaningRefundTier({
    required DateTime cleaningDateTime,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();

    // 희망 시간 1시간 전부터 환불 불가
    final oneHourBefore =
        cleaningDateTime.subtract(const Duration(hours: 1));
    if (!t.isBefore(oneHourBefore)) return CleaningRefundTier.notAllowed;

    // 희망일 D-2 23:59:59 까지 전액
    final d2End = _endOfDay(
      DateTime(cleaningDateTime.year, cleaningDateTime.month,
              cleaningDateTime.day)
          .subtract(const Duration(days: 2)),
    );
    if (!t.isAfter(d2End)) return CleaningRefundTier.full;

    // D-1 ~ 당일 → 1만원 차감
    return CleaningRefundTier.partial;
  }

  /// 청소 환불 예상 금액 (차감 적용). [notAllowed] 면 0.
  static int estimatedCleaningRefund({
    required int cleaningFee,
    required CleaningRefundTier tier,
  }) {
    switch (tier) {
      case CleaningRefundTier.full:
        return cleaningFee;
      case CleaningRefundTier.partial:
        final r = cleaningFee - cleaningLateDeduction;
        return r < 0 ? 0 : r;
      case CleaningRefundTier.notAllowed:
        return 0;
    }
  }

  // ============================================================
  // 내부 헬퍼
  // ============================================================

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59);
}

/// 청소 환불 3구간.
enum CleaningRefundTier {
  /// 결제완료 ~ 희망일 D-2 23:59:59 — 전액
  full,

  /// 희망일 D-1 ~ 당일 — 1만원 차감
  partial,

  /// 희망 시간 1시간 전부터 — 환불 불가
  notAllowed,
}
