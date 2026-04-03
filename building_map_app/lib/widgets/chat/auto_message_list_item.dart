import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/auto_message_template.dart';

/// 자동메시지 관리 페이지 — 템플릿 카드 (목록 아이템)
class AutoMessageListItem extends StatelessWidget {
  final AutoMessageTemplate template;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AutoMessageListItem({
    super.key,
    required this.template,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          template.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.neutral900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _StatusBadge(isActive: template.isActive),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '발송 시점: ${template.trigger.displayText}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.neutral600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '적용된 방: ${template.appliedProperties.length}개',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.neutral600),
                    ),
                  ],
                ),
              ),
              Switch(
                value: template.isActive,
                onChanged: (_) => onToggle(),
                activeTrackColor: AppColors.blue600,
                inactiveTrackColor: AppColors.gray200,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              template.content,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.neutral700),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ActionButton(
                label: '수정',
                icon: Icons.edit_outlined,
                bgColor: AppColors.neutral100,
                textColor: AppColors.neutral700,
                onTap: onEdit,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                label: '삭제',
                icon: Icons.delete_outline,
                bgColor: AppColors.error50,
                textColor: AppColors.error600,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.green100 : AppColors.neutral100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'ON' : 'OFF',
        style: AppTextStyles.caption.copyWith(
          color: isActive ? AppColors.success700 : AppColors.neutral600,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 8),
            Text(label,
                style: AppTextStyles.bodySmall.copyWith(color: textColor)),
          ],
        ),
      ),
    );
  }
}
