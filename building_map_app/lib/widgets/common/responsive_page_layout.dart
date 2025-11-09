import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../utils/responsive_util.dart';
import 'ezstay_logo.dart';

/// 반응형 페이지 레이아웃
///
/// 모든 페이지에서 일관된 최대 너비와 패딩을 제공합니다.
///
/// 사용 예시:
/// ```dart
/// Scaffold(
///   appBar: AppBar(title: Text('페이지')),
///   body: ResponsivePageLayout(
///     child: Column(
///       children: [
///         Text('컨텐츠'),
///       ],
///     ),
///   ),
/// )
/// ```
class ResponsivePageLayout extends StatelessWidget {
  /// 페이지 컨텐츠
  final Widget child;

  /// 최대 너비 (기본값: AppConstants.maxContentWidth = 1200)
  final double? maxWidth;

  /// 좌우 패딩 활성화 여부 (기본값: true)
  final bool usePadding;

  /// 커스텀 패딩 (기본값: null, null이면 ResponsiveUtil.getPadding 사용)
  final EdgeInsets? padding;

  /// 스크롤 가능 여부 (기본값: true)
  final bool scrollable;

  /// 배경색 (기본값: null, null이면 Scaffold의 배경색 사용)
  final Color? backgroundColor;

  /// 카드 스타일 적용 여부 (기본값: false)
  /// true로 설정하면 떠있는 느낌의 카드 스타일 적용
  final bool useCardStyle;

  const ResponsivePageLayout({
    super.key,
    required this.child,
    this.maxWidth,
    this.usePadding = true,
    this.padding,
    this.scrollable = true,
    this.backgroundColor,
    this.useCardStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // 카드 스타일 적용
    if (useCardStyle) {
      content = Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          child: content,
        ),
      );
    }

    // 패딩 적용
    if (usePadding) {
      final effectivePadding = padding ??
          EdgeInsets.all(ResponsiveUtil.getPadding(context));
      content = Padding(
        padding: effectivePadding,
        child: content,
      );
    }

    // 스크롤 가능하게 만들기
    if (scrollable) {
      content = SingleChildScrollView(
        child: content,
      );
    }

    // 최대 너비 제한
    content = MaxWidthContainer(
      maxWidth: maxWidth ?? AppConstants.maxContentWidth,
      child: content,
    );

    // 배경색 적용
    if (backgroundColor != null) {
      content = Container(
        color: backgroundColor,
        child: content,
      );
    }

    return content;
  }
}

/// AppBar가 있는 반응형 페이지 레이아웃
///
/// Scaffold + AppBar + ResponsivePageLayout을 한 번에 제공합니다.
///
/// 사용 예시:
/// ```dart
/// ResponsiveScaffold(
///   title: '페이지 제목',
///   body: Column(
///     children: [
///       Text('컨텐츠'),
///     ],
///   ),
/// )
/// ```
class ResponsiveScaffold extends StatelessWidget {
  /// 페이지 제목
  final String title;

  /// 페이지 컨텐츠
  final Widget body;

  /// 최대 너비
  final double? maxWidth;

  /// 좌우 패딩 활성화 여부
  final bool usePadding;

  /// 커스텀 패딩
  final EdgeInsets? padding;

  /// 스크롤 가능 여부
  final bool scrollable;

  /// AppBar 액션 버튼들
  final List<Widget>? actions;

  /// AppBar leading 위젯
  final Widget? leading;

  /// Floating Action Button
  final Widget? floatingActionButton;

  /// BottomNavigationBar
  final Widget? bottomNavigationBar;

  /// Drawer
  final Widget? drawer;

  /// 배경색
  final Color? backgroundColor;

  /// 카드 스타일 적용 여부
  final bool useCardStyle;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.maxWidth,
    this.usePadding = true,
    this.padding,
    this.scrollable = true,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.backgroundColor,
    this.useCardStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const ResponsiveEZStayLogo(),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        actions: actions,
        leading: leading,
      ),
      body: ResponsivePageLayout(
        maxWidth: maxWidth,
        usePadding: usePadding,
        padding: padding,
        scrollable: scrollable,
        backgroundColor: backgroundColor,
        useCardStyle: useCardStyle,
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
    );
  }
}

/// 최대 너비 제한 컨테이너
class MaxWidthContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const MaxWidthContainer({
    super.key,
    required this.child,
    this.maxWidth = 1200,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
