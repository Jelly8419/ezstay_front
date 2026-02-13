import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../utils/responsive_util.dart';

/// 공통 버튼 위젯
///
/// React UI 일치:
/// - 모바일: px-4 py-2 = 16px 8px (높이 ~36px)
/// - 데스크톱: px-6 py-2.5 = 24px 10px (높이 ~42px)
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Widget? icon;
  final double? width;
  final double? height; // null이면 반응형 높이 사용
  final bool useResponsiveHeight; // true: 36px/42px, false: 고정 높이

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.width,
    this.height, // 기본값 제거 - null이면 반응형
    this.useResponsiveHeight = true, // 기본값: React UI 일치
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? AppColors.primary;
    final effectiveForegroundColor = foregroundColor ?? Colors.white;

    // 반응형 높이 계산: React UI 일치 (모바일 36px, 데스크톱 42px)
    final effectiveHeight = height ??
      (useResponsiveHeight
        ? (ResponsiveUtil.isDesktop(context) ? 42.0 : 36.0)
        : 50.0); // 기본값 fallback

    if (isOutlined) {
      return SizedBox(
        width: width,
        height: effectiveHeight,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: effectiveBackgroundColor,
            side: BorderSide(color: effectiveBackgroundColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            ),
          ),
          child: _buildContent(effectiveBackgroundColor),
        ),
      );
    }

    return Container(
      width: width,
      height: effectiveHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: (isLoading || onPressed == null)
            ? null
            : [
                BoxShadow(
                  color: effectiveBackgroundColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          foregroundColor: effectiveForegroundColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          ),
        ),
        child: _buildContent(effectiveForegroundColor),
      ),
    );
  }

  Widget _buildContent(Color textColor) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.button.copyWith(color: textColor),
          ),
        ],
      );
    }

    return Text(
      text,
      style: AppTextStyles.button.copyWith(color: textColor),
    );
  }
}
