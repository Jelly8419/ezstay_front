import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart' hide AppColors, AppTextStyles;
import '../../models/contract.dart';
import '../../services/contract_service.dart';
import '../../services/payment_service_unified.dart';
import '../../services/rental_order_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../utils/responsive_util.dart';
import '../../widgets/payment_webview.dart';
// import '../../widgets/modals/refund_calculation_modal.dart'; // TODO: API로 전체 Contract 가져오기 후 사용
import '../../widgets/modals/cancel_request_modal.dart';
import '../../widgets/common/app_footer.dart';

/// 게스트용 계약 목록 페이지 (리액트 UI 기반 재설계)
class GuestContractsPage extends StatefulWidget {
  const GuestContractsPage({super.key});

  @override
  State<GuestContractsPage> createState() => _GuestContractsPageState();
}

class _GuestContractsPageState extends State<GuestContractsPage> {
  final ContractService _contractService = ContractService();
  final RentalOrderService _rentalOrderService = RentalOrderService();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'ko_KR');
  final DateFormat _dateFormat = DateFormat('yyyy.MM.dd');

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
      await _fetchCompleteRentalItemsForAllContracts(contracts);

      setState(() {
        _allContracts = contracts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// 렌탈 아이템 API를 호출하여 완전한 데이터 구성
  Future<void> _fetchCompleteRentalItemsForAllContracts(
    List<ContractListItem> contracts,
  ) async {
    try {
      // 렌탈 아이템 전체 목록 가져오기 (inStock=true는 기본값)
      final rentalItemsResponse = await _contractService.getAllRentalItems();

      if (rentalItemsResponse == null) {
        debugPrint('⚠️ [RENTAL_ITEMS] Failed to fetch rental items from API');
        return;
      }

      // API 응답에서 렌탈 아이템 리스트 추출
      final allRentalItems = <String, Map<String, dynamic>>{};

      for (final item in rentalItemsResponse) {
        if (item is Map<String, dynamic> && item['id'] != null) {
          final id = item['id'].toString();
          allRentalItems[id] = {
            'id': id,
            'name': item['name'] ?? '',
            'description': item['description'] ?? '',
            'price': _parsePriceFromString(item['price']),
            'itemType': item['itemType'] ?? '',
            'itemTypeLabel': item['itemTypeLabel'] ?? '',
            'availableStock': item['availableStock'] ?? 0,
            'imageUrl': item['imageUrl'],
          };
          debugPrint(
            '📦 [RENTAL_ITEMS] Added item: id=$id, name=${item['name']}, price=${item['price']}',
          );
        }
      }

      debugPrint(
        '✅ [RENTAL_ITEMS] Loaded ${allRentalItems.length} rental items from API',
      );
      debugPrint(
        '📋 [RENTAL_ITEMS] Available IDs: ${allRentalItems.keys.toList()}',
      );

      // 각 계약의 렌탈 아이템을 완전한 데이터로 변환
      for (final contract in contracts) {
        if (contract.rentalItems == null || contract.rentalItems!.isEmpty) {
          continue;
        }

        debugPrint(
          '🔍 [RENTAL_ITEMS] Contract ${contract.id}: Processing ${contract.rentalItems!.length} items',
        );
        final completeRentalItems = <RentalItem>[];

        for (final contractItem in contract.rentalItems!) {
          debugPrint(
            '🔍 [RENTAL_ITEMS] Looking for item ID: "${contractItem.id}" (type: ${contractItem.id.runtimeType})',
          );

          // API에서 가져온 렌탈 아이템 데이터 찾기
          // ✅ FIX: ID를 String으로 변환하여 Map 조회 (allRentalItems의 키가 String이므로)
          final itemData = allRentalItems[contractItem.id.toString()];

          if (itemData != null) {
            debugPrint(
              '✅ [RENTAL_ITEMS] Found match: ${itemData['name']} (${itemData['price']}원)',
            );
            // 완전한 데이터로 RentalItem 생성
            completeRentalItems.add(
              RentalItem(
                id: itemData['id'] as String,
                name: itemData['name'] as String,
                description: itemData['description'] as String,
                price: itemData['price'] as int,
                quantity: contractItem.quantity, // 계약의 수량 사용
                deliveryStatus: contractItem.deliveryStatus,
              ),
            );
          } else {
            debugPrint(
              '⚠️ [RENTAL_ITEMS] Item ${contractItem.id} not found in API response',
            );
            debugPrint(
              '⚠️ [RENTAL_ITEMS] Current item: name="${contractItem.name}", price=${contractItem.price}',
            );
            // API에서 찾지 못한 경우 기존 데이터 유지
            completeRentalItems.add(contractItem);
          }
        }

        // 완전한 렌탈 아이템 목록 저장
        _savedRentalItems[contract.id] = completeRentalItems;

        // 계약 객체의 rentalItems도 업데이트
        contract.rentalItems?.clear();
        contract.rentalItems?.addAll(completeRentalItems);

        debugPrint(
          '✅ [RENTAL_ITEMS] Contract ${contract.id}: Populated ${completeRentalItems.length} items',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [RENTAL_ITEMS] Failed to fetch rental items: $e');
      debugPrint('📍 Stack trace: $stackTrace');
    }
  }

  /// 가격 문자열을 int로 변환 ("5000.00" → 5000)
  int _parsePriceFromString(dynamic price) {
    if (price == null) return 0;
    if (price is int) return price;
    if (price is double) return price.toInt();
    if (price is String) {
      try {
        return double.parse(price).toInt();
      } catch (e) {
        debugPrint('⚠️ [PRICE_PARSE] Failed to parse price: $price');
        return 0;
      }
    }
    return 0;
  }

  void _onTabChanged(String tab) {
    setState(() {
      _selectedTab = tab;
    });
  }

  // 탭별 계약 필터링
  List<ContractListItem> get _filteredContracts {
    if (_selectedTab == 'in_progress') {
      return _allContracts
          .where(
            (c) => [
              ContractStatus.pendingApproval,
              ContractStatus.approved,
              ContractStatus.paymentCompleted,
              ContractStatus.inProgress,
            ].contains(c.status),
          )
          .toList();
    } else if (_selectedTab == 'completed') {
      return _allContracts
          .where((c) => c.status == ContractStatus.completed)
          .toList();
    } else if (_selectedTab == 'cancelled') {
      return _allContracts
          .where(
            (c) => [
              ContractStatus.rejected,
              ContractStatus.cancelledByGuest,
              ContractStatus.cancelledByHost,
              ContractStatus.refunded,
              ContractStatus.approvalExpired,
              ContractStatus.paymentExpired,
            ].contains(c.status),
          )
          .toList();
    }
    return _allContracts;
  }

  // 옵션 관리 헬퍼 메서드

  /// 입주일 N일 전 체크 (날짜만 비교, 시간 제외)
  /// days=5 → 6일 이상 남았을 때 true (5일 이하 남으면 false)
  bool _isDaysBeforeCheckIn(DateTime checkInDate, int days) {
    final now = DateTime.now();
    // 시간을 제외하고 날짜만 비교
    final checkInDateOnly = DateTime(checkInDate.year, checkInDate.month, checkInDate.day);
    final todayOnly = DateTime(now.year, now.month, now.day);
    final diff = checkInDateOnly.difference(todayOnly).inDays;
    // 5일 전까지 수정 가능 = 6일 이상 남아야 함
    // 예: 입주일 1/31, 오늘 1/25 → 6일 남음 → diff(6) > days(5) → true
    //     입주일 1/31, 오늘 1/26 → 5일 남음 → diff(5) > days(5) → false
    return diff > days;
  }

  /// 옵션 편집 버튼 표시 여부
  /// - 취소/완료되지 않은 계약
  /// - 입주일 5일 전까지만 (6일 이상 남았을 때만)
  bool _canShowEditButton(ContractListItem contract) {
    // 1. 상태 체크: 승인됨, 결제완료, 진행중, 승인대기 상태만 가능
    final allowedStatuses = [
      ContractStatus.pendingApproval,
      ContractStatus.approved,
      ContractStatus.paymentCompleted,
      ContractStatus.inProgress,
    ];
    if (!allowedStatuses.contains(contract.status)) {
      return false;
    }

    // 2. 날짜 체크: 입주일 5일 전까지만 (6일 이상 남아야)
    if (!_isDaysBeforeCheckIn(contract.checkInDate, 5)) {
      return false;
    }

    return true;
  }

  /// 원본 수량 조회 (이름 기반 매칭)
  int _getOriginalQuantity(int contractId, String itemName) {
    final savedItems = _savedRentalItems[contractId];
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
  List<RentalItem> _getCurrentOptions(ContractListItem contract) {
    if (_editingContractId == contract.id) {
      return _modifiedOptions[contract.id] ?? [];
    }
    return contract.rentalItems ?? [];
  }

  /// 옵션 편집 시작 (API에서 이용 가능한 렌탈 아이템 조회)
  Future<void> _handleEditButtonClick(ContractListItem contract) async {
    // 먼저 편집 모드 진입 (로딩 표시용)
    setState(() {
      _editingContractId = contract.id;
    });

    try {
      // API에서 이용 가능한 렌탈 아이템 목록 조회
      final availableItems = await _rentalOrderService.getAvailableRentalItems(
        contract.id,
      );

      debugPrint(
        '📦 [AVAILABLE ITEMS] Contract ID: ${contract.id}, Items: ${availableItems.length}',
      );

      if (!mounted) return;

      setState(() {
        // 원본 저장 (처음 편집 시작할 때만)
        if (!_savedRentalItems.containsKey(contract.id)) {
          _savedRentalItems[contract.id] = contract.rentalItems ?? [];
        }

        // API에서 받아온 이용 가능한 아이템으로 옵션 목록 생성
        // 기존 계약의 rentalItems와 이름으로 매칭하여 수량 유지
        final currentItems = contract.rentalItems ?? [];
        final allOptions = availableItems.map((availableItem) {
          // 기존 계약에서 같은 이름의 아이템 찾기
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

          // API의 id를 사용하고, 기존 수량은 유지
          return RentalItem(
            id: availableItem.id.toString(),
            name: availableItem.name,
            description: availableItem.description ?? existingItem.description,
            price: availableItem.price,
            quantity: existingItem.quantity,
            deliveryStatus: existingItem.deliveryStatus,
          );
        }).toList();

        _modifiedOptions[contract.id] = allOptions;
      });
    } catch (e) {
      debugPrint('❌ [AVAILABLE ITEMS] Error: $e');

      if (!mounted) return;

      // 에러 발생 시 편집 모드 취소
      setState(() {
        _editingContractId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('옵션 목록을 불러오는데 실패했습니다: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  /// 옵션 수량 변경
  void _handleOptionQuantityChange(int contractId, String itemId, int delta) {
    setState(() {
      final options = _modifiedOptions[contractId];
      if (options == null) return;

      final itemIndex = options.indexWhere((item) => item.id == itemId);
      if (itemIndex == -1) return;

      final item = options[itemIndex];
      final newQuantity = (item.quantity + delta).clamp(0, 99);

      options[itemIndex] = item.copyWith(quantity: newQuantity);
    });
  }

  /// 옵션 변경사항 저장
  Future<void> _handleSaveOptionChanges(ContractListItem contract) async {
    final modifiedItems = _modifiedOptions[contract.id];
    if (modifiedItems == null) return;

    // 결제 전 상태인지 확인 (승인대기 또는 승인됨)
    // - PENDING_APPROVAL: 호스트 승인 대기 중
    // - APPROVED: 호스트 승인됨, 게스트 결제 대기 중
    final isBeforePayment = contract.status == ContractStatus.pendingApproval ||
        contract.status == ContractStatus.approved;

    if (isBeforePayment) {
      // 결제 전 상태: 장바구니처럼 렌탈 아이템만 업데이트 (결제 없음)
      await _updatePendingRentalItems(contract, modifiedItems);
    } else {
      // 결제 후 상태 (PAYMENT_COMPLETED, IN_PROGRESS): 추가 결제 플로우 진행
      await _createRentalOrderWithPayment(contract, modifiedItems);
    }
  }

  /// 결제 전 상태: 렌탈 아이템 업데이트 (결제 없이 장바구니처럼)
  /// - PENDING_APPROVAL: 승인대기 상태
  /// - APPROVED: 승인됨 상태 (결제 대기 중)
  Future<void> _updatePendingRentalItems(
    ContractListItem contract,
    List<RentalItem> modifiedItems,
  ) async {
    // 전체 아이템 목록 생성 (수량 0 제외)
    final itemsToUpdate = <RentalOrderItem>[];
    for (final item in modifiedItems) {
      if (item.quantity == 0) continue;
      final itemIdInt = int.tryParse(item.id);
      if (itemIdInt == null) continue;
      itemsToUpdate.add(RentalOrderItem(
        itemId: itemIdInt,
        quantity: item.quantity,
      ));
    }

    debugPrint(
      '🛒 [UPDATE BEFORE_PAYMENT] Contract ID: ${contract.id}, Status: ${contract.status}, Items: ${itemsToUpdate.length}',
    );

    try {
      await _rentalOrderService.updatePendingRentalItems(
        contractId: contract.id,
        items: itemsToUpdate,
      );

      debugPrint('✅ [UPDATE BEFORE_PAYMENT] Success');

      if (!mounted) return;

      // 상태에 따라 다른 안내 메시지 표시
      final message = contract.status == ContractStatus.pendingApproval
          ? '옵션 상품이 저장되었습니다. 승인 후 결제 시 반영됩니다.'
          : '옵션 상품이 저장되었습니다. 결제 시 반영됩니다.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      setState(() {
        _editingContractId = null;
        _modifiedOptions.remove(contract.id);
      });

      await _loadContracts();
    } catch (e) {
      debugPrint('❌ [UPDATE BEFORE_PAYMENT] Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('옵션 저장 중 오류가 발생했습니다: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  /// 승인 후 상태: 렌탈 주문 생성 및 결제 진행
  /// - 수량 증가만 처리 (환불은 별도 환불 모달에서 처리)
  Future<void> _createRentalOrderWithPayment(
    ContractListItem contract,
    List<RentalItem> modifiedItems,
  ) async {
    // 변경사항 계산: 추가된 아이템만 (기존 대비 수량 증가분)
    final itemsToOrder = <RentalOrderItem>[];

    for (final item in modifiedItems) {
      final originalQty = _getOriginalQuantity(contract.id, item.name);
      final addedQty = item.quantity - originalQty;

      if (addedQty > 0) {
        // 수량 증가 → 추가 결제
        final itemIdInt = int.tryParse(item.id);
        if (itemIdInt == null) continue;
        itemsToOrder.add(RentalOrderItem(
          itemId: itemIdInt,
          quantity: addedQty,
        ));
      }
    }

    // 변경사항이 없으면 편집 모드 종료
    if (itemsToOrder.isEmpty) {
      setState(() {
        _editingContractId = null;
        _modifiedOptions.remove(contract.id);
      });
      return;
    }

    debugPrint(
      '💾 [SAVE OPTIONS] Contract ID: ${contract.id}, Items to add: ${itemsToOrder.length}',
    );

    try {
      await _processRentalOrderPayment(contract, itemsToOrder);
    } catch (e) {
      debugPrint('❌ [SAVE OPTIONS] Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('옵션 저장 중 오류가 발생했습니다: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  /// 렌탈 주문 생성 및 결제 진행
  Future<void> _processRentalOrderPayment(
    ContractListItem contract,
    List<RentalOrderItem> itemsToOrder,
  ) async {
    // 1단계: 렌탈 주문 생성 (PENDING 상태)
    final orderResponse = await _rentalOrderService.createRentalOrder(
      contractId: contract.id,
      items: itemsToOrder,
    );

    debugPrint(
      '✅ [RENTAL ORDER] Created: ${orderResponse.orderId}, Amount: ${orderResponse.totalAmount}',
    );

    if (orderResponse.totalAmount == 0) {
      // 결제 불필요 (무료 아이템 등)
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('옵션이 추가되었습니다.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      setState(() {
        _editingContractId = null;
        _modifiedOptions.remove(contract.id);
      });
      await _loadContracts();
      return;
    }

    // 2단계: 결제 정보 조회 (토스 SDK용)
    final paymentInfo = await _rentalOrderService.getPaymentInfo(
      orderResponse.rentalOrderId,
    );

    final orderId = paymentInfo['orderId'] as String? ?? orderResponse.orderId;
    final amount = paymentInfo['amount'] as int? ?? orderResponse.totalAmount;
    final orderName = paymentInfo['orderName'] as String? ?? '렌탈 아이템 추가';
    final customerName = paymentInfo['customerName'] as String?;
    final customerEmail = paymentInfo['customerEmail'] as String?;

    debugPrint('💳 [PAYMENT INFO] Retrieved for order: $orderId, amount: $amount');

    // 3단계: 토스페이먼츠 SDK 직접 호출
    if (!mounted) return;
    await _processRentalPayment(
      contract: contract,
      rentalOrderId: orderResponse.rentalOrderId,
      orderId: orderId,
      amount: amount,
      orderName: orderName,
      customerName: customerName,
      customerEmail: customerEmail,
    );
  }

  /// 토스페이먼츠 렌탈 결제 처리
  ///
  /// 웹: JavaScript SDK로 결제창 호출 → /rental-payment/success로 리다이렉트
  /// 모바일: WebView로 결제창 표시 → 결과 처리
  Future<void> _processRentalPayment({
    required ContractListItem contract,
    required int rentalOrderId,
    required String orderId,
    required int amount,
    required String orderName,
    String? customerName,
    String? customerEmail,
  }) async {
    try {
      if (kIsWeb) {
        // 웹: 토스페이먼츠 JavaScript SDK 직접 호출
        final paymentService = PaymentServiceUnified();

        debugPrint('🌐 [RENTAL PAYMENT] Web - Calling Toss SDK');
        debugPrint('  - rentalOrderId: $rentalOrderId');
        debugPrint('  - orderId: $orderId');
        debugPrint('  - amount: $amount');

        // 토스 SDK 호출 (렌탈 전용 successUrl/failUrl 사용)
        await paymentService.requestRentalPayment(
          rentalOrderId: rentalOrderId,
          orderId: orderId,
          amount: amount,
          orderName: orderName,
          customerName: customerName,
          customerEmail: customerEmail,
        );

        // 웹에서는 자동 리다이렉트됨 → /rental-payment/success 또는 /rental-payment/fail
        // 여기서는 편집 모드만 해제
        setState(() {
          _editingContractId = null;
          _modifiedOptions.remove(contract.id);
        });
      } else {
        // 모바일: WebView로 결제 진행 (기존 로직)
        // 결제 페이지 URL 생성 (백엔드에서 토스 결제창 URL 생성 필요)
        // 현재는 웹 전용이므로 에러 표시
        throw Exception('모바일에서는 아직 렌탈 추가 결제가 지원되지 않습니다.');
      }
    } catch (e) {
      debugPrint('❌ [RENTAL PAYMENT] Error: $e');

      // 미결제 주문 취소 시도
      try {
        await _rentalOrderService.cancelPendingOrder(rentalOrderId);
        debugPrint('🗑️ [RENTAL PAYMENT] Cancelled pending order: $rentalOrderId');
      } catch (cancelError) {
        debugPrint('⚠️ [RENTAL PAYMENT] Failed to cancel pending order: $cancelError');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('결제 처리 중 오류가 발생했습니다: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  /// 옵션 변경사항 취소
  void _handleCancelOptionChanges(int contractId) {
    setState(() {
      _editingContractId = null;
      _modifiedOptions.remove(contractId);
    });
  }

  /// 결제 후 상태인지 확인
  bool _isAfterPayment(ContractListItem contract) {
    return contract.status == ContractStatus.paymentCompleted ||
        contract.status == ContractStatus.inProgress;
  }

  /// 활성 렌탈 아이템이 있는지 확인
  bool _hasActiveRentalItems(ContractListItem contract) {
    final items = contract.rentalItems;
    if (items == null || items.isEmpty) return false;
    return items.any((item) => item.quantity > 0);
  }

  /// 환불 모달 표시
  Future<void> _showRefundModal(ContractListItem contract) async {
    // 결제건별 렌탈 주문 조회
    try {
      final response = await _rentalOrderService.getRentalOrders(contract.id);

      if (!mounted) return;

      // PAID 상태이고 ACTIVE 아이템이 있는 주문만 필터링
      final refundableOrders = response.orders.where((order) {
        return order.status == 'PAID' &&
            order.items.any((item) => item.status == 'ACTIVE');
      }).toList();

      if (refundableOrders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('환불 가능한 옵션 상품이 없습니다.'),
            backgroundColor: Color(0xFF6B7280),
          ),
        );
        return;
      }

      // 환불 모달 표시
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _RefundModal(
          contract: contract,
          orders: refundableOrders,
          onRefund: (rentalOrderId, itemId) async {
            await _processRefund(contract, rentalOrderId, itemId);
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ [REFUND MODAL] Error loading orders: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('주문 정보를 불러오는데 실패했습니다: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  /// 환불 처리
  Future<void> _processRefund(
    ContractListItem contract,
    int rentalOrderId,
    int itemId,
  ) async {
    try {
      debugPrint('🔄 [REFUND] Processing: orderId=$rentalOrderId, itemId=$itemId');

      final result = await _rentalOrderService.cancelItem(
        rentalOrderId: rentalOrderId,
        itemId: itemId,
        reason: '게스트 요청 환불',
      );

      debugPrint('✅ [REFUND] Success: $result');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('환불 요청이 처리되었습니다.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      // 계약 목록 새로고침
      await _loadContracts();
    } catch (e) {
      debugPrint('❌ [REFUND] Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('환불 처리 중 오류가 발생했습니다: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  /// 승인대기 상태 계약 요청 취소
  /// PATCH /api/contracts/:contractId/cancel
  Future<void> _cancelPendingContract(int contractId) async {
    try {
      debugPrint('🚫 [CANCEL] Cancelling pending contract: $contractId');

      await _contractService.withdrawContract(contractId, '게스트 요청 취소');

      debugPrint('✅ [CANCEL] Contract cancelled successfully');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('계약 요청이 취소되었습니다.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      await _loadContracts();
    } catch (e) {
      debugPrint('❌ [CANCEL] Error: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('계약 취소 중 오류가 발생했습니다: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  // 탭별 계약 개수
  int _getTabCount(String tab) {
    if (tab == 'in_progress') {
      return _allContracts
          .where(
            (c) => [
              ContractStatus.pendingApproval,
              ContractStatus.approved,
              ContractStatus.paymentCompleted,
              ContractStatus.inProgress,
            ].contains(c.status),
          )
          .length;
    } else if (tab == 'completed') {
      return _allContracts
          .where((c) => c.status == ContractStatus.completed)
          .length;
    } else if (tab == 'cancelled') {
      return _allContracts
          .where(
            (c) => [
              ContractStatus.rejected,
              ContractStatus.cancelledByGuest,
              ContractStatus.cancelledByHost,
              ContractStatus.refunded, // ← 환불 완료
              ContractStatus.approvalExpired, // ← 미승인 만료
              ContractStatus.paymentExpired, // ← 미결제 만료
            ].contains(c.status),
          )
          .length;
    }
    return 0;
  }

  Color _getStatusColor(ContractStatus status) {
    switch (status) {
      case ContractStatus.pendingApproval:
        return const Color(0xFFFB923C); // yellow-600
      case ContractStatus.approvalExpired:
        return Colors.grey;
      case ContractStatus.approved:
        return const Color(0xFF2563EB); // blue-600
      case ContractStatus.paymentExpired:
        return Colors.grey.shade600;
      case ContractStatus.paymentCompleted:
        return const Color(0xFF16A34A); // green-600
      case ContractStatus.inProgress:
        return const Color(0xFF9333EA); // purple-600
      case ContractStatus.completed:
        return Colors.grey;
      case ContractStatus.rejected:
        return const Color(0xFFDC2626); // red-600
      case ContractStatus.cancelledByGuest:
      case ContractStatus.cancelledByHost:
        return Colors.grey;
      case ContractStatus.refunded:
        return const Color(0xFF9333EA); // purple-600
    }
  }

  Color _getStatusBgColor(ContractStatus status) {
    switch (status) {
      case ContractStatus.pendingApproval:
        return const Color(0xFFFEF3C7); // yellow-100
      case ContractStatus.approved:
        return const Color(0xFFDBEAFE); // blue-100
      case ContractStatus.paymentCompleted:
        return const Color(0xFFDCFCE7); // green-100
      case ContractStatus.inProgress:
        return const Color(0xFFF3E8FF); // purple-100
      case ContractStatus.completed:
      case ContractStatus.cancelledByGuest:
      case ContractStatus.cancelledByHost:
        return const Color(0xFFF3F4F6); // gray-100
      case ContractStatus.rejected:
        return const Color(0xFFFEE2E2); // red-100
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Widget _getStatusIcon(ContractStatus status) {
    switch (status) {
      case ContractStatus.pendingApproval:
        return const Icon(Icons.schedule, size: 16);
      case ContractStatus.approved:
      case ContractStatus.paymentCompleted:
      case ContractStatus.completed:
        return const Icon(Icons.check_circle, size: 16);
      case ContractStatus.rejected:
      case ContractStatus.cancelledByGuest:
      case ContractStatus.cancelledByHost:
        return const Icon(Icons.cancel, size: 16);
      case ContractStatus.inProgress:
        return const Icon(Icons.home, size: 16);
      default:
        return const Icon(Icons.info, size: 16);
    }
  }

  String _getStatusMessage(ContractStatus status) {
    switch (status) {
      case ContractStatus.pendingApproval:
        return '호스트의 승인/거절을 기다리고 있습니다.';
      case ContractStatus.approved:
        return '호스트가 승인했습니다. 결제를 진행해주세요.';
      case ContractStatus.paymentCompleted:
        return '입주일에 맞춰 방문해주세요.';
      case ContractStatus.inProgress:
        return '';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF9FAFB), // gray-50
      child: Column(
        children: [
          // 페이지 타이틀 + 탭 메뉴
          Container(
            color: Colors.white,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppConstants.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 페이지 타이틀
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

                    // 탭 메뉴
                    _buildTabMenu(),
                  ],
                ),
              ),
            ),
          ),

          // 계약 목록
          Expanded(child: _buildContractsList()),
        ],
      ),
    );
  }

  Widget _buildTabMenu() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabButton('in_progress', '진행중', _getTabCount('in_progress')),
          const SizedBox(width: 8),
          _buildTabButton('completed', '지난 계약', _getTabCount('completed')),
          const SizedBox(width: 8),
          _buildTabButton('cancelled', '취소', _getTabCount('cancelled')),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String label, int count) {
    final isSelected = _selectedTab == tab;
    return Expanded(
      child: Material(
        color: isSelected ? const Color(0xFF2563EB) : Colors.white, // blue-600
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _onTabChanged(tab),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF6B7280), // gray-600
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '($count)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
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

    return RefreshIndicator(
      onRefresh: _loadContracts,
      child: ListView(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.maxContentWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 안내 메시지 박스
                    _buildInfoBox(),
                    const SizedBox(height: 16),

                    // 계약 카드 목록
                    if (_filteredContracts.isEmpty)
                      _buildEmptyState()
                    else
                      ..._filteredContracts.map(
                        (contract) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildContractCard(contract),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // blue-50
        border: Border.all(color: const Color(0xFFDBEAFE)), // blue-100
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info,
            color: Color(0xFF2563EB), // blue-600
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안내사항',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A), // blue-900
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• 호스트가 계약 요청을 승인하면 채팅과 결제를 진행할 수 있습니다.\n'
                  '• 결제 완료 후에는 입주일 5일 전까지만 옵션 추가 및 변경이 가능합니다.\n'
                  '• 계약은 결제 선착순으로 확정되며, 결제 완료 전까지는 계약이 보장되지 않습니다.\n'
                  '• 입주일 이후 계약 취소 시 호스트와 합의 후 관리자 승인이 필요합니다.',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF1E40AF), // blue-800
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.home_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '계약 내역이 없습니다.',
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(ContractListItem contract) {
    final statusColor = _getStatusColor(contract.status);
    final statusBgColor = _getStatusBgColor(contract.status);
    final statusMessage = _getStatusMessage(contract.status);
    final showChatButton = [
      ContractStatus.approved,
      ContractStatus.paymentCompleted,
      ContractStatus.inProgress,
      ContractStatus.completed,
    ].contains(contract.status);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)), // gray-200
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상태 배지 + 안내 메시지 + 상세 버튼
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // 상태 배지
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconTheme(
                            data: IconThemeData(color: statusColor),
                            child: _getStatusIcon(contract.status),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            contract.status.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 안내 메시지
                    if (statusMessage.isNotEmpty)
                      Text(
                        statusMessage,
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 13, color: statusColor),
                      ),
                  ],
                ),
              ),

              // 상세 버튼
              IconButton(
                onPressed: () {
                  final path = '/guest/contracts/${contract.id}';
                  debugPrint('🔍 [CONTRACTS] Navigating to: $path');
                  context.go(path);
                },
                icon: const Icon(Icons.article_outlined),
                color: const Color(0xFF2563EB), // blue-600
                tooltip: '상세',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 방 사진 + 계약 정보 (모바일: 세로 배치, 태블릿+: 가로 배치)
          _buildRoomInfoSection(contract, showChatButton),

          // 액션 버튼 영역
          if (contract.status == ContractStatus.pendingApproval) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // 요청 취소 확인 다이얼로그
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('계약 요청 취소'),
                      content: const Text('계약 요청을 취소하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('돌아가기'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            // API 호출: 계약 요청 취소
                            await _cancelPendingContract(contract.id);
                          },
                          child: const Text('취소하기'),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(
                    color: Color(0xFFD1D5DB),
                    width: 2,
                  ), // gray-300
                ),
                child: const Text(
                  '요청 취소',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151), // gray-700
                  ),
                ),
              ),
            ),
          ],

          if (contract.status == ContractStatus.approved) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handlePayment(contract),
                icon: const Icon(Icons.credit_card, size: 16),
                label: Text(
                  '결제하기',
                  style: AppTextStyles.labelMedium,
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xFF2563EB), // blue-600
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],

          if (contract.status == ContractStatus.paymentCompleted) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () async {
                    // TODO: API로 전체 Contract 데이터 가져오기
                    // final fullContract = await _contractService.getContractById(contract.id);

                    // 임시: 간단한 확인 다이얼로그 표시
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('계약 취소'),
                        content: const Text(
                          '계약을 취소하시겠습니까?\n환불 정책에 따라 환불 금액이 계산됩니다.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('돌아가기'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              // TODO: 환불 계산기 모달 표시 (전체 Contract 필요)
                              // RefundCalculationModal(contract: fullContract, ...)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('계약 취소 기능은 개발 중입니다.'),
                                  backgroundColor: Color(0xFF2563EB),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                            ),
                            child: const Text('취소하기'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    side: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
                  ),
                  child: const Text(
                    '계약 취소',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Color(0xFF6B7280), // gray-500
                ),
              ],
            ),
          ],

          if (contract.status == ContractStatus.inProgress) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    // 취소 요청 모달 표시 (입주일 이후)
                    showDialog(
                      context: context,
                      builder: (context) => CancelRequestModal(
                        onSubmit: (reason) {
                          Navigator.of(context).pop();
                          // API 호출: 취소 요청 전송
                          debugPrint(
                            '⚠️ [CANCEL_REQUEST] Contract ID: ${contract.id}, Reason: $reason',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('취소 요청이 관리자에게 전송되었습니다.'),
                              backgroundColor: Color(0xFF10B981), // green-600
                            ),
                          );
                          _loadContracts();
                        },
                        onClose: () => Navigator.of(context).pop(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    side: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
                  ),
                  child: const Text(
                    '취소 요청',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
              ],
            ),
          ],

          // 옵션 상품 섹션
          _buildOptionsSection(contract),
        ],
      ),
    );
  }

  /// 옵션 상품 섹션 구현
  Widget _buildOptionsSection(ContractListItem contract) {
    final isEditing = _editingContractId == contract.id;
    final currentOptions = _getCurrentOptions(contract);
    final canEdit = _canShowEditButton(contract);

    // 입주일 5일 전 체크
    final canChangeOptions =
        contract.status != ContractStatus.paymentCompleted ||
        _isDaysBeforeCheckIn(contract.checkInDate, 5);

    // 옵션 변경사항 계산
    final changes = <OptionChange>[];
    if (isEditing) {
      for (final item in currentOptions) {
        final originalQty = _getOriginalQuantity(contract.id, item.name);
        // 수량이 변경된 경우 (0으로 변경도 포함)
        if (item.quantity != originalQty) {
          changes.add(
            OptionChange(
              itemId: item.id,
              itemName: item.name,
              originalQuantity: originalQty,
              newQuantity: item.quantity,
              pricePerUnit: item.price,
            ),
          );
        }
      }
    }
    final totalDiff = changes.fold<int>(
      0,
      (sum, change) => sum + change.priceDiff,
    );

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB), // gray-50
        border: Border.all(color: const Color(0xFFE5E7EB)), // gray-200
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 옵션 상품 + 버튼들
          Row(
            children: [
              const Text(
                '옵션 상품',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827), // gray-900
                ),
              ),
              // 호스트 권장 배지 (있을 경우)
              // 결제 전 상태: 옵션 추가 및 변경 버튼
              if (canEdit && !isEditing && !_isAfterPayment(contract)) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _handleEditButtonClick(contract),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    side: const BorderSide(
                      color: Color(0xFF2563EB), // blue-600
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '옵션 추가 및 변경',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB), // blue-600
                    ),
                  ),
                ),
              ],
              // 결제 후 상태: 추가 + 취소 버튼 분리
              if (canEdit && !isEditing && _isAfterPayment(contract)) ...[
                const Spacer(),
                // 추가 버튼
                OutlinedButton(
                  onPressed: canChangeOptions
                      ? () => _showAddOptionModal(contract)
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    side: BorderSide(
                      color: canChangeOptions
                          ? const Color(0xFF2563EB) // blue-600
                          : const Color(0xFF9CA3AF), // gray-400
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '추가',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: canChangeOptions
                          ? const Color(0xFF2563EB) // blue-600
                          : const Color(0xFF9CA3AF), // gray-400
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 취소 버튼
                OutlinedButton(
                  onPressed: () => _showCancelOptionModal(contract),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    side: const BorderSide(
                      color: Color(0xFFD1D5DB), // gray-300
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B5563), // gray-600
                    ),
                  ),
                ),
              ],
            ],
          ),
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
                    color: Color(0xFF6B7280), // gray-500
                  ),
                ),
              ),
            )
          else
            ...currentOptions
                .where((item) => item.quantity > 0 || isEditing)
                .map((item) => _buildOptionItem(contract, item, isEditing)),

          // 총 금액 변동 요약 (편집 모드)
          if (isEditing && totalDiff != 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: totalDiff > 0
                    ? const Color(0xFFEFF6FF) // blue-50
                    : const Color(0xFFFEE2E2), // red-50
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: totalDiff > 0
                      ? const Color(0xFFDBEAFE) // blue-100
                      : const Color(0xFFFECACA), // red-100
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
                      color: Color(0xFF111827), // gray-900
                    ),
                  ),
                  Text(
                    '${totalDiff > 0 ? '+' : ''}${_currencyFormat.format(totalDiff.abs())}원',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: totalDiff > 0
                          ? const Color(0xFF2563EB) // blue-600
                          : const Color(0xFFDC2626), // red-600
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 버튼 영역 (편집 모드)
          if (isEditing) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleCancelOptionChanges(contract.id),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(
                        color: Color(0xFFD1D5DB),
                        width: 2,
                      ), // gray-300
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151), // gray-700
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: changes.isEmpty
                        ? null
                        : () => _handleSaveOptionChanges(contract),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: changes.isEmpty
                          ? const Color(0xFFD1D5DB) // gray-300
                          : const Color(0xFF2563EB), // blue-600
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFD1D5DB),
                      disabledForegroundColor: const Color(
                        0xFF6B7280,
                      ), // gray-500
                    ),
                    child: Text(
                      // 결제 후 상태에서만 '추가 결제' 버튼 표시
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
            ),
          ],
        ],
      ),
    );
  }

  /// 옵션 아이템 구현
  Widget _buildOptionItem(
    ContractListItem contract,
    RentalItem item,
    bool isEditing,
  ) {
    final originalQty = _getOriginalQuantity(contract.id, item.name);
    final qtyDiff = item.quantity - originalQty;
    final diffPrice = qtyDiff * item.price;

    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)), // gray-200
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
                  color: Color(0xFF111827), // gray-900
                ),
              ),
              if (isEditing) ...[
                const SizedBox(width: 8),
                Text(
                  '(개당 ${_currencyFormat.format(item.price)}원)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2563EB), // blue-600
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
                color: Color(0xFF6B7280), // gray-500
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
                        // 결제 후 상태: 원래 수량 이하로 감소 불가 (환불은 별도 UI로)
                        // 결제 전 상태: 0까지 감소 가능
                        Builder(builder: (context) {
                          final isAfterPayment = _isAfterPayment(contract);
                          final minQty = isAfterPayment ? originalQty : 0;
                          final canDecrease = item.quantity > minQty;

                          return InkWell(
                            onTap: canDecrease
                                ? () => _handleOptionQuantityChange(
                                    contract.id,
                                    item.id,
                                    -1,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: canDecrease
                                      ? const Color(0xFFD1D5DB) // gray-300
                                      : const Color(0xFFE5E7EB), // gray-200
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
                                    ? const Color(0xFF374151) // gray-700
                                    : const Color(0xFFD1D5DB), // gray-300
                              ),
                            ),
                          );
                        }),
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
                                color: Color(0xFF111827), // gray-900
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 플러스 버튼
                        InkWell(
                          onTap: () => _handleOptionQuantityChange(
                            contract.id,
                            item.id,
                            1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF2563EB), // blue-600
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 16,
                              color: Color(0xFF2563EB), // blue-600
                            ),
                          ),
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
                          color: Color(0xFF2563EB), // blue-600
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else if (qtyDiff < 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '이전 수량에서 $qtyDiff개',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFDC2626), // red-600
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else if (item.quantity > 0) ...[
                      const SizedBox(height: 4),
                      const Text(
                        '이전 수량에서 변동 없음',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280), // gray-500
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
                      '${_currencyFormat.format(item.price * item.quantity)}원',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827), // gray-900
                      ),
                    ),
                    if (qtyDiff > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '(+${_currencyFormat.format(diffPrice)}원)',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2563EB), // blue-600
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else if (qtyDiff < 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '(${_currencyFormat.format(diffPrice)}원)',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFFDC2626), // red-600
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
              '${_currencyFormat.format(item.price)}원 × ${item.quantity}개 = ${_currencyFormat.format(item.price * item.quantity)}원',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151), // gray-700
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 방 정보 섹션 (모바일 반응형)
  Widget _buildRoomInfoSection(ContractListItem contract, bool showChatButton) {
    final isMobile = ResponsiveUtil.isMobile(context);

    if (isMobile) {
      // 모바일: 세로 배치 (이미지 위, 정보 아래)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 방 사진 (전체 너비, 높이 192px)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: contract.roomThumbnail != null
                ? Image.network(
                    contract.roomThumbnail!,
                    width: double.infinity,
                    height: 192,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 192,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.home, size: 40),
                      );
                    },
                  )
                : Container(
                    width: double.infinity,
                    height: 192,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.home, size: 40),
                  ),
          ),
          const SizedBox(height: 16),

          // 계약 정보
          _buildContractInfoColumn(contract, showChatButton, isMobile: true),
        ],
      );
    } else {
      // 태블릿/데스크톱: 가로 배치
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 방 사진 (140x140)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: contract.roomThumbnail != null
                ? Image.network(
                    contract.roomThumbnail!,
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 140,
                        height: 140,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.home, size: 40),
                      );
                    },
                  )
                : Container(
                    width: 140,
                    height: 140,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.home, size: 40),
                  ),
          ),
          const SizedBox(width: 16),

          // 계약 정보
          Expanded(
            child: _buildContractInfoColumn(contract, showChatButton, isMobile: false),
          ),
        ],
      );
    }
  }

  /// 계약 정보 컬럼
  Widget _buildContractInfoColumn(ContractListItem contract, bool showChatButton, {required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 방 이름
        Text(
          contract.roomName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827), // gray-900
          ),
        ),
        SizedBox(height: isMobile ? 12 : 8),

        // 주소
        _buildInfoRow('주소', contract.roomAddress, isMobile: isMobile),
        SizedBox(height: isMobile ? 12 : 4),

        // 계약 기간
        _buildInfoRow(
          '계약 기간',
          '${_dateFormat.format(contract.checkInDate)} - ${_dateFormat.format(contract.checkOutDate)} (${contract.totalDays}일)',
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 12 : 4),

        // 결제 금액
        _buildInfoRow(
          '결제 금액',
          '₩${_currencyFormat.format(contract.finalTotalAmount)}',
          isMobile: isMobile,
          valueStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        SizedBox(height: isMobile ? 12 : 4),

        // 호스트 + 채팅 버튼
        _buildHostRow(contract, showChatButton, isMobile: isMobile),
      ],
    );
  }

  /// 호스트 행 (채팅 버튼 포함)
  Widget _buildHostRow(ContractListItem contract, bool showChatButton, {required bool isMobile}) {
    final labelWidget = Text(
      '호스트',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF6B7280), // gray-600
      ),
    );

    final valueWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          contract.partnerDisplayName,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF111827),
          ),
        ),
        if (showChatButton) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              context.go('/chat-list?contractId=${contract.id}');
            },
            child: const Icon(
              Icons.chat_bubble_outline,
              color: Color(0xFF2563EB),
              size: 18,
            ),
          ),
        ],
      ],
    );

    if (isMobile) {
      // 모바일: 세로 배치
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          labelWidget,
          const SizedBox(height: 4),
          valueWidget,
        ],
      );
    } else {
      // 태블릿/데스크톱: 가로 배치
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: labelWidget),
          Flexible(child: valueWidget),
        ],
      );
    }
  }

  /// 정보 행 (모바일 반응형)
  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle, bool isMobile = false}) {
    final labelWidget = Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF6B7280), // gray-600
      ),
    );

    final valueWidget = Text(
      value,
      style: valueStyle ?? const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: Color(0xFF000000),
      ),
    );

    if (isMobile) {
      // 모바일: 세로 배치
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          labelWidget,
          const SizedBox(height: 4),
          valueWidget,
        ],
      );
    } else {
      // 태블릿/데스크톱: 가로 배치
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: labelWidget),
          Expanded(child: valueWidget),
        ],
      );
    }
  }

  /// 옵션 추가 모달 표시 (리액트 UI 기준)
  void _showAddOptionModal(ContractListItem contract) async {
    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      ),
    );

    try {
      // 이용 가능한 옵션 조회
      final rentalOrderService = RentalOrderService();
      final availableItems = await rentalOrderService.getAvailableRentalItems(contract.id);

      if (!mounted) return;
      Navigator.pop(context); // 로딩 닫기

      // 모달 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _AddOptionModal(
          contract: contract,
          availableOptions: availableItems,
          onConfirm: (selectedOptions) {
            // 결제 페이지로 이동
            _handleAdditionalOptionPayment(contract, selectedOptions);
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // 로딩 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('옵션 조회 오류: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  /// 옵션 환불 모달 표시 (리액트 UI 기준 - 테이블 형식)
  void _showCancelOptionModal(ContractListItem contract) async {
    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      ),
    );

    try {
      // 렌탈 주문 내역 조회
      final rentalOrderService = RentalOrderService();
      final response = await rentalOrderService.getRentalOrders(contract.id);

      if (!mounted) return;
      Navigator.pop(context); // 로딩 닫기

      if (response.orders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('구매한 옵션 상품이 없습니다.'),
            backgroundColor: Color(0xFF6B7280),
          ),
        );
        return;
      }

      // 환불 모달 표시 (테이블 형식)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _CancelOptionModal(
          contract: contract,
          orders: response.orders,
          onRefund: (rentalOrderId, itemId, reason) async {
            await _handleRefund(rentalOrderId, itemId, reason);
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // 로딩 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('주문 내역 조회 오류: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  /// 추가 옵션 결제 처리
  Future<void> _handleAdditionalOptionPayment(
    ContractListItem contract,
    Map<int, int> selectedOptions,
  ) async {
    if (selectedOptions.isEmpty) return;

    try {
      // 옵션 아이템 준비
      final items = <RentalOrderItem>[];

      for (final entry in selectedOptions.entries) {
        if (entry.value > 0) {
          items.add(RentalOrderItem(
            itemId: entry.key,
            quantity: entry.value,
          ));
        }
      }

      // 렌탈 주문 서비스로 추가 주문 생성
      final rentalOrderService = RentalOrderService();
      final orderResponse = await rentalOrderService.createRentalOrder(
        contractId: contract.id,
        items: items,
      );

      if (!mounted) return;

      // 결제 정보 조회
      final paymentInfo = await rentalOrderService.getPaymentInfo(orderResponse.rentalOrderId);

      if (!mounted) return;

      // 웹: 토스 페이먼츠로 결제
      if (kIsWeb) {
        final paymentService = PaymentServiceUnified();
        await paymentService.requestRentalPayment(
          rentalOrderId: orderResponse.rentalOrderId,
          orderId: paymentInfo['orderId'] as String,
          amount: paymentInfo['amount'] as int,
          orderName: paymentInfo['orderName'] as String,
          customerName: paymentInfo['customerName'] as String?,
          customerEmail: paymentInfo['customerEmail'] as String?,
        );
      }
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

  /// 환불 처리
  Future<void> _handleRefund(int rentalOrderId, int itemId, String reason) async {
    try {
      final rentalOrderService = RentalOrderService();
      await rentalOrderService.cancelItem(
        rentalOrderId: rentalOrderId,
        itemId: itemId,
        reason: reason,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('환불이 완료되었습니다. 영업일 기준 3-5일 내 입금됩니다.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      // 계약 목록 새로고침
      _loadContracts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('환불 오류: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      rethrow;
    }
  }

  /// 결제 처리
  ///
  /// 토스페이먼츠 SDK가 자체적으로 결제수단 선택 UI를 제공하므로
  /// 별도의 결제수단 선택 모달 없이 바로 결제를 요청합니다.
  Future<void> _handlePayment(ContractListItem contract) async {
    try {
      // 1. PaymentServiceUnified 인스턴스 생성
      final paymentService = PaymentServiceUnified();

      // 2. 결제 정보 조회
      final paymentInfo = await paymentService.getPaymentInfo(contract.id);

      if (!mounted) return;

      // 3. 플랫폼별 결제 처리
      if (kIsWeb) {
        // 웹: JavaScript SDK로 결제창 호출
        // 토스 SDK가 자체적으로 결제수단 선택 UI를 제공함
        await paymentService.requestPayment(
          contractId: contract.id,
          paymentInfo: paymentInfo,
        );
        // 이후 /payment/success 또는 /payment/fail로 자동 리다이렉트됨
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
          // 결제 승인 처리
          await paymentService.confirmPayment(
            contractId: contract.id,
            paymentKey: result['paymentKey'] as String,
            orderId: result['orderId'] as String,
            amount: result['amount'] as int,
          );

          if (!mounted) return;

          // 성공 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('결제가 완료되었습니다!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );

          // 계약 목록 새로고침
          _loadContracts();
        }
      }
    } catch (e) {
      if (!mounted) return;

      // 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('결제 오류: $e'),
          backgroundColor: const Color(0xFFF44336),
        ),
      );
    }
  }
}

/// 환불 모달 위젯
class _RefundModal extends StatefulWidget {
  final ContractListItem contract;
  final List<RentalOrder> orders;
  final Future<void> Function(int rentalOrderId, int itemId) onRefund;

  const _RefundModal({
    required this.contract,
    required this.orders,
    required this.onRefund,
  });

  @override
  State<_RefundModal> createState() => _RefundModalState();
}

class _RefundModalState extends State<_RefundModal> {
  final _currencyFormat = NumberFormat('#,###');
  bool _isProcessing = false;
  final Set<String> _selectedItems = {}; // "orderId_itemId" 형식

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들 바
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 헤더
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '옵션 상품 환불',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: const Color(0xFF6B7280),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 주문 목록
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '환불할 상품을 선택하세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...widget.orders.map((order) => _buildOrderCard(order)),
                ],
              ),
            ),
          ),
          // 하단 버튼
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedItems.isEmpty || _isProcessing
                          ? null
                          : _processRefunds,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFFDC2626),
                        disabledBackgroundColor: const Color(0xFFD1D5DB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              '환불 요청 (${_selectedItems.length}개)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(RentalOrder order) {
    final activeItems = order.items.where((item) => item.status == 'ACTIVE').toList();
    if (activeItems.isEmpty) return const SizedBox.shrink();

    final orderDate = order.createdAt != null
        ? DateFormat('yyyy.MM.dd HH:mm').format(order.createdAt!)
        : '날짜 없음';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 주문 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.orderType == 'INITIAL'
                        ? const Color(0xFFDBEAFE)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order.orderType == 'INITIAL' ? '최초 주문' : '추가 주문',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: order.orderType == 'INITIAL'
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    orderDate,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                Text(
                  '${_currencyFormat.format(order.totalAmount)}원',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          // 아이템 목록
          ...activeItems.map((item) => _buildItemRow(order, item)),
        ],
      ),
    );
  }

  Widget _buildItemRow(RentalOrder order, RentalOrderItemDetail item) {
    final key = '${order.id}_${item.id}';
    final isSelected = _selectedItems.contains(key);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedItems.remove(key);
          } else {
            _selectedItems.add(key);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        child: Row(
          children: [
            // 체크박스
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFDC2626) : Colors.white,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFDC2626)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            // 상품 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_currencyFormat.format(item.price)}원 × ${item.quantity}개',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            // 금액
            Text(
              '${_currencyFormat.format(item.subtotal)}원',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processRefunds() async {
    if (_selectedItems.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      for (final key in _selectedItems) {
        final parts = key.split('_');
        final rentalOrderId = int.parse(parts[0]);
        final itemId = int.parse(parts[1]);

        await widget.onRefund(rentalOrderId, itemId);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('환불 처리 중 오류: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

/// 옵션 추가 모달 (리액트 UI 기준)
class _AddOptionModal extends StatefulWidget {
  final ContractListItem contract;
  final List<AvailableRentalItem> availableOptions;
  final void Function(Map<int, int> selectedOptions) onConfirm;

  const _AddOptionModal({
    required this.contract,
    required this.availableOptions,
    required this.onConfirm,
  });

  @override
  State<_AddOptionModal> createState() => _AddOptionModalState();
}

class _AddOptionModalState extends State<_AddOptionModal> {
  final _currencyFormat = NumberFormat('#,###');
  final Map<int, int> _quantities = {};

  int get _totalAmount {
    int total = 0;
    for (final entry in _quantities.entries) {
      if (entry.value > 0) {
        final option = widget.availableOptions.firstWhere(
          (o) => o.id == entry.key,
          orElse: () => AvailableRentalItem(id: 0, name: '', price: 0, availableStock: 0),
        );
        total += option.price * entry.value;
      }
    }
    return total;
  }

  bool get _hasSelection => _quantities.values.any((q) => q > 0);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 672), // max-w-2xl
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '옵션 추가 구매',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827), // gray-900
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(4),
                    child: const Icon(
                      Icons.close,
                      size: 24,
                      color: Color(0xFF9CA3AF), // gray-400
                    ),
                  ),
                ],
              ),
            ),

            // 안내 메시지 (파란색 박스)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF), // blue-50
                  border: Border.all(color: const Color(0xFFBFDBFE)), // blue-200
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '• 계약 시작일의 5일 전 까지만 구매할 수 있어요.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1E40AF), // blue-800
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 옵션 목록
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: widget.availableOptions.map((option) {
                    final qty = _quantities[option.id] ?? 0;
                    return _buildOptionCard(option, qty);
                  }).toList(),
                ),
              ),
            ),

            // 결제 금액 및 버튼
            if (_hasSelection) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFD1D5DB)), // gray-300
                  ),
                ),
                child: Column(
                  children: [
                    // 총 결제 금액
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF), // blue-50
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '총 결제 금액',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827), // gray-900
                            ),
                          ),
                          Text(
                            '${_currencyFormat.format(_totalAmount)}원',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB), // blue-600
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 버튼
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(
                                color: Color(0xFFD1D5DB), // gray-300
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              '취소',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF374151), // gray-700
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onConfirm(_quantities);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: const Color(0xFF2563EB), // blue-600
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              '결제하기',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else
              const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(AvailableRentalItem option, int qty) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)), // gray-200
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상품명
          Text(
            option.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827), // gray-900
            ),
          ),
          // 설명
          if (option.description != null && option.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              option.description!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280), // gray-500
              ),
            ),
          ],
          // 가격
          const SizedBox(height: 4),
          Text(
            '개당 ${_currencyFormat.format(option.price)}원',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB), // blue-600
            ),
          ),
          const SizedBox(height: 12),

          // 수량 조절 및 금액
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 수량 조절
              Row(
                children: [
                  // 마이너스 버튼
                  InkWell(
                    onTap: qty > 0
                        ? () {
                            setState(() {
                              _quantities[option.id] = qty - 1;
                            });
                          }
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFD1D5DB), // gray-300
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.remove,
                        size: 16,
                        color: qty > 0
                            ? const Color(0xFF4B5563) // gray-600
                            : const Color(0xFFD1D5DB), // gray-300
                      ),
                    ),
                  ),
                  // 수량
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$qty',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  // 플러스 버튼
                  InkWell(
                    onTap: qty < option.availableStock
                        ? () {
                            setState(() {
                              _quantities[option.id] = qty + 1;
                            });
                          }
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('이 옵션은 최대 ${option.availableStock}개까지 선택 가능합니다.'),
                                backgroundColor: const Color(0xFFF59E0B),
                              ),
                            );
                          },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF2563EB), // blue-600
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 16,
                        color: Color(0xFF2563EB), // blue-600
                      ),
                    ),
                  ),
                ],
              ),
              // 금액
              if (qty > 0)
                Text(
                  '${_currencyFormat.format(option.price * qty)}원',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827), // gray-900
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 옵션 환불 모달 (리액트 UI 기준 - 테이블 형식)
class _CancelOptionModal extends StatefulWidget {
  final ContractListItem contract;
  final List<RentalOrder> orders;
  final Future<void> Function(int rentalOrderId, int itemId, String reason) onRefund;

  const _CancelOptionModal({
    required this.contract,
    required this.orders,
    required this.onRefund,
  });

  @override
  State<_CancelOptionModal> createState() => _CancelOptionModalState();
}

class _CancelOptionModalState extends State<_CancelOptionModal> {
  final _currencyFormat = NumberFormat('#,###');
  final Set<int> _refundedOrders = {};
  final Set<int> _refundRequestedOrders = {};
  bool _isProcessing = false;

  String _formatDateWithDay(DateTime? date) {
    if (date == null) return '-';
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ($weekday)';
  }

  String _getDeliveryStatusText(String? status) {
    switch (status) {
      case 'pending':
      case 'preparing':
      case 'PENDING':
      case 'PREPARING':
        return '배송 준비중';
      case 'shipping':
      case 'SHIPPING':
        return '배송중';
      case 'delivered':
      case 'DELIVERED':
        return '배송 완료';
      default:
        return status ?? '배송 준비중';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 결제 완료된 주문만 필터링
    final paidOrders = widget.orders.where((o) => o.status == 'PAID').toList();
    final isMobile = ResponsiveUtil.isMobile(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Container(
        constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 1024), // max-w-5xl
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '옵션 환불',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827), // gray-900
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(4),
                    child: const Icon(
                      Icons.close,
                      size: 24,
                      color: Color(0xFF9CA3AF), // gray-400
                    ),
                  ),
                ],
              ),
            ),

            // 안내 메시지 (노란색 박스)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEFCE8), // yellow-50
                  border: Border.all(color: const Color(0xFFFDE68A)), // yellow-200
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '• 옵션 상품은 배송 전에는 전액 환불, 배송이 시작된 이후에는 왕복 배송비 7,000원 차감 후 환불됩니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF854D0E), // yellow-800
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 테이블 (PC) / 카드 리스트 (모바일)
            if (paidOrders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Text(
                  '구매한 옵션 상품이 없습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280), // gray-500
                  ),
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                  child: isMobile
                      ? _buildOrderCardList(paidOrders)
                      : _buildOrderTable(paidOrders),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// 배송 상태 뱃지 스타일
  Color _getDeliveryStatusBadgeColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
      case 'preparing':
        return const Color(0xFFFEF3C7); // yellow-100
      case 'shipping':
        return const Color(0xFFDBEAFE); // blue-100
      case 'delivered':
        return const Color(0xFFDCFCE7); // green-100
      default:
        return const Color(0xFFF3F4F6); // gray-100
    }
  }

  Color _getDeliveryStatusTextColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
      case 'preparing':
        return const Color(0xFF92400E); // yellow-800
      case 'shipping':
        return const Color(0xFF1E40AF); // blue-800
      case 'delivered':
        return const Color(0xFF166534); // green-800
      default:
        return const Color(0xFF1F2937); // gray-800
    }
  }

  Color _getDeliveryStatusBorderColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
      case 'preparing':
        return const Color(0xFFFCD34D); // yellow-300
      case 'shipping':
        return const Color(0xFF93C5FD); // blue-300
      case 'delivered':
        return const Color(0xFF86EFAC); // green-300
      default:
        return const Color(0xFFD1D5DB); // gray-300
    }
  }

  /// 모바일 - 카드 리스트 형식 (sm:hidden space-y-4)
  Widget _buildOrderCardList(List<RentalOrder> orders) {
    return Column(
      children: orders.map((order) {
        final activeItems = order.items.where((item) => item.status == 'ACTIVE').toList();
        if (activeItems.isEmpty) return const SizedBox.shrink();

        final isRefunded = _refundedOrders.contains(order.id);
        final isRefundRequested = _refundRequestedOrders.contains(order.id);
        final deliveryStatus = activeItems.first.deliveryStatus;

        return Container(
          margin: const EdgeInsets.only(bottom: 16), // space-y-4
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8), // rounded-lg
            border: Border.all(color: const Color(0xFFD1D5DB)), // border-gray-300
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 주문일자 + 주문번호 + 배송상태 뱃지 (bg-gray-100)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // px-4 py-3
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6), // bg-gray-100
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFD1D5DB), width: 2), // border-b-2 border-gray-300
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 주문일자
                    Text(
                      _formatDateWithDay(order.createdAt),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827), // gray-900
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 주문번호 + 배송상태 뱃지 (같은 줄)
                    Row(
                      children: [
                        // 주문번호
                        Text(
                          order.orderId,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280), // gray-500
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 배송상태 뱃지 (주문번호 바로 옆)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getDeliveryStatusBadgeColor(deliveryStatus),
                            borderRadius: BorderRadius.circular(9999), // rounded-full
                            border: Border.all(color: _getDeliveryStatusBorderColor(deliveryStatus)),
                          ),
                          child: Text(
                            _getDeliveryStatusText(deliveryStatus),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getDeliveryStatusTextColor(deliveryStatus),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 상품 목록 + 총액 + 환불 버튼
              Padding(
                padding: const EdgeInsets.all(16), // px-4 py-3
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 상품 목록
                    ...activeItems.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final isLast = idx == activeItems.length - 1;
                      // subtotal 사용 (0이면 price * quantity로 계산)
                      final itemTotal = item.subtotal > 0 ? item.subtotal : item.price * item.quantity;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 상품명
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827), // gray-900
                            ),
                          ),
                          // 상품 설명 (있을 경우)
                          if (item.description != null && item.description!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.description!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280), // gray-500
                              ),
                            ),
                          ],
                          // 금액 (수량)
                          const SizedBox(height: 4),
                          Text(
                            '${_currencyFormat.format(itemTotal)}원 (${item.quantity}개)',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827), // gray-900
                            ),
                          ),
                          if (!isLast) ...[
                            const SizedBox(height: 12),
                            const Divider(color: Color(0xFFE5E7EB), height: 1), // border-t border-gray-200
                            const SizedBox(height: 12),
                          ],
                        ],
                      );
                    }),

                    // 총 주문금액 (pt-2 border-t-2 border-gray-300)
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.only(top: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFD1D5DB), width: 2),
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${_currencyFormat.format(order.totalAmount)}원',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827), // gray-900
                          ),
                        ),
                      ),
                    ),

                    // 환불 버튼 (w-full)
                    const SizedBox(height: 8),
                    _buildMobileRefundButton(order, isRefunded, isRefundRequested),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 모바일용 전체 너비 환불 버튼
  Widget _buildMobileRefundButton(RentalOrder order, bool isRefunded, bool isRefundRequested) {
    String buttonText;
    if (isRefunded) {
      buttonText = '환불 완료';
    } else if (isRefundRequested) {
      buttonText = '환불 대기';
    } else {
      final deliveryStatus = order.items.first.deliveryStatus ?? '';
      if (deliveryStatus.toLowerCase() == 'delivered') {
        buttonText = '환불 요청';
      } else {
        buttonText = '환불하기';
      }
    }

    final isDisabled = isRefunded || isRefundRequested || _isProcessing;

    return SizedBox(
      width: double.infinity, // w-full
      child: ElevatedButton(
        onPressed: isDisabled ? null : () => _handleRefundClick(order),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // px-4 py-3
          backgroundColor: isDisabled
              ? const Color(0xFFF3F4F6) // gray-100
              : const Color(0xFF2563EB), // blue-600
          foregroundColor: isDisabled
              ? const Color(0xFF6B7280) // gray-500
              : Colors.white,
          disabledBackgroundColor: const Color(0xFFF3F4F6),
          disabledForegroundColor: const Color(0xFF6B7280),
          side: isDisabled
              ? const BorderSide(color: Color(0xFFD1D5DB)) // gray-300
              : const BorderSide(color: Color(0xFF2563EB)), // blue-600
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // rounded-lg
          ),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 주문 테이블 빌드 (주문별로 그룹화) - PC 전용
  Widget _buildOrderTable(List<RentalOrder> orders) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB), // gray-50
              border: Border(
                bottom: BorderSide(color: Color(0xFFD1D5DB), width: 2),
              ),
            ),
            child: Row(
              children: [
                _buildHeaderCell('주문일자\n(주문번호)', flex: 15),
                _buildHeaderCell('상품정보', flex: 30),
                _buildHeaderCell('수량', flex: 10, align: TextAlign.center),
                _buildHeaderCell('상품금액', flex: 13, align: TextAlign.right),
                _buildHeaderCell('총 금액', flex: 13, align: TextAlign.right),
                _buildHeaderCell('상태', flex: 19, align: TextAlign.center),
              ],
            ),
          ),
          // 주문 목록
          ...orders.map((order) => _buildOrderRow(order)),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required int flex, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          textAlign: align,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF374151), // gray-700
          ),
        ),
      ),
    );
  }

  /// 주문 행 빌드 (아이템이 여러 개일 경우 세로로 병합)
  Widget _buildOrderRow(RentalOrder order) {
    final activeItems = order.items.where((item) => item.status == 'ACTIVE').toList();
    if (activeItems.isEmpty) return const SizedBox.shrink();

    final isRefunded = _refundedOrders.contains(order.id);
    final isRefundRequested = _refundRequestedOrders.contains(order.id);

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 주문일자 (주문번호) - 세로 병합
            Expanded(
              flex: 15,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB), // gray-50
                  border: Border(
                    right: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDateWithDay(order.createdAt),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827), // gray-900
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.orderId,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280), // gray-500
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 상품 목록 (상품정보, 수량, 상품금액)
            Expanded(
              flex: 53, // 30 + 10 + 13
              child: Column(
                children: activeItems.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final isLast = idx == activeItems.length - 1;

                  return Container(
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : const Border(
                              bottom: BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                    ),
                    child: Row(
                      children: [
                        // 상품정보
                        Expanded(
                          flex: 30,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ),
                        // 수량
                        Expanded(
                          flex: 10,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              '${item.quantity}개',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ),
                        // 상품금액
                        Expanded(
                          flex: 13,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              '${_currencyFormat.format(item.subtotal)}원',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // 총 금액 - 세로 병합
            Expanded(
              flex: 13,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF), // blue-50
                  border: Border(
                    left: BorderSide(color: Color(0xFFE5E7EB)),
                    right: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${_currencyFormat.format(order.totalAmount)}원',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB), // blue-600
                    ),
                  ),
                ),
              ),
            ),

            // 상태 및 환불 버튼 - 세로 병합
            Expanded(
              flex: 19,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getDeliveryStatusText(activeItems.first.deliveryStatus),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827), // gray-900
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRefundButton(order, isRefunded, isRefundRequested),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundButton(RentalOrder order, bool isRefunded, bool isRefundRequested) {
    String buttonText;
    if (isRefunded) {
      buttonText = '환불 완료';
    } else if (isRefundRequested) {
      buttonText = '환불 대기';
    } else {
      final deliveryStatus = order.items.first.deliveryStatus ?? '';
      if (deliveryStatus.toLowerCase() == 'delivered') {
        buttonText = '환불 요청';
      } else {
        buttonText = '환불하기';
      }
    }

    final isDisabled = isRefunded || isRefundRequested || _isProcessing;

    return ElevatedButton(
      onPressed: isDisabled ? null : () => _handleRefundClick(order),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        backgroundColor: isDisabled
            ? const Color(0xFFF3F4F6) // gray-100
            : const Color(0xFF2563EB), // blue-600
        foregroundColor: isDisabled
            ? const Color(0xFF6B7280) // gray-500
            : Colors.white,
        disabledBackgroundColor: const Color(0xFFF3F4F6),
        disabledForegroundColor: const Color(0xFF6B7280),
        side: isDisabled
            ? const BorderSide(color: Color(0xFFD1D5DB)) // gray-300
            : const BorderSide(color: Color(0xFF2563EB)), // blue-600
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        buttonText,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _handleRefundClick(RentalOrder order) async {
    final deliveryStatus = order.items.first.deliveryStatus?.toLowerCase() ?? '';
    final isShipping = deliveryStatus == 'shipping';
    final isDelivered = deliveryStatus == 'delivered';
    final refundAmount = isShipping ? order.totalAmount - 7000 : order.totalAmount;

    if (isDelivered) {
      // 배송 완료 - 환불 요청
      setState(() => _refundRequestedOrders.add(order.id));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('환불 요청이 제출되었습니다. 관리자 승인 후 처리됩니다.'),
          backgroundColor: Color(0xFF2563EB),
        ),
      );
      return;
    }

    // 확인 다이얼로그
    final confirmMsg = isShipping
        ? '배송중인 상품입니다. 왕복 배송비 7,000원을 차감한 ${_currencyFormat.format(refundAmount)}원이 환불됩니다. 진행하시겠습니까?'
        : '${_currencyFormat.format(refundAmount)}원이 환불됩니다. 진행하시겠습니까?';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('환불 확인'),
        content: Text(confirmMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
            child: const Text('환불하기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 환불 처리
    setState(() => _isProcessing = true);

    try {
      for (final item in order.items.where((i) => i.status == 'ACTIVE')) {
        await widget.onRefund(order.id, item.id, '고객 요청 환불');
      }

      setState(() {
        _refundedOrders.add(order.id);
        _isProcessing = false;
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('환불 오류: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }
}
