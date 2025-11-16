import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// 폼 섹션 컴포넌트 (리액트 FormSection 복제)
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
    return Column(
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Section content
        child,
      ],
    );
  }
}
