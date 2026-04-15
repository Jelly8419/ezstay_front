import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../utils/format_utils.dart';
import '../../utils/price_calculator.dart';
import '../../services/rental_order_service.dart';

/// 옵션 추가 구매 모달
class AddOptionModal extends StatefulWidget {
  final List<AvailableRentalItem> availableOptions;
  final bool hasPendingDelivery;
  final void Function(Map<int, int> selectedOptions) onConfirm;

  const AddOptionModal({
    super.key,
    required this.availableOptions,
    required this.hasPendingDelivery,
    required this.onConfirm,
  });

  @override
  State<AddOptionModal> createState() => _AddOptionModalState();
}

class _AddOptionModalState extends State<AddOptionModal> {
  final Map<int, int> _quantities = {};

  int get _totalAmount {
    int total = 0;
    for (final entry in _quantities.entries) {
      if (entry.value > 0) {
        final option = widget.availableOptions.firstWhere(
          (o) => o.id == entry.key,
          orElse: () =>
              AvailableRentalItem(id: 0, name: '', price: 0, totalStock: 0),
        );
        total += option.price * entry.value;
      }
    }
    return total;
  }

  bool get _hasSelection => _quantities.values.any((q) => q > 0);

  bool get _isBelowMinimum =>
      !widget.hasPendingDelivery &&
      _totalAmount > 0 &&
      PriceCalculator.isInvalidRentalAmount(_totalAmount);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 672),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '옵션 추가 구매',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: const Color(0xFF111827),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(4),
                    child: const Icon(
                      Icons.close,
                      size: 24,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),

            // 안내 메시지 (파란색 박스)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '• 계약 시작일의 5일 전 까지만 구매할 수 있어요.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF1E40AF),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 옵션 목록
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: widget.availableOptions.map((option) {
                    final qty = _quantities[option.id] ?? 0;
                    return _buildOptionCard(option, qty);
                  }).toList(),
                ),
              ),
            ),

            // 결제 금액 및 버튼
            if (_hasSelection) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFD1D5DB))),
                ),
                child: Column(
                  children: [
                    // 총 결제 금액
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '총 결제 금액',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: const Color(0xFF111827),
                            ),
                          ),
                          Text(
                            '${FormatUtils.formatCurrency(_totalAmount)}원',
                            style: AppTextStyles.headingMedium.copyWith(
                              color: AppColors.primary600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 최소 금액 에러 문구
                    if (_isBelowMinimum) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          PriceCalculator.rentalAmountErrorMessage(
                            currentAmount: _totalAmount,
                          ),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],

                    // 버튼
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(
                                color: Color(0xFFD1D5DB),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              '취소',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: const Color(0xFF374151),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isBelowMinimum
                                ? null
                                : () {
                                    Navigator.pop(context);
                                    widget.onConfirm(_quantities);
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: AppColors.primary600,
                              disabledBackgroundColor: const Color(0xFFD1D5DB),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: const Color(0xFF9CA3AF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              '결제하기',
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else
              const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(AvailableRentalItem option, int qty) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상품명
          Text(
            option.name,
            style: AppTextStyles.labelMedium.copyWith(
              color: const Color(0xFF111827),
            ),
          ),
          // 설명
          if (option.description != null && option.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              option.description!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
          // 가격
          const SizedBox(height: 4),
          Text(
            '개당 ${FormatUtils.formatCurrency(option.price)}원',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primary600,
            ),
          ),
          const SizedBox(height: 12),

          // 수량 조절 및 금액
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 수량 조절
              Row(
                children: [
                  // 마이너스 버튼
                  InkWell(
                    onTap: qty > 0
                        ? () {
                            setState(() {
                              _quantities[option.id] = qty - 1;
                            });
                          }
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFD1D5DB),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.remove,
                        size: 16,
                        color: qty > 0
                            ? const Color(0xFF4B5563)
                            : const Color(0xFFD1D5DB),
                      ),
                    ),
                  ),
                  // 수량
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$qty',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  // 플러스 버튼
                  InkWell(
                    onTap: qty < option.totalStock
                        ? () {
                            setState(() {
                              _quantities[option.id] = qty + 1;
                            });
                          }
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '이 옵션은 최대 ${option.totalStock}개까지 선택 가능합니다.',
                                ),
                                backgroundColor: const Color(0xFFF59E0B),
                              ),
                            );
                          },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primary600,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 16,
                        color: AppColors.primary600,
                      ),
                    ),
                  ),
                ],
              ),
              // 금액
              if (qty > 0)
                Text(
                  '${FormatUtils.formatCurrency(option.price * qty)}원',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: const Color(0xFF111827),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
