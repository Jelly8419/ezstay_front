import 'package:flutter/material.dart';
import '../../utils/responsive_util.dart';

/// 콘텐츠 최대 너비 1200px 제한 + 반응형 좌우 패딩 + 중앙 정렬
///
/// 배경은 부모 Container에서 풀와이드로 처리하고,
/// 콘텐츠 영역만 이 위젯으로 감싼다.
class ContentContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ContentContainer({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtil.isMobile(context)
        ? 16.0
        : ResponsiveUtil.isTablet(context)
            ? 24.0
            : 32.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: child,
        ),
      ),
    );
  }
}
