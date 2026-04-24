import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/contract_detail.dart';
import '../../utils/format_utils.dart';

/// 계약 정보 모달 — 금액 섹션 (호스트용/게스트용 통합)
class ContractInfoPricingSection extends StatelessWidget {
  final ContractDetail contract;
  final String userMode;

  const ContractInfoPricingSection({
    super.key,
    required this.contract,
    required this.userMode,
  });

  int get _hostCommissionFee {
    final base = contract.isEzCleaning
        ? contract.rentalFee + contract.maintenanceFee
        : contract.rentalFee + contract.maintenanceFee + contract.cleaningFee;
    return (base * 0.033).floor();
  }

  int get _actualSettlementAmount {
    final base = contract.isEzCleaning
        ? contract.rentalFee + contract.maintenanceFee
        : contract.rentalFee + contract.maintenanceFee + contract.cleaningFee;
    return base - _hostCommissionFee;
  }

  @override
  Widget build(BuildContext context) {
    return userMode == 'host' ? _buildHostSection() : _buildGuestSection();
  }

  Widget _buildHostSection() {
    final total = contract.rentalFee +
        contract.maintenanceFee +
        contract.cleaningFee +
        contract.deposit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('계약 금액',
            style: AppTextStyles.headingSmall.copyWith(color: AppColors.gray900)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            border: Border.all(color: AppColors.gray200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('이용 금액',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.gray900,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  children: [
                    _PriceRow(label: '임대료', amount: contract.rentalFee),
                    const SizedBox(height: 8),
                    _PriceRow(label: '관리비', amount: contract.maintenanceFee),
                    const SizedBox(height: 8),
                    _CleaningFeeRow(
                        cleaningFee: contract.cleaningFee,
                        isEzCleaning: contract.isEzCleaning),
                  ],
                ),
              ),

              // 보증금
              _DividerRow(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('보증금 ',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.gray900,
                              fontWeight: FontWeight.w700,
                            )),
                        Text('(임차인 퇴실 후 환급)',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.neutral500)),
                      ],
                    ),
                    Text(FormatUtils.formatKRW(contract.deposit),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.gray900,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),

              // 총 계약 금액
              _DividerRow(
                thick: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('총 계약 금액',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.gray900,
                          fontWeight: FontWeight.w700,
                        )),
                    Text(FormatUtils.formatKRW(total),
                        style: AppTextStyles.headingSmall
                            .copyWith(color: AppColors.gray900)),
                  ],
                ),
              ),

              // 호스트 계약수수료
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('임대인 계약수수료',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.gray900)),
                    Text('- ${FormatUtils.formatKRW(_hostCommissionFee)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.gray900,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),

              // 정산 예정 금액
              _DividerRow(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('정산 예정금액',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.blue600,
                          fontWeight: FontWeight.w700,
                        )),
                    Text(FormatUtils.formatKRW(_actualSettlementAmount),
                        style: AppTextStyles.headingSmall
                            .copyWith(color: AppColors.blue600)),
                  ],
                ),
              ),

              // 임차인 프로모션 수수료 할인 (정보성 — 정산에 영향 없음)
              if ((contract.platformFeeDiscount ?? 0) > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '임차인 수수료 할인 (${contract.appliedPromotions.length}건)',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.neutral500,
                            ),
                          ),
                          Text(
                            '-${FormatUtils.formatKRW(contract.platformFeeDiscount ?? 0)}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.neutral500,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      ...contract.appliedPromotions.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Text(
                            '· ${p.eventName}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.neutral500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuestSection() {
    final platformFeeOriginal =
        contract.platformFeeOriginal ?? contract.platformFee;
    final platformFeeDiscount = contract.platformFeeDiscount ?? 0;
    final total = contract.rentalFee +
        contract.maintenanceFee +
        contract.cleaningFee +
        contract.platformFee +
        contract.deposit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('임대 계약 금액',
            style: AppTextStyles.headingSmall.copyWith(color: AppColors.gray900)),
        const SizedBox(height: 16),
        _PriceRow(label: '임대료', amount: contract.rentalFee),
        const SizedBox(height: 12),
        _PriceRow(label: '관리비', amount: contract.maintenanceFee),
        const SizedBox(height: 12),
        _CleaningFeeRow(
            cleaningFee: contract.cleaningFee,
            isEzCleaning: contract.isEzCleaning),
        const SizedBox(height: 12),
        _PriceRow(label: '계약 수수료', amount: platformFeeOriginal),
        if (platformFeeDiscount > 0) ...[
          const SizedBox(height: 12),
          _PriceRow(
            label:
                '수수료 할인 (${contract.appliedPromotions.length}건)',
            amount: -platformFeeDiscount,
            isDiscount: true,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: contract.appliedPromotions
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '· ${p.eventName}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.neutral500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: 12),

        // 보증금
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('보증금 ',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.neutral700)),
                Text('(퇴실 후 반환 예정)',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.neutral500)),
              ],
            ),
            Text(FormatUtils.formatKRW(contract.deposit),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray900,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),

        // 총 임대 계약 금액
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.gray200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('총 임대 계약 금액',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.gray900,
                      fontWeight: FontWeight.w700,
                    )),
                Text(FormatUtils.formatKRW(total),
                    style: AppTextStyles.headingSmall
                        .copyWith(color: AppColors.gray900)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final int amount;
  final bool isDiscount;

  const _PriceRow({
    required this.label,
    required this.amount,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = isDiscount
        ? '-${FormatUtils.formatKRW(amount.abs())}'
        : FormatUtils.formatKRW(amount);
    final valueColor = isDiscount ? AppColors.primary600 : AppColors.gray900;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral700)),
        Text(displayText,
            style: AppTextStyles.bodyMedium.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            )),
      ],
    );
  }
}

class _CleaningFeeRow extends StatelessWidget {
  final int cleaningFee;
  final bool isEzCleaning;

  const _CleaningFeeRow({required this.cleaningFee, required this.isEzCleaning});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text('청소비',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral700)),
            if (isEzCleaning) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.blue600,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('EZ서비스',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.neutral0,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ],
          ],
        ),
        Text(FormatUtils.formatKRW(cleaningFee),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.gray900,
              fontWeight: FontWeight.w700,
            )),
      ],
    );
  }
}

/// 상단 구분선 + 패딩 래퍼
class _DividerRow extends StatelessWidget {
  final Widget child;
  final bool thick;

  const _DividerRow({required this.child, this.thick = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: thick ? AppColors.gray300 : AppColors.gray200,
              width: thick ? 2 : 1,
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}
