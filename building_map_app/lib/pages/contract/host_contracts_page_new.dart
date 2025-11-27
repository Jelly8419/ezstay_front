import 'package:building_map_app/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/contract.dart';
import '../../services/contract_service.dart';
import '../../widgets/modals/guest_preparation_modal.dart';
import '../../widgets/modals/host_contract_rejection_modal.dart';
import '../../widgets/common/app_gnb.dart';

/// 호스트 계약 관리 페이지 (React UI 완전 복제)
class HostContractsPageNew extends StatefulWidget {
  const HostContractsPageNew({super.key});

  @override
  State<HostContractsPageNew> createState() => _HostContractsPageNewState();
}

class _HostContractsPageNewState extends State<HostContractsPageNew> {
  final ContractService _contractService = ContractService();
  final NumberFormat _currencyFormat = NumberFormat('#,###');
  final DateFormat _dateFormat = DateFormat('yyyy.MM.dd(E)', 'ko_KR');

  List<ContractListItem> _contracts = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedTab =
      'in_progress'; // 'in_progress', 'past', 'cancelled' - 기본값: 진행중
  String? _selectedStatus; // 상태 필터 (ContractStatus 또는 'all')

  // 거절 모달 상태
  bool _showRejectionModal = false;
  int? _selectedContractIdForRejection;

  // 게스트 입주 준비 모달 상태
  bool _showGuestPreparationModal = false;
  int? _selectedContractIdForApproval;

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
      final contracts = await _contractService.getHostContracts(
        status: _selectedStatus,
      );

      debugPrint('📋 [HOST_CONTRACTS] Loaded ${contracts.length} contracts');
      debugPrint('📋 [HOST_CONTRACTS] _selectedTab: $_selectedTab');

      // 각 계약의 실제 상태값 로깅
      for (var i = 0; i < contracts.length; i++) {
        debugPrint(
          '📋 [CONTRACT $i] ID: ${contracts[i].id}, Status: ${contracts[i].status}, Status String: ${contracts[i].status.toString()}',
        );
      }

      setState(() {
        _contracts = contracts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ [HOST_CONTRACTS] Error loading contracts: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // 필터링된 계약 목록 (게스트 페이지와 동일한 구조)
  List<ContractListItem> get _filteredContracts {
    debugPrint(
      '🔍 [FILTER] Starting filter - Total: ${_contracts.length}, Tab: $_selectedTab, Status: $_selectedStatus',
    );

    // 1단계: 탭 기반 필터링
    List<ContractListItem> tabFiltered;

    if (_selectedTab == 'in_progress') {
      final expectedStatuses = [
        ContractStatus.pendingApproval,
        ContractStatus.approved,
        ContractStatus.paymentCompleted,
        ContractStatus.inProgress,
      ];

      debugPrint(
        '🔍 [FILTER] Checking in_progress tab. Expected statuses: ${expectedStatuses.map((s) => s.toString()).join(', ')}',
      );

      // 각 계약에 대해 상태 매칭 확인
      for (var contract in _contracts) {
        final matches = expectedStatuses.contains(contract.status);
        debugPrint(
          '🔍 [FILTER] Contract ${contract.id}: status=${contract.status}, matches=$matches',
        );
      }

      tabFiltered = _contracts
          .where((c) => expectedStatuses.contains(c.status))
          .toList();
    } else if (_selectedTab == 'past') {
      tabFiltered = _contracts
          .where((c) => c.status == ContractStatus.completed)
          .toList();
    } else if (_selectedTab == 'cancelled') {
      tabFiltered = _contracts
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
          .toList();
    } else {
      tabFiltered = _contracts;
    }

    debugPrint('🔍 [FILTER] After tab filter: ${tabFiltered.length}');

    // 2단계: 상태 필터 적용 (선택된 경우에만)
    if (_selectedStatus != null && _selectedStatus != 'all') {
      final statusFiltered = tabFiltered
          .where((c) => c.status.toString().split('.').last == _selectedStatus)
          .toList();
      debugPrint('🔍 [FILTER] After status filter: ${statusFiltered.length}');
      return statusFiltered;
    }

    debugPrint('🔍 [FILTER] Final result: ${tabFiltered.length}');
    return tabFiltered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // bg-gray-50
      appBar: const AppGNB(),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1024),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 24, bottom: 96),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 탭 (진행중 / 지난계약 / 취소)
                      _buildTabs(),
                      const SizedBox(height: 12),

                      // 상태 필터 드롭다운 (왼쪽 정렬)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildStatusDropdown(),
                      ),
                      const SizedBox(height: 24),

                      // 안내 메시지
                      _buildInfoMessage(),
                      const SizedBox(height: 24),

                      // 계약 목록
                      _buildContractList(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 거절 모달
          if (_showRejectionModal && _selectedContractIdForRejection != null)
            HostContractRejectionModal(
              contractId: _selectedContractIdForRejection!,
              onClose: () {
                setState(() {
                  _showRejectionModal = false;
                  _selectedContractIdForRejection = null;
                });
              },
              onConfirm: _submitRejection,
            ),

          // 게스트 입주 준비 모달
          if (_showGuestPreparationModal &&
              _selectedContractIdForApproval != null)
            GuestPreparationModal(
              contractId: _selectedContractIdForApproval!,
              onClose: () {
                setState(() {
                  _showGuestPreparationModal = false;
                  _selectedContractIdForApproval = null;
                });
              },
              onConfirm: _submitApproval,
            ),
        ],
      ),
    );
  }

  /// 탭별 계약 개수 계산
  int _getTabCount(String tab) {
    return _contracts.where((contract) {
      if (tab == 'in_progress') {
        return [
          ContractStatus.pendingApproval,
          ContractStatus.approved,
          ContractStatus.paymentCompleted,
          ContractStatus.inProgress,
        ].contains(contract.status);
      } else if (tab == 'past') {
        return contract.status == ContractStatus.completed;
      } else if (tab == 'cancelled') {
        return [
          ContractStatus.rejected,
          ContractStatus.cancelledByGuest,
          ContractStatus.cancelledByHost,
          ContractStatus.refunded, // ← 환불 완료
          ContractStatus.approvalExpired, // ← 미승인 만료
          ContractStatus.paymentExpired, // ← 미결제 만료
        ].contains(contract.status);
      }
      return false;
    }).length;
  }

  /// 3개 탭 (진행중 / 지난계약 / 취소)
  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: '진행중',
              count: _getTabCount('in_progress'),
              isSelected: _selectedTab == 'in_progress',
              onTap: () {
                setState(() {
                  _selectedTab = 'in_progress';
                  _selectedStatus = null;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton(
              label: '지난계약',
              count: _getTabCount('past'),
              isSelected: _selectedTab == 'past',
              onTap: () {
                setState(() {
                  _selectedTab = 'past';
                  _selectedStatus = null;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton(
              label: '취소',
              count: _getTabCount('cancelled'),
              isSelected: _selectedTab == 'cancelled',
              onTap: () {
                setState(() {
                  _selectedTab = 'cancelled';
                  _selectedStatus = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '($count)',
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 상태 필터 드롭다운
  Widget _buildStatusDropdown() {
    // 탭별 표시할 상태 옵션
    List<String?> getAvailableStatuses() {
      if (_selectedTab == 'in_progress') {
        return [
          null, // 전체
          'PENDING_APPROVAL',
          'APPROVED',
          'PAYMENT_COMPLETED',
          'IN_PROGRESS',
        ];
      } else if (_selectedTab == 'past') {
        return [null, 'COMPLETED'];
      } else if (_selectedTab == 'cancelled') {
        return [
          null,
          'REJECTED',
          'CANCELLED_BY_GUEST',
          'CANCELLED_BY_HOST',
          'REFUNDED',
          'APPROVAL_EXPIRED',
          'PAYMENT_EXPIRED',
        ];
      }
      return [null];
    }

    return PopupMenuButton<String?>(
      initialValue: _selectedStatus,
      onSelected: (String? newStatus) {
        setState(() {
          _selectedStatus = newStatus;
        });
        _loadContracts(); // 필터 변경 시 계약 목록 새로고침
      },
      offset: const Offset(0, 48), // 버튼 아래에 메뉴 표시
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getStatusText(_selectedStatus),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF374151),
            ),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        return getAvailableStatuses().map((String? status) {
          return PopupMenuItem<String?>(
            value: status,
            child: Text(
              _getStatusText(status),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
              ),
            ),
          );
        }).toList();
      },
    );
  }

  String _getStatusText(String? status) {
    if (status == null) return '계약 상태';
    if (status == 'all') return '전체';

    final statusMap = {
      'PENDING_APPROVAL': '승인 대기',
      'APPROVED': '결제 대기',
      'REJECTED': '승인 거절',
      'PAYMENT_COMPLETED': '결제 완료',
      'IN_PROGRESS': '임대 중',
      'COMPLETED': '계약 종료',
      'CANCELLED_BY_GUEST': '계약 취소',
      'CANCELLED_BY_HOST': '계약 취소',
    };

    return statusMap[status] ?? '승인 대기';
  }

  /// 안내 메시지 박스
  Widget _buildInfoMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE), // bg-blue-50
        border: Border.all(color: const Color(0xFFBFDBFE)), // border-blue-100
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '안내사항',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A), // text-blue-900
                  ),
                ),
                const SizedBox(height: 4),
                _buildInfoItem('게스트의 계약 요청을 승인하거나 거절할 수 있습니다.'),
                _buildInfoItem('승인 후 게스트가 결제하면 계약이 확정됩니다.'),
                _buildInfoItem('호스트가 계약을 취소하려면 위약금을 결제해야 합니다.'),
                _buildInfoItem('입주일 이후 취소 시 게스트와 합의 후 관리자 승인이 필요합니다.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '• $text',
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1E40AF), // text-blue-800
        ),
      ),
    );
  }

  /// 계약 목록
  Widget _buildContractList() {
    // 로딩 상태
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // 에러 상태
    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 16, color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadContracts,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    // 빈 목록
    if (_filteredContracts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
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
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // 계약 목록
    return Column(
      children: _filteredContracts
          .map((contract) => _buildContractCard(contract))
          .toList(),
    );
  }

  /// 계약 카드
  Widget _buildContractCard(ContractListItem contract) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상태 뱃지 + 안내 메시지 (수평) + 상세 버튼
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildStatusBadge(contract.status),
              const SizedBox(width: 12),
              Expanded(child: _buildStatusMessage(contract.status)),
              _buildDetailButton(contract),
            ],
          ),

          const SizedBox(height: 16),

          // 방 정보 (사진 + 텍스트)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 방 사진
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: contract.roomThumbnail != null
                    ? Image.network(
                        '${ApiConfig.baseUrl}${contract.roomThumbnail!}',
                        width: 128,
                        height: 128,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 128,
                          height: 128,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.home,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        width: 128,
                        height: 128,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.home,
                          size: 48,
                          color: Colors.grey,
                        ),
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
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('주소', contract.roomAddress),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      '계약 기간',
                      '${_dateFormat.format(contract.checkInDate)} - ${_dateFormat.format(contract.checkOutDate)} (${contract.totalDays}일)',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('게스트', contract.partnerName),
                  ],
                ),
              ),
            ],
          ),

          // 게스트 메시지
          if (contract.guestMessage != null) ...[
            const SizedBox(height: 12),
            _buildGuestMessage(contract.guestMessage!),
          ],

          // 계약 금액 정보
          const SizedBox(height: 16),
          _buildPricingSection(contract),

          // 버튼 영역
          if (contract.status == ContractStatus.pendingApproval) ...[
            const SizedBox(height: 16),
            _buildActionButtons(contract.id),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ContractStatus status) {
    final config = _getStatusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: config['bgColor'],
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        config['text'],
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: config['textColor'],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(ContractStatus status) {
    final statusString = status.toString().split('.').last.toUpperCase();
    final configs = {
      'PENDINGAPPROVAL': {
        'text': '승인 대기',
        'bgColor': const Color(0xFFFEF3C7),
        'textColor': const Color(0xFFA16207),
      },
      'APPROVED': {
        'text': '결제 대기',
        'bgColor': const Color(0xFFDBEAFE),
        'textColor': const Color(0xFF1D4ED8),
      },
      'PAYMENTCOMPLETED': {
        'text': '결제 완료',
        'bgColor': const Color(0xFFD1FAE5),
        'textColor': const Color(0xFF065F46),
      },
    };

    return configs[statusString] ??
        {
          'text': '승인 대기',
          'bgColor': const Color(0xFFFEF3C7),
          'textColor': const Color(0xFFA16207),
        };
  }

  Widget _buildStatusMessage(ContractStatus status) {
    String message = '';
    Color color = Colors.grey;

    if (status == ContractStatus.pendingApproval) {
      message = '게스트의 계약 요청을 검토해주세요.';
      color = const Color(0xFFCA8A04);
    } else if (status == ContractStatus.approved) {
      message = '게스트가 결제하면 계약이 확정됩니다.';
      color = const Color(0xFF2563EB);
    } else if (status == ContractStatus.paymentCompleted) {
      message = '입주일에 맞춰 게스트를 맞이해주세요.';
      color = const Color(0xFF059669);
    }

    if (message.isEmpty) return const SizedBox.shrink();

    return Text(message, style: TextStyle(fontSize: 14, color: color));
  }

  Widget _buildDetailButton(ContractListItem contract) {
    return GestureDetector(
      onTap: () {
        context.go('/host/contracts/${contract.id}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.description_outlined, size: 16, color: Color(0xFF2563EB)),
            SizedBox(width: 6),
            Text(
              '계약 상세',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '게스트 메시지',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection(ContractListItem contract) {
    final settlementAmount =
        contract.hostEarnings ?? _calculateSettlement(contract);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이용 금액
          const Text(
            '이용 금액',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),

          // 임대료, 관리비, 청소비
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              children: [
                _buildAmountRow('임대료', contract.rentalFee ?? 0),
                const SizedBox(height: 8),
                _buildAmountRow('관리비', contract.maintenanceFee ?? 0),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '청소비',
                          style: TextStyle(fontSize: 14, color: Colors.black),
                        ),
                        if (contract.isEzCleaning == true) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'EZ서비스',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '₩${_currencyFormat.format(contract.cleaningFee ?? 0)}',
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
          ),

          const SizedBox(height: 8),

          // 보증금
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '보증금 ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      TextSpan(
                        text: '(게스트 퇴실 후 환급)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₩${_currencyFormat.format(contract.deposit ?? 0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 총 계약 금액
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFD1D5DB), width: 2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '총 계약 금액',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  '₩${_currencyFormat.format((contract.rentalFee ?? 0) + (contract.maintenanceFee ?? 0) + (contract.cleaningFee ?? 0) + (contract.deposit ?? 0))}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 정산 예정금액
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '정산 예정금액',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
                Text(
                  '₩${_currencyFormat.format(settlementAmount)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black)),
        Text(
          '₩${_currencyFormat.format(amount)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  int _calculateSettlement(ContractListItem contract) {
    final rentalFee = contract.rentalFee ?? 0;
    final maintenanceFee = contract.maintenanceFee ?? 0;
    final cleaningFee = contract.cleaningFee ?? 0;
    final isEzCleaning = contract.isEzCleaning == true;

    final usageFee = isEzCleaning
        ? rentalFee + maintenanceFee
        : rentalFee + maintenanceFee + cleaningFee;
    final commissionFee = (usageFee * 0.033).floor();

    return usageFee - commissionFee;
  }

  Widget _buildActionButtons(int contractId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: () => _handleApprove(contractId),
          icon: const Icon(Icons.check, size: 16),
          label: const Text(
            '승인하기',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => _handleReject(contractId),
          icon: const Icon(Icons.close, size: 16),
          label: const Text(
            '거절하기',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF6B7280),
            side: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  /// 승인 버튼 클릭
  Future<void> _handleApprove(int contractId) async {
    // 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계약 승인'),
        content: const Text('이 계약 요청을 승인하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('승인'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 게스트 입주 준비 모달 표시
    setState(() {
      _selectedContractIdForApproval = contractId;
      _showGuestPreparationModal = true;
    });
  }

  /// 거절 버튼 클릭
  void _handleReject(int contractId) {
    setState(() {
      _selectedContractIdForRejection = contractId;
      _showRejectionModal = true;
    });
  }

  /// 승인 API 호출 (권장 아이템 포함)
  Future<void> _submitApproval(List<int> selectedItemIds) async {
    if (_selectedContractIdForApproval == null) return;

    setState(() {
      _showGuestPreparationModal = false;
    });

    try {
      // API 호출 (권장 아이템 포함)
      final recommendedItems = selectedItemIds
          .map((itemId) => {'itemId': itemId, 'quantity': 1})
          .toList();

      await _contractService.approveContract(
        _selectedContractIdForApproval!,
        recommendedItems: recommendedItems.isEmpty ? null : recommendedItems,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('계약이 승인되었습니다. 게스트가 결제하면 계약이 확정됩니다.')),
      );

      // 계약 목록 새로고침
      await _loadContracts();

      setState(() {
        _selectedContractIdForApproval = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('계약 승인 실패: $e')));
    }
  }

  /// 거절 API 호출
  Future<void> _submitRejection(String rejectionReason) async {
    if (_selectedContractIdForRejection == null) return;

    setState(() {
      _showRejectionModal = false;
    });

    try {
      await _contractService.rejectContract(
        _selectedContractIdForRejection!,
        rejectionReason,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('계약이 거절되었습니다.')));

      // 계약 목록 새로고침
      await _loadContracts();

      setState(() {
        _selectedContractIdForRejection = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('계약 거절 실패: $e')));
    }
  }
}
