import 'package:flutter/material.dart';
import '../core/theme/app_spacing.dart';

/// 반응형 유틸리티
///
/// **SSoT**: 내부적으로 [AppBreakpoints]에 위임한다.
/// - mobile: < 600px
/// - tablet: 600px ~ 1279px
/// - desktop: >= 1280px
///
/// ⚠️ Phase 2 변경: 이전에는 desktop 기준이 1024였으나, [AppBreakpoints]와
/// 통일하기 위해 1280으로 상향. 1024~1279px 구간의 화면은 이제 tablet으로
/// 분기된다. 이 변경으로 레이아웃이 깨지는 페이지가 있으면 개별 수정 필요.
///
/// 신규 코드는 [AppBreakpoints]를 직접 쓰는 것을 권장.
class ResponsiveUtil {
  /// 화면 크기 분류
  static bool isMobile(BuildContext context) => AppBreakpoints.isMobile(context);

  static bool isTablet(BuildContext context) => AppBreakpoints.isTablet(context);

  static bool isDesktop(BuildContext context) => AppBreakpoints.isDesktop(context);

  /// 반응형 값 반환
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// 그리드 컬럼 개수
  static int getGridCrossAxisCount(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 3;
    return 2;
  }

  /// 최대 컨텐츠 너비
  static double getMaxContentWidth(BuildContext context) {
    if (isDesktop(context)) return AppSizes.contentMaxWidthDefault;
    if (isTablet(context)) return 900;
    return MediaQuery.of(context).size.width;
  }

  /// 패딩 값
  static double getPadding(BuildContext context) {
    if (isDesktop(context)) return 24;
    if (isTablet(context)) return 20;
    return 16;
  }

  /// 폰트 크기 스케일
  static double getFontScale(BuildContext context) {
    if (isDesktop(context)) return 1.1;
    if (isTablet(context)) return 1.05;
    return 1.0;
  }
}

/// 반응형 레이아웃 위젯
///
/// ⚠️ Phase 2: [features/web/web_layout.dart]의 [ResponsiveLayout]과 중복 정의.
/// 신규 코드는 그쪽을 사용할 것. 이 정의는 하위 호환 유지용으로만 보존.
@Deprecated('Use ResponsiveLayout from lib/features/web/web_layout.dart instead')
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtil.isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (ResponsiveUtil.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

/// 중앙 정렬된 최대 너비 컨테이너
class MaxWidthContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const MaxWidthContainer({
    super.key,
    required this.child,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? ResponsiveUtil.getMaxContentWidth(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: child,
      ),
    );
  }
}
