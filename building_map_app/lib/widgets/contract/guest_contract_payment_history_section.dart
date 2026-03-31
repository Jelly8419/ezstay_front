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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: payment.isPayment ? AppColors.blue100 : AppColors.error50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            payment.isPayment ? Icons.payment : Icons.replay,
            color: payment.isPayment ? AppColors.blue600 : AppColors.error600,
            size: 20,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payment.isPayment ? '결제' : '환불',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                FormatUtils.formatDateTime(payment.transactionDate),
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
              const SizedBox(height: 6),
              _buildPaymentStatusBadge(payment.status),
            ],
          ),
        ),

        Text(
          '${payment.isPayment ? '' : '-'}${FormatUtils.formatCurrency(payment.amount)}원',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: payment.isPayment ? AppColors.gray900 : AppColors.error600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusBadge(String status) {
    final config = _getPaymentStatusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (config['color'] as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        config['text'] as String,
        style: AppTextStyles.bodySmall.copyWith(
          fontSize: 12,
          color: config['color'] as Color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Map<String, dynamic> _getPaymentStatusConfig(String status) {
    final statusMap = {
      'COMPLETED': {'text': '완료', 'color': AppColors.success500},
      'PENDING': {'text': '대기', 'color': AppColors.warning500},
      'FAILED': {'text': '실패', 'color': AppColors.error500},
    };
    return statusMap[status] ?? statusMap['PENDING']!;
  }
}
