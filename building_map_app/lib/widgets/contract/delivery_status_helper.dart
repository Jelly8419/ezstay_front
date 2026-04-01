import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// 배송 상태 표시 유틸리티 (순수 static 메서드)
class DeliveryStatusHelper {
  DeliveryStatusHelper._();

  static String label(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return '배송 전';
      case 'IN_TRANSIT':
        return '배송 중';
      case 'DELIVERED':
        return '배송 완료';
      default:
        return '배송 전';
    }
  }

  static Color bgColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return AppColors.blue50;
      case 'IN_TRANSIT':
        return AppColors.warning50;
      case 'DELIVERED':
        return AppColors.success50;
      default:
        return AppColors.neutral50;
    }
  }

  static Color textColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return AppColors.blue700;
      case 'IN_TRANSIT':
        return AppColors.warning700;
      case 'DELIVERED':
        return AppColors.success700;
      default:
        return AppColors.neutral500;
    }
  }

  static Color borderColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return AppColors.primary200;
      case 'IN_TRANSIT':
        return AppColors.warning500;
      case 'DELIVERED':
        return AppColors.success100;
      default:
        return AppColors.neutral200;
    }
  }

  static Widget badge(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor(status),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor(status)),
      ),
      child: Text(
        label(status),
        style: TextStyle(
          fontSize: 11,
          color: textColor(status),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
