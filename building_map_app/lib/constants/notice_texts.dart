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

  static const optionReturnRequestAdminConfirm =
      '반품 신청 후 실제 환불 금액은 관리자 처리 후 최종 확정됩니다.';

  static const optionReturnShippingFeeNotice =
      '배송 완료 상품 반품 시 수거비 7,000원이 차감될 수 있습니다. 동일 계약 내 수거 진행 중인 건이 있으면 면제됩니다.';

  // === 환불 규칙 텍스트 생성 ===
  /// RefundRule, RefundPolicyRule 등 description + refundRate 조합 텍스트
  static String cancellationText(String description, int refundRate) {
    if (refundRate == 0) {
      return '$description : 임대료 환불 불가';
    }
    return '$description : 임대료의 $refundRate% 환불';
  }

  // === 계약 안내사항 (게스트) ===
  static const guestContractNotices = [
    '옵션 상품(침구류, 어메니티 키트, 헤어드라이기 등)은 호스트 계약 정보에 표시되지 않습니다.',
    '옵션 상품, 계약 변경사항에 대한 문의는 EZStay 고객센터로 연락 바랍니다.',
    '입주일 기준 7일 이내 계약 변경은 불가하며, 이후 변경 시 추가 수수료가 발생할 수 있습니다.',
  ];

  // === 계약 안내사항 (호스트) ===
  static const hostContractNotices = [
    '옵션 상품(침구류, 어메니티 키트, 헤어드라이기 등)은 호스트 계약 정보에 표시되지 않습니다.',
    '보증금은 제3자 예치기관에 보관되며, 정산 금액에 포함되지 않습니다',
    '정산은 계약 종료 후 영업일 기준 1~2일 내에 진행됩니다',
    '방의 상태가 훼손된 경우 퇴실 확인 전 보증금 보류 신청을 할 수 있습니다',
    '계약 취소 시 취소 정책에 따라 위약금이 부과될 수 있습니다',
    '문의사항이 있으시면 고객센터로 연락 주시기 바랍니다',
  ];

  // === 환불 계산 모달용 (bullet 포맷) ===
  static String get commonRefundPolicyBullets =>
      '• $sameDayCancelPenalty\n'
      '• $alwaysRefundDefault\n'
      '• $afterSameDayNoServiceFeeRefund\n'
      '• $optionRefundBeforeDelivery';
}
