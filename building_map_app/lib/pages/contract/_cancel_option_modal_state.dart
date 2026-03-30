part of 'guest_contracts_page.dart';

class _CancelOptionModalState extends State<_CancelOptionModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 탭 인덱스
  static const _tabCancel = 0;
  static const _tabReturn = 1;

  // 결제취소 탭: 선택된 아이템 id set + 사유
  final Set<int> _selectedCancelIds = {};
  final TextEditingController _cancelReasonCtrl = TextEditingController();

  // 반품신청 탭: 선택된 아이템 id set + 사유
  final Set<int> _selectedReturnIds = {};
  final TextEditingController _returnReasonCtrl = TextEditingController();

  bool _isProcessing = false;

  // 탭 활성화 여부
  bool get _isCancelTabEnabled =>
      widget.contract.status == ContractStatus.paymentCompleted;

  bool get _isReturnTabEnabled =>
      widget.contract.status == ContractStatus.paymentCompleted ||
      widget.contract.status == ContractStatus.inProgress;

  // 결제취소 탭에 표시할 주문 (PAID이고 PENDING 아이템 보유)
  List<RentalOrder> get _cancelableOrders => widget.orders
      .where((o) => o.status == 'PAID' && o.deliveryStatus == 'PENDING')
      .toList();

  // 반품신청 탭에 표시할 주문 (IN_TRANSIT or DELIVERED 아이템 보유)
  List<RentalOrder> get _returnableOrders => widget.orders
      .where((o) =>
          o.status == 'PAID' &&
          (o.deliveryStatus == 'IN_TRANSIT' ||
              o.deliveryStatus == 'DELIVERED'))
      .toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 결제취소 탭 비활성이면 반품신청 탭으로 초기 이동
    if (!_isCancelTabEnabled && _isReturnTabEnabled) {
      _tabController.index = _tabReturn;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cancelReasonCtrl.dispose();
    _returnReasonCtrl.dispose();
    super.dispose();
  }

  // ── 배송 상태 헬퍼 ────────────────────────────────────────────
  String _deliveryLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return '배송 전';
      case 'IN_TRANSIT':
        return '배송 중';
      case 'DELIVERED':
        return '배송 완료';
      default:
        return '배송 전';
    }
  }

  Color _deliveryBgColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return AppColors.blue50;
      case 'IN_TRANSIT':
        return AppColors.warning50;
      case 'DELIVERED':
        return AppColors.success50;
      default:
        return AppColors.neutral50;
    }
  }

  Color _deliveryTextColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return AppColors.blue700;
      case 'IN_TRANSIT':
        return AppColors.warning700;
      case 'DELIVERED':
        return AppColors.success700;
      default:
        return AppColors.neutral500;
    }
  }

  Color _deliveryBorderColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return AppColors.primary200;
      case 'IN_TRANSIT':
        return AppColors.warning500;
      case 'DELIVERED':
        return AppColors.success100;
      default:
        return AppColors.neutral200;
    }
  }

  // ── 반품 탭: 현재 선택 중인 주문 ID (주문 혼합 방지) ──────────
  int? get _selectedReturnOrderId {
    if (_selectedReturnIds.isEmpty) return null;
    for (final order in _returnableOrders) {
      if (order.items.any((i) => _selectedReturnIds.contains(i.id))) {
        return order.id;
      }
    }
    return null;
  }

  // ── 결제취소 탭: 선택된 아이템 총 금액 ────────────────────────
  int get _selectedCancelTotalAmount {
    int total = 0;
    for (final order in _cancelableOrders) {
      for (final item in order.items) {
        if (_selectedCancelIds.contains(item.id)) {
          total += item.price * item.quantity;
        }
      }
    }
    return total;
  }

  // ── preview 조회 (반품 신청 버튼 클릭 시 호출) ─────────────────
  Future<ReturnPreviewResponse?> _fetchReturnPreview() async {
    if (_selectedReturnIds.isEmpty) return null;
    try {
      return await widget.onGetReturnPreview(
        widget.contract.id,
        _selectedReturnIds.toList(),
      );
    } catch (_) {
      return null;
    }
  }

  // ── build ─────────────────────────────────────────────────────
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
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  const Text('옵션 상품 취소/반품',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // 탭 바
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('결제 취소'),
                      if (!_isCancelTabEnabled)
                        const SizedBox(width: 4),
                      if (!_isCancelTabEnabled)
                        Icon(Icons.lock_outline, size: 14,
                            color: AppColors.neutral400),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('반품 신청'),
                      if (!_isReturnTabEnabled)
                        const SizedBox(width: 4),
                      if (!_isReturnTabEnabled)
                        Icon(Icons.lock_outline, size: 14,
                            color: AppColors.neutral400),
                    ],
                  ),
                ),
              ],
              labelColor: AppColors.blue600,
              unselectedLabelColor: AppColors.neutral400,
              indicatorColor: AppColors.blue600,
            ),
            const Divider(height: 1),
            // 탭 뷰
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

  // ── 결제취소 탭 ───────────────────────────────────────────────
  Widget _buildCancelTab() {
    if (!_isCancelTabEnabled) {
      return _buildDisabledMsg('결제 완료 상태에서만 결제 취소가 가능합니다.');
    }
    final orders = _cancelableOrders;
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
              // 취소 사유 (선택)
              const Text('취소 사유 (선택)',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _cancelReasonCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: '취소 사유를 입력해 주세요. (선택)',
                  hintStyle:
                      TextStyle(fontSize: 13, color: AppColors.neutral400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: AppColors.neutral300),
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
                  style: TextStyle(
                      fontSize: 12, color: AppColors.blue700),
                ),
              ),
            ],
          ),
        ),
        _buildCancelFooter(),
      ],
    );
  }

  Widget _buildCancelOrderCard(RentalOrder order) {
    final allItemIds = order.items
        .where((i) => i.status == 'ACTIVE')
        .map((i) => i.id)
        .toList();
    final allSelected =
        allItemIds.isNotEmpty && allItemIds.every(_selectedCancelIds.contains);
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
            _buildOrderCardHeader(
              order: order,
              allSelected: allSelected,
              onSelectAll: (v) {
                setState(() {
                  if (v == true) {
                    _selectedCancelIds.addAll(allItemIds);
                  } else {
                    _selectedCancelIds.removeAll(allItemIds);
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            ...order.items
                .where((i) => i.status == 'ACTIVE')
                .map((item) => _buildItemCheckRow(
                      item: item,
                      selected: _selectedCancelIds.contains(item.id),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedCancelIds.add(item.id);
                          } else {
                            _selectedCancelIds.remove(item.id);
                          }
                        });
                      },
                    )),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelFooter() {
    final selectedCount = _selectedCancelIds.length;
    final totalAmount = _selectedCancelTotalAmount;
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
                    '환불 예정: ${_formatAmount(totalAmount)}원',
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

  // ── 반품신청 탭 ───────────────────────────────────────────────
  Widget _buildReturnTab() {
    if (!_isReturnTabEnabled) {
      return _buildDisabledMsg('결제 완료 또는 입주 중 상태에서만 반품 신청이 가능합니다.');
    }
    final orders = _returnableOrders;
    if (orders.isEmpty) {
      return _buildDisabledMsg('반품 가능한 주문이 없습니다.\n(배송 중 또는 배송 완료 상태의 주문만 반품 가능)');
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...orders.map((order) => _buildReturnOrderCard(order)),
              const SizedBox(height: 8),
              // 반품 사유
              const Text('반품 사유',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _returnReasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '반품 사유를 입력해 주세요.',
                  hintStyle:
                      TextStyle(fontSize: 13, color: AppColors.neutral400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: AppColors.neutral300),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              // 안내 문구
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
        _buildReturnFooter(),
      ],
    );
  }

  Widget _buildReturnOrderCard(RentalOrder order) {
    final lockedOrderId = _selectedReturnOrderId;
    final isOtherOrder =
        lockedOrderId != null && lockedOrderId != order.id;

    // ACTIVE 아이템 (선택 가능 대상)
    final activeItems = order.items
        .where((i) => i.status == 'ACTIVE')
        .toList();
    // CANCEL_REQUESTED 아이템 (비활성 표시)
    final requestedItems = order.items
        .where((i) => i.status == 'CANCEL_REQUESTED')
        .toList();

    final allActiveIds = activeItems.map((i) => i.id).toList();
    final allSelected = !isOtherOrder &&
        allActiveIds.isNotEmpty &&
        allActiveIds.every(_selectedReturnIds.contains);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isOtherOrder ? AppColors.neutral100 : AppColors.neutral200,
        ),
      ),
      child: Opacity(
        opacity: isOtherOrder ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderCardHeader(
                order: order,
                allSelected: allSelected,
                onSelectAll: isOtherOrder
                    ? (_) {} // 다른 주문 선택 중이면 전체선택 무시
                    : (v) {
                        setState(() {
                          if (v == true) {
                            _selectedReturnIds.addAll(allActiveIds);
                          } else {
                            _selectedReturnIds.removeAll(allActiveIds);
                          }
                        });
                      },
              ),
              if (isOtherOrder)
                Padding(
                  padding: const EdgeInsets.only(left: 40, top: 4),
                  child: Text(
                    '다른 주문이 선택되어 있습니다. 주문별로 각각 신청해 주세요.',
                    style: TextStyle(fontSize: 11, color: AppColors.neutral400),
                  ),
                ),
              const SizedBox(height: 8),
              // ACTIVE 아이템
              ...activeItems.map((item) => _buildItemCheckRow(
                    item: item,
                    selected: _selectedReturnIds.contains(item.id),
                    enabled: !isOtherOrder,
                    onChanged: isOtherOrder
                        ? (_) {}
                        : (v) {
                            setState(() {
                              if (v == true) {
                                _selectedReturnIds.add(item.id);
                              } else {
                                _selectedReturnIds.remove(item.id);
                              }
                            });
                          },
                  )),
              // CANCEL_REQUESTED 아이템 (비활성 표시)
              ...requestedItems.map((item) => _buildDisabledItemRow(item)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReturnFooter() {
    final selectedCount = _selectedReturnIds.length;
    final hasReason = _returnReasonCtrl.text.trim().isNotEmpty;
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
                (selectedCount > 0 && hasReason && !_isProcessing)
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

  // ── 공용 위젯 헬퍼 ────────────────────────────────────────────
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
              style: TextStyle(
                  fontSize: 14, color: AppColors.neutral500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCardHeader({
    required RentalOrder order,
    required bool allSelected,
    required ValueChanged<bool?> onSelectAll,
  }) {
    return Row(
      children: [
        Checkbox(
          value: allSelected,
          onChanged: onSelectAll,
          activeColor: AppColors.blue600,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Expanded(
          child: Text(
            '주문 #${order.orderId}',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        _buildDeliveryBadge(order.deliveryStatus),
      ],
    );
  }

  Widget _buildItemCheckRow({
    required RentalOrderItemDetail item,
    required bool selected,
    required ValueChanged<bool?> onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: enabled ? onChanged : null,
            activeColor: AppColors.blue600,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: 13,
                color: enabled ? null : AppColors.neutral400,
              ),
            ),
          ),
          Text(
            '${_formatAmount(item.price * item.quantity)}원',
            style: TextStyle(
              fontSize: 13,
              color: enabled ? AppColors.neutral700 : AppColors.neutral400,
            ),
          ),
        ],
      ),
    );
  }

  /// CANCEL_REQUESTED 아이템 표시 (체크박스 없이 비활성 상태)
  Widget _buildDisabledItemRow(RentalOrderItemDetail item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 48), // 체크박스 자리
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.neutral400,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.warning50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.warning500),
            ),
            child: Text(
              '반품 신청됨',
              style: TextStyle(fontSize: 10, color: AppColors.warning700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryBadge(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _deliveryBgColor(status),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _deliveryBorderColor(status)),
      ),
      child: Text(
        _deliveryLabel(status),
        style: TextStyle(
            fontSize: 11,
            color: _deliveryTextColor(status),
            fontWeight: FontWeight.w500),
      ),
    );
  }

  String _formatAmount(int amount) {
    final str = amount.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return amount < 0 ? '-$buf' : buf.toString();
  }

  // ── 제출 ─────────────────────────────────────────────────────
  Future<void> _submitCancelItems() async {
    if (_selectedCancelIds.isEmpty) return;
    setState(() => _isProcessing = true);
    try {
      final result = await widget.onCancelItems(
        widget.contract.id,
        _selectedCancelIds.toList(),
        _cancelReasonCtrl.text.trim(),
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
          builder: (ctx) => AlertDialog(
            title: const Text('결제 취소 완료'),
            content: Text(
                '${result.succeeded.length}건이 취소되었습니다.\n'
                '환불 예정 금액: ${_formatAmount(result.totalRefunded)}원'),
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
      }
      if (mounted) {
        widget.onRefreshContracts();
        Navigator.of(context).pop();
      }
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) _showErrorDialog('결제 취소 중 오류가 발생했습니다.\n$e');
    }
  }

  Future<void> _submitReturnRequest() async {
    if (_selectedReturnIds.isEmpty) return;
    final reason = _returnReasonCtrl.text.trim();
    if (reason.isEmpty) return;
    setState(() => _isProcessing = true);

    try {
      // 1) preview API 호출하여 예상 금액 조회
      final preview = await _fetchReturnPreview();
      if (!mounted) return;

      // 2) 확인 다이얼로그 표시
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('반품 신청 확인'),
          content: _buildPreviewConfirmContent(preview),
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
                  backgroundColor: AppColors.warning600),
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

      // 3) 실제 반품 신청 API 호출
      await widget.onReturnRequest(
        widget.contract.id,
        _selectedReturnIds.toList(),
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
        widget.onRefreshContracts();
        Navigator.of(context).pop();
      }
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) _showErrorDialog('반품 신청 중 오류가 발생했습니다.\n$e');
    }
  }

  /// preview 응답을 확인 다이얼로그 content로 변환
  Widget _buildPreviewConfirmContent(ReturnPreviewResponse? preview) {
    if (preview == null) {
      return const Text(
          '선택한 상품의 반품을 신청하시겠습니까?\n\n실제 환불 금액은 관리자 처리 후 최종 확정됩니다.');
    }
    final summary = preview.summary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('상품 금액',
                style: TextStyle(fontSize: 13, color: AppColors.neutral600)),
            Text('${_formatAmount(summary.totalItemAmount)}원',
                style: const TextStyle(fontSize: 13)),
          ],
        ),
        if (summary.totalShippingDeduction > 0) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('수거비 차감',
                  style: TextStyle(fontSize: 13, color: AppColors.error600)),
              Text('-${_formatAmount(summary.totalShippingDeduction)}원',
                  style: TextStyle(fontSize: 13, color: AppColors.error600)),
            ],
          ),
        ],
        // shippingDeductionReason 표시
        ...preview.orderPreviews
            .where((op) => op.shippingDeductionReason.isNotEmpty)
            .map((op) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('※ ${op.shippingDeductionReason}',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.neutral500)),
                )),
        const Divider(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('예상 환불 합계',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            Text('${_formatAmount(summary.totalRefundAmount)}원',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue600)),
          ],
        ),
        const SizedBox(height: 8),
        Text('* 실제 환불 금액은 관리자 처리 후 최종 확정됩니다.',
            style: TextStyle(fontSize: 11, color: AppColors.neutral500)),
      ],
    );
  }

  Future<void> _showErrorDialog(String message) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error600),
            child: const Text('확인',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
