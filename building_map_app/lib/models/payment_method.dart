import 'package:flutter/material.dart';
import 'contract.dart';

/// 결제 수단 extension (UI용 추가 정보)
extension PaymentMethodExtension on PaymentMethod {
  /// 결제 수단 설명
  String get description {
    switch (this) {
      case PaymentMethod.bc:
      case PaymentMethod.kb:
      case PaymentMethod.sh:
      case PaymentMethod.ss:
      case PaymentMethod.hd:
      case PaymentMethod.lt:
      case PaymentMethod.wr:
      case PaymentMethod.ka:
      case PaymentMethod.nh:
        return '신용/체크카드 결제';
      case PaymentMethod.kakaoPay:
        return '카카오페이로 간편결제';
      case PaymentMethod.naverPay:
        return '네이버페이로 간편결제';
      case PaymentMethod.payco:
        return '페이코로 간편결제';
      // TODO: 오픈 후 가상계좌 추가 예정
      // case PaymentMethod.virtualAccount:
      //   return '계좌번호 발급 후 입금';
    }
  }

  /// 결제 수단 아이콘
  IconData get icon {
    switch (this) {
      case PaymentMethod.bc:
      case PaymentMethod.kb:
      case PaymentMethod.sh:
      case PaymentMethod.ss:
      case PaymentMethod.hd:
      case PaymentMethod.lt:
      case PaymentMethod.wr:
      case PaymentMethod.ka:
      case PaymentMethod.nh:
        return Icons.credit_card;
      case PaymentMethod.kakaoPay:
        return Icons.chat_bubble;
      case PaymentMethod.naverPay:
        return Icons.shopping_bag;
      case PaymentMethod.payco:
        return Icons.payment;
      // TODO: 오픈 후 가상계좌 추가 예정
      // case PaymentMethod.virtualAccount:
      //   return Icons.receipt_long;
    }
  }
}
