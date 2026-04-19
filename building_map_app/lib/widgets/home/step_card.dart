import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// STEP 가이드 카드.
///
/// 상단에 40×40 아이콘 박스 + 우측 STEP 숫자, 하단에 제목/설명.
/// [variant]에 따라 색상 테마가 바뀐다 (guest=primary, host=green).
///
/// 사용 예시:
/// ```dart
/// StepCard(
///   icon: LucideIcons.search,
///   stepNumber: '01',
///   title: '방 검색',
///   description: '임대기간, 임대료, 지역 등 원하는 방을 검색',
///   variant: StepCardVariant.guest,
/// )
/// ```
class StepCard extends StatelessWidget {
  const StepCard({
    super.key,
    required this.icon,
    required this.stepNumber,
    required this.title,
    required this.description,
    this.variant = StepCardVariant.guest,
  });

  final IconData icon;

  /// "01", "02" 형태 권장. 자유 문자열 허용.
  final String stepNumber;
  final String title;
  final String description;
  final StepCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final (iconBgColor, iconColor, accentColor) = switch (variant) {
      StepCardVariant.guest => (
          AppColors.primary50,
          AppColors.primary600,
          AppColors.primary500,
        ),
      StepCardVariant.host => (
          AppColors.green100,
          AppColors.green600,
          AppColors.green500,
        ),
    };

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.neutral200, width: 0.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              Text(
                stepNumber,
                style: AppTextStyles.headingSmall.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// STEP 카드 색상 variant.
enum StepCardVariant {
  /// 파란 계열 (임차인 동선)
  guest,

  /// 초록 계열 (임대인 동선)
  host,
}
