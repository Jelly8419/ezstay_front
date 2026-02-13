/// 결제 내역 모델
class PaymentHistory {
  final int id;
  final String transactionType; // 'PAYMENT' | 'REFUND'
  final int amount;
  final DateTime transactionDate;
  final String status; // 'COMPLETED' | 'PENDING' | 'FAILED'
  final String? description;

  const PaymentHistory({
    required this.id,
    required this.transactionType,
    required this.amount,
    required this.transactionDate,
    required this.status,
    this.description,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      id: json['id'] as int,
      transactionType: json['transactionType'] as String,
      amount: json['amount'] as int,
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      status: json['status'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionType': transactionType,
      'amount': amount,
      'transactionDate': transactionDate.toIso8601String(),
      'status': status,
      if (description != null) 'description': description,
    };
  }

  /// 거래 타입이 결제인지 확인
  bool get isPayment => transactionType == 'PAYMENT';

  /// 거래 타입이 환불인지 확인
  bool get isRefund => transactionType == 'REFUND';

  /// 거래 상태가 완료인지 확인
  bool get isCompleted => status == 'COMPLETED';
}
