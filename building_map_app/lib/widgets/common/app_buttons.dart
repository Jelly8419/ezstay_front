import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

/// Primary Button - 주요 액션 버튼
///
/// 사용 예시:
/// ```dart
/// AppPrimaryButton(
///   text: '검색하기',
///   onPressed: () {
///     // 검색 로직
///   },
/// )
/// ```
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.fullWidth = true,
    this.height = AppSizes.buttonHeightMd,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final bool fullWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = !isLoading && !isDisabled && onPressed != null;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isInteractive ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isInteractive ? AppColors.blue500 : AppColors.neutral300,
          foregroundColor: AppColors.neutral0,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.neutral0),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AppSizes.iconSm),
                    SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    text,
                    style: AppTextStyles.buttonText.copyWith(
                      color: AppColors.neutral0,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Secondary Button - 보조 액션 버튼
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.fullWidth = true,
    this.height = AppSizes.buttonHeightMd,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final bool fullWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = !isLoading && !isDisabled && onPressed != null;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: isInteractive ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.neutral0,
          foregroundColor: isInteractive
              ? AppColors.neutral700
              : AppColors.neutral400,
          side: BorderSide(
            color: isInteractive ? AppColors.neutral300 : AppColors.neutral200,
            width: 1,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.neutral700,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AppSizes.iconSm),
                    SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    text,
                    style: AppTextStyles.buttonText.copyWith(
                      color: isInteractive
                          ? AppColors.neutral700
                          : AppColors.neutral400,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Text Button - 텍스트만 있는 버튼
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isDisabled = false,
    this.icon,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = !isDisabled && onPressed != null;

    return TextButton(
      onPressed: isInteractive ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: isInteractive
            ? AppColors.primary600
            : AppColors.neutral400,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSizes.iconSm),
            SizedBox(width: AppSpacing.xs),
          ],
          Text(
            text,
            style: AppTextStyles.labelMedium.copyWith(
              color: isInteractive
                  ? AppColors.primary600
                  : AppColors.neutral400,
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon Button - 아이콘 버튼
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = AppSizes.iconMd,
    this.color,
    this.backgroundColor,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      icon: Icon(icon),
      iconSize: size,
      color: color ?? AppColors.neutral700,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        minimumSize: Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
