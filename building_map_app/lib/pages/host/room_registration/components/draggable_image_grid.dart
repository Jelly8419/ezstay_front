import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// 드래그 가능한 이미지 그리드 (기존 방식 적용)
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
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: images.asMap().entries.map((entry) {
        final index = entry.key;
        final imagePath = entry.value;
        return _buildDraggableImageCard(imagePath, index);
      }).toList(),
    );
  }

  Widget _buildDraggableImageCard(String imagePath, int index) {
    return Draggable<int>(
      data: index,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 150, // 기존의 약 1/2 크기
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gray300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? Image.network(
                    imagePath,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(imagePath),
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
      ),
      childWhenDragging: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gray300),
          color: AppColors.gray200,
        ),
        child: const Icon(
          Icons.image_outlined,
          color: Colors.grey,
          size: 40,
        ),
      ),
      child: DragTarget<int>(
        onAcceptWithDetails: (details) {
          final oldIndex = details.data;
          final newIndex = index;
          if (oldIndex != newIndex) {
            final newImages = List<String>.from(images);
            final item = newImages.removeAt(oldIndex);
            newImages.insert(newIndex, item);
            onReorder(newImages);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: candidateData.isNotEmpty
                    ? AppColors.primary600
                    : AppColors.gray300,
                width: candidateData.isNotEmpty ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb
                      ? Image.network(
                          imagePath,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(imagePath),
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                ),
                // 드래그 핸들 영역 (웹에서도 작동하도록)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
                // Drag indicator (좌측 상단)
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
      ),
    );
  }
}
