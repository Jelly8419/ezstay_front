/// 계좌 정보 모델
/// 호스트 정산계좌 (GET /api/host/account) 및 게스트 환급계좌 (GET /api/account/refund) 공용
class BankAccount {
  final int id;
  final String? bankCode;
  final String bankName;
  final String accountNumber; // 마스킹 (예: 110****6789)
  final String accountHolder;
  final bool isVerified;
  final DateTime? verifiedAt;
  final bool isPrimary;
  final DateTime createdAt;

  BankAccount({
    required this.id,
    this.bankCode,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    required this.isVerified,
    this.verifiedAt,
    this.isPrimary = false,
    required this.createdAt,
  });

  /// JSON → BankAccount 변환
  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as int,
      bankCode: json['bankCode'] as String?,
      bankName: json['bankName'] as String,
      accountNumber: json['accountNumber'] as String,
      accountHolder: json['accountHolder'] as String,
      isVerified: json['isVerified'] as bool? ?? false,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
      isPrimary: json['isPrimary'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// BankAccount → JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (bankCode != null) 'bankCode': bankCode,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountHolder': accountHolder,
      'isVerified': isVerified,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'isPrimary': isPrimary,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'BankAccount(id: $id, bankName: $bankName, accountNumber: $accountNumber, accountHolder: $accountHolder, isVerified: $isVerified)';
  }
}
