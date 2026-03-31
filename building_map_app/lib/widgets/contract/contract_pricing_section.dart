import 'package:flutter/material.dart';
import '../../utils/format_utils.dart';
import '../../utils/fee_calculator.dart';
import '../../models/contract.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 계약 금액 정보 섹션 (임대료/관리비/청소비/보증금/총액/정산예정)
class ContractPricingSection extends StatelessWidget {
  final ContractListItem contract;

  const ContractPricingSection({
    super.key,
    required this.contract,
  });

  @override
  Widget build(BuildContext context) {
    final settlementAmount =
        contract.hostEarnings ?? FeeCalculator.calculateHostSettlement(contract);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이용 금액
          Text(
            '이용 금액',
            style: AppTextStyles.labelLarge.copyWith(
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),

          // 임대료, 관리비, 청소비
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              children: [
                _buildAmountRow('임대료', contract.rentalFee ?? 0),
                const SizedBox(height: 8),
                _buildAmountRow('관리비', contract.maintenanceFee ?? 0),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '청소비',
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.black),
                        ),
                        if (contract.isEzCleaning == true) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary600,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'EZ서비스',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '₩${FormatUtils.formatCurrency(contract.cleaningFee ?? 0)}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 보증금
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '보증금 ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      TextSpan(
                        text: '(게스트 퇴실 후 환급)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₩${FormatUtils.formatCurrency(contract.deposit ?? 0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 총 계약 금액
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFD1D5DB), width: 2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '총 계약 금액',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  '₩${FormatUtils.formatCurrency((contract.rentalFee ?? 0) + (contract.maintenanceFee ?? 0) + (contract.cleaningFee ?? 0) + (contract.deposit ?? 0))}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 정산 예정금액
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '정산 예정금액',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary600,
                  ),
                ),
                Text(
                  '₩${FormatUtils.formatCurrency(settlementAmount)}',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.primary600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: Colors.black)),
        Text(
          '₩${FormatUtils.formatCurrency(amount)}',
          style: AppTextStyles.labelMedium.copyWith(
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

}
