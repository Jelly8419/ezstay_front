import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/contract.dart';
import '../../utils/format_utils.dart';

/// 옵션 상품 섹션
///
/// 계약 카드 내 옵션 상품 목록, 편집 UI, 금액 요약을 표시합니다.
class ContractOptionsSection extends StatelessWidget {
  final ContractListItem contract;
  final bool isEditing;
  final List<RentalItem> currentOptions;
  final bool canEdit;
  final bool canAddOption;
  final bool isAfterPayment;
  final List<OptionChange> changes;
  final int totalDiff;
  final VoidCallback onEditButtonClick;
  final VoidCallback onShowAddOptionModal;
  final VoidCallback onShowCancelOptionModal;
  final void Function(int contractId, String itemId, int delta)
      onOptionQuantityChange;
  final VoidCallback onSaveOptionChanges;
  final VoidCallback onCancelOptionChanges;
  final int Function(int contractId, String itemName) getOriginalQuantity;

  const ContractOptionsSection({
    super.key,
    required this.contract,
    required this.isEditing,
    required this.currentOptions,
    required this.canEdit,
    required this.canAddOption,
    required this.isAfterPayment,
    required this.changes,
    required this.totalDiff,
    required this.onEditButtonClick,
    required this.onShowAddOptionModal,
    required this.onShowCancelOptionModal,
    required this.onOptionQuantityChange,
    required this.onSaveOptionChanges,
    required this.onCancelOptionChanges,
    required this.getOriginalQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 옵션 상품 + 버튼들
          _buildHeader(context),
          const SizedBox(height: 12),

          // 옵션 목록
          if (currentOptions
                  .where((item) => item.quantity > 0 || isEditing)
                  .isEmpty &&
              !isEditing)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '선택한 옵션이 없습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            )
          else
            ...currentOptions
                .where((item) => item.quantity > 0 || isEditing)
                .map((item) => _OptionItemTile(
                      contract: contract,
                      item: item,
                      isEditing: isEditing,
                      isAfterPayment: isAfterPayment,
                      originalQuantity:
                          getOriginalQuantity(contract.id, item.name),
                      onQuantityChange: (delta) =>
                          onOptionQuantityChange(contract.id, item.id, delta),
                    )),

          // 총 금액 변동 요약 (편집 모드)
          if (isEditing && totalDiff != 0) ...[
            const SizedBox(height: 16),
            _buildTotalDiffSummary(),
          ],

          // 버튼 영역 (편집 모드)
          if (isEditing) ...[
            const SizedBox(height: 16),
            _buildEditButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Text(
          '옵션 상품',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        // 결제 전 상태: 옵션 추가 및 변경 버튼
        if (canEdit && !isEditing && !isAfterPayment) ...[
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onEditButtonClick,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              side: const BorderSide(color: AppColors.primary600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '옵션 추가 및 변경',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary600,
              ),
            ),
          ),
        ],
        // 결제 후 상태: ���가 + 취소 버튼 분리
        if (canEdit && !isEditing && isAfterPayment) ...[
          const Spacer(),
          OutlinedButton(
            onPressed: () {
              if (!canAddOption) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('알림'),
                    content: const Text(
                      '계약 시작일의 5일 전부터는 옵션을 추가할 수 없습니다.',
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary600,
                        ),
                        child: const Text(
                          '확인',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
                return;
              }
              onShowAddOptionModal();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              side: const BorderSide(color: AppColors.primary600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '추가',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onShowCancelOptionModal,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '취소',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTotalDiffSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: totalDiff > 0
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: totalDiff > 0
              ? const Color(0xFFDBEAFE)
              : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            totalDiff > 0
                ? '총 추가금액'
                : (contract.status == ContractStatus.paymentCompleted
                      ? '총 환불받을 금액'
                      : '총 차감할 금액'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          Text(
            '${totalDiff > 0 ? '+' : ''}${FormatUtils.formatCurrency(totalDiff.abs())}원',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: totalDiff > 0
                  ? AppColors.primary600
                  : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancelOptionChanges,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(
                color: Color(0xFFD1D5DB),
                width: 2,
              ),
            ),
            child: const Text(
              '취소',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: changes.isEmpty ? null : onSaveOptionChanges,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: changes.isEmpty
                  ? const Color(0xFFD1D5DB)
                  : AppColors.primary600,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFD1D5DB),
              disabledForegroundColor: const Color(0xFF6B7280),
            ),
            child: Text(
              (contract.status == ContractStatus.paymentCompleted ||
                      contract.status == ContractStatus.inProgress)
                  ? '추가 결제'
                  : '저장',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 옵션 아이템 타일
class _OptionItemTile extends StatelessWidget {
  final ContractListItem contract;
  final RentalItem item;
  final bool isEditing;
  final bool isAfterPayment;
  final int originalQuantity;
  final void Function(int delta) onQuantityChange;

  const _OptionItemTile({
    required this.contract,
    required this.item,
    required this.isEditing,
    required this.isAfterPayment,
    required this.originalQuantity,
    required this.onQuantityChange,
  });

  @override
  Widget build(BuildContext context) {
    final qtyDiff = item.quantity - originalQuantity;
    final diffPrice = qtyDiff * item.price;

    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상품명과 설명
          Row(
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              if (isEditing) ...[
                const SizedBox(width: 8),
                Text(
                  '(개당 ${FormatUtils.formatCurrency(item.price)}원)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primary600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          if (item.description != null && item.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.description!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],

          // 수량 조절 또는 가격 정보
          if (isEditing) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 수량 조절
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // 마이너스 버튼
                        Builder(
                          builder: (context) {
                            final minQty = isAfterPayment ? originalQuantity : 0;
                            final canDecrease = item.quantity > minQty;

                            return InkWell(
                              onTap: canDecrease
                                  ? () => onQuantityChange(-1)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: canDecrease
                                        ? const Color(0xFFD1D5DB)
                                        : const Color(0xFFE5E7EB),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: canDecrease
                                      ? Colors.white
                                      : const Color(0xFFF9FAFB),
                                ),
                                child: Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: canDecrease
                                      ? const Color(0xFF374151)
                                      : const Color(0xFFD1D5DB),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),

                        // 수량 표시
                        SizedBox(
                          width: 32,
                          child: Center(
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 플러스 버튼 (품목별 최대 5개)
                        Builder(
                          builder: (context) {
                            final canIncrease = item.quantity < 5;
                            return InkWell(
                              onTap: canIncrease
                                  ? () => onQuantityChange(1)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: canIncrease
                                        ? AppColors.primary600
                                        : const Color(0xFFE5E7EB),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: canIncrease
                                      ? Colors.white
                                      : const Color(0xFFF9FAFB),
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 16,
                                  color: canIncrease
                                      ? AppColors.primary600
                                      : const Color(0xFFD1D5DB),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    // 수량 차이 표시
                    if (qtyDiff > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '이전 수량에서 +$qtyDiff개',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else if (qtyDiff < 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '이전 수량에서 $qtyDiff개',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else if (item.quantity > 0) ...[
                      const SizedBox(height: 4),
                      const Text(
                        '이전 수량에서 변동 없음',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),

                // 가격 표시
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${FormatUtils.formatCurrency(item.price * item.quantity)}원',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (qtyDiff > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '(+${FormatUtils.formatCurrency(diffPrice)}원)',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else if (qtyDiff < 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '(${FormatUtils.formatCurrency(diffPrice)}원)',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFFDC2626),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ] else if (item.quantity > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${FormatUtils.formatCurrency(item.price)}원 × ${item.quantity}개 = ${FormatUtils.formatCurrency(item.price * item.quantity)}원',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
