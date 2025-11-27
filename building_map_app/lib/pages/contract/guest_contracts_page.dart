import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart' hide AppColors, AppTextStyles;
import '../../models/contract.dart';
import '../../services/contract_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/common/app_gnb.dart';
// import '../../widgets/modals/refund_calculation_modal.dart'; // TODO: API로 전체 Contract 가져오기 후 사용
import '../../widgets/modals/option_refund_modal.dart';
import '../../widgets/modals/cancel_request_modal.dart';

/// 게스트용 계약 목록 페이지 (리액트 UI 기반 재설계)
class GuestContractsPage extends StatefulWidget {
  const GuestContractsPage({super.key});

  @override
  State<GuestContractsPage> createState() => _GuestContractsPageState();
}

class _GuestContractsPageState extends State<GuestContractsPage> {
  final ContractService _contractService = ContractService();
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

  /// 입주일 N일 전 체크
  bool _isDaysBeforeCheckIn(DateTime checkInDate, int days) {
    final now = DateTime.now();
    final diff = checkInDate.difference(now).inDays;
    return diff >= days;
  }

  /// 옵션 편집 버튼 표시 여부
  bool _canShowEditButton(ContractListItem contract) {
    return [
      ContractStatus.approved,
      ContractStatus.paymentCompleted,
      ContractStatus.inProgress,
    ].contains(contract.status);
  }

  /// 원본 수량 조회
  int _getOriginalQuantity(int contractId, String itemId) {
    final savedItems = _savedRentalItems[contractId];
    if (savedItems == null) return 0;

    final item = savedItems.firstWhere(
      (i) => i.id == itemId,
      orElse: () => RentalItem(
        id: itemId,
        name: '',
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

  /// 옵션 편집 시작
  void _handleEditButtonClick(ContractListItem contract) {
    setState(() {
      _editingContractId = contract.id;

      // 원본 저장 (처음 편집 시작할 때만)
      if (!_savedRentalItems.containsKey(contract.id)) {
        _savedRentalItems[contract.id] = contract.rentalItems ?? [];
      }

      // 모든 사용 가능한 옵션 초기화 (기존 수량 유지)
      final currentItems = contract.rentalItems ?? [];
      final allOptions = AvailableOption.defaultOptions.map((option) {
        final existingItem = currentItems.firstWhere(
          (item) => item.id == option.id,
          orElse: () => RentalItem(
            id: option.id,
            name: option.name,
            description: option.description,
            price: option.price,
            quantity: 0,
            deliveryStatus: DeliveryStatus.pending,
          ),
        );
        return existingItem;
      }).toList();

      _modifiedOptions[contract.id] = allOptions;
    });
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

    final savedItems = _savedRentalItems[contract.id] ?? [];

    // 변경사항 계산
    final changes = <OptionChange>[];
    for (final item in modifiedItems) {
      if (item.quantity == 0) continue; // 수량 0인 항목은 제외

      final originalQty = _getOriginalQuantity(contract.id, item.id);
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

    if (changes.isEmpty) {
      // 변경사항 없으면 편집 모드 종료
      setState(() {
        _editingContractId = null;
        _modifiedOptions.remove(contract.id);
      });
      return;
    }

    // TODO: API 호출하여 옵션 변경사항 저장
    debugPrint(
      '💾 [SAVE OPTIONS] Contract ID: ${contract.id}, Changes: ${changes.length}',
    );
    for (final change in changes) {
      debugPrint(
        '  - ${change.itemName}: ${change.originalQuantity} → ${change.newQuantity} (${change.quantityDiff > 0 ? '+' : ''}${change.priceDiff})',
      );
    }

    // 결제 완료 상태에서 수량 감소 시 환불 모달 표시
    if (contract.status == ContractStatus.paymentCompleted) {
      final totalDiff = changes.fold<int>(
        0,
        (sum, change) => sum + change.priceDiff,
      );
      if (totalDiff < 0) {
        // 옵션 환불 모달 표시
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => OptionRefundModal(
            refundAmount: -totalDiff,
            onConfirm: () {
              Navigator.of(context).pop();
              // 환불 확정 처리
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '옵션 수량이 변경되었습니다. ${_currencyFormat.format(-totalDiff)}원은 영업일 기준 3-5일 내 환불됩니다.',
                  ),
                  backgroundColor: const Color(0xFF10B981), // green-600
                ),
              );
              setState(() {
                _editingContractId = null;
                _modifiedOptions.remove(contract.id);
              });
            },
            onClose: () {
              Navigator.of(context).pop();
            },
          ),
        );
        return;
      }
    }

    // 저장 성공 후 상태 업데이트
    setState(() {
      _editingContractId = null;
      _modifiedOptions.remove(contract.id);
      // API 응답으로 contract.rentalItems 업데이트 완료
    });
  }

  /// 옵션 변경사항 취소
  void _handleCancelOptionChanges(int contractId) {
    setState(() {
      _editingContractId = null;
      _modifiedOptions.remove(contractId);
    });
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
    return Scaffold(
      appBar: const AppGNB(),
      backgroundColor: const Color(0xFFF9FAFB), // gray-50
      body: Column(
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
              style: const TextStyle(fontSize: 16),
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
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
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
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
                        style: TextStyle(fontSize: 13, color: statusColor),
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

          // 방 사진 + 계약 정보
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 방 사진
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
                child: Column(
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
                    const SizedBox(height: 8),

                    // 주소
                    _buildInfoRow('주소', contract.roomAddress),
                    const SizedBox(height: 4),

                    // 계약 기간
                    _buildInfoRow(
                      '계약 기간',
                      '${_dateFormat.format(contract.checkInDate)} - ${_dateFormat.format(contract.checkOutDate)} (${contract.totalDays}일)',
                    ),
                    const SizedBox(height: 4),

                    // 결제 금액
                    _buildInfoRow(
                      '결제 금액',
                      '₩${_currencyFormat.format(contract.finalTotalAmount)}',
                      valueStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // 호스트 + 채팅 버튼
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow('호스트', contract.partnerName),
                        ),
                        if (showChatButton) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              // 채팅 페이지로 이동
                              context.push('/guest/chat/${contract.id}');
                            },
                            icon: const Icon(Icons.chat_bubble_outline),
                            color: const Color(0xFF2563EB),
                            iconSize: 16,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: '호스트와 채팅하기',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

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
                          onPressed: () {
                            Navigator.of(context).pop();
                            // API 호출: 계약 요청 취소
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('계약 요청이 취소되었습니다.'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                            _loadContracts();
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
                onPressed: () {
                  // 결제 페이지로 이동
                  context.push('/guest/payment/${contract.id}');
                },
                icon: const Icon(Icons.credit_card, size: 16),
                label: const Text(
                  '결제하기',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
        if (item.quantity == 0) continue;
        final originalQty = _getOriginalQuantity(contract.id, item.id);
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
          // 헤더: 옵션 상품 + 편집 버튼
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
              if (canEdit && !isEditing) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _handleEditButtonClick(contract),
                  icon: const Icon(Icons.shopping_cart, size: 16),
                  label: Text(
                    '옵션 추가 및 변경',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: canChangeOptions
                          ? const Color(0xFF2563EB) // blue-600
                          : const Color(0xFF6B7280), // gray-500
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    backgroundColor: canChangeOptions
                        ? const Color(0xFFEFF6FF) // blue-50
                        : const Color(0xFFF9FAFB), // gray-50
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
                      contract.status == ContractStatus.paymentCompleted
                          ? '결제 및 환불'
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
    final originalQty = _getOriginalQuantity(contract.id, item.id);
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
                        InkWell(
                          onTap: item.quantity > 0
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
                                color: item.quantity > 0
                                    ? const Color(0xFFD1D5DB) // gray-300
                                    : const Color(0xFFE5E7EB), // gray-200
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: item.quantity > 0
                                  ? Colors.white
                                  : const Color(0xFFF9FAFB),
                            ),
                            child: Icon(
                              Icons.remove,
                              size: 16,
                              color: item.quantity > 0
                                  ? const Color(0xFF374151) // gray-700
                                  : const Color(0xFFD1D5DB), // gray-300
                            ),
                          ),
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

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280), // gray-600
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style:
                valueStyle ??
                const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF000000),
                ),
          ),
        ),
      ],
    );
  }
}
