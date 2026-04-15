import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';

/// 환불 내역 행 위젯
///
/// 환불 정보 다이얼로그에서 항목별 금액을 표시하는 데 사용됩니다.
class RefundRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subLabel;
  final bool isBold;
  final bool isWarning;
  final bool isHighlight;

  const RefundRow({
    super.key,
    required this.label,
    required this.value,
    this.subLabel,
    this.isBold = false,
    this.isWarning = false,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                  color: isWarning
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF374151),
                ),
              ),
              if (subLabel != null)
                Text(
                  subLabel!,
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
            ],
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
              color: isHighlight
                  ? const Color(0xFF2563EB)
                  : isWarning
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
