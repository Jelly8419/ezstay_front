import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 폼 섹션 컴포넌트 (카드 스타일의 섹션)
class FormSection extends StatelessWidget {
  final IconData? icon;
  final String title;
  final Widget child;

  const FormSection({
    super.key,
    this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: AppColors.gray200),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 24,
                  color: AppColors.primary600,
                ),
                const SizedBox(width: 12),
              ],
              Text(
                title,
                style: AppTextStyles.headingSmall.copyWith(
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Section content
          child,
        ],
      ),
    );
  }
}
