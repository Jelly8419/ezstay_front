import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../constants/notice_texts.dart';
import '../../models/contract_detail.dart';
import '../contract/contract_common_widgets.dart';

/// 게스트 계약 상세 — 환불 규정 섹션
class GuestContractCancellationSection extends StatelessWidget {
  final ContractDetail contract;

  const GuestContractCancellationSection({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    final snapshot = contract.refundPolicySnapshot;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '환불 규정',
            style: AppTextStyles.headingMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          if (snapshot != null && snapshot.rules.isNotEmpty) ...[
            ...snapshot.rules.map(
              (rule) => BulletText(
                text: NoticeTexts.cancellationText(
                  rule.periodLabel,
                  rule.description,
                  rule.refundRate,
                ),
              ),
            ),
          ] else ...[
            Text(
              contract.refundPolicyDetail.isNotEmpty
                  ? contract.refundPolicyDetail
                  : '환불 정책 정보를 불러올 수 없습니다.',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 14,
                color: AppColors.neutral700,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
