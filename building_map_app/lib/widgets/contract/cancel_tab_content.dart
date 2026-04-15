import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/notice_texts.dart';
import '../../core/exceptions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/rental_order_service.dart';
import '../../utils/format_utils.dart';
import '../../utils/price_calculator.dart';
import '../../widgets/modals/option_refund_modal.dart';
import 'guest_contract_dialogs.dart';
import 'order_item_rows.dart';

/// 결제취소 탭 독립 위젯
/// - 아이템별 취소 수량을 Map<itemId, cancelQuantity>로 관리
/// - quantity > 1 이면 수량 스피너 표시, 부분 취소 가능
/// - 제출 완료 시 [onComplete] 콜백으로 부모에 통보
class CancelTabContent extends StatefulWidget {
  final bool enabled;
  final List<RentalOrder> cancelableOrders;
  final int contractId;
  final Future<RentalItemCancelResponse> Function(
    int contractId,
    List<RentalItemCancelRequest> items,
    String reason,
  ) onCancelItems;
  final VoidCallback onComplete;

  const CancelTabContent({
    super.key,
    required this.enabled,
    required this.cancelableOrders,
    required this.contractId,
    required this.onCancelItems,
    required this.onComplete,
  });

  @override
  State<CancelTabContent> createState() => _CancelTabContentState();
}

class _CancelTabContentState extends State<CancelTabContent> {
  /// key: item.id, value: 취소할 수량 (0 = 선택 안 함)
  final Map<int, int> _cancelQuantities = {};
  bool _isProcessing = false;

  // ── 금액 계산 ──────────────────────────────────────────

  /// 선택된 취소 총액 (cancelQuantity × pricePerItem)
  int get _selectedTotalAmount {
    int total = 0;
    for (final order in widget.cancelableOrders) {
      for (final item in order.items) {
        final qty = _cancelQuantities[item.id] ?? 0;
        if (qty > 0) total += item.price * qty;
      }
    }
    return total;
  }

  /// 전체 ACTIVE 아이템 총액
  int get _totalActiveAmount {
    int total = 0;
    for (final order in widget.cancelableOrders) {
      for (final item in order.items) {
        if (item.status == 'ACTIVE') {
          total += item.price * item.quantity;
        }
      }
    }
    return total;
  }

  /// 취소 후 잔액
  int get _remainingAmountAfterCancel =>
      _totalActiveAmount - _selectedTotalAmount;

  bool get _hasInvalidRemainingAmount =>
      PriceCalculator.isInvalidRentalAmount(_remainingAmountAfterCancel);

  /// 1개 이상 선택된 아이템이 있는지
  bool get _hasAnySelected =>
      _cancelQuantities.values.any((q) => q > 0);

  // ── 선택 헬퍼 ──────────────────────────────────────────

  /// 주문 내 ACTIVE 아이템 전체 선택 여부 (각 아이템이 quantity 전량 선택된 경우)
  bool _isOrderFullySelected(RentalOrder order) {
    final activeItems = order.items.where((i) => i.status == 'ACTIVE').toList();
    if (activeItems.isEmpty) return false;
    return activeItems.every(
      (i) => (_cancelQuantities[i.id] ?? 0) == i.quantity,
    );
  }

  void _selectAllInOrder(RentalOrder order, bool select) {
    setState(() {
      for (final item in order.items.where((i) => i.status == 'ACTIVE')) {
        _cancelQuantities[item.id] = select ? item.quantity : 0;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ── 빌드 ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final orders = widget.cancelableOrders;
    if (!widget.enabled || orders.isEmpty) {
      return _buildDisabledMsg(
          '결제 취소 가능한 주문이 없습니다.\n(결제 취소 가능한 상태의 주문만 표시됩니다.)');
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...orders.map((order) => _buildCancelOrderCard(order)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.blue50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.blue100),
                ),
                child: Text(
                  NoticeTexts.optionRefundBeforeDelivery,
                  style: AppTextStyles.caption.copyWith(color: AppColors.blue700),
                ),
              ),
            ],
          ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildCancelOrderCard(RentalOrder order) {
    final allSelected = _isOrderFullySelected(order);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OrderItemRows.orderCardHeader(
              order: order,
              allSelected: allSelected,
              onSelectAll: (v) => _selectAllInOrder(order, v == true),
            ),
            const SizedBox(height: 8),
            ...order.items
                .where((i) => i.status == 'ACTIVE')
                .map((item) => OrderItemRows.itemCancelQuantityRow(
                      item: item,
                      cancelQuantity: _cancelQuantities[item.id] ?? 0,
                      onQuantityChanged: (qty) {
                        setState(() => _cancelQuantities[item.id] = qty);
                      },
                    )),
            ...order.items
                .where((i) =>
                    i.status == 'CANCELLED' || i.status == 'REFUNDED')
                .map((item) => OrderItemRows.disabledItemRow(
                      item,
                      label: item.status == 'REFUNDED' ? '환불완료' : '취소완료',
                      badgeColor: DisabledItemBadgeColor.neutral,
                    )),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final selectedCount =
        _cancelQuantities.values.where((q) => q > 0).length;
    final totalAmount = _selectedTotalAmount;
    final invalidRemaining = _hasInvalidRemainingAmount;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.neutral200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (invalidRemaining) ...[
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.error50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error500),
              ),
              child: Text(
                PriceCalculator.rentalCancelRemainingErrorMessage(),
                style: AppTextStyles.caption.copyWith(color: AppColors.error700),
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$selectedCount개 품목 선택됨',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral600),
                    ),
                    if (_hasAnySelected)
                      Text(
                        '환불 예정: ${FormatUtils.formatCurrency(totalAmount)}원',
                        style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.blue600),
                      ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.neutral300),
                ),
                child: Text('닫기',
                    style: TextStyle(color: AppColors.neutral600)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: (_hasAnySelected &&
                        !_isProcessing &&
                        !invalidRemaining)
                    ? _submitCancelItems
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue600,
                  disabledBackgroundColor: AppColors.neutral300,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('결제 취소',
                        style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 제출 ───────────────────────────────────────────────

  Future<void> _submitCancelItems() async {
    if (!_hasAnySelected) return;

    final requestItems = _cancelQuantities.entries
        .where((e) => e.value > 0)
        .map((e) =>
            RentalItemCancelRequest(id: e.key, cancelQuantity: e.value))
        .toList();

    setState(() => _isProcessing = true);
    try {
      final result = await widget.onCancelItems(
        widget.contractId,
        requestItems,
        '',
      );
      if (!mounted) return;

      if (result.hasFailures) {
        final failMsg =
            result.failed.map((f) => '주문 #${f.orderId}: ${f.reason}').join('\n');
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('일부 취소 실패'),
            content: Text(
                '${result.succeeded.length}건 취소 완료, ${result.failed.length}건 실패\n\n$failMsg'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue600),
                child: const Text('확인',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } else {
        await showDialog(
          context: context,
          builder: (ctx) => OptionRefundModal(
            refundAmount: result.totalRefunded,
            onClose: () => Navigator.pop(ctx),
          ),
        );
      }
      if (mounted) widget.onComplete();
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) showErrorDialog(context, '결제 취소 중 오류가 발생했습니다.\n$e');
    }
  }

  Widget _buildDisabledMsg(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 36, color: AppColors.neutral400),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
            ),
          ],
        ),
      ),
    );
  }
}
