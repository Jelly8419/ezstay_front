import 'package:flutter/material.dart';
import '../../utils/format_utils.dart';
import '../../models/contract.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 계약 금액 정보 섹션
/// 기본: 정산 예정금액만 표시 / 탭하면 상세 내역 펼침
class ContractPricingSection extends StatefulWidget {
  final ContractListItem contract;

  const ContractPricingSection({
    super.key,
    required this.contract,
  });

  @override
  State<ContractPricingSection> createState() => _ContractPricingSectionState();
}

class _ContractPricingSectionState extends State<ContractPricingSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final settlement = widget.contract.hostSettlement;
    if (settlement == null) return const SizedBox.shrink();

    final subtotal = settlement.rentalFee +
        settlement.maintenanceFee +
        settlement.cleaningFee -
        settlement.discountAmount;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 정산 예정금액 + 토글 아이콘
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '정산 예정금액',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary600,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '₩${FormatUtils.formatCurrency(settlement.hostEarnings)}',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.primary600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 20,
                      color: AppColors.primary600,
                    ),
                  ],
                ),
              ],
            ),

            // 펼침 상세 내역
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFE5E7EB), height: 1),
              const SizedBox(height: 12),

              // 이용 금액
              Text(
                '이용 금액',
                style: AppTextStyles.labelLarge.copyWith(color: const Color(0xFF111827)),
              ),
              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  children: [
                    _buildRow('임대료', settlement.rentalFee),
                    const SizedBox(height: 6),
                    _buildRow('관리비', settlement.maintenanceFee),
                    const SizedBox(height: 6),
                    _buildCleaningRow(settlement.cleaningFee),
                    if (settlement.discountAmount > 0) ...[
                      const SizedBox(height: 6),
                      _buildRow('할인', -settlement.discountAmount,
                          valueColor: const Color(0xFFDC2626)),
                    ],
                  ],
                ),
              ),

              // 소계
              _buildDividerRow(
                label: '소계',
                amount: subtotal,
                topBorderWidth: 1,
                topBorderColor: const Color(0xFFE5E7EB),
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                valueStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),

              // 차감 항목
              const SizedBox(height: 12),
              Text(
                '차감 항목',
                style: AppTextStyles.labelLarge.copyWith(color: const Color(0xFF111827)),
              ),
              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _buildRow('호스트 수수료', -settlement.hostPlatformFee,
                    valueColor: const Color(0xFF374151)),
              ),

              // 정산 예정금액 (상세 내 합계)
              _buildDividerRow(
                label: '정산 예정금액',
                amount: settlement.hostEarnings,
                topBorderWidth: 2,
                topBorderColor: const Color(0xFFD1D5DB),
                labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary600),
                valueStyle: AppTextStyles.headingSmall.copyWith(color: AppColors.primary600),
              ),

              // 보증금 안내
              if ((widget.contract.deposit ?? 0) > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '보증금 ₩${FormatUtils.formatCurrency(widget.contract.deposit ?? 0)}은 게스트 퇴실 후 별도로 환급됩니다.',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1D4ED8), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, int amount, {Color? valueColor}) {
    final isNegative = amount < 0;
    final displayAmount = isNegative ? -amount : amount;
    final prefix = isNegative ? '- ' : '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: Colors.black)),
        Text(
          '$prefix₩${FormatUtils.formatCurrency(displayAmount)}',
          style: AppTextStyles.labelMedium.copyWith(
            color: valueColor ?? const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildCleaningRow(int amount) {
    final contract = widget.contract;
    final isEzCleaning = amount == 0 && (contract.cleaningFee ?? 0) > 0;
    final displayAmount = isEzCleaning ? (contract.cleaningFee ?? 0) : amount;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text('청소비', style: AppTextStyles.bodyMedium.copyWith(color: Colors.black)),
            if (isEzCleaning) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary600,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'EZ서비스',
                  style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(정산 제외)',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        Text(
          isEzCleaning
              ? '(₩${FormatUtils.formatCurrency(displayAmount)})'
              : '₩${FormatUtils.formatCurrency(displayAmount)}',
          style: AppTextStyles.labelMedium.copyWith(
            color: isEzCleaning ? Colors.grey[600]! : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildDividerRow({
    required String label,
    required int amount,
    required double topBorderWidth,
    required Color topBorderColor,
    required TextStyle labelStyle,
    required TextStyle valueStyle,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: topBorderColor, width: topBorderWidth)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle),
          Text('₩${FormatUtils.formatCurrency(amount)}', style: valueStyle),
        ],
      ),
    );
  }
}
