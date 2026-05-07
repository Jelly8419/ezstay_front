import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/guest_move_in/guest_move_in.dart';

/// 게스트 입주 준비 상태 칩 (결제 대기 / 결제 완료 / 완료)
class GuestMoveInStatusChip extends StatelessWidget {
  final GuestMoveInStatus status;

  const GuestMoveInStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: status.chipColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.bodySmall.copyWith(
          color: status.chipTextColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
