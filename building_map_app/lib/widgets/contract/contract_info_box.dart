import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// 계약 목록 상단 안내사항 박스 (파란색)
class ContractInfoBox extends StatelessWidget {
  const ContractInfoBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // blue-50
        border: Border.all(color: const Color(0xFFDBEAFE)), // blue-100
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info,
            color: AppColors.primary600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안내사항',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• 호스트가 계약 요청을 승인하면 채팅과 결제를 진행할 수 있습니다.\n'
                  '• 결제 완료 후에는 입주일 5일 전까지만 옵션 추가 및 변경이 가능합니다.\n'
                  '• 계약은 결제 선착순으로 확정되며, 결제 완료 전까지는 계약이 보장되지 않습니다.\n'
                  '• 입주일 이후 계약 취소 시 호스트와 합의 후 관리자 승인이 필요합니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF1E40AF),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
