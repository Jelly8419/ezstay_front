import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 계약 목록 탭 메뉴 (진행중 / 지난 계약 / 취소)
class ContractTabMenu extends StatelessWidget {
  final String selectedTab;
  final ValueChanged<String> onTabChanged;
  final int Function(String tab) getTabCount;

  const ContractTabMenu({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    required this.getTabCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabButton('in_progress', '진행중', getTabCount('in_progress')),
          const SizedBox(width: 8),
          _buildTabButton('completed', '지난 계약', getTabCount('completed')),
          const SizedBox(width: 8),
          _buildTabButton('cancelled', '취소', getTabCount('cancelled')),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String label, int count) {
    final isSelected = selectedTab == tab;
    return Expanded(
      child: Material(
        color: isSelected ? AppColors.primary600 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onTabChanged(tab),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '($count)',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.normal,
                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
