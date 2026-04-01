import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/notice_texts.dart';
import '../../core/exceptions.dart';
import '../../core/theme/app_colors.dart';
import '../../services/rental_order_service.dart';
import '../../utils/format_utils.dart';
import '../../widgets/modals/option_refund_modal.dart';
import 'guest_contract_dialogs.dart';
import 'order_item_rows.dart';

/// 결제취소 탭 독립 위젯
/// - 선택 상태를 자체 관리
/// - 제출 완료 시 [onComplete] 콜백으로 부모에 통보
class CancelTabContent extends StatefulWidget {
  final bool enabled;
  final List<RentalOrder> cancelableOrders;
  final int contractId;
  final Future<RentalItemCancelResponse> Function(
    int contractId,
    List<int> itemIds,
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
  final Set<int> _selectedIds = {};
  final TextEditingController _reasonCtrl = TextEditingController();
  bool _isProcessing = false;

  int get _selectedTotalAmount {
    int total = 0;
    for (final order in widget.cancelableOrders) {
      for (final item in order.items) {
        if (_selectedIds.contains(item.id)) {
          total += item.price * item.quantity;
        }
      }
    }
    return total;
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return _buildDisabledMsg('결제 완료 상태에서만 결제 취소가 가능합니다.');
    }
    final orders = widget.cancelableOrders;
    if (orders.isEmpty) {
      return _buildDisabledMsg('취소 가능한 주문이 없습니다.\n(배송 전 상태의 주문만 취소 가능)');
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...orders.map((order) => _buildCancelOrderCard(order)),
              const SizedBox(height: 8),
              const Text('취소 사유 (선택)',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: '취소 사유를 입력해 주세요. (선택)',
                  hintStyle:
                      TextStyle(fontSize: 13, color: AppColors.neutral400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.neutral300),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
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
                  style: TextStyle(fontSize: 12, color: AppColors.blue700),
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
    final allItemIds = order.items
        .where((i) => i.status == 'ACTIVE')
        .map((i) => i.id)
        .toList();
    final allSelected =
        allItemIds.isNotEmpty && allItemIds.every(_selectedIds.contains);
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
              onSelectAll: (v) {
                setState(() {
                  if (v == true) {
                    _selectedIds.addAll(allItemIds);
                  } else {
                    _selectedIds.removeAll(allItemIds);
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            ...order.items
                .where((i) => i.status == 'ACTIVE')
                .map((item) => OrderItemRows.itemCheckRow(
                      item: item,
                      selected: _selectedIds.contains(item.id),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedIds.add(item.id);
                          } else {
                            _selectedIds.remove(item.id);
                          }
                        });
                      },
                    )),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final selectedCount = _selectedIds.length;
    final totalAmount = _selectedTotalAmount;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$selectedCount개 선택됨',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.neutral600),
                ),
                if (selectedCount > 0)
                  Text(
                    '환불 예정: ${FormatUtils.formatCurrency(totalAmount)}원',
                    style: const TextStyle(
                        fontSize: 13,
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
            onPressed: (selectedCount > 0 && !_isProcessing)
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
    );
  }

  Future<void> _submitCancelItems() async {
    if (_selectedIds.isEmpty) return;
    setState(() => _isProcessing = true);
    try {
      final result = await widget.onCancelItems(
        widget.contractId,
        _selectedIds.toList(),
        _reasonCtrl.text.trim(),
      );
      if (!mounted) return;
      if (result.hasFailures) {
        final failMsg = result.failed
            .map((f) => '주문 #${f.orderId}: ${f.reason}')
            .join('\n');
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
      if (mounted) {
        widget.onComplete();
        Navigator.of(context).pop();
      }
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
              style: TextStyle(fontSize: 14, color: AppColors.neutral500),
            ),
          ],
        ),
      ),
    );
  }
}
