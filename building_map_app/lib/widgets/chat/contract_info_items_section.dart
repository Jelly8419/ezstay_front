import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/contract_detail.dart';
import '../../utils/format_utils.dart';

/// 계약 정보 모달 — 옵션 상품 섹션 (게스트만)
class ContractInfoRentalItemsSection extends StatelessWidget {
  final ContractDetail contract;

  const ContractInfoRentalItemsSection({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2, size: 20, color: AppColors.neutral700),
            const SizedBox(width: 8),
            Text('옵션 상품 (EZstay에서 제공)',
                style:
                    AppTextStyles.headingSmall.copyWith(color: AppColors.gray900)),
          ],
        ),
        const SizedBox(height: 16),

        ...contract.rentalItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gray200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.gray900,
                                fontWeight: FontWeight.w700,
                              )),
                          if (item.description != null &&
                              item.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(item.description!,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.gray600)),
                          ],
                          const SizedBox(height: 4),
                          Text('수량: ${item.quantity}개',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.gray600)),
                        ],
                      ),
                    ),
                    Text(FormatUtils.formatKRW(item.totalPrice),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.gray900,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),
            )),

        Container(
          padding: const EdgeInsets.only(top: 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.gray200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('옵션 상품 합계',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.gray900,
                    fontWeight: FontWeight.w700,
                  )),
              Text(FormatUtils.formatKRW(
                  contract.rentalItems.fold(0, (sum, item) => sum + item.totalPrice)),
                  style: AppTextStyles.headingSmall
                      .copyWith(color: AppColors.gray900)),
            ],
          ),
        ),
      ],
    );
  }
}

/// 계약 정보 모달 — 결제 내역 섹션 (게스트만)
class ContractInfoPaymentHistorySection extends StatelessWidget {
  final ContractDetail contract;

  const ContractInfoPaymentHistorySection({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.credit_card, size: 20, color: AppColors.neutral700),
            const SizedBox(width: 8),
            Text('결제 내역',
                style:
                    AppTextStyles.headingSmall.copyWith(color: AppColors.gray900)),
          ],
        ),
        const SizedBox(height: 16),

        ...contract.paymentHistory.map((history) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gray200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(history.isPayment ? '결제' : '환불',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.gray900,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ],
                          ),
                          if (history.description != null) ...[
                            const SizedBox(height: 4),
                            Text(history.description!,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.gray600)),
                          ],
                          const SizedBox(height: 4),
                          Text(
                              FormatUtils.formatDateTimeDot(
                                  history.occurredAt),
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.neutral500)),
                        ],
                      ),
                    ),
                    Text(
                      '${history.isPayment ? '+' : '-'}${FormatUtils.formatKRW(history.amount)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: history.isPayment
                            ? AppColors.gray900
                            : const Color(0xFFDC2626),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

}
