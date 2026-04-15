import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/contract.dart';
import 'contract_status_helper.dart';

/// 계약 상태 배지 위젯 (백엔드 CONTRACT_STATUS 전체 매핑)
///
/// Guest/Host 계약 상세, 채팅 목록 등에서 공통으로 사용하는 상태 배지입니다.
/// 문구·색상은 [ContractStatusHelper.getStatusBadgeConfig]를 단일 소스로 사용합니다.
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

  static ({String text, Color bgColor, Color textColor}) _getBadgeConfig(String status) {
    return ContractStatusHelper.getStatusBadgeConfig(ContractStatus.fromString(status));
  }

  /// 상태 텍스트만 필요한 경우 (위젯 없이)
  static String getStatusText(String status) {
    return _getBadgeConfig(status).text;
  }

  /// 상태 텍스트 색상만 필요한 경우
  static Color getStatusColor(String status) {
    return _getBadgeConfig(status).textColor;
  }

  /// 상태 배경 색상만 필요한 경우
  static Color getStatusBgColor(String status) {
    return _getBadgeConfig(status).bgColor;
  }

  @override
  Widget build(BuildContext context) {
    final contractStatus = ContractStatus.fromString(status);
    final config = ContractStatusHelper.getStatusBadgeConfig(contractStatus);
    final icon = ContractStatusHelper.getStatusIcon(contractStatus);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: config.bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          config.text,
          style: AppTextStyles.caption.copyWith(
            color: config.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            IconTheme(
              data: IconThemeData(color: config.textColor, size: 16),
              child: icon,
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
