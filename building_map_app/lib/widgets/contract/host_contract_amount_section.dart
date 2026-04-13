import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/contract.dart';
import '../../models/contract_detail.dart';
import '../../utils/format_utils.dart';
import '../contract/contract_common_widgets.dart';

/// 호스트 계약 금액 섹션
class HostContractAmountSection extends StatelessWidget {
  final ContractDetail contract;

  const HostContractAmountSection({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    final settlement = contract.hostSettlement;

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.gray200),
        boxShadow: ContractDetailCard.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '계약 금액',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: AppRadius.radiusSm,
              border: Border.all(color: AppColors.gray200),
            ),
            child: settlement != null
                ? _buildWithSettlement(settlement)
                : _buildFallback(),
          ),
        ],
      ),
    );
  }

  /// hostSettlement 있을 때: 계산 과정 전체 표시
  Widget _buildWithSettlement(HostSettlement s) {
    final subtotal = s.rentalFee + s.maintenanceFee + s.cleaningFee - s.discountAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('이용 금액'),
        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Column(
            children: [
              _row('임대료', s.rentalFee),
              const SizedBox(height: 6),
              _row('관리비', s.maintenanceFee),
              const SizedBox(height: 6),
              _cleaningRow(
                displayAmount: contract.cleaningFee,
                isEzCleaning: s.cleaningFee == 0 && contract.cleaningFee > 0,
              ),
              if (s.discountAmount > 0) ...[
                const SizedBox(height: 6),
                _row('할인', -s.discountAmount, valueColor: AppColors.error600),
              ],
            ],
          ),
        ),

        _dividerRow(
          label: '소계',
          amount: subtotal,
          topBorderWidth: 1,
          topBorderColor: AppColors.gray200,
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gray900),
          valueStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gray900),
        ),

        const SizedBox(height: 12),
        _sectionLabel('차감 항목'),
        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: _row('임대인 수수료', -s.hostPlatformFee, valueColor: AppColors.neutral700),
        ),

        _dividerRow(
          label: '정산 예정금액',
          amount: s.hostEarnings,
          topBorderWidth: 2,
          topBorderColor: AppColors.gray300,
          labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.blue600),
          valueStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.blue600),
        ),

        if (contract.deposit > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.blue100),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '보증금 ₩${FormatUtils.formatCurrency(contract.deposit)}은 임차인 퇴실 후 별도로 환급됩니다.',
                    style: TextStyle(fontSize: 13, color: AppColors.blue900, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// hostSettlement 없을 때: 기존 단순 표시 (fallback)
  Widget _buildFallback() {
    final totalContractAmount =
        contract.rentalFee + contract.maintenanceFee + contract.cleaningFee + contract.deposit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('이용 금액'),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Column(
            children: [
              _row('임대료', contract.rentalFee),
              const SizedBox(height: 6),
              _row('관리비', contract.maintenanceFee),
              const SizedBox(height: 6),
              _cleaningRow(
                displayAmount: contract.cleaningFee,
                isEzCleaning: contract.isEzCleaning,
              ),
            ],
          ),
        ),
        _dividerRow(
          label: '보증금',
          amount: contract.deposit,
          topBorderWidth: 1,
          topBorderColor: AppColors.gray200,
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gray900),
          valueStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gray900),
        ),
        _dividerRow(
          label: '총 계약 금액',
          amount: totalContractAmount,
          topBorderWidth: 2,
          topBorderColor: AppColors.gray300,
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gray900),
          valueStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.gray900),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gray900),
    );
  }

  Widget _row(String label, int amount, {Color? valueColor, String? subLabel}) {
    final isNegative = amount < 0;
    final displayAmount = isNegative ? -amount : amount;
    final prefix = isNegative ? '- ' : '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(fontSize: 14, color: AppColors.neutral700)),
            if (subLabel != null) ...[
              const SizedBox(width: 4),
              Text(subLabel, style: TextStyle(fontSize: 12, color: AppColors.neutral500)),
            ],
          ],
        ),
        Text(
          '$prefix₩${FormatUtils.formatCurrency(displayAmount)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.gray900,
          ),
        ),
      ],
    );
  }

  Widget _cleaningRow({required int displayAmount, required bool isEzCleaning}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text('청소비', style: TextStyle(fontSize: 14, color: AppColors.neutral700)),
            if (isEzCleaning) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.blue600,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'EZ서비스',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(정산 제외)',
                style: TextStyle(fontSize: 12, color: AppColors.neutral500),
              ),
            ],
          ],
        ),
        Text(
          isEzCleaning
              ? '(₩${FormatUtils.formatCurrency(displayAmount)})'
              : '₩${FormatUtils.formatCurrency(displayAmount)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isEzCleaning ? AppColors.neutral500 : AppColors.gray900,
          ),
        ),
      ],
    );
  }

  Widget _dividerRow({
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
