import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../../../../core/theme/app_colors.dart';

/// 드래그 가능한 이미지 그리드 (가로 배치, 정사각형 크기)
class DraggableImageGrid extends StatelessWidget {
  final List<String> images;
  final ValueChanged<List<String>> onReorder;
  final ValueChanged<int> onRemove;

  const DraggableImageGrid({
    super.key,
    required this.images,
    required this.onReorder,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableGridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 한 줄에 4개씩 배치
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0, // 정사각형 비율
      ),
      onReorder: (oldIndex, newIndex) {
        final newImages = List<String>.from(images);
        final item = newImages.removeAt(oldIndex);
        newImages.insert(newIndex, item);
        onReorder(newImages);
      },
      itemBuilder: (context, index) {
        return Container(
          key: ValueKey('image_$index'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gray300),
            image: DecorationImage(
              image: NetworkImage(images[index]),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Drag handle (좌측 상단)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.drag_indicator,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              // Main badge (첫 번째 사진만)
              if (index == 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary600,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '대표',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              // Remove button (우측 하단)
              Positioned(
                bottom: 8,
                right: 8,
                child: InkWell(
                  onTap: () => onRemove(index),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.error600,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
