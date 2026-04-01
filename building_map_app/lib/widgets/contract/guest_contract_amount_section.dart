import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/contract_detail.dart';
import '../../utils/format_utils.dart';

/// 게스트 계약 상세 — 임대 계약 금액 섹션
class GuestContractAmountSection extends StatelessWidget {
  final ContractDetail contract;

  const GuestContractAmountSection({super.key, required this.contract});

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
          Text(
            '임대 계약 금액',
            style: AppTextStyles.headingMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 16),

          _buildAmountRow('임대료', contract.rentalFee),
          _buildAmountRow('관리비', contract.maintenanceFee),
          _buildAmountRowWithBadge(
            '청소비',
            contract.cleaningFee,
            showEzBadge: contract.isEzCleaning,
          ),
          _buildAmountRow('계약 수수료', contract.platformFee),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.gray200),
          ),

          _buildAmountRowWithSubtext('보증금', '(퇴실 후 반환 예정)', contract.deposit),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 2, thickness: 2, color: AppColors.gray200),
          ),

          _buildAmountRow(
            '총 임대 계약 금액',
            contract.finalTotalAmount,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, int amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal
                  ? const Color(0xFF111827)
                  : const Color(0xFF374151),
            ),
          ),
          Text(
            '${FormatUtils.formatCurrency(amount)}원',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRowWithBadge(
    String label,
    int amount, {
    bool showEzBadge = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF374151),
                ),
              ),
              if (showEzBadge) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'EZ서비스',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Text(
            '${FormatUtils.formatCurrency(amount)}원',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRowWithSubtext(String label, String subtext, int amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                subtext,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          Text(
            '${FormatUtils.formatCurrency(amount)}원',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
