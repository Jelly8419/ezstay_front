import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/exceptions.dart';
import 'package:go_router/go_router.dart';
import '../../utils/format_utils.dart';
import '../../utils/contract_utils.dart';
import '../../constants/notice_texts.dart';
import '../../models/contract.dart';
import '../../services/contract_service.dart';
import '../../services/payment_service_unified.dart';
import '../../services/payment_service_web.dart'
    if (dart.library.io) '../../services/payment_service_stub.dart';
import '../../services/rental_order_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../utils/responsive_util.dart';
import '../../widgets/payment_webview.dart';
import '../../widgets/payment_method_modal.dart';
// import '../../widgets/modals/refund_calculation_modal.dart'; // TODO: API로 전체 Contract 가져오기 후 사용
import '../../widgets/modals/cancel_request_modal.dart';
import '../../widgets/modals/deposit_agreement_review_modal.dart';
import '../../widgets/common/app_footer.dart';

part '_cancel_option_modal_state.dart';

/// 게스트용 계약 목록 페이지 (리액트 UI 기반 재설계)
class GuestContractsPage extends StatefulWidget {
  const GuestContractsPage({super.key});

  @override
  State<GuestContractsPage> createState() => _GuestContractsPageState();
}

class _GuestContractsPageState extends State<GuestContractsPage> {
  final ContractService _contractService = ContractService();
  final RentalOrderService _rentalOrderService = RentalOrderService();
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
      await _fetchCompleteRentalItemsForAllContracts(contracts);

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

  /// 렌탈 아이템 API를 호출하여 완전한 데이터 구성
  Future<void> _fetchCompleteRentalItemsForAllContracts(
    List<ContractListItem> contracts,
  ) async {
    try {
      // 렌탈 아이템 전체 목록 가져오기 (inStock=true는 기본값)
      final rentalItemsResponse = await _contractService.getAllRentalItems();

      if (rentalItemsResponse == null) {
        AppLogger.w('⚠️ [RENTAL_ITEMS] Failed to fetch rental items from API');
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
        }
      }


      // 각 계약의 렌탈 아이템을 완전한 데이터로 변환
      for (final contract in contracts) {
        if (contract.rentalItems == null || contract.rentalItems!.isEmpty) {
          continue;
        }

        final completeRentalItems = <RentalItem>[];

        for (final contractItem in contract.rentalItems!) {

          // API에서 가져온 렌탈 아이템 데이터 찾기
          // ✅ FIX: ID를 String으로 변환하여 Map 조회 (allRentalItems의 키가 String이므로)
          final itemData = allRentalItems[contractItem.id.toString()];

          if (itemData != null) {
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
            // API에서 찾지 못한 경우 기존 데이터 유지
            completeRentalItems.add(contractItem);
          }
        }

        // 완전한 렌탈 아이템 목록 저장
        _savedRentalItems[contract.id] = completeRentalItems;

        // 계약 객체의 rentalItems도 업데이트
        contract.rentalItems?.clear();
        contract.rentalItems?.addAll(completeRentalItems);

      }
    } catch (e, stackTrace) {
      AppLogger.e('❌ [RENTAL_ITEMS] Failed to fetch rental items: $e');
      AppLogger.e('📍 Stack trace: $stackTrace');
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
        AppLogger.w('⚠️ [PRICE_PARSE] Failed to parse price: $price');
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

  /// 보증금 환급이 완료된 상태인지 확인
  /// returned(반환완료) 또는 returnConfirmed(반환확정)인 경우만 완료로 간주
  bool _isDepositRefundComplete(ContractListItem c) {
    return c.depositStatus == DepositStatus.returned ||
        c.depositStatus == DepositStatus.returnConfirmed;
  }

  // 탭별 계약 필터링
  List<ContractListItem> get _filteredContracts {
    if (_selectedTab == 'in_progress') {
      return _allContracts
          .where(
            (c) =>
                [
                  ContractStatus.pendingApproval,
                  ContractStatus.approved,
                  ContractStatus.paymentCompleted,
                  ContractStatus.inProgress,
                ].contains(c.status) ||
                // COMPLETED이지만 보증금 환급 미완료 시 진행중으로 표시
                (c.status == ContractStatus.completed &&
                    !_isDepositRefundComplete(c)),
          )
          .toList();
    } else if (_selectedTab == 'completed') {
      return _allContracts
          .where(
            (c) =>
                c.status == ContractStatus.completed &&
                _isDepositRefundComplete(c),
          )
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

  /// 옵션 편집/추가 버튼 표시 여부
  /// - PRD: PENDING_PAYMENT(approved) → 추가/수량변경 D-5 이전
  /// - PRD: PAID(paymentCompleted) → 추가 D-5 이전, 취소 가능
  /// - PRD: USING(inProgress) → 추가 X, 취소 X (환불 요청만 별도)
  bool _canShowEditButton(ContractListItem contract) {
    // 1. 상태 체크: 결제 전/후 + 임대 중 모두 옵션 버튼 표시
    final allowedStatuses = [
      ContractStatus.pendingApproval,
      ContractStatus.approved,
      ContractStatus.paymentCompleted,
      ContractStatus.inProgress,
    ];
    if (!allowedStatuses.contains(contract.status)) {
      return false;
    }

    // 2. 결제 전 상태는 D-5 체크 적용
    if (!_isAfterPayment(contract)) {
      if (!_isDaysBeforeCheckIn(contract.checkInDate, 5)) {
        return false;
      }
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    // 먼저 편집 모드 진입 (로딩 표시용)
    setState(() {
      _editingContractId = contract.id;
    });

    try {
      // API에서 이용 가능한 렌탈 아이템 목록 조회
      final availableItems = await _rentalOrderService.getAvailableRentalItems(
        contract.id,
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
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      AppLogger.e('❌ [AVAILABLE ITEMS] Error: $e');

      if (!mounted) return;

      // 에러 발생 시 편집 모드 취소
      setState(() {
        _editingContractId = null;
      });

      scaffoldMessenger.showSnackBar(
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
      final newQuantity = (item.quantity + delta).clamp(0, 5);

      options[itemIndex] = item.copyWith(quantity: newQuantity);
    });
  }

  /// 옵션 변경사항 저장
  Future<void> _handleSaveOptionChanges(ContractListItem contract) async {
    final modifiedItems = _modifiedOptions[contract.id];
    if (modifiedItems == null) return;

    // async 갭 전에 ScaffoldMessenger 미리 캡처
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 결제 전 상태인지 확인 (승인대기 또는 승인됨)
    // - PENDING_APPROVAL: 호스트 승인 대기 중
    // - APPROVED: 호스트 승인됨, 게스트 결제 대기 중
    final isBeforePayment =
        contract.status == ContractStatus.pendingApproval ||
        contract.status == ContractStatus.approved;

    if (isBeforePayment) {
      // 결제 전 상태: 총 옵션 금액 최소 10,000원 검증
      final totalOptionsFee = modifiedItems.fold(
        0,
        (sum, item) => sum + item.price * item.quantity,
      );
      if (totalOptionsFee > 0 && totalOptionsFee < 10000) {
        scaffoldMessenger
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('옵션 상품 총액은 최소 10,000원 이상이어야 합니다.'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        return;
      }
      // 결제 전 상태: 장바구니처럼 렌탈 아이템만 업데이트 (결제 없음)
      await _updatePendingRentalItems(contract, modifiedItems, scaffoldMessenger);
    } else {
      // 결제 후 상태 (PAYMENT_COMPLETED, IN_PROGRESS): 추가 결제 플로우 진행
      await _createRentalOrderWithPayment(contract, modifiedItems, scaffoldMessenger);
    }
  }

  /// 결제 전 상태: 렌탈 아이템 업데이트 (결제 없이 장바구니처럼)
  /// - PENDING_APPROVAL: 승인대기 상태
  /// - APPROVED: 승인됨 상태 (결제 대기 중)
  Future<void> _updatePendingRentalItems(
    ContractListItem contract,
    List<RentalItem> modifiedItems,
    ScaffoldMessengerState scaffoldMessenger,
  ) async {
    // 전체 아이템 목록 생성 (수량 0 제외)
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


      if (!mounted) return;

      // 상태에 따라 다른 안내 메시지 표시
      final message = contract.status == ContractStatus.pendingApproval
          ? '옵션 상품이 저장되었습니다. 승인 후 결제 시 반영됩니다.'
          : '옵션 상품이 저장되었습니다. 결제 시 반영됩니다.';

      scaffoldMessenger.showSnackBar(
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
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      AppLogger.e('❌ [UPDATE BEFORE_PAYMENT] Error: $e');
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
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
    ScaffoldMessengerState scaffoldMessenger,
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
        itemsToOrder.add(
          RentalOrderItem(itemId: itemIdInt, quantity: addedQty),
        );
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


    try {
      await _processRentalOrderPayment(contract, itemsToOrder, scaffoldMessenger);
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      AppLogger.e('❌ [SAVE OPTIONS] Error: $e');
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
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
    ScaffoldMessengerState scaffoldMessenger,
  ) async {
    // 1단계: 렌탈 주문 생성 (PENDING 상태)
    final orderResponse = await _rentalOrderService.createRentalOrder(
      contractId: contract.id,
      items: itemsToOrder,
    );


    if (orderResponse.totalAmount == 0) {
      // 결제 불필요 (무료 아이템 등)
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
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
    final customerPhone = paymentInfo['customerPhone'] as String?;


    // 3단계: 결제수단 선택 모달
    if (!mounted) return;
    final selectedMethod = await showPaymentMethodModal(
      context,
      totalAmount: amount,
    );

    if (selectedMethod == null || !mounted) return;

    // 4단계: PayTag SDK 호출
    await _processRentalPayment(
      contract: contract,
      rentalOrderId: orderResponse.rentalOrderId,
      orderId: orderId,
      amount: amount,
      orderName: orderName,
      payType: selectedMethod.value,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      scaffoldMessenger: scaffoldMessenger,
    );
  }

  /// PayTag 렌탈 결제 처리
  ///
  /// 웹: JavaScript SDK로 결제창 호출 → /rental-payment/success로 리다이렉트
  /// 모바일: WebView로 결제창 표시 → 결과 처리
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
    required ScaffoldMessengerState scaffoldMessenger,
  }) async {
    try {
      if (kIsWeb) {
        // 웹: PayTag JavaScript SDK 직접 호출
        final paymentService = PaymentServiceUnified();


        // PayTag SDK 호출 (렌탈 결제)
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

        setState(() {
          _editingContractId = null;
          _modifiedOptions.remove(contract.id);
        });

        if (payResult != null) {
          if (!mounted) return;
          _showRentalPaymentSuccessDialog(payResult, onConfirm: _loadContracts);
        } else {
          _loadContracts();
        }
      } else {
        // 모바일: 현재 웹 전용
        // TODO: 모바일 PayTag WebView 렌탈 결제 구현
        throw Exception('모바일에서는 아직 렌탈 추가 결제가 지원되지 않습니다.');
      }
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      AppLogger.e('❌ [RENTAL PAYMENT] Error: $e');

      // 미결제 주문 취소 시도
      try {
        await _rentalOrderService.cancelPendingOrder(rentalOrderId);
      } catch (cancelError) {
      }

      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
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

  /// 렌탈 결제 완료 다이얼로그
  void _showRentalPaymentSuccessDialog(Map<String, dynamic> result, {VoidCallback? onConfirm}) {
    final paidAmount = result['paidAmount'] as int?;
    final receiptUrl = result['receiptUrl'] as String?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success500, size: 28),
            const SizedBox(width: 8),
            const Text('결제 완료'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('옵션 상품 결제가 완료되었습니다!'),
            if (paidAmount != null) ...[
              const SizedBox(height: 12),
              Text(
                '결제 금액: ${_formatAmount(paidAmount)}원',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            if (receiptUrl != null && receiptUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(receiptUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  '영수증 확인',
                  style: TextStyle(
                    color: AppColors.primary500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
            ),
            child: const Text('확인', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  /// 활성 렌탈 아이템이 있는지 확인
  bool _hasActiveRentalItems(ContractListItem contract) {
    final items = contract.rentalItems;
    if (items == null || items.isEmpty) return false;
    return items.any((item) => item.quantity > 0);
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

      showDialog(
        context: context,
        builder: (context) => DepositAgreementReviewModal(
          agreement: agreement,
          onAccept: () async {
            Navigator.of(context).pop();
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
          onClose: () => Navigator.of(context).pop(),
        ),
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
    // rootNavigator: true 로 go_router 대신 최상위 Navigator를 사용해
    // go_router 페이지 스택을 건드리지 않고 다이얼로그만 닫음
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
    final reasonController = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) {
        final totalRefund = refundData?['finalRefundAmount'] ?? 0;
        final penalty = refundData?['penaltyAmount'] ?? 0;
        final refundRate = refundData?['rentalFeeRefundRate'] ?? 100;
        final policyName = refundData?['policyDisplayName'] ?? '';
        final ruleDesc = refundData?['applicableRuleDescription'] ?? '';
        final serverMessage = refundData?['message'] ?? '';
        final platformFeeDeducted = refundData?['platformFeeDeducted'] ?? 0;
        final isSameDay = refundData?['isSameDayCancellation'] ?? false;

        // 항목별 환불 금액
        final rentalFeeRefund = refundData?['rentalFeeRefundAmount'] ?? 0;
        final maintenanceFeeRefund = refundData?['maintenanceFeeRefundAmount'] ?? 0;
        final cleaningFeeRefund = refundData?['cleaningFeeRefundAmount'] ?? 0;
        final rentalItemsRefund = refundData?['rentalItemsFeeRefundAmount'] ?? 0;
        final depositRefund = refundData?['depositRefundAmount'] ?? 0;
        final guestServiceFeeRefunded = refundData?['guestServiceFeeRefunded'] ?? false;

        // 원금액
        final originalRentalFee = refundData?['originalRentalFee'] ?? 0;
        final originalMaintenanceFee = refundData?['originalMaintenanceFee'] ?? 0;
        final originalCleaningFee = refundData?['originalCleaningFee'] ?? 0;
        final originalRentalItemsFee = refundData?['originalRentalItemsFee'] ?? 0;
        final originalDeposit = refundData?['originalDeposit'] ?? 0;
        final originalPlatformFee = refundData?['originalPlatformFee'] ?? 0;

        return AlertDialog(
          title: const Text('계약 취소 및 환불 안내'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 환불 정책 정보
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (policyName.isNotEmpty)
                        Text(
                          '환불 정책: $policyName',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      if (ruleDesc.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          ruleDesc,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                      if (isSameDay) ...[
                        const SizedBox(height: 4),
                        const Text(
                          '결제 당일 취소 — 전액 환불',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 항목별 환불 내역
                const Text(
                  '환불 내역',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                _buildRefundRow(
                  '임대료 ($refundRate% 환불)',
                  '${FormatUtils.formatCurrency(rentalFeeRefund as num)}원',
                  subLabel: '결제액 ${FormatUtils.formatCurrency(originalRentalFee as num)}원',
                ),
                if ((originalMaintenanceFee as num) > 0)
                  _buildRefundRow(
                    '관리비',
                    '${FormatUtils.formatCurrency(maintenanceFeeRefund as num)}원',
                    subLabel: '결제액 ${FormatUtils.formatCurrency(originalMaintenanceFee)}원',
                  ),
                if ((originalCleaningFee as num) > 0)
                  _buildRefundRow(
                    '청소비',
                    '${FormatUtils.formatCurrency(cleaningFeeRefund as num)}원',
                    subLabel: '결제액 ${FormatUtils.formatCurrency(originalCleaningFee)}원',
                  ),
                if ((originalRentalItemsFee as num) > 0)
                  _buildRefundRow(
                    '옵션상품',
                    '${FormatUtils.formatCurrency(rentalItemsRefund as num)}원',
                    subLabel: '결제액 ${FormatUtils.formatCurrency(originalRentalItemsFee)}원',
                  ),
                if ((originalDeposit as num) > 0)
                  _buildRefundRow(
                    '보증금',
                    '${FormatUtils.formatCurrency(depositRefund as num)}원',
                    subLabel: '결제액 ${FormatUtils.formatCurrency(originalDeposit)}원',
                  ),
                _buildRefundRow(
                  '서비스 수수료',
                  guestServiceFeeRefunded
                      ? '${FormatUtils.formatCurrency(originalPlatformFee as num)}원'
                      : '환불 없음',
                  subLabel: '결제액 ${FormatUtils.formatCurrency(originalPlatformFee as num)}원',
                  isWarning: !guestServiceFeeRefunded,
                ),
                const Divider(height: 20),

                if ((penalty as num) > 0)
                  _buildRefundRow(
                    '위약금',
                    '-${FormatUtils.formatCurrency(penalty)}원',
                    isWarning: true,
                  ),
                if ((platformFeeDeducted as num) > 0)
                  _buildRefundRow(
                    '차감 수수료',
                    '-${FormatUtils.formatCurrency(platformFeeDeducted)}원',
                    isWarning: true,
                  ),
                _buildRefundRow(
                  '최종 환불 예정 금액',
                  '${FormatUtils.formatCurrency(totalRefund as num)}원',
                  isBold: true,
                  isHighlight: true,
                ),
                const SizedBox(height: 12),

                // 서버 안내 메시지
                if (serverMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Text(
                      serverMessage,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // 취소 사유 입력
                const Text(
                  '취소 사유',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '취소 사유를 입력해주세요',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('돌아가기'),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('취소 사유를 입력해주세요.'),
                      backgroundColor: Color(0xFFDC2626),
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('환불 요청'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRefundRow(
    String label,
    String value, {
    String? subLabel,
    bool isBold = false,
    bool isWarning = false,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                  color: isWarning
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF374151),
                ),
              ),
              if (subLabel != null)
                Text(
                  subLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
              color: isHighlight
                  ? const Color(0xFF2563EB)
                  : isWarning
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  // 탭별 계약 개수
  int _getTabCount(String tab) {
    if (tab == 'in_progress') {
      return _allContracts
          .where(
            (c) =>
                [
                  ContractStatus.pendingApproval,
                  ContractStatus.approved,
                  ContractStatus.paymentCompleted,
                  ContractStatus.inProgress,
                ].contains(c.status) ||
                (c.status == ContractStatus.completed &&
                    !_isDepositRefundComplete(c)),
          )
          .length;
    } else if (tab == 'completed') {
      return _allContracts
          .where(
            (c) =>
                c.status == ContractStatus.completed &&
                _isDepositRefundComplete(c),
          )
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
        return const Color(0xFFA16207); // yellow-700
      case ContractStatus.approvalExpired:
        return Colors.grey;
      case ContractStatus.approved:
        return const Color(0xFF1D4ED8); // blue-700
      case ContractStatus.paymentExpired:
        return Colors.grey.shade600;
      case ContractStatus.paymentCompleted:
        return const Color(0xFF15803D); // green-700
      case ContractStatus.inProgress:
        return const Color(0xFF7E22CE); // purple-700
      case ContractStatus.completed:
        return Colors.grey;
      case ContractStatus.rejected:
        return const Color(0xFFDC2626); // red-600
      case ContractStatus.cancelledByGuest:
      case ContractStatus.cancelledByHost:
      case ContractStatus.cancelledByAdminWithRefund:
      case ContractStatus.cancelledByAdminNoRefund:
        return Colors.grey;
      case ContractStatus.refunded:
        return const Color(0xFF7E22CE); // purple-700
      case ContractStatus.cancelRequested:
        return const Color(0xFFEA580C); // orange-600
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

  /// 퇴실 상태 표시 섹션
  Widget _buildCheckoutStatusSection(ContractListItem contract) {
    if (contract.checkoutStatus == null ||
        contract.checkoutStatus == CheckoutStatus.notStarted) {
      return const SizedBox.shrink();
    }

    Color bgColor;
    Color borderColor;
    Color textColor;
    String title;
    String message;

    switch (contract.checkoutStatus!) {
      case CheckoutStatus.guestCompleted:
        bgColor = const Color(0xFFFEF3C7); // yellow-100
        borderColor = const Color(0xFFFDE68A); // yellow-200
        textColor = const Color(0xFF92400E); // yellow-800
        title = '퇴실 확인 대기중';
        message = '호스트가 퇴실 상태를 확인하고 있습니다.';
      case CheckoutStatus.hostConfirmed:
        bgColor = const Color(0xFFDCFCE7); // green-100
        borderColor = const Color(0xFFBBF7D0); // green-200
        textColor = const Color(0xFF166534); // green-800
        title = '퇴실 확인 완료';
        message = '보증금 환급 절차가 진행됩니다.';
      case CheckoutStatus.holdRequested:
        bgColor = const Color(0xFFFFF7ED); // orange-50
        borderColor = const Color(0xFFFED7AA); // orange-200
        textColor = const Color(0xFF9A3412); // orange-800
        title = '보증금 반환 보류 신청중';
        message = '호스트가 보증금 반환 보류를 신청했습니다. 관리자 승인을 기다리고 있습니다.';
      case CheckoutStatus.hostPending:
        bgColor = const Color(0xFFFFF7ED); // orange-50
        borderColor = const Color(0xFFFED7AA); // orange-200
        textColor = const Color(0xFF9A3412); // orange-800
        if (contract.depositAgreementStatus == 'ACCEPTED') {
          title = '✅ 합의 완료';
          message = '보증금 합의가 완료되었습니다. 차감 후 환급이 진행됩니다.';
          bgColor = const Color(0xFFDCFCE7); // green-100
          borderColor = const Color(0xFFBBF7D0); // green-200
          textColor = const Color(0xFF166534); // green-800
        } else if (contract.depositAgreementStatus == 'SUBMITTED') {
          title = '합의 내용 확인 요청';
          message = '호스트가 보증금 합의 내용을 제출했습니다. 확인해주세요.';
        } else {
          title = '⚠️ 퇴실 확인 보류';
          message = '호스트가 합의 내용을 작성 중입니다.';
        }
      case CheckoutStatus.agreementSubmitted:
        bgColor = const Color(0xFFEFF6FF); // blue-50
        borderColor = const Color(0xFFBFDBFE); // blue-200
        textColor = const Color(0xFF1E40AF); // blue-800
        title = '합의 내용 확인 요청';
        message = '호스트가 보증금 합의 내용을 제출했습니다. 확인해주세요.';
      case CheckoutStatus.autoReturned:
        bgColor = const Color(0xFFDCFCE7); // green-100
        borderColor = const Color(0xFFBBF7D0); // green-200
        textColor = const Color(0xFF166534); // green-800
        title = '보증금 전액 반환';
        message = '합의 기한이 경과하여 보증금이 전액 반환됩니다.';
      case CheckoutStatus.notStarted:
        return const SizedBox.shrink();
    }

    // 합의 데드라인 계산 (정책 7.9.1: 관리자 승인 시점 + 10일)
    String? deadlineText;
    if (contract.checkoutStatus == CheckoutStatus.hostPending ||
        contract.checkoutStatus == CheckoutStatus.agreementSubmitted) {
      // 서버에서 agreementDeadline을 내려주면 사용, 없으면 퇴실일 + 10일 폴백
      DateTime deadline;
      if (contract.agreementDeadline != null) {
        deadline =
            DateTime.tryParse(contract.agreementDeadline!) ??
            contract.checkOutDate.add(const Duration(days: 10));
      } else {
        final checkoutTimeStr = contract.roomCheckoutTime ?? '11:00';
        final timeParts = checkoutTimeStr.split(':');
        final checkoutHour = int.tryParse(timeParts[0]) ?? 11;
        final checkoutMinute = timeParts.length > 1
            ? (int.tryParse(timeParts[1]) ?? 0)
            : 0;
        final checkOutDate = contract.checkOutDate;
        deadline = DateTime(
          checkOutDate.year,
          checkOutDate.month,
          checkOutDate.day,
          checkoutHour,
          checkoutMinute,
        ).add(const Duration(days: 10));
      }
      final remaining = deadline.difference(DateTime.now()).inDays;
      if (remaining > 0) {
        deadlineText =
            '합의 마감까지 D-$remaining일 (${deadline.month}/${deadline.day})';
      } else if (remaining == 0) {
        deadlineText = '합의 마감 오늘까지';
      } else {
        deadlineText = '합의 기한 경과';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(fontSize: 13, color: textColor),
                  ),
                  if (deadlineText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      deadlineText,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // AGREEMENT_SUBMITTED 또는 HOST_PENDING+SUBMITTED: "확인하기" 버튼
            if (contract.checkoutStatus == CheckoutStatus.agreementSubmitted ||
                (contract.checkoutStatus == CheckoutStatus.hostPending &&
                    contract.depositAgreementStatus == 'SUBMITTED')) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _showDepositAgreementReviewModal(contract),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  side: BorderSide(color: textColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  '확인하기',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 게스트 퇴실 완료 처리
  Future<void> _handleGuestCheckout(int contractId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('퇴실 완료'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('퇴실을 완료하시겠습니까?\n호스트가 퇴실 상태를 확인한 후 보증금 환급이 진행됩니다.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                border: Border.all(color: const Color(0xFFFECACA)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '방 도어락 비밀번호를 임의 변경 후 퇴실하셨을 경우, \n퇴실 확인 전에 호스트에게 비밀번호를 안내하지 않으면 보증금 환급 절차에 불이익이 발생할 수 있습니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF991B1B),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('돌아가기'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              foregroundColor: Colors.white,
            ),
            child: const Text('퇴실 완료'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _contractService.requestCheckout(contractId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('퇴실 완료가 처리되었습니다. 호스트의 확인을 기다려주세요.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _loadContracts();
      }
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '퇴실 처리 실패: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF9FAFB), // gray-50
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
            _buildContractsList(),
          ],
        ),
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
        color: isSelected ? AppColors.primary600 : Colors.white,
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

    return Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 896),
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
            color: AppColors.primary600, // blue-600
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
                    fontSize: 14,
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
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.grey.shade600,
            ),
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
                        vertical: 4,
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
                              fontSize: 14,
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
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 13,
                          color: statusColor,
                        ),
                      ),
                  ],
                ),
              ),

              // 상세 버튼
              IconButton(
                onPressed: () {
                  final path = '/guest/contracts/${contract.id}';
                  context.go(path);
                },
                icon: const Icon(Icons.article_outlined),
                color: AppColors.primary600, // blue-600
                tooltip: '상세',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 방 사진 + 계약 정보 (모바일: 세로 배치, 태블릿+: 가로 배치)
          _buildRoomInfoSection(contract, showChatButton),

          // 퇴실 상태 표시
          _buildCheckoutStatusSection(contract),

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
                label: Text('결제하기', style: AppTextStyles.labelMedium),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppColors.primary600, // blue-600
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
                  onPressed: () => _showRefundInfoAndCancel(contract),
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
                  color: Color(0xFF6B7280),
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
                        onSubmit: (reason) async {
                          Navigator.of(context).pop();
                          try {
                            await _contractService.requestCancellation(
                              contract.id,
                              reason,
                            );
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

          // 퇴실 완료 버튼 (COMPLETED 상태 + 퇴실 미처리)
          if (contract.status == ContractStatus.completed &&
              (contract.checkoutStatus == null ||
                  contract.checkoutStatus == CheckoutStatus.notStarted)) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _handleGuestCheckout(contract.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                '퇴실 완료',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 옵션 상품 섹션 구현
  Widget _buildOptionsSection(ContractListItem contract) {
    final isEditing = _editingContractId == contract.id;
    final currentOptions = _getCurrentOptions(contract);
    final canEdit = _canShowEditButton(contract);

    // 입주일 5일 전 체크 (추가 가능 여부)
    final canAddOption = _isDaysBeforeCheckIn(contract.checkInDate, 5);

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
                      color: AppColors.primary600, // blue-600
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
                      color: AppColors.primary600, // blue-600
                    ),
                  ),
                ),
              ],
              // 결제 후 상태: 추가 + 취소 버튼 분리
              if (canEdit && !isEditing && _isAfterPayment(contract)) ...[
                const Spacer(),
                // 추가 버튼 (D-5 이후면 alert 안내)
                OutlinedButton(
                  onPressed: () {
                    if (!canAddOption) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('알림'),
                          content: const Text(
                            '계약 시작일의 5일 전부터는 옵션을 추가할 수 없습니다.',
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary600,
                              ),
                              child: const Text(
                                '확인',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                    _showAddOptionModal(contract);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    side: const BorderSide(
                      color: AppColors.primary600, // blue-600
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '추가',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary600, // blue-600
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
                    '${totalDiff > 0 ? '+' : ''}${FormatUtils.formatCurrency(totalDiff.abs())}원',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: totalDiff > 0
                          ? AppColors.primary600 // blue-600
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
                          : AppColors.primary600, // blue-600
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
                  '(개당 ${FormatUtils.formatCurrency(item.price)}원)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primary600, // blue-600
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
                        Builder(
                          builder: (context) {
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
                          },
                        ),
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

                        // 플러스 버튼 (품목별 최대 5개)
                        Builder(
                          builder: (context) {
                            final canIncrease = item.quantity < 5;
                            return InkWell(
                              onTap: canIncrease
                                  ? () => _handleOptionQuantityChange(
                                      contract.id,
                                      item.id,
                                      1,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: canIncrease
                                        ? AppColors.primary600
                                        : const Color(0xFFE5E7EB),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: canIncrease
                                      ? Colors.white
                                      : const Color(0xFFF9FAFB),
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 16,
                                  color: canIncrease
                                      ? AppColors.primary600
                                      : const Color(0xFFD1D5DB),
                                ),
                              ),
                            );
                          },
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
                          color: AppColors.primary600, // blue-600
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
                      '${FormatUtils.formatCurrency(item.price * item.quantity)}원',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827), // gray-900
                      ),
                    ),
                    if (qtyDiff > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '(+${FormatUtils.formatCurrency(diffPrice)}원)',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary600, // blue-600
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else if (qtyDiff < 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '(${FormatUtils.formatCurrency(diffPrice)}원)',
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
              '${FormatUtils.formatCurrency(item.price)}원 × ${item.quantity}개 = ${FormatUtils.formatCurrency(item.price * item.quantity)}원',
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
                    ContractUtils.getFullImageUrl(contract.roomThumbnail),
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
                    ContractUtils.getFullImageUrl(contract.roomThumbnail),
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
            child: _buildContractInfoColumn(
              contract,
              showChatButton,
              isMobile: false,
            ),
          ),
        ],
      );
    }
  }

  /// 계약 정보 컬럼
  Widget _buildContractInfoColumn(
    ContractListItem contract,
    bool showChatButton, {
    required bool isMobile,
  }) {
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
          '${FormatUtils.formatDate(contract.checkInDate)} - ${FormatUtils.formatDate(contract.checkOutDate)} (${contract.totalDays}일)',
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 12 : 4),

        // 결제 금액
        _buildInfoRow(
          '결제 금액',
          '₩${FormatUtils.formatCurrency(contract.finalTotalAmount)}',
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
  Widget _buildHostRow(
    ContractListItem contract,
    bool showChatButton, {
    required bool isMobile,
  }) {
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
          style: const TextStyle(fontSize: 16, color: Color(0xFF111827)),
        ),
        if (showChatButton) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              context.go('/chat-list?contractId=${contract.id}');
            },
            child: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.primary600,
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
        children: [labelWidget, const SizedBox(height: 4), valueWidget],
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
  Widget _buildInfoRow(
    String label,
    String value, {
    TextStyle? valueStyle,
    bool isMobile = false,
  }) {
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
      style:
          valueStyle ??
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Color(0xFF000000),
          ),
    );

    if (isMobile) {
      // 모바일: 세로 배치
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [labelWidget, const SizedBox(height: 4), valueWidget],
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
      builder: (_) => _AddOptionModal(
        contract: contract,
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
      builder: (_) => _CancelOptionModal(
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
          items.add(RentalOrderItem(itemId: entry.key, quantity: entry.value));
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
      final paymentInfo = await rentalOrderService.getPaymentInfo(
        orderResponse.rentalOrderId,
      );

      if (!mounted) return;

      // 웹: PayTag로 결제
      if (kIsWeb) {
        // 결제수단 선택 모달
        final selectedMethod = await showPaymentMethodModal(
          context,
          totalAmount: paymentInfo['amount'] as int,
        );

        if (selectedMethod == null || !mounted) return;

        final paymentService = PaymentServiceUnified();
        await paymentService.requestRentalPayment(
          rentalOrderId: orderResponse.rentalOrderId,
          orderId: paymentInfo['orderId'] as String,
          amount: paymentInfo['amount'] as int,
          orderName: paymentInfo['orderName'] as String,
          payType: selectedMethod.value,
          customerName: paymentInfo['customerName'] as String?,
          customerEmail: paymentInfo['customerEmail'] as String?,
          customerPhone: paymentInfo['customerPhone'] as String?,
        );
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

  /// 결제 처리
  ///
  /// 결제수단 선택 모달을 먼저 표시한 후, 선택된 payType으로 PayTag SDK를 호출합니다.
  Future<void> _handlePayment(ContractListItem contract) async {
    try {
      // 1. PaymentServiceUnified 인스턴스 생성
      final paymentService = PaymentServiceUnified();

      // 2. 결제 정보 조회
      final paymentInfo = await paymentService.getPaymentInfo(contract.id);

      if (!mounted) return;

      // 3. 플랫폼별 결제 처리
      if (kIsWeb) {
        // 3-1. 결제수단 선택 모달 표시
        final selectedMethod = await showPaymentMethodModal(
          context,
          totalAmount: paymentInfo['amount'] as int,
        );

        if (selectedMethod == null || !mounted) return;

        // 3-2. 선택된 payType으로 PayTag SDK 호출
        final enrichedPaymentInfo = Map<String, dynamic>.from(paymentInfo)
          ..['payType'] = selectedMethod.value;

        final result = await paymentService.requestPayment(
          contractId: contract.id,
          paymentInfo: enrichedPaymentInfo,
        );

        if (!mounted) return;

        // TODO: 오픈 후 가상계좌 추가 시 입금 안내 다이얼로그 활성화
        // if (selectedMethod == PaymentMethod.virtualAccount && result != null) {
        //   _showVbankInfoDialog(result);
        // } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('결제가 완료되었습니다!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        // }
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
          // 결제 승인 처리
          await paymentService.confirmPayment(
            contractId: contract.id,
            recvPayparam: result['recvPayparam'] as String,
            orderId: result['orderId'] as String,
            amount: result['amount'] as int,
            payType: result['payType'] as String?,
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
    } on PopupBlockedException {
      if (!mounted) return;
      _showPopupBlockedDialog();
    } on UnauthorizedException {
      if (mounted) context.go('/login');
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

  /// 팝업 차단 안내 다이얼로그
  void _showPopupBlockedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('팝업 차단 감지'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('결제창을 열기 위해 팝업 차단을 해제해주세요.'),
            SizedBox(height: 12),
            Text(
              '해제 방법:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text('• 주소창 오른쪽의 팝업 차단 아이콘 클릭'),
            Text('• "팝업 허용" 선택 후 페이지 새로고침'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // TODO: 오픈 후 가상계좌 추가 시 아래 메서드들 주석 해제
  // void _showVbankInfoDialog(Map<String, dynamic> result) { ... }
  // Widget _vbankRow(String label, String value) { ... }
}

/// 옵션 추가 구매 모달
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
  final Map<int, int> _quantities = {};

  int get _totalAmount {
    int total = 0;
    for (final entry in _quantities.entries) {
      if (entry.value > 0) {
        final option = widget.availableOptions.firstWhere(
          (o) => o.id == entry.key,
          orElse: () =>
              AvailableRentalItem(id: 0, name: '', price: 0, availableStock: 0),
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
        constraints: const BoxConstraints(maxWidth: 672),
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
                      color: Color(0xFF111827),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(4),
                    child: const Icon(
                      Icons.close,
                      size: 24,
                      color: Color(0xFF9CA3AF),
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
                  color: const Color(0xFFEFF6FF),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '• 계약 시작일의 5일 전 까지만 구매할 수 있어요.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF1E40AF)),
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
                  border: Border(top: BorderSide(color: Color(0xFFD1D5DB))),
                ),
                child: Column(
                  children: [
                    // 총 결제 금액
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
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
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            '${FormatUtils.formatCurrency(_totalAmount)}원',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary600,
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
                                color: Color(0xFFD1D5DB),
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
                                color: Color(0xFF374151),
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
                              backgroundColor: AppColors.primary600,
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
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
              color: Color(0xFF111827),
            ),
          ),
          // 설명
          if (option.description != null && option.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              option.description!,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
          // 가격
          const SizedBox(height: 4),
          Text(
            '개당 ${FormatUtils.formatCurrency(option.price)}원',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary600,
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
                          color: const Color(0xFFD1D5DB),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.remove,
                        size: 16,
                        color: qty > 0
                            ? const Color(0xFF4B5563)
                            : const Color(0xFFD1D5DB),
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
                                content: Text(
                                  '이 옵션은 최대 ${option.availableStock}개까지 선택 가능합니다.',
                                ),
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
                          color: AppColors.primary600,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 16,
                        color: AppColors.primary600,
                      ),
                    ),
                  ),
                ],
              ),
              // 금액
              if (qty > 0)
                Text(
                  '${FormatUtils.formatCurrency(option.price * qty)}원',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 옵션 취소/반품 모달
///
/// - [결제취소] 탭: 배송전 아이템 선택 → 즉시 PG 환불
/// - [반품신청] 탭: 배송중/완료 아이템 선택 → 관리자 처리 대기
class _CancelOptionModal extends StatefulWidget {
  final ContractListItem contract;
  final List<RentalOrder> orders;
  final Future<RentalItemCancelResponse> Function(
    int contractId,
    List<int> itemIds,
    String reason,
  ) onCancelItems;
  final Future<void> Function(
    int contractId,
    List<int> itemIds,
    String reason,
  ) onReturnRequest;
  final Future<ReturnPreviewResponse> Function(
    int contractId,
    List<int> itemIds,
  ) onGetReturnPreview;
  final VoidCallback onRefreshContracts;

  const _CancelOptionModal({
    required this.contract,
    required this.orders,
    required this.onCancelItems,
    required this.onReturnRequest,
    required this.onGetReturnPreview,
    required this.onRefreshContracts,
  });

  @override
  State<_CancelOptionModal> createState() => _CancelOptionModalState();
}

