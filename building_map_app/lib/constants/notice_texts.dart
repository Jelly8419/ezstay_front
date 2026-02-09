/// 안내사항 및 환불 정책 관련 공통 문구
///
/// 방 상세, 계약 시작, 계약 상세, 환불 계산 모달 등에서 공통으로 사용
class NoticeTexts {
  NoticeTexts._();

  // === 환불 안내사항 ===
  static const sameDayCancelPenalty =
      '결제 당일 취소 시, 환불 규정과 관계 없이 임대료와 계약 수수료를 합계한 10%만 위약금으로 부과됩니다.';

  static const alwaysRefundDefault = '관리비, 청소비, 보증금은 전액 환불됩니다.';

  static const afterSameDayNoServiceFeeRefund =
      '결제 당일 이후에는 계약수수료가 환불되지 않습니다.';

  static const rentRefundByHost = '임대료 환불 규정은 호스트의 설정에 따라 달라집니다.';

  // === 옵션 상품 환불 ===
  static const optionRefundWithin7Days = '옵션 상품은 배송 완료 후 7일 내에 환불이 가능합니다.';

  static const optionRefundRestrictions =
      '옵션 상품의 사용 흔적 및 오염, 배송 완료 7일 이후 환불은 불가하며, 단순변심은 왕복 배송비 7,000원이 청구됩니다.';

  static const optionRefundBeforeDelivery =
      '옵션 상품은 배송 전에는 전액 환불, 배송이 시작된 이후에는 왕복 배송비 7,000원 차감 후 환불됩니다.';

  // === 환불 규칙 텍스트 생성 ===
  /// RefundRule, RefundPolicyRule 등 description + refundRate 조합 텍스트
  static String cancellationText(String description, int refundRate) {
    if (refundRate == 0) {
      return '$description : 임대료 환불 불가';
    }
    return '$description : 임대료의 $refundRate% 환불';
  }

  // === 환불 계산 모달용 (bullet 포맷) ===
  static String get commonRefundPolicyBullets =>
      '• $sameDayCancelPenalty\n'
      '• $alwaysRefundDefault\n'
      '• $afterSameDayNoServiceFeeRefund\n'
      '• $optionRefundBeforeDelivery';
}
