import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/move_in/move_in.dart';
import '../../../../utils/responsive_util.dart';

/// 입주 준비 서비스 홈 상단 요약 카드 4개 (이미지 ① 상단)
///
/// - 데스크탑/태블릿: 가로 4개 균등 분할
/// - 모바일: 가로 스크롤 가능한 한 줄
class MoveInSummaryCards extends StatelessWidget {
  final MoveInCaseCounts counts;

  const MoveInSummaryCards({super.key, required this.counts});

  @override
  Widget build(BuildContext context) {
    final cards = <_SummaryCardData>[
      _SummaryCardData(
        label: '총 등록 건수',
        value: counts.total,
        valueColor: AppColors.textPrimary,
      ),
      _SummaryCardData(
        label: '청소 결제 대기',
        value: counts.cleaningPending,
        valueColor: AppColors.warning700,
      ),
      _SummaryCardData(
        label: '임차인 결제 요청 대기',
        value: counts.paymentRequestPending,
        valueColor: AppColors.primary600,
      ),
      _SummaryCardData(
        label: '진행 중',
        value: counts.inProgress,
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
          itemBuilder: (_, i) => SizedBox(width: 160, child: _SummaryCard(data: cards[i])),
        ),
      );
    }
    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) SizedBox(width: AppSpacing.md),
          Expanded(child: _SummaryCard(data: cards[i])),
        ],
      ],
    );
  }
}

class _SummaryCardData {
  final String label;
  final int value;
  final Color valueColor;
  const _SummaryCardData({
    required this.label,
    required this.value,
    required this.valueColor,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryCardData data;
  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            data.label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
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
    );
  }
}
