import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import '../core/exceptions.dart';
import '../models/contract.dart';
import '../services/rental_order_service.dart';
import '../services/payment_service_unified.dart';

/// 게스트 계약 옵션 관리 서비스
/// - 옵션 편집/저장/결제 비즈니스 로직 담당
/// - UI 상태 변경은 콜백으로 위임
class GuestContractOptionService {
  final RentalOrderService _rentalOrderService;

  GuestContractOptionService({RentalOrderService? rentalOrderService})
      : _rentalOrderService = rentalOrderService ?? RentalOrderService();

  // ========== 헬퍼 메서드 ==========

  /// 옵션 편집/추가 버튼 표시 여부
  bool canShowEditButton(ContractListItem contract, bool Function(DateTime, int) isDaysBeforeCheckIn) {
    final allowedStatuses = [
      ContractStatus.pendingApproval,
      ContractStatus.approved,
      ContractStatus.paymentCompleted,
      ContractStatus.inProgress,
    ];
    if (!allowedStatuses.contains(contract.status)) {
      return false;
    }

    if (!isAfterPayment(contract)) {
      if (!isDaysBeforeCheckIn(contract.checkInDate, 5)) {
        return false;
      }
    }

    return true;
  }

  /// 원본 수량 조회 (이름 기반 매칭)
  int getOriginalQuantity(
    Map<int, List<RentalItem>> savedRentalItems,
    int contractId,
    String itemName,
  ) {
    final savedItems = savedRentalItems[contractId];
    if (savedItems == null) return 0;

    final item = savedItems.firstWhere(
      (i) => i.name == itemName,
      orElse: () => RentalItem(
        id: '',
        name: itemName,
        price: 0,
        quantity: 0,
        deliveryStatus: DeliveryStatus.pending,
      ),
    );
    return item.quantity;
  }

  /// 현재 옵션 리스트 가져오기 (편집 중이면 수정본, 아니면 원본)
  List<RentalItem> getCurrentOptions(
    int? editingContractId,
    Map<int, List<RentalItem>> modifiedOptions,
    ContractListItem contract,
  ) {
    if (editingContractId == contract.id) {
      return modifiedOptions[contract.id] ?? [];
    }
    return contract.rentalItems ?? [];
  }

  /// 결제 후 상태인지 확인
  bool isAfterPayment(ContractListItem contract) {
    return contract.status == ContractStatus.paymentCompleted ||
        contract.status == ContractStatus.inProgress;
  }

  /// 활성 렌탈 아이템이 있는지 확인
  bool hasActiveRentalItems(ContractListItem contract) {
    final items = contract.rentalItems;
    if (items == null || items.isEmpty) return false;
    return items.any((item) => item.quantity > 0);
  }

  // ========== 옵션 수량 변경 ==========

  /// 옵션 수량 변경 (수정된 옵션 맵을 직접 변경)
  void handleOptionQuantityChange(
    Map<int, List<RentalItem>> modifiedOptions,
    int contractId,
    String itemId,
    int delta,
  ) {
    final options = modifiedOptions[contractId];
    if (options == null) return;

    final itemIndex = options.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;

    final item = options[itemIndex];
    final newQuantity = (item.quantity + delta).clamp(0, 5);
    options[itemIndex] = item.copyWith(quantity: newQuantity);
  }

  // ========== 옵션 편집 시작 ==========

  /// 옵션 편집 시작 — API에서 이용 가능한 렌탈 아이템 조회
  /// 성공 시 [onSuccess] 콜백으로 병합된 옵션 목록 전달
  Future<void> handleEditButtonClick({
    required ContractListItem contract,
    required Map<int, List<RentalItem>> savedRentalItems,
    required void Function(List<RentalItem> mergedOptions) onSuccess,
    required void Function() onError,
    required void Function(String message) onShowError,
    required void Function() onUnauthorized,
  }) async {
    try {
      final availableItems = await _rentalOrderService.getAvailableRentalItems(
        contract.id,
      );

      // 원본 저장 (처음 편집 시작할 때만)
      if (!savedRentalItems.containsKey(contract.id)) {
        savedRentalItems[contract.id] = contract.rentalItems ?? [];
      }

      // API에서 받아온 이용 가능한 아이템으로 옵션 목록 생성
      final currentItems = contract.rentalItems ?? [];
      final allOptions = availableItems.map((availableItem) {
        final existingItem = currentItems.firstWhere(
          (item) => item.name == availableItem.name,
          orElse: () => RentalItem(
            id: availableItem.id.toString(),
            name: availableItem.name,
            description: availableItem.description,
            price: availableItem.price,
            quantity: 0,
            deliveryStatus: DeliveryStatus.pending,
          ),
        );

        return RentalItem(
          id: availableItem.id.toString(),
          name: availableItem.name,
          description: availableItem.description ?? existingItem.description,
          price: availableItem.price,
          quantity: existingItem.quantity,
          deliveryStatus: existingItem.deliveryStatus,
        );
      }).toList();

      onSuccess(allOptions);
    } on UnauthorizedException {
      onUnauthorized();
    } catch (e) {
      AppLogger.e('❌ [AVAILABLE ITEMS] Error: $e');
      onError();
      onShowError('옵션 목록을 불러오는데 실패했습니다: $e');
    }
  }

  // ========== 옵션 변경사항 저장 ==========

  /// 옵션 변경사항 저장 (결제 전/후 분기)
  Future<void> handleSaveOptionChanges({
    required ContractListItem contract,
    required List<RentalItem> modifiedItems,
    required Map<int, List<RentalItem>> savedRentalItems,
    required void Function() onComplete,
    required Future<void> Function() onReloadContracts,
    required void Function(String message, bool isSuccess) onShowMessage,
    required void Function() onUnauthorized,
    required Future<String?> Function(int totalAmount) onSelectPaymentMethod,
    required Future<void> Function(Map<String, dynamic> result, VoidCallback? onConfirm) onShowPaymentSuccess,
  }) async {
    final isBeforePayment =
        contract.status == ContractStatus.pendingApproval ||
        contract.status == ContractStatus.approved;

    if (isBeforePayment) {
      // 결제 전: 총 옵션 금액 최소 10,000원 검증
      final totalOptionsFee = modifiedItems.fold(
        0,
        (sum, item) => sum + item.price * item.quantity,
      );
      if (totalOptionsFee > 0 && totalOptionsFee < 10000) {
        onShowMessage('옵션 상품 총액은 최소 10,000원 이상이어야 합니다.', false);
        return;
      }
      await _updatePendingRentalItems(
        contract: contract,
        modifiedItems: modifiedItems,
        onComplete: onComplete,
        onReloadContracts: onReloadContracts,
        onShowMessage: onShowMessage,
        onUnauthorized: onUnauthorized,
      );
    } else {
      // 결제 후: 추가 결제 플로우
      await _createRentalOrderWithPayment(
        contract: contract,
        modifiedItems: modifiedItems,
        savedRentalItems: savedRentalItems,
        onComplete: onComplete,
        onReloadContracts: onReloadContracts,
        onShowMessage: onShowMessage,
        onUnauthorized: onUnauthorized,
        onSelectPaymentMethod: onSelectPaymentMethod,
        onShowPaymentSuccess: onShowPaymentSuccess,
      );
    }
  }

  /// 결제 전 상태: 렌탈 아이템 업데이트 (결제 없이 장바구니처럼)
  Future<void> _updatePendingRentalItems({
    required ContractListItem contract,
    required List<RentalItem> modifiedItems,
    required void Function() onComplete,
    required Future<void> Function() onReloadContracts,
    required void Function(String message, bool isSuccess) onShowMessage,
    required void Function() onUnauthorized,
  }) async {
    final itemsToUpdate = <RentalOrderItem>[];
    for (final item in modifiedItems) {
      if (item.quantity == 0) continue;
      final itemIdInt = int.tryParse(item.id);
      if (itemIdInt == null) continue;
      itemsToUpdate.add(
        RentalOrderItem(itemId: itemIdInt, quantity: item.quantity),
      );
    }

    try {
      await _rentalOrderService.updatePendingRentalItems(
        contractId: contract.id,
        items: itemsToUpdate,
      );

      final message = contract.status == ContractStatus.pendingApproval
          ? '옵션 상품이 저장되었습니다. 승인 후 결제 시 반영됩니다.'
          : '옵션 상품이 저장되었습니다. 결제 시 반영됩니다.';

      onShowMessage(message, true);
      onComplete();
      await onReloadContracts();
    } on UnauthorizedException {
      onUnauthorized();
    } catch (e) {
      AppLogger.e('❌ [UPDATE BEFORE_PAYMENT] Error: $e');
      onShowMessage('옵션 저장 중 오류가 발생했습니다: $e', false);
    }
  }

  /// 승인 후 상태: 렌탈 주문 생성 및 결제 진행
  Future<void> _createRentalOrderWithPayment({
    required ContractListItem contract,
    required List<RentalItem> modifiedItems,
    required Map<int, List<RentalItem>> savedRentalItems,
    required void Function() onComplete,
    required Future<void> Function() onReloadContracts,
    required void Function(String message, bool isSuccess) onShowMessage,
    required void Function() onUnauthorized,
    required Future<String?> Function(int totalAmount) onSelectPaymentMethod,
    required Future<void> Function(Map<String, dynamic> result, VoidCallback? onConfirm) onShowPaymentSuccess,
  }) async {
    final itemsToOrder = <RentalOrderItem>[];

    for (final item in modifiedItems) {
      final originalQty = getOriginalQuantity(savedRentalItems, contract.id, item.name);
      final addedQty = item.quantity - originalQty;

      if (addedQty > 0) {
        final itemIdInt = int.tryParse(item.id);
        if (itemIdInt == null) continue;
        itemsToOrder.add(
          RentalOrderItem(itemId: itemIdInt, quantity: addedQty),
        );
      }
    }

    if (itemsToOrder.isEmpty) {
      onComplete();
      return;
    }

    try {
      await _processRentalOrderPayment(
        contract: contract,
        itemsToOrder: itemsToOrder,
        onComplete: onComplete,
        onReloadContracts: onReloadContracts,
        onShowMessage: onShowMessage,
        onUnauthorized: onUnauthorized,
        onSelectPaymentMethod: onSelectPaymentMethod,
        onShowPaymentSuccess: onShowPaymentSuccess,
      );
    } on UnauthorizedException {
      onUnauthorized();
    } catch (e) {
      AppLogger.e('❌ [SAVE OPTIONS] Error: $e');
      onShowMessage('옵션 저장 중 오류가 발생했습니다: $e', false);
    }
  }

  /// 렌탈 주문 생성 및 결제 진행
  Future<void> _processRentalOrderPayment({
    required ContractListItem contract,
    required List<RentalOrderItem> itemsToOrder,
    required void Function() onComplete,
    required Future<void> Function() onReloadContracts,
    required void Function(String message, bool isSuccess) onShowMessage,
    required void Function() onUnauthorized,
    required Future<String?> Function(int totalAmount) onSelectPaymentMethod,
    required Future<void> Function(Map<String, dynamic> result, VoidCallback? onConfirm) onShowPaymentSuccess,
  }) async {
    // 1단계: 렌탈 주문 생성
    final orderResponse = await _rentalOrderService.createRentalOrder(
      contractId: contract.id,
      items: itemsToOrder,
    );

    if (orderResponse.totalAmount == 0) {
      onShowMessage('옵션이 추가되었습니다.', true);
      onComplete();
      await onReloadContracts();
      return;
    }

    // 2단계: 결제 정보 조회
    final paymentInfo = await _rentalOrderService.getPaymentInfo(
      orderResponse.rentalOrderId,
    );

    final orderId = paymentInfo['orderId'] as String? ?? orderResponse.orderId;
    final amount = paymentInfo['amount'] as int? ?? orderResponse.totalAmount;
    final orderName = paymentInfo['orderName'] as String? ?? '렌탈 아이템 추가';
    final customerName = paymentInfo['customerName'] as String?;
    final customerEmail = paymentInfo['customerEmail'] as String?;
    final customerPhone = paymentInfo['customerPhone'] as String?;

    // 3단계: 결제수단 선택
    final selectedMethod = await onSelectPaymentMethod(amount);
    if (selectedMethod == null) return;

    // 4단계: PayTag SDK 호출
    await _processRentalPayment(
      contract: contract,
      rentalOrderId: orderResponse.rentalOrderId,
      orderId: orderId,
      amount: amount,
      orderName: orderName,
      payType: selectedMethod,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      onComplete: onComplete,
      onReloadContracts: onReloadContracts,
      onShowMessage: onShowMessage,
      onUnauthorized: onUnauthorized,
      onShowPaymentSuccess: onShowPaymentSuccess,
    );
  }

  /// PayTag 렌탈 결제 처리
  Future<void> _processRentalPayment({
    required ContractListItem contract,
    required int rentalOrderId,
    required String orderId,
    required int amount,
    required String orderName,
    required String payType,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    required void Function() onComplete,
    required Future<void> Function() onReloadContracts,
    required void Function(String message, bool isSuccess) onShowMessage,
    required void Function() onUnauthorized,
    required Future<void> Function(Map<String, dynamic> result, VoidCallback? onConfirm) onShowPaymentSuccess,
  }) async {
    try {
      if (kIsWeb) {
        final paymentService = PaymentServiceUnified();

        final payResult = await paymentService.requestRentalPayment(
          rentalOrderId: rentalOrderId,
          orderId: orderId,
          amount: amount,
          orderName: orderName,
          payType: payType,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
        );

        onComplete();

        if (payResult != null) {
          await onShowPaymentSuccess(payResult, onReloadContracts);
        } else {
          await onReloadContracts();
        }
      } else {
        throw Exception('모바일에서는 아직 렌탈 추가 결제가 지원되지 않습니다.');
      }
    } on UnauthorizedException {
      onUnauthorized();
    } catch (e) {
      AppLogger.e('❌ [RENTAL PAYMENT] Error: $e');

      try {
        await _rentalOrderService.cancelPendingOrder(rentalOrderId);
      } catch (cancelError) {
        // ignore
      }

      onShowMessage('결제 처리 중 오류가 발생했습니다: $e', false);
    }
  }
}
