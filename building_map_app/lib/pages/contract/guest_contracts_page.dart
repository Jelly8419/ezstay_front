import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/exceptions.dart';
import 'package:go_router/go_router.dart';
import '../../models/contract.dart';
import '../../services/contract_service.dart';
import '../../services/payment_service_web.dart'
    if (dart.library.io) '../../services/payment_service_stub.dart';
import '../../services/rental_order_service.dart';
import '../../services/guest_contract_option_service.dart';
import '../../services/guest_checkout_service.dart';
import '../../services/guest_payment_service.dart';
import '../../services/rental_item_enrichment_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/payment_webview.dart';
import '../../widgets/payment_method_modal.dart';
import '../../widgets/common/app_footer.dart';
import '../../widgets/contract/add_option_modal.dart';
import '../../widgets/contract/contract_tab_menu.dart';
import '../../widgets/contract/contract_info_box.dart';
import '../../widgets/contract/guest_contract_dialogs.dart';
import '../../widgets/contract/cancel_option_modal.dart';
import '../../widgets/contract/contract_status_helper.dart';
import '../../widgets/contract/guest_contract_card.dart';
import '../../widgets/common/empty_state_box.dart';

/// 게스트용 계약 목록 페이지 (리액트 UI 기반 재설계)
class GuestContractsPage extends StatefulWidget {
  const GuestContractsPage({super.key});

  @override
  State<GuestContractsPage> createState() => _GuestContractsPageState();
}

class _GuestContractsPageState extends State<GuestContractsPage> {
  final ContractService _contractService = ContractService();
  final GuestContractOptionService _optionService = GuestContractOptionService();
  final GuestCheckoutService _checkoutService = GuestCheckoutService();
  final GuestPaymentService _paymentService = GuestPaymentService();
  final RentalItemEnrichmentService _enrichmentService = RentalItemEnrichmentService();
  List<ContractListItem> _allContracts = [];
  bool _isLoading = true;
  String? _errorMessage;

  // 탭 기반 필터링
  String _selectedTab =
      'in_progress'; // 'in_progress', 'completed', 'cancelled'

  // 옵션 관리 상태
  int? _editingContractId; // 현재 편집 중인 계약 ID
  final Map<int, List<RentalItem>> _modifiedOptions = {}; // 계약별 수정된 옵션
  final Map<int, List<RentalItem>> _savedRentalItems = {}; // 계약별 원본 옵션 저장

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
    });
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 전체 계약 불러오기 (필터 없음)
      final contracts = await _contractService.getGuestContracts();

      // 각 계약의 완전한 렌탈 아이템 데이터 가져오기
      await _enrichmentService.enrichAllContracts(contracts, _savedRentalItems);

      setState(() {
        _allContracts = contracts;
        _isLoading = false;
      });
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onTabChanged(String tab) {
    setState(() {
      _selectedTab = tab;
    });
  }

  List<ContractListItem> get _filteredContracts =>
      ContractStatusHelper.filterByTab(_allContracts, _selectedTab);

  // 옵션 관리 헬퍼 메서드

  /// 입주일 N일 전 체크 (날짜만 비교, 시간 제외)
  /// days=5 → 6일 이상 남았을 때 true (5일 이하 남으면 false)
  bool _isDaysBeforeCheckIn(DateTime checkInDate, int days) {
    final now = DateTime.now();
    // 시간을 제외하고 날짜만 비교
    final checkInDateOnly = DateTime(
      checkInDate.year,
      checkInDate.month,
      checkInDate.day,
    );
    final todayOnly = DateTime(now.year, now.month, now.day);
    final diff = checkInDateOnly.difference(todayOnly).inDays;
    // 5일 전까지 수정 가능 = 6일 이상 남아야 함
    // 예: 입주일 1/31, 오늘 1/25 → 6일 남음 → diff(6) > days(5) → true
    //     입주일 1/31, 오늘 1/26 → 5일 남음 → diff(5) > days(5) → false
    return diff > days;
  }

  // ========== 옵션 관리 (서비스 위임) ==========

  bool _canShowEditButton(ContractListItem contract) =>
      _optionService.canShowEditButton(contract, _isDaysBeforeCheckIn);

  List<RentalItem> _getCurrentOptions(ContractListItem contract) =>
      _optionService.getCurrentOptions(_editingContractId, _modifiedOptions, contract);

  bool _isAfterPayment(ContractListItem contract) =>
      _optionService.isAfterPayment(contract);

  int _getOriginalQuantity(int contractId, String itemName) =>
      _optionService.getOriginalQuantity(_savedRentalItems, contractId, itemName);

  void _handleOptionQuantityChange(int contractId, String itemId, int delta) {
    setState(() {
      _optionService.handleOptionQuantityChange(_modifiedOptions, contractId, itemId, delta);
    });
  }

  void _handleCancelOptionChanges(int contractId) {
    setState(() {
      _editingContractId = null;
      _modifiedOptions.remove(contractId);
    });
  }

  Future<void> _handleEditButtonClick(ContractListItem contract) async {
    setState(() => _editingContractId = contract.id);

    await _optionService.handleEditButtonClick(
      contract: contract,
      savedRentalItems: _savedRentalItems,
      onSuccess: (mergedOptions) {
        if (!mounted) return;
        setState(() => _modifiedOptions[contract.id] = mergedOptions);
      },
      onError: () {
        if (!mounted) return;
        setState(() => _editingContractId = null);
      },
      onShowError: (message) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: const Color(0xFFDC2626)),
        );
      },
      onUnauthorized: () { if (mounted) context.go('/login'); },
    );
  }

  Future<void> _handleSaveOptionChanges(ContractListItem contract) async {
    AppLogger.d('🔥 [_handleSaveOptionChanges] start, contractId=${contract.id}');
    final modifiedItems = _modifiedOptions[contract.id];
    AppLogger.d('🔥 [_handleSaveOptionChanges] modifiedItems=$modifiedItems');
    if (modifiedItems == null) return;

    final payResult = await _optionService.handleSaveOptionChanges(
      contract: contract,
      modifiedItems: modifiedItems,
      savedRentalItems: _savedRentalItems,
      onComplete: () {
        if (!mounted) return;
        setState(() {
          _editingContractId = null;
          _modifiedOptions.remove(contract.id);
        });
      },
      onReloadContracts: _loadContracts,
      onShowMessage: (message, isSuccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          );
      },
      onUnauthorized: () { if (mounted) context.go('/login'); },
      onSelectPaymentMethod: (totalAmount) async {
        if (!mounted) return null;
        final selected = await showPaymentMethodModal(context, totalAmount: totalAmount);
        if (!mounted) return null;
        return selected?.value;
      },
    );

    AppLogger.d('🎉 [page] payResult=$payResult, mounted=$mounted');
    if (payResult != null && mounted) {
      showRentalPaymentSuccessDialog(context, result: payResult, onConfirm: _loadContracts);
    }
  }


  /// 보증금 합의 확인 모달 표시 (게스트)
  Future<void> _showDepositAgreementReviewModal(
    ContractListItem contract,
  ) async {
    try {
      final agreement = await _contractService.getDepositAgreement(contract.id);

      if (!mounted) return;

      if (agreement == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('합의 정보가 없습니다.'),
            backgroundColor: Color(0xFF6B7280),
          ),
        );
        return;
      }

      showDepositAgreementReviewDialog(
        context,
        agreement: agreement,
        onAccept: () async {
          try {
            await _contractService.acceptDepositAgreement(contract.id);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('합의에 동의하였습니다.'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
            _loadContracts();
          } on UnauthorizedException {
            if (mounted) context.go('/login');
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('합의 동의 처리에 실패했습니다: $e'),
                backgroundColor: const Color(0xFFDC2626),
              ),
            );
          }
        },
        onShowMessage: (_, __) {},
      );
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      AppLogger.e('❌ [DEPOSIT AGREEMENT] Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('합의 정보를 불러오는데 실패했습니다: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  /// 승인대기 상태 계약 요청 취소
  /// PATCH /api/contracts/:contractId/cancel
  Future<void> _cancelPendingContract(int contractId) async {
    try {

      await _contractService.withdrawContract(contractId, '게스트 요청 취소');


      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('계약 요청이 취소되었습니다.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      await _loadContracts();
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      AppLogger.e('❌ [CANCEL] Error: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('계약 취소 중 오류가 발생했습니다: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  /// PAYMENT_COMPLETED 상태 계약 취소: 환불 금액 계산 후 모달 표시
  Future<void> _showRefundInfoAndCancel(contract) async {
    // 1단계: 로딩 표시하며 환불 금액 계산 API 호출
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    Map<String, dynamic>? refundData;
    try {
      final result = await _contractService.calculateRefund(contract.id);
      refundData = result['data'] as Map<String, dynamic>?;
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: false).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('환불 금액 조회에 실패했습니다: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: false).pop(); // 로딩 닫기

    // 2단계: 환불 정보 모달 표시
    showRefundInfoDialog(
      context,
      refundData: refundData,
      onConfirmRefund: (reason) async {
        try {
          await _contractService.requestRefund(contract.id, reason);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('환불 요청이 처리되었습니다.'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          _loadContracts();
        } on UnauthorizedException {
          if (mounted) context.go('/login');
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('환불 요청에 실패했습니다: $e'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      },
      onShowMessage: (message, isSuccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isSuccess ? const Color(0xFF10B981) : const Color(0xFFDC2626),
          ),
        );
      },
    );
  }


  int _getTabCount(String tab) =>
      ContractStatusHelper.countByTab(_allContracts, tab);

  /// 게스트 퇴실 완료 처리
  Future<void> _handleGuestCheckout(int contractId) async {
    final confirmed = await showGuestCheckoutConfirmDialog(context);
    if (confirmed != true) return;

    await _checkoutService.requestCheckout(
      contractId: contractId,
      onSuccess: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('퇴실 완료가 처리되었습니다. 호스트의 확인을 기다려주세요.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _loadContracts();
      },
      onError: (errorMessage) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('퇴실 처리 실패: $errorMessage'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      },
      onUnauthorized: () { if (mounted) context.go('/login'); },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF9FAFB),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // 페이지 타이틀 + 탭 메뉴
            Container(
              color: Colors.white,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 896),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        child: Text(
                          '계약 관리',
                          style: AppTextStyles.headingLarge.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ContractTabMenu(
                        selectedTab: _selectedTab,
                        onTabChanged: _onTabChanged,
                        getTabCount: _getTabCount,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildContractsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildContractsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadContracts,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 896),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const ContractInfoBox(),
                  const SizedBox(height: 16),
                  if (_filteredContracts.isEmpty)
                    const EmptyStateBox(
                      icon: Icons.home_outlined,
                      message: '계약 내역이 없습니다.',
                    )
                  else
                    ..._filteredContracts.map(
                      (contract) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildContractCardWidget(contract),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const AppFooter(),
      ],
    );
  }

  Widget _buildContractCardWidget(ContractListItem contract) {
    final isEditing = _editingContractId == contract.id;
    final currentOptions = _getCurrentOptions(contract);
    final canEdit = _canShowEditButton(contract);
    final canAddOption = _isDaysBeforeCheckIn(contract.checkInDate, 5);
    final isAfterPay = _isAfterPayment(contract);

    final changes = <OptionChange>[];
    if (isEditing) {
      for (final item in currentOptions) {
        final originalQty = _getOriginalQuantity(contract.id, item.name);
        if (item.quantity != originalQty) {
          changes.add(OptionChange(
            itemId: item.id,
            itemName: item.name,
            originalQuantity: originalQty,
            newQuantity: item.quantity,
            pricePerUnit: item.price,
          ));
        }
      }
    }
    final totalDiff = changes.fold<int>(0, (sum, c) => sum + c.priceDiff);

    return GuestContractCard(
      contract: contract,
      isEditing: isEditing,
      currentOptions: currentOptions,
      canEdit: canEdit,
      canAddOption: canAddOption,
      isAfterPayment: isAfterPay,
      optionChanges: changes,
      totalDiff: totalDiff,
      onPayment: () => _handlePayment(contract),
      onCancelPending: () => _cancelPendingContract(contract.id),
      onShowRefundInfoAndCancel: () => _showRefundInfoAndCancel(contract),
      onShowDepositAgreementReview: () => _showDepositAgreementReviewModal(contract),
      onEditButtonClick: () => _handleEditButtonClick(contract),
      onShowAddOptionModal: () => _showAddOptionModal(contract),
      onShowCancelOptionModal: () => _showCancelOptionModal(contract),
      onOptionQuantityChange: _handleOptionQuantityChange,
      onSaveOptionChanges: () => _handleSaveOptionChanges(contract),
      onCancelOptionChanges: () => _handleCancelOptionChanges(contract.id),
      getOriginalQuantity: _getOriginalQuantity,
      onGuestCheckout: () => _handleGuestCheckout(contract.id),
      onCancelRequest: (reason) async {
        try {
          await _contractService.requestCancellation(contract.id, reason);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('취소 요청이 관리자에게 전송되었습니다.'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          _loadContracts();
        } on UnauthorizedException {
          if (mounted) context.go('/login');
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('취소 요청에 실패했습니다: $e'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      },
    );
  }

  /// 옵션 추가 모달 표시 (리액트 UI 기준)
  void _showAddOptionModal(ContractListItem contract) async {
    // 먼저 API 호출
    List<AvailableRentalItem> availableItems;
    try {
      final rentalOrderService = RentalOrderService();
      availableItems = await rentalOrderService.getAvailableRentalItems(
        contract.id,
      );
    } on UnauthorizedException {
      if (mounted) context.go('/login');
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('옵션 조회 오류: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (!mounted) return;

    // API 완료 후 모달 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddOptionModal(
        availableOptions: availableItems,
        onConfirm: (selectedOptions) {
          // 결제 페이지로 이동
          _handleAdditionalOptionPayment(contract, selectedOptions);
        },
      ),
    );
  }

  /// 옵션 환불 모달 표시 (리액트 UI 기준 - 테이블 형식)
  bool _isCancelOptionModalOpen = false;

  void _showCancelOptionModal(ContractListItem contract) async {
    if (_isCancelOptionModalOpen) return;
    _isCancelOptionModalOpen = true;

    // 먼저 API 호출
    RentalOrderSummaryResponse response;
    try {
      final rentalOrderService = RentalOrderService();
      response = await rentalOrderService.getRentalOrders(contract.id);
    } on UnauthorizedException {
      _isCancelOptionModalOpen = false;
      if (mounted) context.go('/login');
      return;
    } catch (e) {
      _isCancelOptionModalOpen = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('주문 내역 조회 오류: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (!mounted) {
      _isCancelOptionModalOpen = false;
      return;
    }

    if (response.orders.isEmpty) {
      _isCancelOptionModalOpen = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('구매한 옵션 상품이 없습니다.'),
          backgroundColor: Color(0xFF6B7280),
        ),
      );
      return;
    }

    // API 완료 후 환불 모달 표시
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CancelOptionModal(
        contract: contract,
        orders: response.orders,
        onCancelItems: (contractId, itemIds, reason) async {
          return await _handleCancelItems(
            contractId,
            itemIds,
            reason: reason,
          );
        },
        onReturnRequest: (contractId, itemIds, reason) async {
          await _handleReturnRequest(contractId, itemIds, reason: reason);
        },
        onGetReturnPreview: (contractId, itemIds) async {
          return await _handleGetReturnPreview(contractId, itemIds);
        },
        onRefreshContracts: _loadContracts,
      ),
    );
    _isCancelOptionModalOpen = false;
  }

  /// 추가 옵션 결제 처리 (서비스 위임)
  Future<void> _handleAdditionalOptionPayment(
    ContractListItem contract,
    Map<int, int> selectedOptions,
  ) async {
    try {
      final data = await _paymentService.prepareAdditionalOptionPayment(
        contractId: contract.id,
        selectedOptions: selectedOptions,
      );
      if (data == null || !mounted) return;

      // 웹: 결제수단 선택 → PayTag SDK
      if (kIsWeb) {
        final selectedMethod = await showPaymentMethodModal(
          context,
          totalAmount: data.amount,
        );
        if (selectedMethod == null || !mounted) return;

        final payResult = await _paymentService.requestAdditionalOptionWebPayment(
          rentalOrderId: data.rentalOrderId,
          paymentInfo: data.paymentInfo,
          payType: selectedMethod.value,
        );
        if (payResult != null && mounted) {
          showRentalPaymentSuccessDialog(context, result: payResult, onConfirm: _loadContracts);
        }
      }
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('결제 오류: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  /// 결제취소 (아이템 단위 즉시환불)
  Future<RentalItemCancelResponse> _handleCancelItems(
    int contractId,
    List<int> itemIds, {
    String reason = '',
  }) async {
    try {
      final rentalOrderService = RentalOrderService();
      final result = await rentalOrderService.cancelRentalItems(
        contractId: contractId,
        itemIds: itemIds,
        reason: reason,
      );
      _loadContracts();
      return result;
    } on UnauthorizedException {
      if (mounted) context.go('/login');
      rethrow;
    }
  }

  /// 반품 신청 (단일 주문 내 아이템, 주문별 개별 호출)
  Future<void> _handleReturnRequest(
    int contractId,
    List<int> itemIds, {
    required String reason,
  }) async {
    try {
      final rentalOrderService = RentalOrderService();
      await rentalOrderService.returnRequestRentalItems(
        contractId: contractId,
        itemIds: itemIds,
        reason: reason,
      );
      _loadContracts();
    } on UnauthorizedException {
      if (mounted) context.go('/login');
      rethrow;
    }
  }

  /// 반품 예상 금액 조회
  Future<ReturnPreviewResponse> _handleGetReturnPreview(
    int contractId,
    List<int> itemIds,
  ) async {
    try {
      final rentalOrderService = RentalOrderService();
      return await rentalOrderService.getReturnPreview(
        contractId: contractId,
        itemIds: itemIds,
      );
    } on UnauthorizedException {
      if (mounted) context.go('/login');
      rethrow;
    }
  }

  /// 결제 처리 (서비스 위임)
  Future<void> _handlePayment(ContractListItem contract) async {
    try {
      // 1. 결제 정보 조회
      final paymentInfo = await _paymentService.getPaymentInfo(contract.id);
      if (!mounted) return;

      // 2. 플랫폼별 결제 처리
      if (kIsWeb) {
        final selectedMethod = await showPaymentMethodModal(
          context,
          totalAmount: paymentInfo['amount'] as int,
        );
        if (selectedMethod == null || !mounted) return;

        await _paymentService.requestWebPayment(
          contractId: contract.id,
          paymentInfo: paymentInfo,
          payType: selectedMethod.value,
        );
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('결제가 완료되었습니다!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _loadContracts();
      } else {
        // 모바일: WebView로 결제창 표시
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentWebView(
              paymentUrl: paymentInfo['paymentUrl'] as String,
              contractId: contract.id,
            ),
          ),
        );
        if (!mounted) return;

        if (result != null && result['success'] == true) {
          await _paymentService.confirmMobilePayment(
            contractId: contract.id,
            recvPayparam: result['recvPayparam'] as String,
            orderId: result['orderId'] as String,
            amount: result['amount'] as int,
            payType: result['payType'] as String?,
          );
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('결제가 완료되었습니다!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          _loadContracts();
        }
      }
    } on PopupBlockedException {
      if (!mounted) return;
      _showPopupBlockedDialog();
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('결제 오류: $e'),
          backgroundColor: const Color(0xFFF44336),
        ),
      );
    }
  }

  void _showPopupBlockedDialog() => showPopupBlockedDialog(context);

  // TODO: 오픈 후 가상계좌 추가 시 아래 메서드들 주석 해제
  // void _showVbankInfoDialog(Map<String, dynamic> result) { ... }
  // Widget _vbankRow(String label, String value) { ... }
}

