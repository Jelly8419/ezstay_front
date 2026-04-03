import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/auto_message_template.dart';

/// 자동 메시지 폼 — 사용할 방 선택 섹션
class AutoMessagePropertySelector extends StatelessWidget {
  final List<PropertyInfo> properties;
  final List<String> selectedProperties;
  final ValueChanged<String> onToggleProperty;
  final VoidCallback onToggleAll;

  const AutoMessagePropertySelector({
    super.key,
    required this.properties,
    required this.selectedProperties,
    required this.onToggleProperty,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: AppColors.neutral600),
            const SizedBox(width: 8),
            Text('사용할 방',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.neutral900)),
          ],
        ),
        const SizedBox(height: 12),

        InkWell(
          onTap: onToggleAll,
          child: Text(
            selectedProperties.length == properties.length ? '전체 해제' : '전체 선택',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.blue600),
          ),
        ),
        const SizedBox(height: 12),

        Container(
          constraints: const BoxConstraints(maxHeight: 192),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: properties.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final property = properties[index];
              final isSelected = selectedProperties.contains(property.id);

              return InkWell(
                onTap: () => onToggleProperty(property.id),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (_) => onToggleProperty(property.id),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(property.name,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.neutral700)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        Text('선택된 방: ${selectedProperties.length}개',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500)),
      ],
    );
  }
}
