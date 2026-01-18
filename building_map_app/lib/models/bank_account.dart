/// 계좌 정보 모델
/// Backend API: GET /api/host/account
class BankAccount {
  final int id;
  final String bankName;
  final String accountNumber; // 뒷 6자리 마스킹 (예: 1234-5678-90******)
  final String accountHolder;
  final bool isVerified;
  final DateTime? verifiedAt;
  final bool isPrimary;
  final DateTime createdAt;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    required this.isVerified,
    this.verifiedAt,
    required this.isPrimary,
    required this.createdAt,
  });

  /// JSON → BankAccount 변환
  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as int,
      bankName: json['bankName'] as String,
      accountNumber: json['accountNumber'] as String,
      accountHolder: json['accountHolder'] as String,
      isVerified: json['isVerified'] as bool,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
      isPrimary: json['isPrimary'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// BankAccount → JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
