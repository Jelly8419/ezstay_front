/// 호스트 귀책 취소 부담금 미리보기 데이터
class CancelPreviewData {
  // 원본 결제 항목
  final int originalRentalFee;
  final int originalCleaningFee;
  final int originalMaintenanceFee;
  final int originalDeposit;
  final int originalPlatformFee;
  final int originalRentalItemsFee;
  final int originalTotalAmount;

  // 항목별 환불 금액
  final int rentalFeeRefundAmount;
  final int cleaningFeeRefundAmount;
  final int maintenanceFeeRefundAmount;
  final int depositRefundAmount;
  final int rentalItemsFeeRefundAmount;

  // 호스트 납부 / 게스트 수령
  final int hostBurdenAmount;
  final int penaltyAmount;
  final int guestRefundAmount;
  final int guestCompensationAmount;

  // 위약금 결제용 주문번호 (백엔드 preview 응답에서 수신)
  final String? orderId;

  // 결제자 정보 (PayTag SDK order_name, order_hp 파라미터용)
  final String? customerName;
  final String? customerPhone;

  // 정책 정보
  final int daysBeforeCheckin;
  final int refundRate;
  final String policyDisplayName;
  final String applicableRuleDescription;
  final String message;

  const CancelPreviewData({
    this.orderId,
    this.customerName,
    this.customerPhone,
    required this.originalRentalFee,
    required this.originalCleaningFee,
    required this.originalMaintenanceFee,
    required this.originalDeposit,
    required this.originalPlatformFee,
    required this.originalRentalItemsFee,
    required this.originalTotalAmount,
    required this.rentalFeeRefundAmount,
    required this.cleaningFeeRefundAmount,
    required this.maintenanceFeeRefundAmount,
    required this.depositRefundAmount,
    required this.rentalItemsFeeRefundAmount,
    required this.hostBurdenAmount,
    required this.penaltyAmount,
    required this.guestRefundAmount,
    required this.guestCompensationAmount,
    required this.daysBeforeCheckin,
    required this.refundRate,
    required this.policyDisplayName,
    required this.applicableRuleDescription,
    required this.message,
  });

  factory CancelPreviewData.fromJson(Map<String, dynamic> json) {
    return CancelPreviewData(
      orderId: json['orderId'] as String?,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      originalRentalFee: (json['originalRentalFee'] as num? ?? 0).toInt(),
      originalCleaningFee: (json['originalCleaningFee'] as num? ?? 0).toInt(),
      originalMaintenanceFee: (json['originalMaintenanceFee'] as num? ?? 0).toInt(),
      originalDeposit: (json['originalDeposit'] as num? ?? 0).toInt(),
      originalPlatformFee: (json['originalPlatformFee'] as num? ?? 0).toInt(),
      originalRentalItemsFee: (json['originalRentalItemsFee'] as num? ?? 0).toInt(),
      originalTotalAmount: (json['originalTotalAmount'] as num? ?? 0).toInt(),
      rentalFeeRefundAmount: (json['rentalFeeRefundAmount'] as num? ?? 0).toInt(),
      cleaningFeeRefundAmount: (json['cleaningFeeRefundAmount'] as num? ?? 0).toInt(),
      maintenanceFeeRefundAmount: (json['maintenanceFeeRefundAmount'] as num? ?? 0).toInt(),
      depositRefundAmount: (json['depositRefundAmount'] as num? ?? 0).toInt(),
      rentalItemsFeeRefundAmount: (json['rentalItemsFeeRefundAmount'] as num? ?? 0).toInt(),
      hostBurdenAmount: (json['hostBurdenAmount'] as num? ?? 0).toInt(),
      penaltyAmount: (json['penaltyAmount'] as num? ?? 0).toInt(),
      guestRefundAmount: (json['guestRefundAmount'] as num? ?? 0).toInt(),
      guestCompensationAmount: (json['guestCompensationAmount'] as num? ?? 0).toInt(),
      daysBeforeCheckin: (json['daysBeforeCheckin'] as num? ?? 0).toInt(),
      refundRate: (json['refundRate'] as num? ?? 0).toInt(),
      policyDisplayName: json['policyDisplayName'] as String? ?? '',
      applicableRuleDescription: json['applicableRuleDescription'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  bool get hasBurden => hostBurdenAmount > 0;
}

/// 호스트 귀책 취소 결제 prepare 데이터
/// GET /api/contracts/:contractId/cancel-by-host/payment-info
class CancelPaymentInfo {
  final String orderId;
  final int hostBurdenAmount;
  final int? pgAmount; // 테스트 환경에서만 존재
  final String? customerName;
  final String? customerPhone;

  const CancelPaymentInfo({
    required this.orderId,
    required this.hostBurdenAmount,
    this.pgAmount,
    this.customerName,
    this.customerPhone,
  });

  factory CancelPaymentInfo.fromJson(Map<String, dynamic> json) {
    return CancelPaymentInfo(
      orderId: json['orderId'] as String,
      hostBurdenAmount: (json['hostBurdenAmount'] as num).toInt(),
      pgAmount: (json['pgAmount'] as num?)?.toInt(),
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
    );
  }

  /// SDK에 전달할 실제 결제 금액 (테스트 환경이면 pgAmount 우선)
  int get sdkAmount => pgAmount ?? hostBurdenAmount;
}
