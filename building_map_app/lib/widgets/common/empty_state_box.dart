import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';

/// 범용 빈 상태 박스 위젯
///
/// 목록이 비어있을 때 아이콘 + 메시지를 표시합니다.
class EmptyStateBox extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyStateBox({
    super.key,
    this.icon = Icons.home_outlined,
    this.message = '내역이 없습니다.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
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
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
