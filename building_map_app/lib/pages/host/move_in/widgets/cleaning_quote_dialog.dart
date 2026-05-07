import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/move_in/move_in.dart';

/// 청소 PG 결제 직전 — 견적 미리보기 다이얼로그
///
/// PRD 7.2 / 가이드 3.4 Step1.
/// 결과:
/// - `true` → "결제 진행"
/// - `null` / `false` → 취소
Future<bool?> showCleaningQuoteDialog(
  BuildContext context, {
  required MoveInCase moveInCase,
  required CleaningQuoteResponse quote,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CleaningQuoteDialog(moveInCase: moveInCase, quote: quote),
  );
}

class _CleaningQuoteDialog extends StatelessWidget {
  final MoveInCase moveInCase;
  final CleaningQuoteResponse quote;

  const _CleaningQuoteDialog({required this.moveInCase, required this.quote});

  @override
  Widget build(BuildContext context) {
    final c = moveInCase;
    final room = c.roomSnapshot;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      title: const Text('청소 결제 확인'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('서비스', '입주 청소 서비스'),
            _row('대상 방', room.displayName),
            _row('주소', room.fullAddress),
            _row('입주일', _formatDate(c.checkInDate)),
            _row('퇴실일', _formatDate(c.checkOutDate)),
            if (c.cleaningRequestedDate != null)
              _row('희망 청소일', _formatDate(c.cleaningRequestedDate!)),
            if (room.cleaningSuppliesLocation?.isNotEmpty == true)
              _row('청소용품 위치', room.cleaningSuppliesLocation!),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '결제 금액',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  _money(quote.cleaningFee),
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.primary600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              '${quote.areaPyeong}평 기준 — ${quote.formula}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.payment, size: 18),
          label: const Text('결제 진행'),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  String _money(int amount) {
    final fmt = NumberFormat.decimalPattern('en_US').format(amount);
    return '$fmt원';
  }

  String _formatDate(String yyyymmdd) {
    try {
      return DateFormat('yyyy.MM.dd').format(DateTime.parse(yyyymmdd));
    } catch (_) {
      return yyyymmdd;
    }
  }
}
