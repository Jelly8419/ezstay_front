import 'package:flutter/material.dart';

/// 반응형 유틸리티
class ResponsiveUtil {
  /// 화면 크기 분류
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

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
    if (isDesktop(context)) return 1200;
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
