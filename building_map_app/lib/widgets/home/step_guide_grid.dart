import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import 'step_card.dart';

/// 여러 [StepCard]를 반응형 그리드로 배치한다.
///
/// 핵심: **`GridView` 사용 금지**. `LayoutBuilder` + `Wrap` + 고정 카드 너비
/// 조합으로 구현하여 섹션 간 카드 크기가 일관되도록 한다.
///
/// 사용 예시:
/// ```dart
/// StepGuideGrid(
///   steps: [
///     StepCard(icon: LucideIcons.search, stepNumber: '01', ...),
///     StepCard(icon: LucideIcons.fileText, stepNumber: '02', ...),
///     StepCard(icon: LucideIcons.creditCard, stepNumber: '03', ...),
///     StepCard(icon: LucideIcons.home, stepNumber: '04', ...),
///   ],
/// )
/// ```
class StepGuideGrid extends StatelessWidget {
  const StepGuideGrid({
    super.key,
    required this.steps,
    this.mobileCardWidth = 140,
    this.desktopCardWidth = 240,
    this.spacing = AppSpacing.md,
  });

  /// 개별 [StepCard] 리스트.
  final List<StepCard> steps;

  /// 모바일(<600px)에서 각 카드의 고정 너비.
  final double mobileCardWidth;

  /// 태블릿 이상에서 각 카드의 고정 너비.
  final double desktopCardWidth;

  /// 카드 간 가로·세로 간격.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final cardWidth = isMobile ? mobileCardWidth : desktopCardWidth;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 가용 너비에 카드가 몇 개 들어갈 수 있는지 계산.
        // 최소 1열은 보장.
        final available = constraints.maxWidth;
        final approxPerRow =
            ((available + spacing) / (cardWidth + spacing)).floor().clamp(1, steps.length);
        final effectiveWidth =
            approxPerRow == 1 ? available : cardWidth.toDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          alignment: WrapAlignment.center,
          children: [
            for (final step in steps)
              SizedBox(
                width: effectiveWidth,
                child: step,
              ),
          ],
        );
      },
    );
  }
}
