import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/contract.dart';
import '../../services/rental_order_service.dart';
import 'cancel_tab_content.dart';
import 'return_tab_content.dart';

/// 옵션 취소/반품 모달
///
/// - [결제취소] 탭: 배송전 아이템 선택 → 즉시 PG 환불
/// - [반품신청] 탭: 배송중/완료 아이템 선택 → 관리자 처리 대기
class CancelOptionModal extends StatefulWidget {
  final ContractListItem contract;
  final List<RentalOrder> orders;
  final Future<RentalItemCancelResponse> Function(
    int contractId,
    List<RentalItemCancelRequest> items,
    String reason,
  ) onCancelItems;
  final Future<void> Function(
    int contractId,
    List<RentalItemReturnRequest> items,
    String reason,
  ) onReturnRequest;
  final Future<ReturnPreviewResponse> Function(
    int contractId,
    List<int> itemIds,
  ) onGetReturnPreview;
  final VoidCallback onRefreshContracts;

  const CancelOptionModal({
    super.key,
    required this.contract,
    required this.orders,
    required this.onCancelItems,
    required this.onReturnRequest,
    required this.onGetReturnPreview,
    required this.onRefreshContracts,
  });

  @override
  State<CancelOptionModal> createState() => _CancelOptionModalState();
}

class _CancelOptionModalState extends State<CancelOptionModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool get _isCancelTabEnabled =>
      widget.contract.status == ContractStatus.paymentCompleted;

  bool get _isReturnTabEnabled =>
      widget.contract.status == ContractStatus.paymentCompleted ||
      widget.contract.status == ContractStatus.inProgress;

  List<RentalOrder> get _cancelableOrders => widget.orders
      .where((o) =>
          (o.status == 'PAID' ||
              o.status == 'PARTIAL_REFUND' ||
              o.status == 'FULLY_REFUNDED' ||
              o.status == 'CANCELLED') &&
          o.deliveryStatus == 'PENDING')
      .toList();

  List<RentalOrder> get _returnableOrders => widget.orders
      .where((o) =>
          (o.status == 'PAID' ||
              o.status == 'PARTIAL_REFUND' ||
              o.status == 'FULLY_REFUNDED' ||
              o.status == 'CANCELLED') &&
          (o.deliveryStatus == 'IN_TRANSIT' ||
              o.deliveryStatus == 'DELIVERED'))
      .toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (!_isCancelTabEnabled && _isReturnTabEnabled) {
      _tabController.index = 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabComplete() {
    widget.onRefreshContracts();
    Navigator.of(context).pop();
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
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  CancelTabContent(
                    enabled: _isCancelTabEnabled,
                    cancelableOrders: _cancelableOrders,
                    contractId: widget.contract.id,
                    onCancelItems: widget.onCancelItems,
                    onComplete: _handleTabComplete,
                  ),
                  ReturnTabContent(
                    enabled: _isReturnTabEnabled,
                    returnableOrders: _returnableOrders,
                    contractId: widget.contract.id,
                    onReturnRequest: widget.onReturnRequest,
                    onGetReturnPreview: widget.onGetReturnPreview,
                    onComplete: _handleTabComplete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
