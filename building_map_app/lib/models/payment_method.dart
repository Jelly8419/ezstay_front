import 'package:flutter/material.dart';
import 'contract.dart';

/// 결제 수단 extension (UI용 추가 정보)
extension PaymentMethodExtension on PaymentMethod {
  /// 결제 수단 설명
  String get description {
    switch (this) {
      case PaymentMethod.creditCard:
        return '간편하고 빠른 결제';
      case PaymentMethod.bankTransfer:
        return '수수료 없이 안전한 결제';
      case PaymentMethod.virtualAccount:
        return '계좌번호 발급 후 입금';
      case PaymentMethod.easyPay:
        return '카카오페이·네이버페이·토스페이';
      case PaymentMethod.mobilePayment:
        return '휴대폰 소액결제로 간편하게';
    }
  }

  /// 결제 수단 아이콘
  IconData get icon {
    switch (this) {
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.virtualAccount:
        return Icons.receipt_long;
      case PaymentMethod.easyPay:
        return Icons.smartphone;
      case PaymentMethod.mobilePayment:
        return Icons.phone_android;
    }
  }
}
