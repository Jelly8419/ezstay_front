import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 계약 상태 배지 설정
class _StatusConfig {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  const _StatusConfig({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });
}

/// 계약 상태 배지 위젯 (백엔드 CONTRACT_STATUS 전체 매핑)
///
/// Guest/Host 계약 상세, 채팅 목록 등에서 공통으로 사용하는 상태 배지입니다.
/// [compact] true이면 채팅 목록 등에서 사용하는 작은 사이즈 배지를 렌더링합니다.
class ContractStatusBadge extends StatelessWidget {
  final String status;
  final bool showIcon;
  final bool compact;

  const ContractStatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.compact = false,
  });

  static final Map<String, _StatusConfig> _statusMap = {
    'PENDING_APPROVAL': _StatusConfig(
      text: '승인 대기',
      backgroundColor: AppColors.warning50,
      textColor: AppColors.secondary700,
      icon: Icons.schedule,
    ),
    'APPROVED': _StatusConfig(
      text: '결제 대기',
      backgroundColor: AppColors.blue100,
      textColor: AppColors.blue700,
      icon: Icons.payment,
    ),
    'REJECTED': _StatusConfig(
      text: '거절됨',
      backgroundColor: AppColors.error50,
      textColor: AppColors.error700,
      icon: Icons.block,
    ),
    'PAYMENT_COMPLETED': _StatusConfig(
      text: '결제 완료',
      backgroundColor: AppColors.green100,
      textColor: AppColors.success700,
      icon: Icons.check_circle,
    ),
    'IN_PROGRESS': _StatusConfig(
      text: '임대 중',
      backgroundColor: AppColors.purple50,
      textColor: AppColors.purple600,
      icon: Icons.home,
    ),
    'COMPLETED': _StatusConfig(
      text: '계약 종료',
      backgroundColor: AppColors.gray50,
      textColor: AppColors.neutral700,
      icon: Icons.check_circle_outline,
    ),
    'CANCELLED_BY_GUEST': _StatusConfig(
      text: '게스트 취소',
      backgroundColor: AppColors.error50,
      textColor: AppColors.error700,
      icon: Icons.cancel,
    ),
    'CANCELLED_BY_HOST': _StatusConfig(
      text: '호스트 취소',
      backgroundColor: AppColors.error50,
      textColor: AppColors.error700,
      icon: Icons.cancel,
    ),
    'CANCELLED_BY_ADMIN_WITH_REFUND': _StatusConfig(
      text: '관리자 취소 (환불)',
      backgroundColor: AppColors.error50,
      textColor: AppColors.error700,
      icon: Icons.admin_panel_settings,
    ),
    'CANCELLED_BY_ADMIN_NO_REFUND': _StatusConfig(
      text: '관리자 취소',
      backgroundColor: AppColors.error50,
      textColor: AppColors.error700,
      icon: Icons.admin_panel_settings,
    ),
    'REFUNDED': _StatusConfig(
      text: '환불 완료',
      backgroundColor: AppColors.purple50,
      textColor: AppColors.purple600,
      icon: Icons.currency_exchange,
    ),
    'APPROVAL_EXPIRED': _StatusConfig(
      text: '미승인 만료',
      backgroundColor: AppColors.gray50,
      textColor: AppColors.neutral700,
      icon: Icons.timer_off,
    ),
    'PAYMENT_EXPIRED': _StatusConfig(
      text: '미결제 만료',
      backgroundColor: AppColors.gray50,
      textColor: AppColors.neutral700,
      icon: Icons.timer_off,
    ),
    'CANCEL_REQUESTED': _StatusConfig(
      text: '취소 요청',
      backgroundColor: const Color(0xFFFFF7ED), // orange-50
      textColor: const Color(0xFFEA580C), // orange-600
      icon: Icons.pending_actions,
    ),
  };

  static _StatusConfig _getConfig(String status) {
    return _statusMap[status] ?? _statusMap['PENDING_APPROVAL']!;
  }

  /// 상태 텍스트만 필요한 경우 (위젯 없이)
  static String getStatusText(String status) {
    return _getConfig(status).text;
  }

  /// 상태 텍스트 색상만 필요한 경우
  static Color getStatusColor(String status) {
    return _getConfig(status).textColor;
  }

  /// 상태 배경 색상만 필요한 경우
  static Color getStatusBgColor(String status) {
    return _getConfig(status).backgroundColor;
  }

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);

    if (compact) {
      // 채팅 목록 등에서 사용하는 작은 배지
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: config.backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          config.text,
          style: AppTextStyles.caption.copyWith(
            color: config.textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              config.icon,
              size: 16,
              color: config.textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            config.text,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 14,
              color: config.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
