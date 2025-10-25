import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

/// 웹 전용 레이아웃 시스템
///
/// 플러터 웹에서 반응형 디자인을 쉽게 구현할 수 있습니다.
///
/// 사용 예시:
/// ```dart
/// ResponsiveLayout(
///   mobile: MobileHomePage(),
///   tablet: TabletHomePage(),
///   desktop: DesktopHomePage(),
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop (1280px 이상)
        if (constraints.maxWidth >= AppBreakpoints.desktop) {
          return desktop ?? tablet ?? mobile;
        }
        // Tablet (600px ~ 1279px)
        else if (constraints.maxWidth >= AppBreakpoints.mobile) {
          return tablet ?? mobile;
        }
        // Mobile (600px 미만)
        else {
          return mobile;
        }
      },
    );
  }
}

/// 반응형 그리드 레이아웃
///
/// 화면 크기에 따라 자동으로 컬럼 수가 조정됩니다.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = AppSpacing.md,
    this.runSpacing,
  });

  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double? runSpacing;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int columns;

    if (screenWidth >= AppBreakpoints.desktop) {
      columns = desktopColumns;
    } else if (screenWidth >= AppBreakpoints.mobile) {
      columns = tabletColumns;
    } else {
      columns = mobileColumns;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing ?? spacing,
        childAspectRatio: 0.75, // 카드 비율 조정 가능
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// 웹 컨테이너 - 최대 너비 제한
///
/// 데스크톱에서 콘텐츠가 너무 넓어지는 것을 방지합니다.
class WebContainer extends StatelessWidget {
  const WebContainer({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: padding ?? AppSpacing.pagePadding,
        child: child,
      ),
    );
  }
}

/// 반응형 패딩
class ResponsivePadding extends StatelessWidget {
  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobilePadding = AppSpacing.md,
    this.tabletPadding = AppSpacing.lg,
    this.desktopPadding = AppSpacing.xl,
  });

  final Widget child;
  final double mobilePadding;
  final double tabletPadding;
  final double desktopPadding;

  @override
  Widget build(BuildContext context) {
    final padding = AppBreakpoints.getResponsivePadding(context);

    return Padding(
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}

/// 사이드바 레이아웃 (데스크톱 전용)
///
/// 왼쪽: 사이드바 (필터 등)
/// 오른쪽: 메인 콘텐츠
class SidebarLayout extends StatelessWidget {
  const SidebarLayout({
    super.key,
    required this.sidebar,
    required this.content,
    this.sidebarWidth = 280,
    this.showSidebar = true,
  });

  final Widget sidebar;
  final Widget content;
  final double sidebarWidth;
  final bool showSidebar;

  @override
  Widget build(BuildContext context) {
    if (!showSidebar || AppBreakpoints.isMobile(context)) {
      return content;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 사이드바
        SizedBox(
          width: sidebarWidth,
          child: sidebar,
        ),
        SizedBox(width: AppSpacing.lg),

        // 메인 콘텐츠
        Expanded(
          child: content,
        ),
      ],
    );
  }
}

/// 반응형 텍스트 크기
class ResponsiveText extends StatelessWidget {
  const ResponsiveText(
    this.text, {
    super.key,
    required this.style,
    this.scaleFactor = 1.0,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final double scaleFactor;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double scale = scaleFactor;

    // 모바일에서는 약간 작게
    if (screenWidth < AppBreakpoints.mobile) {
      scale *= 0.9;
    }
    // 데스크톱에서는 약간 크게
    else if (screenWidth >= AppBreakpoints.desktop) {
      scale *= 1.1;
    }

    return Text(
      text,
      style: style.copyWith(fontSize: style.fontSize! * scale),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}

/// 웹 전용 호버 효과
class HoverEffect extends StatefulWidget {
  const HoverEffect({
    super.key,
    required this.child,
    this.onHover,
    this.scale = 1.02,
    this.elevation = 8,
  });

  final Widget child;
  final VoidCallback? onHover;
  final double scale;
  final double elevation;

  @override
  State<HoverEffect> createState() => _HoverEffectState();
}

class _HoverEffectState extends State<HoverEffect> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHover?.call();
      },
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? widget.scale : 1.0,
        duration: AppDurations.fast,
        curve: AppCurves.smooth,
        child: widget.child,
      ),
    );
  }
}

/// 데스크톱 네비게이션 바 (상단 고정)
class DesktopNavBar extends StatelessWidget {
  const DesktopNavBar({
    super.key,
    required this.logo,
    this.actions = const [],
    this.backgroundColor,
  });

  final Widget logo;
  final List<Widget> actions;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        boxShadow: AppShadows.appBar,
      ),
      child: WebContainer(
        child: Row(
          children: [
            // 로고
            logo,
            const Spacer(),

            // 액션들
            ...actions.map((action) => Padding(
              padding: EdgeInsets.only(left: AppSpacing.lg),
              child: action,
            )),
          ],
        ),
      ),
    );
  }
}

/// 푸터 (데스크톱)
class WebFooter extends StatelessWidget {
  const WebFooter({
    super.key,
    required this.children,
    this.backgroundColor,
  });

  final List<Widget> children;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.xxl,
        horizontal: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFF5F5F5),
      ),
      child: WebContainer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children.map((child) {
            return Expanded(child: child);
          }).toList(),
        ),
      ),
    );
  }
}

/// 스크롤 탑 버튼 (웹 전용)
class ScrollToTopButton extends StatefulWidget {
  const ScrollToTopButton({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  State<ScrollToTopButton> createState() => _ScrollToTopButtonState();
}

class _ScrollToTopButtonState extends State<ScrollToTopButton> {
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  void _scrollListener() {
    if (widget.scrollController.offset > 300 && !_showButton) {
      setState(() => _showButton = true);
    } else if (widget.scrollController.offset <= 300 && _showButton) {
      setState(() => _showButton = false);
    }
  }

  void _scrollToTop() {
    widget.scrollController.animateTo(
      0,
      duration: AppDurations.slow,
      curve: AppCurves.smooth,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_showButton) return const SizedBox.shrink();

    return Positioned(
      right: AppSpacing.xl,
      bottom: AppSpacing.xl,
      child: FloatingActionButton(
        onPressed: _scrollToTop,
        child: const Icon(Icons.arrow_upward),
      ),
    );
  }
}
