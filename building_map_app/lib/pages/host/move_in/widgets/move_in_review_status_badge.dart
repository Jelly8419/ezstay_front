import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/move_in/move_in.dart';

/// 입주 준비 간편 방의 심사 상태 뱃지
///
/// - PENDING  : 회색/주황 톤 ("심사 대기")
/// - APPROVED : 녹색 톤 ("사용 가능")
/// - REJECTED : 빨강 톤 ("심사 거절")
class MoveInReviewStatusBadge extends StatelessWidget {
  final MoveInRoomReviewStatus status;

  const MoveInReviewStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = _schemeFor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: scheme.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: scheme.foreground.withValues(alpha: 0.3)),
      ),
      child: Text(
        scheme.label,
        style: AppTextStyles.labelSmall.copyWith(
          color: scheme.foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static _BadgeScheme _schemeFor(MoveInRoomReviewStatus status) {
    switch (status) {
      case MoveInRoomReviewStatus.pending:
        return const _BadgeScheme(
          label: '심사 대기',
          background: AppColors.warning50,
          foreground: AppColors.warning700,
        );
      case MoveInRoomReviewStatus.approved:
        return const _BadgeScheme(
          label: '사용 가능',
          background: AppColors.success50,
          foreground: AppColors.success700,
        );
      case MoveInRoomReviewStatus.rejected:
        return const _BadgeScheme(
          label: '심사 거절',
          background: AppColors.error50,
          foreground: AppColors.error700,
        );
    }
  }
}

class _BadgeScheme {
  final String label;
  final Color background;
  final Color foreground;
  const _BadgeScheme({
    required this.label,
    required this.background,
    required this.foreground,
  });
}
