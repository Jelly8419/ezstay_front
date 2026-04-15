import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 보증금 차감 지급 상태 배지
/// PENDING / PAYABLE → 주황 "지급 예정"
/// COMPLETED         → 초록 "지급 완료"
Widget buildDepositDeductionBadge(String status) {
  final isCompleted = status == 'COMPLETED';
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: isCompleted ? AppColors.success50 : AppColors.warning50,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      isCompleted ? '지급 완료' : '지급 예정',
      style: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.w600,
        color: isCompleted ? AppColors.success700 : AppColors.warning700,
      ),
    ),
  );
}
