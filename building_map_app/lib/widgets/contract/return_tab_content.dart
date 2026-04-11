import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/notice_texts.dart';
import '../../core/exceptions.dart';
import '../../core/theme/app_colors.dart';
import '../../services/rental_order_service.dart';
import 'guest_contract_dialogs.dart';
import 'order_item_rows.dart';

/// 반품신청 탭 독립 위젯
/// - 선택 상태를 자체 관리
/// - 제출 완료 시 [onComplete] 콜백으로 부모에 통보
class ReturnTabContent extends StatefulWidget {
  final bool enabled;
  final List<RentalOrder> returnableOrders;
  final int contractId;
  final Future<void> Function(
    int contractId,
    List<int> itemIds,
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
  final Set<int> _selectedIds = {};
  final TextEditingController _reasonCtrl = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<ReturnPreviewResponse?> _fetchReturnPreview() async {
    if (_selectedIds.isEmpty) return null;
    try {
      return await widget.onGetReturnPreview(
        widget.contractId,
        _selectedIds.toList(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return _buildDisabledMsg('결제 완료 또는 입주 중 상태에서만 반품 신청이 가능합니다.');
    }
    final orders = widget.returnableOrders;
    if (orders.isEmpty) {
      return _buildDisabledMsg('반품 가능한 주문이 없습니다.\n(배송 중 또는 배송 완료 상태의 주문만 표시됩니다.)');
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
    final activeItems = order.items
        .where((i) => i.status == 'ACTIVE')
        .toList();
    final requestedItems = order.items
        .where((i) => i.status == 'CANCEL_REQUESTED')
        .toList();

    final allActiveIds = activeItems.map((i) => i.id).toList();
    final allSelected =
        allActiveIds.isNotEmpty && allActiveIds.every(_selectedIds.contains);

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
                    _selectedIds.addAll(allActiveIds);
                  } else {
                    _selectedIds.removeAll(allActiveIds);
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            ...activeItems.map((item) => OrderItemRows.itemCheckRow(
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
            ...requestedItems.map((item) => OrderItemRows.disabledItemRow(item)),
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
    final selectedCount = _selectedIds.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          Text(
            '$selectedCount개 선택됨',
            style: TextStyle(
                fontSize: 13, color: AppColors.neutral600),
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
            onPressed:
                (selectedCount > 0 && !_isProcessing)
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

  Future<void> _submitReturnRequest() async {
    if (_selectedIds.isEmpty) return;
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
                disabledBackgroundColor: AppColors.neutral300,
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

      await widget.onReturnRequest(
        widget.contractId,
        _selectedIds.toList(),
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
      if (mounted) {
        widget.onComplete();
      }
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
