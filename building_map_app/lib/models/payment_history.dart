/// 결제 내역 모델
class PaymentHistory {
  final DateTime occurredAt;
  final int amount; // 양수: 결제, 음수: 환불
  final String? description;

  const PaymentHistory({
    required this.occurredAt,
    required this.amount,
    this.description,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      amount: json['amount'] as int,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'occurredAt': occurredAt.toIso8601String(),
      'amount': amount,
      if (description != null) 'description': description,
    };
  }

  /// 결제 여부 (amount 양수)
  bool get isPayment => amount > 0;

  /// 환불 여부 (amount 음수)
  bool get isRefund => amount < 0;
}
