import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 호스트 계약 관리 페이지 안내 메시지 박스
class HostInfoMessage extends StatelessWidget {
  const HostInfoMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // bg-blue-50
        border: Border.all(color: const Color(0xFFDBEAFE)), // border-blue-100
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안내사항',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 4),
                _buildInfoItem('임차인의 계약 요청을 승인하거나 거절할 수 있습니다.'),
                _buildInfoItem('승인 후 임차인이 결제하면 계약이 확정됩니다.'),
                _buildInfoItem('임대인이 계약을 취소하려면 위약금을 결제해야 합니다.'),
                _buildInfoItem('입주일 이후 취소 시 임차인과 합의 후 관리자 승인이 필요합니다.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '• $text',
        style: AppTextStyles.bodyMedium.copyWith(
          color: const Color(0xFF1E40AF),
        ),
      ),
    );
  }
}
