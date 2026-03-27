import 'package:flutter/material.dart';
import '../utils/format_utils.dart';
import '../models/chat_message.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// 시스템 메시지 말풍선
/// - 중앙 정렬
/// - 아이콘 + 텍스트
/// - 연한 배경색
class SystemMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const SystemMessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getSystemMessageConfig(message.systemMessageType);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.neutral300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,  // 왼쪽 정렬
          children: [
            // 헤더: 시스템 메시지 레이블 + 타임스탬프
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: config.labelColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    config.label,  // "계약요청", "계약승인" 등
                    style: AppTextStyles.bodySmall.copyWith(
                      color: config.labelColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  FormatUtils.formatDateTimeDot(message.timestamp),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 본문 텍스트
            Text(
              message.text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 시스템 메시지 타입별 UI 설정
  SystemMessageConfig _getSystemMessageConfig(String? type) {
    switch (type) {
      case 'contract_approved':
        return SystemMessageConfig(
          label: '계약승인',
          labelColor: AppColors.primary500,
          icon: Icons.check_circle,
          iconColor: AppColors.success500,
          backgroundColor: AppColors.success500.withValues(alpha: 0.08),
          borderColor: AppColors.success500.withValues(alpha: 0.2),
          textColor: AppColors.success500.darken(0.2),
        );
      case 'contract_completed':
        return SystemMessageConfig(
          label: '계약완료',
          labelColor: AppColors.primary500,
          icon: Icons.verified,
          iconColor: AppColors.primary500,
          backgroundColor: AppColors.primary500.withValues(alpha: 0.08),
          borderColor: AppColors.primary500.withValues(alpha: 0.2),
          textColor: AppColors.primary500.darken(0.2),
        );
      case 'contract_cancelled':
        return SystemMessageConfig(
          label: '계약취소',
          labelColor: AppColors.error500,
          icon: Icons.cancel,
          iconColor: AppColors.error500,
          backgroundColor: AppColors.error500.withValues(alpha: 0.08),
          borderColor: AppColors.error500.withValues(alpha: 0.2),
          textColor: AppColors.error500.darken(0.2),
        );
      case 'payment_completed':
        return SystemMessageConfig(
          label: '결제완료',
          labelColor: AppColors.primary500,
          icon: Icons.payments,
          iconColor: AppColors.info500,
          backgroundColor: AppColors.info500.withValues(alpha: 0.08),
          borderColor: AppColors.info500.withValues(alpha: 0.2),
          textColor: AppColors.info500.darken(0.2),
        );
      case 'check_in':
        return SystemMessageConfig(
          label: '체크인',
          labelColor: AppColors.primary500,
          icon: Icons.login,
          iconColor: AppColors.info500,
          backgroundColor: AppColors.info500.withValues(alpha: 0.08),
          borderColor: AppColors.info500.withValues(alpha: 0.2),
          textColor: AppColors.info500.darken(0.2),
        );
      case 'check_out':
        return SystemMessageConfig(
          label: '체크아웃',
          labelColor: AppColors.textSecondary,
          icon: Icons.logout,
          iconColor: AppColors.textSecondary,
          backgroundColor: AppColors.neutral100,
          borderColor: AppColors.neutral300,
          textColor: AppColors.textSecondary,
        );
      default:
        return SystemMessageConfig(
          label: '시스템 알림',
          labelColor: AppColors.primary500,
          icon: Icons.info_outline,
          iconColor: AppColors.textSecondary,
          backgroundColor: AppColors.neutral100,
          borderColor: AppColors.neutral300,
          textColor: AppColors.textSecondary,
        );
    }
  }
}

/// 시스템 메시지 UI 설정
class SystemMessageConfig {
  final String label;  // 레이블 텍스트 ("계약요청", "계약승인" 등)
  final Color labelColor;  // 레이블 색상
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  SystemMessageConfig({
    required this.label,
    required this.labelColor,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}
