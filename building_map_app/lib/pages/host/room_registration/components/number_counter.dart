import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// 숫자 증감 컴포넌트 (리액트 NumberCounter 복제)
class NumberCounter extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  const NumberCounter({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Label
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        // Counter controls
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Minus button
              _buildButton(
                icon: Icons.remove,
                enabled: value > min,
                onTap: () => onChanged(value - 1),
              ),
              // Value display
              Container(
                width: 48,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.gray300),
                    right: BorderSide(color: AppColors.gray300),
                  ),
                ),
                child: Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              // Plus button
              _buildButton(
                icon: Icons.add,
                enabled: value < max,
                onTap: () => onChanged(value + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
        ),
      ),
    );
  }
}
