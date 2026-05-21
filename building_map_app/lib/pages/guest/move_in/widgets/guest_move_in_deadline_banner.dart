import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../utils/guest_move_in_format.dart';

/// 결제 마감 기한 안내 박스 (노란 배경) — 결제 대기 상태에서만 노출.
///
/// 메인 목록 카드 / 상세 화면 / 결제 화면 공용.
/// [deadline] 은 KST ISO 문자열, 내부에서 'yyyy.MM.dd (E) HH:mm' 로 포맷.
///
/// [compact] true  — 내용 너비에 맞춘 작은 칩 + 간략 문구 ('결제 마감일 …').
///                   목록 카드에서 우측 정렬용. 부모가 Align 으로 위치 제어.
/// [compact] false — 전체 너비 배너 + 안내 문구. 상세/결제 화면용.
class GuestMoveInDeadlineBanner extends StatelessWidget {
  final String? deadline;

  /// true 면 마감이 지나 결제 불가 — 문구를 경고형으로 전환.
  final bool expired;

  /// true 면 목록 카드용 작은 칩 형태.
  final bool compact;

  const GuestMoveInDeadlineBanner({
    super.key,
    required this.deadline,
    this.expired = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = GuestMoveInFormat.formatDeadline(deadline);
    return Container(
      width: compact ? null : double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.warning500.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: compact ? 16 : 18,
            color: AppColors.warning700,
          ),
          SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
          if (compact)
            Text(
              expired ? '결제 마감 종료' : '결제 마감일 $formatted',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.warning700,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Expanded(
              child: Text(
                expired
                    ? '결제 마감 기한이 지나 결제할 수 없습니다. (마감 $formatted)'
                    : '결제 마감 기한  $formatted 까지 결제를 완료해주세요.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.warning700,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
