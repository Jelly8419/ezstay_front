import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/calculated_pricing.dart';
import '../../utils/format_utils.dart';
import '../../utils/price_calculator.dart';

/// 옵션 상품 섹션 (빈 상태 UI 포함)
/// 6일 정책: 입주일 6일 전까지만 옵션 상품 선택 가능
class ContractRentalItemsSection extends StatelessWidget {
  final List<SelectedRentalItem> selectedRentalItems;
  final DateTime? checkInDate;

  const ContractRentalItemsSection({
    super.key,
    required this.selectedRentalItems,
    required this.checkInDate,
  });

  @override
  Widget build(BuildContext context) {
    final hasItems = selectedRentalItems.isNotEmpty;

    // 6일 정책 체크: 입주일 6일 전까지만 선택 가능
    final canSelectRental = PriceCalculator.canSelectRentalItems(
      checkInDate: checkInDate,
    );
    final disabledReason = PriceCalculator.getRentalItemsDisabledReason(
      checkInDate: checkInDate,
    );

    // 정책 위반 시 옵션 상품 포함 불가
    final isRentalDisabled = !canSelectRental && hasItems;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // React: "옵션 상품" + "(X개 선택)" in gray
          Row(
            children: [
              Text('옵션 상품', style: AppTextStyles.headingSmall),
              const SizedBox(width: 8),
              Text(
                '(${selectedRentalItems.length}개 선택)',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 6일 정책 위반 경고 메시지
          if (isRentalDisabled) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error50,
                border: Border.all(color: AppColors.error500),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: AppColors.error500,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          disabledReason ?? '옵션 상품을 선택할 수 없습니다.',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '선택하신 옵션 상품은 계약에 포함되지 않습니다.',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 12,
                            color: AppColors.error600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 빈 상태 UI
          if (!hasItems)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text(
                    '선택한 옵션 상품이 없습니다.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '방 상세페이지에서 옵션 상품을 선택해주세요.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            )
          else
            // 옵션 상품 목록 (정책 위반 시 반투명 처리)
            Opacity(
              opacity: isRentalDisabled ? 0.5 : 1.0,
              child: Column(
                children: selectedRentalItems
                    .map(
                      (item) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[100]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: const Color(0xFF111827),
                                    ),
                                  ),
                                  if (item.description != null &&
                                      item.description!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        item.description!,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontSize: 13,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${FormatUtils.formatCurrency(item.price)}원 x ${item.quantity}개',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: 13,
                                        color: const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${FormatUtils.formatCurrency(item.totalPrice)}원',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          // 옵션 상품 안내 (파란색 박스)
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // blue-50
              border: Border.all(color: const Color(0xFFDBEAFE)), // blue-100
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '옵션 상품은 계약 승인 후에도 입주 5일 전까지 추가로 구매할 수 있습니다.(각 최대 4개)',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 13,
                      color: const Color(0xFF1E40AF),
                    ),
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
