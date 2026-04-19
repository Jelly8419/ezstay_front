import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

/// 홈화면 섹션 공통 래퍼.
///
/// 핵심: **배경은 풀너비(`double.infinity`)로 채우고 내부 자식만 [maxWidth]로
/// 중앙 정렬**한다. 1920px 등 초광폭 화면에서 배경 그라데이션이 좁게 끝나지
/// 않도록 설계.
///
/// 사용 예시:
/// ```dart
/// HomeSection(
///   backgroundColor: AppColors.background,
///   verticalScale: VerticalPaddingScale.lg,
///   child: Column(
///     children: [
///       SectionHeader(title: '임차인 이용 방법', subtitle: '...'),
///       StepGuideGrid(steps: [...]),
///     ],
///   ),
/// )
/// ```
class HomeSection extends StatelessWidget {
  const HomeSection({
    super.key,
    required this.child,
    this.backgroundColor,
    this.backgroundGradient,
    this.maxWidth = AppSizes.contentMaxWidthDefault,
    this.padding,
    this.verticalScale = VerticalPaddingScale.md,
  });

  final Widget child;

  /// 섹션 배경색. [backgroundGradient]와 동시 지정 시 gradient 우선.
  final Color? backgroundColor;

  /// 섹션 배경 그라데이션.
  final Gradient? backgroundGradient;

  /// 내부 컨텐츠 최대 너비 (배경은 항상 풀너비).
  final double maxWidth;

  /// 내부 컨텐츠 패딩. null이면 반응형 기본값 + [verticalScale] 기준 세로 패딩 적용.
  final EdgeInsets? padding;

  /// 세로 패딩 스케일 (sm/md/lg).
  final VerticalPaddingScale verticalScale;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? _defaultPadding(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundGradient == null ? backgroundColor : null,
        gradient: backgroundGradient,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: effectivePadding,
            child: child,
          ),
        ),
      ),
    );
  }

  EdgeInsets _defaultPadding(BuildContext context) {
    final horizontal = AppBreakpoints.isMobile(context)
        ? AppSpacing.md
        : AppBreakpoints.isTablet(context)
            ? AppSpacing.lg
            : AppSpacing.xl;

    final vertical = switch (verticalScale) {
      VerticalPaddingScale.sm => AppSpacing.lg,
      VerticalPaddingScale.md => AppSpacing.xl * 2,
      VerticalPaddingScale.lg => AppSpacing.xl * 3,
    };

    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }
}

/// 섹션 세로 패딩 규모.
enum VerticalPaddingScale {
  /// 24px — 타이트한 띠 섹션 (지역 안내 등)
  sm,

  /// 64px — 일반 섹션
  md,

  /// 96px — CTA처럼 강조되는 섹션
  lg,
}
