import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// 옵션 토글 버튼 (리액트 OptionToggle 복제)
class OptionToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onToggle;

  const OptionToggle({
    super.key,
    required this.label,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary50 : Colors.white,
          border: Border.all(
            color: selected ? AppColors.primary600 : AppColors.gray300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary900 : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
