import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors.dart';
import '../../utils/responsive_util.dart';

/// EZStay 로고 위젯
///
/// 반응형 크기 조정 및 다양한 변형을 지원합니다.
///
/// 사용 예시:
/// ```dart
/// EZStayLogo(width: 120, height: 40)
/// EZStayLogo.iconOnly(size: 32)
/// ResponsiveEZStayLogo()
/// ```
class EZStayLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final EZStayLogoVariant variant;
  final BoxFit fit;

  const EZStayLogo({
    super.key,
    this.width,
    this.height,
    this.variant = EZStayLogoVariant.primary,
    this.fit = BoxFit.contain,
  });

  /// 아이콘 전용 생성자 (정사각형)
  const EZStayLogo.iconOnly({super.key, double size = 32.0})
    : width = size,
      height = size,
      variant = EZStayLogoVariant.iconOnly,
      fit = BoxFit.contain;

  @override
  Widget build(BuildContext context) {
    // white variant는 PNG 유지 (SVG 각 path에 색상 개별 지정되어 colorFilter 불가)
    if (variant == EZStayLogoVariant.white) {
      return Image.asset(
        'assets/logos/ezstay_logo_white.png',
        width: width,
        height: height,
        fit: fit,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }

    return SvgPicture.asset(
      _getAssetPath(),
      width: width,
      height: height,
      fit: fit,
      placeholderBuilder: (_) => SizedBox(width: width, height: height),
    );
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'EZ',
          style: TextStyle(
            fontSize: (height ?? 40) * 0.5,
            fontWeight: FontWeight.bold,
            color: AppColors.primary500,
          ),
        ),
      ),
    );
  }

  String _getAssetPath() {
    switch (variant) {
      case EZStayLogoVariant.primary:
        return 'assets/logos/ezstay_logo_primary.svg';
      case EZStayLogoVariant.white:
        return 'assets/logos/ezstay_logo_white.png'; // 미사용 (위에서 처리)
      case EZStayLogoVariant.iconOnly:
        return 'assets/logos/ezstay_icon_only.svg';
    }
  }
}

/// 로고 변형 타입
enum EZStayLogoVariant {
  /// 기본 컬러 로고 (청록색)
  primary,

  /// 흰색 로고 (다크 배경용)
  white,

  /// 아이콘만 (좁은 공간용)
  iconOnly,
}

/// 반응형 로고 위젯
///
/// 화면 크기에 따라 자동으로 크기와 변형을 조정합니다.
/// - 데스크톱 (>900px): 전체 로고, 120x40
/// - 태블릿 (600-900px): 중간 크기, 80x32
/// - 모바일 (<600px): 아이콘만, 32x32
class ResponsiveEZStayLogo extends StatelessWidget {
  final EZStayLogoVariant? forcedVariant;

  const ResponsiveEZStayLogo({super.key, this.forcedVariant});

  @override
  Widget build(BuildContext context) {
    // 데스크톱: 전체 로고
    if (ResponsiveUtil.isDesktop(context)) {
      return EZStayLogo(
        width: 120,
        height: 40,
        variant: forcedVariant ?? EZStayLogoVariant.primary,
      );
    }
    // 태블릿: 중간 크기
    else if (ResponsiveUtil.isTablet(context)) {
      return EZStayLogo(
        width: 80,
        height: 32,
        variant: forcedVariant ?? EZStayLogoVariant.primary,
      );
    }
    // 모바일: 아이콘만
    else {
      return EZStayLogo.iconOnly(size: 32);
    }
  }
}

/// 로고 사용 가이드라인
class LogoGuidelines {
  LogoGuidelines._();

  // 최소 크기 (가독성 보장)
  static const double minWidth = 32.0;
  static const double minHeight = 32.0;

  // 권장 크기
  static const double appBarWidthDesktop = 120.0;
  static const double appBarHeightDesktop = 40.0;
  static const double appBarSizeMobile = 32.0;
  static const double heroSizeDesktop = 200.0;
  static const double heroSizeMobile = 150.0;
  static const double faviconSize = 32.0;

  // 여백 (로고 주변 최소 여백)
  static double getClearSpace(double logoHeight) {
    return logoHeight * 0.25; // 로고 높이의 25%
  }

  // 다크모드 감지하여 적절한 로고 변형 반환
  static EZStayLogoVariant getVariantForTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? EZStayLogoVariant.white : EZStayLogoVariant.primary;
  }
}
