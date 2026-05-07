// 입주 준비 서비스 (임차인) — 도메인 enum 모음
//
// 백엔드 응답 문자열 ↔ 한글 라벨 ↔ enum 변환을 한 곳에서 관리.
// 백엔드 API 명세: backend_md_list/입주준비서비스_임차인_API.md

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// 게스트 입주 준비 요청 상태 (PRD 9.1)
enum GuestMoveInStatus {
  pendingPayment('PENDING_PAYMENT', '결제 대기'),
  paid('PAID', '결제 완료'),
  completed('COMPLETED', '완료');

  final String code;
  final String label;
  const GuestMoveInStatus(this.code, this.label);

  static GuestMoveInStatus fromCode(String? code) {
    return GuestMoveInStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => GuestMoveInStatus.pendingPayment,
    );
  }

  /// 상태 칩 배경색
  Color get chipColor {
    switch (this) {
      case GuestMoveInStatus.pendingPayment:
        return AppColors.warning50;
      case GuestMoveInStatus.paid:
        return AppColors.primary100;
      case GuestMoveInStatus.completed:
        return AppColors.success50;
    }
  }

  /// 상태 칩 텍스트 색
  Color get chipTextColor {
    switch (this) {
      case GuestMoveInStatus.pendingPayment:
        return AppColors.warning700;
      case GuestMoveInStatus.paid:
        return AppColors.primary700;
      case GuestMoveInStatus.completed:
        return AppColors.success700;
    }
  }
}

/// 주문 상태
enum GuestOrderStatus {
  pending('PENDING', '결제 대기'),
  paid('PAID', '결제 완료'),
  partialRefund('PARTIAL_REFUND', '부분 환불'),
  fullyRefunded('FULLY_REFUNDED', '전체 환불'),
  cancelled('CANCELLED', '취소');

  final String code;
  final String label;
  const GuestOrderStatus(this.code, this.label);

  static GuestOrderStatus fromCode(String? code) {
    return GuestOrderStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => GuestOrderStatus.pending,
    );
  }
}

/// 배송 상태
enum DeliveryStatus {
  pending('PENDING', '준비 중'),
  inTransit('IN_TRANSIT', '배송 중'),
  delivered('DELIVERED', '배송 완료');

  final String code;
  final String label;
  const DeliveryStatus(this.code, this.label);

  static DeliveryStatus fromCode(String? code) {
    return DeliveryStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => DeliveryStatus.pending,
    );
  }
}

/// 주문 타입 (최초/추가)
enum OrderType {
  initial('INITIAL', '최초 결제'),
  additional('ADDITIONAL', '추가 결제');

  final String code;
  final String label;
  const OrderType(this.code, this.label);

  static OrderType fromCode(String? code) {
    return OrderType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => OrderType.initial,
    );
  }
}

/// 옵션 타입 (구매/대여)
enum GuestOptionType {
  purchase('PURCHASE', '구매'),
  rental('RENTAL', '대여');

  final String code;
  final String label;
  const GuestOptionType(this.code, this.label);

  static GuestOptionType fromCode(String? code) {
    return GuestOptionType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => GuestOptionType.purchase,
    );
  }
}

/// 옵션 카테고리
enum GuestOptionCategory {
  amenityKit('AMENITY_KIT', '입주용품 세트'),
  beddingSet('BEDDING_SET', '침구류'),
  hairDryer('HAIR_DRYER', '헤어드라이기'),
  towelSet('TOWEL_SET', '수건'),
  other('OTHER', '기타');

  final String code;
  final String label;
  const GuestOptionCategory(this.code, this.label);

  static GuestOptionCategory fromCode(String? code) {
    return GuestOptionCategory.values.firstWhere(
      (e) => e.code == code,
      orElse: () => GuestOptionCategory.other,
    );
  }
}

/// 주문 라인 상태 (취소된 라인 구분)
enum OrderItemStatus {
  active('ACTIVE'),
  cancelled('CANCELLED');

  final String code;
  const OrderItemStatus(this.code);

  static OrderItemStatus fromCode(String? code) {
    return OrderItemStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => OrderItemStatus.active,
    );
  }
}
