import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/contract_detail.dart';
import '../../utils/format_utils.dart';

/// 게스트 계약 상세 — 옵션 상품 섹션
class GuestContractOptionSection extends StatelessWidget {
  final ContractDetail contract;

  const GuestContractOptionSection({super.key, required this.contract});

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
              Icon(
                Icons.inventory_2_outlined,
                size: 20,
                color: AppColors.neutral700,
              ),
              const SizedBox(width: 8),
              Text(
                '옵션 상품 (EZstay에서 제공)',
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (contract.rentalItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '선택한 옵션이 없습니다.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
              ),
            )
          else ...[
            ...contract.rentalItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: EdgeInsets.only(top: index > 0 ? 12 : 0),
                child: _buildRentalItemCard(item),
              );
            }),

            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.gray200, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '옵션 상품 합계',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                  ),
                  Text(
                    '${FormatUtils.formatCurrency(contract.rentalItemsFee)}원',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRentalItemCard(ContractRentalItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray200, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                if (item.description != null && item.description!.isNotEmpty)
                  Text(
                    item.description!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '수량: ${item.quantity}개',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Text(
            '${FormatUtils.formatCurrency(item.price * item.quantity)}원',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
        ],
      ),
    );
  }
}
