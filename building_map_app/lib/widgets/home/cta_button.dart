import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// 홈 CTA 섹션에서 사용하는 큰 버튼.
///
/// [variant]로 색 반전 (primary 배경 화면에서는 white, 밝은 배경에서는 primary).
///
/// 사용 예시:
/// ```dart
/// CTAButton(
///   text: '방 검색하기',
///   trailingIcon: LucideIcons.arrowRight,
///   variant: CTAButtonVariant.onPrimary,
///   onPressed: () => context.go('/map'),
/// )
/// ```
class CTAButton extends StatelessWidget {
  const CTAButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.trailingIcon = LucideIcons.arrowRight,
    this.variant = CTAButtonVariant.onPrimary,
    this.fullWidth = false,
    this.height = 56,
    this.fixedWidth = 280,
  });

  final String text;
  final VoidCallback onPressed;
  final IconData? trailingIcon;
  final CTAButtonVariant variant;

  /// true면 가로 100%, false면 [fixedWidth] 고정.
  final bool fullWidth;
  final double height;
  final double fixedWidth;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      // primary 배경 위에 얹는 흰 버튼
      CTAButtonVariant.onPrimary => (Colors.white, AppColors.primary700),
      // 흰/뉴트럴 배경 위에 얹는 primary 버튼
      CTAButtonVariant.filled => (AppColors.primary600, Colors.white),
    };

    final isMobile = AppBreakpoints.isMobile(context);
    final width = fullWidth || isMobile ? double.infinity : fixedWidth;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: AppTextStyles.labelLarge.copyWith(
                color: fg,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (trailingIcon != null) ...[
              SizedBox(width: AppSpacing.sm),
              Icon(trailingIcon, size: 20, color: fg),
            ],
          ],
        ),
      ),
    );
  }
}

enum CTAButtonVariant {
  /// primary600 배경 섹션에서 사용: 흰 버튼
  onPrimary,

  /// 뉴트럴 배경에서 사용: primary 버튼
  filled,
}
