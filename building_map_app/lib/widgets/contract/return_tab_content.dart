import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/notice_texts.dart';
import '../../core/exceptions.dart';
import '../../core/theme/app_colors.dart';
import '../../services/rental_order_service.dart';
import 'guest_contract_dialogs.dart';
import 'order_item_rows.dart';

/// 반품신청 탭 독립 위젯
/// - 아이템별 반품 수량을 Map<itemId, returnQuantity>로 관리
/// - quantity > 1 이면 수량 스피너 표시, 부분 반품 가능
/// - 제출 완료 시 [onComplete] 콜백으로 부모에 통보
class ReturnTabContent extends StatefulWidget {
  final bool enabled;
  final List<RentalOrder> returnableOrders;
  final int contractId;
  final Future<void> Function(
    int contractId,
    List<RentalItemReturnRequest> items,
    String reason,
  ) onReturnRequest;
  final Future<ReturnPreviewResponse> Function(
    int contractId,
    List<int> itemIds,
  ) onGetReturnPreview;
  final VoidCallback onComplete;

  const ReturnTabContent({
    super.key,
    required this.enabled,
    required this.returnableOrders,
    required this.contractId,
    required this.onReturnRequest,
    required this.onGetReturnPreview,
    required this.onComplete,
  });

  @override
  State<ReturnTabContent> createState() => _ReturnTabContentState();
}

class _ReturnTabContentState extends State<ReturnTabContent> {
  /// key: item.id, value: 반품할 수량 (0 = 선택 안 함)
  final Map<int, int> _returnQuantities = {};
  final TextEditingController _reasonCtrl = TextEditingController();
  bool _isProcessing = false;

  // ── 헬퍼 ───────────────────────────────────────────────

  bool get _hasAnySelected =>
      _returnQuantities.values.any((q) => q > 0);

  bool _isOrderFullySelected(RentalOrder order) {
    final activeItems = order.items.where((i) => i.status == 'ACTIVE').toList();
    if (activeItems.isEmpty) return false;
    return activeItems.every(
      (i) => (_returnQuantities[i.id] ?? 0) == i.quantity,
    );
  }

  void _selectAllInOrder(RentalOrder order, bool select) {
    setState(() {
      for (final item in order.items.where((i) => i.status == 'ACTIVE')) {
        _returnQuantities[item.id] = select ? item.quantity : 0;
      }
    });
  }

  /// 선택된 아이템 ID 목록 (preview 조회용 — 전체 수량 선택 여부 무관하게 id만 전달)
  List<int> get _selectedItemIds => _returnQuantities.entries
      .where((e) => e.value > 0)
      .map((e) => e.key)
      .toList();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<ReturnPreviewResponse?> _fetchReturnPreview() async {
    if (!_hasAnySelected) return null;
    try {
      return await widget.onGetReturnPreview(
        widget.contractId,
        _selectedItemIds,
      );
    } catch (_) {
      return null;
    }
  }

  // ── 빌드 ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return _buildDisabledMsg('결제 완료 또는 입주 중 상태에서만 반품 신청이 가능합니다.');
    }
    final orders = widget.returnableOrders;
    if (orders.isEmpty) {
      return _buildDisabledMsg(
          '반품 가능한 주문이 없습니다.\n(배송 중 또는 배송 완료 상태의 주문만 표시됩니다.)');
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...orders.map((order) => _buildReturnOrderCard(order)),
              const SizedBox(height: 8),
              const Text('반품 사유',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '반품 사유를 입력해 주세요.',
                  hintStyle:
                      TextStyle(fontSize: 13, color: AppColors.neutral400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.neutral300),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning500),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ${NoticeTexts.optionRefundWithin7Days}',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.warning700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• ${NoticeTexts.optionRefundRestrictions}',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.warning700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• ${NoticeTexts.optionReturnShippingFeeNotice}',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.warning700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• ${NoticeTexts.optionReturnRequestAdminConfirm}',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.warning700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildReturnOrderCard(RentalOrder order) {
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
                      cancelQuantity: _returnQuantities[item.id] ?? 0,
                      onQuantityChanged: (qty) {
                        setState(() => _returnQuantities[item.id] = qty);
                      },
                    )),
            ...order.items
                .where((i) => i.status == 'CANCEL_REQUESTED')
                .map((item) => OrderItemRows.disabledItemRow(item)),
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
        _returnQuantities.values.where((q) => q > 0).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          Text(
            '$selectedCount개 품목 선택됨',
            style: TextStyle(fontSize: 13, color: AppColors.neutral600),
          ),
          const Spacer(),
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
            onPressed: (_hasAnySelected && !_isProcessing)
                ? _submitReturnRequest
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning600,
              disabledBackgroundColor: AppColors.neutral300,
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('반품 신청',
                    style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── 제출 ───────────────────────────────────────────────

  Future<void> _submitReturnRequest() async {
    if (!_hasAnySelected) return;
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('반품 사유 필요'),
          content: const Text('반품 사유를 입력해 주세요.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning600),
              child: const Text('확인',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }
    setState(() => _isProcessing = true);

    try {
      final preview = await _fetchReturnPreview();
      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('반품 신청 확인'),
          content: buildReturnPreviewConfirmContent(preview),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.neutral300),
              ),
              child: Text('취소',
                  style: TextStyle(color: AppColors.neutral600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning600,
              ),
              child: const Text('반품 신청',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) {
        setState(() => _isProcessing = false);
        return;
      }

      final requestItems = _returnQuantities.entries
          .where((e) => e.value > 0)
          .map((e) =>
              RentalItemReturnRequest(id: e.key, returnQuantity: e.value))
          .toList();

      await widget.onReturnRequest(
        widget.contractId,
        requestItems,
        reason,
      );
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('반품 신청 완료'),
          content: const Text(
              '반품 신청이 접수되었습니다.\n실제 환불 금액은 관리자 처리 후 최종 확정됩니다.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning600),
              child: const Text('확인',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (mounted) widget.onComplete();
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) showErrorDialog(context, '반품 신청 중 오류가 발생했습니다.\n$e');
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
