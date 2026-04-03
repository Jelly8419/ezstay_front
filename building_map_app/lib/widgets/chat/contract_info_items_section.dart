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
              Text(FormatUtils.formatKRW(contract.rentalItemsFee),
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
                              Text(_typeLabel(history.transactionType),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.gray900,
                                    fontWeight: FontWeight.w700,
                                  )),
                              const SizedBox(width: 8),
                              _PaymentStatusBadge(status: history.status),
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
                                  history.transactionDate),
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

  String _typeLabel(String type) {
    switch (type) {
      case 'PAYMENT':
        return '결제';
      case 'PARTIAL_REFUND':
        return '부분 환불';
      case 'FULL_REFUND':
        return '전체 환불';
      default:
        return type;
    }
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  final String status;

  const _PaymentStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    final String label;

    switch (status) {
      case 'COMPLETED':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF047857);
        label = '완료';
      case 'PENDING':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFA16207);
        label = '대기';
      case 'FAILED':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFB91C1C);
        label = '실패';
      default:
        bgColor = AppColors.neutral100;
        textColor = AppColors.neutral700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          )),
    );
  }
}
