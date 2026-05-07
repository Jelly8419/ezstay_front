import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/guest_move_in/guest_move_in.dart';
import '../utils/guest_move_in_format.dart';

/// 결제 요약 박스 — 선택 옵션 + 수량 + 합계
///
/// 비로그인 미리보기와 결제 화면 공용.
class GuestMoveInSummaryBox extends StatelessWidget {
  final List<GuestMoveInOption> options;
  final Map<int, int> selectedQuantities; // optionId → quantity

  const GuestMoveInSummaryBox({
    super.key,
    required this.options,
    required this.selectedQuantities,
  });

  int get _total {
    int sum = 0;
    for (final option in options) {
      final qty = selectedQuantities[option.optionId] ?? 0;
      sum += option.price * qty;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final selectedOptions = options.where(
      (o) => (selectedQuantities[o.optionId] ?? 0) > 0,
    );

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
          Text('주문 요약', style: AppTextStyles.headingSmall),
          SizedBox(height: AppSpacing.md),
          if (selectedOptions.isEmpty)
            Text(
              '선택된 옵션이 없습니다.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...selectedOptions.map((option) {
              final qty = selectedQuantities[option.optionId] ?? 1;
              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        qty > 1 ? '${option.name} × $qty' : option.name,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    Text(
                      GuestMoveInFormat.formatPrice(option.price * qty),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              );
            }),
          SizedBox(height: AppSpacing.md),
          Divider(color: AppColors.border, height: 1),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('총 결제 금액', style: AppTextStyles.bodyLarge),
              Spacer(),
              Text(
                GuestMoveInFormat.formatPrice(_total),
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.primary700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
