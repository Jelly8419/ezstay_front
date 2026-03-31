import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// 모바일 카드 슬라이드 인디케이터 (드래그/탭으로 페이지 이동)
class DraggableScrollIndicator extends StatelessWidget {
  final int totalItems;
  final int currentIndex;
  final PageController pageController;

  const DraggableScrollIndicator({
    super.key,
    required this.totalItems,
    required this.currentIndex,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space24,
        vertical: AppSpacing.space12,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final handleWidth = totalWidth / totalItems;
          final currentPosition = currentIndex * handleWidth;

          return GestureDetector(
            onHorizontalDragUpdate: (details) {
              final dragPosition = details.localPosition.dx.clamp(
                0.0,
                totalWidth,
              );
              final targetIndex = (dragPosition / handleWidth)
                  .floor()
                  .clamp(0, totalItems - 1);

              if (targetIndex != currentIndex) {
                pageController.animateToPage(
                  targetIndex,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
              }
            },
            onTapDown: (details) {
              final tapPosition = details.localPosition.dx.clamp(
                0.0,
                totalWidth,
              );
              final targetIndex = (tapPosition / handleWidth)
                  .floor()
                  .clamp(0, totalItems - 1);

              pageController.animateToPage(
                targetIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.neutral200,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    left: currentPosition,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: handleWidth,
                      decoration: BoxDecoration(
                        color: AppColors.primary500,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary500.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${currentIndex + 1}/$totalItems',
                          style: const TextStyle(
                            color: AppColors.neutral0,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
