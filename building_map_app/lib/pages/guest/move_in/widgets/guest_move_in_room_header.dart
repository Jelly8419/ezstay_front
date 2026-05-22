import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/guest_move_in/guest_move_in.dart';
import '../utils/guest_move_in_format.dart';

/// 룸 정보 + 입주일/퇴실일 헤더 카드
///
/// 비로그인 미리보기, 상세, 결제, 결제 완료 화면 공용.
class GuestMoveInRoomHeader extends StatelessWidget {
  final GuestMoveInRoom room;
  final String checkInDate;
  final String checkOutDate;

  const GuestMoveInRoomHeader({
    super.key,
    required this.room,
    required this.checkInDate,
    required this.checkOutDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (room.displayName != null && room.displayName!.isNotEmpty) ...[
            Text(room.displayName!, style: AppTextStyles.headingMedium),
            SizedBox(height: AppSpacing.xs),
          ],
          Text(
            room.fullAddress,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Divider(color: AppColors.border, height: 1),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _DateBlock(
                  label: '입주일',
                  date: GuestMoveInFormat.formatDate(checkInDate),
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.border),
              Expanded(
                child: _DateBlock(
                  label: '퇴실일',
                  date: GuestMoveInFormat.formatDate(checkOutDate),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateBlock extends StatelessWidget {
  final String label;
  final String date;

  const _DateBlock({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(date, style: AppTextStyles.bodyLarge),
      ],
    );
  }
}
