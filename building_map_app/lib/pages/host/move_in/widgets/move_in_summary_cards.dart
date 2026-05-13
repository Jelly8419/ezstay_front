import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/move_in/move_in.dart';
import '../../../../utils/responsive_util.dart';

/// 입주 준비 서비스 홈 상단 요약 카드 (이미지 ① 상단)
///
/// 3개 카드를 토글식 필터로 사용. 셋 중 하나는 항상 선택된 상태.
enum MoveInSummaryFilter { all, cleaningPending, cleaningPaid }

class MoveInSummaryCards extends StatelessWidget {
  final MoveInCaseCounts counts;
  final MoveInSummaryFilter selected;
  final ValueChanged<MoveInSummaryFilter> onSelected;

  const MoveInSummaryCards({
    super.key,
    required this.counts,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <_SummaryCardData>[
      _SummaryCardData(
        filter: MoveInSummaryFilter.all,
        label: '총 등록 건수',
        value: counts.total,
        valueColor: AppColors.textPrimary,
      ),
      _SummaryCardData(
        filter: MoveInSummaryFilter.cleaningPending,
        label: '청소 결제 대기',
        value: counts.cleaningPending,
        valueColor: AppColors.warning700,
      ),
      _SummaryCardData(
        filter: MoveInSummaryFilter.cleaningPaid,
        label: '청소 결제 완료',
        value: counts.cleaningPaid,
        valueColor: AppColors.success600,
      ),
    ];

    final isMobile = ResponsiveUtil.isMobile(context);
    if (isMobile) {
      return SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: cards.length,
          separatorBuilder: (_, __) => SizedBox(width: AppSpacing.sm),
          itemBuilder: (_, i) => SizedBox(
            width: 160,
            child: _SummaryCard(
              data: cards[i],
              isSelected: cards[i].filter == selected,
              onTap: () => onSelected(cards[i].filter),
            ),
          ),
        ),
      );
    }
    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) SizedBox(width: AppSpacing.md),
          Expanded(
            child: _SummaryCard(
              data: cards[i],
              isSelected: cards[i].filter == selected,
              onTap: () => onSelected(cards[i].filter),
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryCardData {
  final MoveInSummaryFilter filter;
  final String label;
  final int value;
  final Color valueColor;
  const _SummaryCardData({
    required this.filter,
    required this.label,
    required this.value,
    required this.valueColor,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryCardData data;
  final bool isSelected;
  final VoidCallback onTap;
  const _SummaryCard({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusMd,
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary50 : AppColors.surface,
            borderRadius: AppRadius.radiusMd,
            border: Border.all(
              color: isSelected ? AppColors.primary500 : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected
                      ? AppColors.primary700
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${data.value}',
                    style: AppTextStyles.displaySmall.copyWith(
                      color: data.valueColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 2),
                  Text(
                    '건',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
