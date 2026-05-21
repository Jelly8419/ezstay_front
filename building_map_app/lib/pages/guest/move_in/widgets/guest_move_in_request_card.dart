import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/guest_move_in/guest_move_in.dart';
import '../utils/guest_move_in_format.dart';
import 'guest_move_in_deadline_banner.dart';
import 'guest_move_in_status_chip.dart';

/// 목록 화면용 케이스 카드
class GuestMoveInRequestCard extends StatelessWidget {
  final GuestMoveInRequestListItem item;
  final VoidCallback onTap;

  const GuestMoveInRequestCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.room.displayName ?? item.room.address ?? '-',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                GuestMoveInStatusChip(status: item.status),
              ],
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              item.room.fullAddress,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  '입주 ${GuestMoveInFormat.formatDate(item.checkInDate)}'
                  ' · 퇴실 ${GuestMoveInFormat.formatDate(item.checkOutDate)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (item.status == GuestMoveInStatus.pendingPayment) ...[
              SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: GuestMoveInDeadlineBanner(
                  deadline: item.paymentDeadline,
                  expired: !item.canPay,
                  compact: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
