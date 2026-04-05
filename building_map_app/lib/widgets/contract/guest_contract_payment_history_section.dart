import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/contract_detail.dart';
import '../../models/payment_history.dart';
import '../../utils/format_utils.dart';

/// 게스트 계약 상세 — 결제 내역 섹션
class GuestContractPaymentHistorySection extends StatelessWidget {
  final ContractDetail contract;

  const GuestContractPaymentHistorySection({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              const Icon(
                Icons.credit_card,
                size: 20,
                color: Color(0xFF374151),
              ),
              const SizedBox(width: 8),
              Text(
                '결제 내역',
                style: AppTextStyles.headingMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ...contract.paymentHistory.map(
            (payment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPaymentHistoryTile(payment),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryTile(PaymentHistory payment) {
    final isPayment = payment.isPayment;
    final displayAmount = payment.amount.abs();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isPayment ? AppColors.blue100 : AppColors.error50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPayment ? Icons.payment : Icons.replay,
            color: isPayment ? AppColors.blue600 : AppColors.error600,
            size: 20,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPayment ? '결제' : '환불',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                FormatUtils.formatDateTime(payment.occurredAt),
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 14,
                  color: AppColors.gray600,
                ),
              ),
              if (payment.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  payment.description!,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ),
        ),

        Text(
          '${isPayment ? '' : '-'}${FormatUtils.formatCurrency(displayAmount)}원',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isPayment ? AppColors.gray900 : AppColors.error600,
          ),
        ),
      ],
    );
  }
}
