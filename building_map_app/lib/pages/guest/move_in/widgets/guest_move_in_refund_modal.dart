import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/guest_move_in/guest_move_in.dart';
import '../../../../models/move_in/move_in_refund_policy.dart';
import '../utils/guest_move_in_format.dart';

/// 입주용품/침구류 옵션 취소·반품 모달 (계약관리 CancelOptionModal 과 동일 UX)
///
/// - [결제 취소] 탭: 수량 단위 부분 취소 → 즉시 PG 환불
/// - [반품 신청] 탭: 수량 단위 부분 반품 → 관리자 승인 대기
///
/// 잔액 최소금액 가드 없음 — 0원(전량 취소) 허용.
class GuestMoveInRefundModal extends StatefulWidget {
  final GuestMoveInOrder order;

  /// 케이스 입주/퇴실일 — 정책 시점 판정용 ('YYYY-MM-DD')
  final DateTime checkInDate;
  final DateTime checkOutDate;

  /// (orderDbId, items) → 취소 결과. null 이면 실패(부모가 에러 표시).
  final Future<GuestOrderRefundResponse?> Function(
    int orderDbId,
    String reason,
    List<GuestRefundItem> items,
  ) onCancel;

  /// (orderDbId, items) → 반품 요청 결과.
  final Future<GuestReturnRequestResponse?> Function(
    int orderDbId,
    String reason,
    List<GuestReturnItem> items,
  ) onReturn;

  const GuestMoveInRefundModal({
    super.key,
    required this.order,
    required this.checkInDate,
    required this.checkOutDate,
    required this.onCancel,
    required this.onReturn,
  });

  @override
  State<GuestMoveInRefundModal> createState() => _GuestMoveInRefundModalState();
}

class _GuestMoveInRefundModalState extends State<GuestMoveInRefundModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// itemId → 선택 수량 (0 = 미선택)
  final Map<int, int> _cancelQty = {};
  final Map<int, int> _returnQty = {};
  bool _processing = false;

  GuestMoveInOrder get _order => widget.order;

  List<GuestMoveInOrderItem> get _activeItems => _order.items
      .where((i) => i.status == OrderItemStatus.active)
      .toList();

  bool get _cancelEnabled => MoveInRefundPolicy.canCancelOrder(
        checkInDate: widget.checkInDate,
        isPaid: _order.status == GuestOrderStatus.paid ||
            _order.status == GuestOrderStatus.partialRefund,
        isDeliveryPending:
            _order.deliveryStatus == DeliveryStatus.pending,
      );

  bool get _returnEnabled => MoveInRefundPolicy.canRequestReturn(
        checkInDate: widget.checkInDate,
        checkOutDate: widget.checkOutDate,
        isDelivered:
            _order.deliveryStatus == DeliveryStatus.delivered,
      );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (!_cancelEnabled && _returnEnabled) _tabController.index = 1;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _selectedTotal(Map<int, int> sel) {
    int total = 0;
    for (final item in _activeItems) {
      final q = sel[item.itemId] ?? 0;
      if (q > 0) total += item.pricePerItem * q;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Dialog(
      insetPadding: isMobile
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 24)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Text('옵션 상품 취소/반품',
                      style: AppTextStyles.labelLarge
                          .copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: [
                _tab('결제 취소', _cancelEnabled),
                _tab('반품 신청', _returnEnabled),
              ],
              labelColor: AppColors.primary600,
              unselectedLabelColor: AppColors.neutral400,
              indicatorColor: AppColors.primary600,
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCancelTab(),
                  _buildReturnTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, bool enabled) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (!enabled) ...[
            const SizedBox(width: 4),
            Icon(Icons.lock_outline, size: 14, color: AppColors.neutral400),
          ],
        ],
      ),
    );
  }

  // ── 결제 취소 탭 ──────────────────────────────────────────

  Widget _buildCancelTab() {
    if (!_cancelEnabled) {
      return _disabledMsg(
          '결제 취소 가능한 시점이 아닙니다.\n(입주일 5일 전까지 전액, 이후 배송 전까지 가능)');
    }
    if (_activeItems.isEmpty) {
      return _disabledMsg('취소 가능한 상품이 없습니다.');
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _orderHeader(),
              const SizedBox(height: 8),
              ..._activeItems.map((item) => _quantityRow(
                    item: item,
                    qty: _cancelQty[item.itemId] ?? 0,
                    maxQuantity: item.quantity,
                    onChanged: (q) =>
                        setState(() => _cancelQty[item.itemId] = q),
                  )),
              const SizedBox(height: 12),
              _infoBox(
                '결제 취소 시 선택한 수량만큼 즉시 환불됩니다. '
                '결제수단에 따라 환불까지 영업일 기준 최대 5일이 소요될 수 있습니다.',
              ),
            ],
          ),
        ),
        _footer(
          selectedCount: _cancelQty.values.where((q) => q > 0).length,
          total: _selectedTotal(_cancelQty),
          actionLabel: '결제 취소',
          onSubmit: _submitCancel,
        ),
      ],
    );
  }

  Future<void> _submitCancel() async {
    final items = _cancelQty.entries
        .where((e) => e.value > 0)
        .map((e) => GuestRefundItem(itemId: e.key, cancelQuantity: e.value))
        .toList();
    if (items.isEmpty) return;

    setState(() => _processing = true);
    final result =
        await widget.onCancel(_order.orderDbId, '', items);
    if (!mounted) return;
    setState(() => _processing = false);
    if (result != null) Navigator.of(context).pop(true);
  }

  // ── 반품 신청 탭 ──────────────────────────────────────────

  Widget _buildReturnTab() {
    if (!_returnEnabled) {
      return _disabledMsg(
          '반품 가능한 시점이 아닙니다.\n(입주일~퇴실일 + 배송 완료 상태에서만 가능)');
    }
    if (_activeItems.isEmpty) {
      return _disabledMsg('반품 가능한 상품이 없습니다.');
    }
    final allExhausted =
        _activeItems.every((i) => i.returnableQuantity <= 0);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_order.hasPendingReturn) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    allExhausted
                        ? '이미 반품 요청한 상품입니다. 관리자 승인 후 환불 처리됩니다.'
                        : '일부 상품은 반품 요청이 진행 중입니다. 남은 수량만 추가로 반품할 수 있습니다.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _orderHeader(),
              const SizedBox(height: 8),
              ..._activeItems.map((item) => _quantityRow(
                    item: item,
                    qty: _returnQty[item.itemId] ?? 0,
                    maxQuantity: item.returnableQuantity,
                    exhaustedLabel: '반품 진행 중',
                    onChanged: (q) =>
                        setState(() => _returnQty[item.itemId] = q),
                  )),
              const SizedBox(height: 12),
              _infoBox(
                '반품 요청은 관리자 승인 후 처리됩니다. 승인 시 왕복배송비 '
                '${GuestMoveInFormat.formatPrice(MoveInRefundPolicy.returnShippingFee)}'
                '가 차감된 금액이 환불됩니다.',
              ),
            ],
          ),
        ),
        _footer(
          selectedCount: _returnQty.values.where((q) => q > 0).length,
          total: _selectedTotal(_returnQty),
          actionLabel: '반품 신청',
          onSubmit: _submitReturn,
          totalLabel: '반품 상품 금액',
        ),
      ],
    );
  }

  Future<void> _submitReturn() async {
    final items = _returnQty.entries
        .where((e) => e.value > 0)
        .map((e) => GuestReturnItem(itemId: e.key, returnQuantity: e.value))
        .toList();
    if (items.isEmpty) return;

    setState(() => _processing = true);
    final result =
        await widget.onReturn(_order.orderDbId, '', items);
    if (!mounted) return;
    setState(() => _processing = false);
    if (result != null) Navigator.of(context).pop(true);
  }

  // ── 공통 행/푸터 ──────────────────────────────────────────

  Widget _orderHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            '주문 #${_order.orderId}',
            style:
                AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _order.deliveryStatus.label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// [maxQuantity] 선택 가능한 최대 수량 (취소=item.quantity,
  /// 반품=returnableQuantity). 0 이면 진행 중 안내 행으로 대체.
  Widget _quantityRow({
    required GuestMoveInOrderItem item,
    required int qty,
    required int maxQuantity,
    required ValueChanged<int> onChanged,
    String exhaustedLabel = '선택 불가',
  }) {
    if (maxQuantity <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const SizedBox(width: 40),
            Expanded(
              child: Text(
                item.name ?? '옵션',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neutral400,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.neutral300),
              ),
              child: Text(
                exhaustedLabel,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  color: AppColors.neutral500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final selected = qty > 0;
    final isMultiple = maxQuantity > 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => onChanged(v == true ? maxQuantity : 0),
            activeColor: AppColors.primary600,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Expanded(
            child: Text(
              item.name ?? '옵션',
              style: AppTextStyles.bodySmall.copyWith(
                color: selected ? null : AppColors.neutral400,
              ),
            ),
          ),
          if (isMultiple) ...[
            if (selected)
              _QuantitySpinner(
                value: qty,
                min: 1,
                max: maxQuantity,
                onChanged: onChanged,
              )
            else
              Text(
                '$maxQuantity개',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.neutral400),
              ),
            const SizedBox(width: 8),
          ],
          Text(
            GuestMoveInFormat.formatPrice(
              item.pricePerItem * (selected ? qty : maxQuantity),
            ),
            style: AppTextStyles.bodySmall.copyWith(
              color: selected
                  ? AppColors.textPrimary
                  : AppColors.neutral400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary100),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: AppColors.primary700),
      ),
    );
  }

  Widget _footer({
    required int selectedCount,
    required int total,
    required String actionLabel,
    required VoidCallback onSubmit,
    String totalLabel = '환불 예정',
  }) {
    final hasSelected = selectedCount > 0;
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
                  '$selectedCount개 품목 선택됨',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.neutral600),
                ),
                if (hasSelected)
                  Text(
                    '$totalLabel: ${GuestMoveInFormat.formatPrice(total)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary600,
                    ),
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
            onPressed:
                (hasSelected && !_processing) ? onSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              disabledBackgroundColor: AppColors.neutral300,
            ),
            child: _processing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(actionLabel,
                    style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _disabledMsg(String msg) {
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
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.neutral500),
            ),
          ],
        ),
      ),
    );
  }
}

/// 수량 증감 스피너 (계약관리와 동일 디자인)
class _QuantitySpinner extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _QuantitySpinner({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(Icons.remove, value > min, () => onChanged(value - 1)),
        Container(
          constraints: const BoxConstraints(minWidth: 28),
          alignment: Alignment.center,
          child: Text(
            '$value / $max',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.neutral700),
          ),
        ),
        _btn(Icons.add, value < max, () => onChanged(value + 1)),
      ],
    );
  }

  Widget _btn(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled ? AppColors.neutral300 : AppColors.neutral200,
          ),
          borderRadius: BorderRadius.circular(4),
          color: enabled ? Colors.white : AppColors.neutral100,
        ),
        child: Icon(icon,
            size: 14,
            color: enabled ? AppColors.neutral700 : AppColors.neutral300),
      ),
    );
  }
}
