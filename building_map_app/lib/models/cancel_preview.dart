/// 호스트 귀책 취소 부담금 미리보기 데이터
/// GET /api/contracts/:contractId/cancel-by-host/preview
class CancelPreviewData {
  final String policyDisplayName;
  final String applicableRuleDescription;
  final int penaltyAmount;
  final int refundRate;
  final int platformFeeRefundAmount;
  final int hostBurdenAmount;

  const CancelPreviewData({
    required this.policyDisplayName,
    required this.applicableRuleDescription,
    required this.penaltyAmount,
    required this.refundRate,
    required this.platformFeeRefundAmount,
    required this.hostBurdenAmount,
  });

  factory CancelPreviewData.fromJson(Map<String, dynamic> json) {
    return CancelPreviewData(
      policyDisplayName: json['policyDisplayName'] as String? ?? '',
      applicableRuleDescription:
          json['applicableRuleDescription'] as String? ?? '',
      penaltyAmount: (json['penaltyAmount'] as num? ?? 0).toInt(),
      refundRate: (json['refundRate'] as num? ?? 0).toInt(),
      platformFeeRefundAmount:
          (json['platformFeeRefundAmount'] as num? ?? 0).toInt(),
      hostBurdenAmount: (json['hostBurdenAmount'] as num? ?? 0).toInt(),
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
