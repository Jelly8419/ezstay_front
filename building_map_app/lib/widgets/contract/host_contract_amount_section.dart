import 'package:flutter/material.dart';
import '../../constants/fee_constants.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/contract_detail.dart';
import '../../utils/format_utils.dart';
import '../contract/contract_common_widgets.dart';

/// 호스트 계약 금액 섹션
///
/// 임대료/관리비/청소비/보증금/수수료/정산 예정금액 표시
class HostContractAmountSection extends StatelessWidget {
  final ContractDetail contract;

  const HostContractAmountSection({super.key, required this.contract});

  static int _calcCommissionFee(ContractDetail c) {
    final baseAmount = c.isEzCleaning
        ? c.rentalFee + c.maintenanceFee
        : c.rentalFee + c.maintenanceFee + c.cleaningFee;
    return FeeConstants.calculateHostFee(baseAmount);
  }

  static int _calcSettlementAmount(ContractDetail c) {
    final baseAmount = c.isEzCleaning
        ? c.rentalFee + c.maintenanceFee
        : c.rentalFee + c.maintenanceFee + c.cleaningFee;
    return baseAmount - _calcCommissionFee(c);
  }

  @override
  Widget build(BuildContext context) {
    final commissionFee = _calcCommissionFee(contract);
    final settlementAmount = _calcSettlementAmount(contract);
    final totalContractAmount = contract.rentalFee +
        contract.maintenanceFee +
        contract.cleaningFee +
        contract.deposit;

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: ContractDetailCard.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '계약 금액',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: AppRadius.radiusSm,
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '이용 금액',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '임대료',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                            ),
                          ),
                          Text(
                            FormatUtils.formatKRW(contract.rentalFee),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '관리비',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                            ),
                          ),
                          Text(
                            FormatUtils.formatKRW(contract.maintenanceFee),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '청소비',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              if (contract.isEzCleaning) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'EZ서비스',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            FormatUtils.formatKRW(contract.cleaningFee),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 보증금
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Text(
                            '보증금 ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            '(게스트 퇴실 후 환급)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        FormatUtils.formatKRW(contract.deposit),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),

                // 총 계약 금액
                const SizedBox(height: 8),
                Container(
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        FormatUtils.formatKRW(totalContractAmount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),

                // 호스트 계약수수료
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '호스트 계약수수료',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF000000),
                        ),
                      ),
                      Text(
                        '- ${FormatUtils.formatKRW(commissionFee)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF000000),
                        ),
                      ),
                    ],
                  ),
                ),

                // 정산 예정금액
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '정산 예정금액',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      Text(
                        FormatUtils.formatKRW(settlementAmount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
