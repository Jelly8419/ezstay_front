import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import '../../constants/fee_constants.dart';
import '../../utils/format_utils.dart';
import '../../utils/contract_utils.dart';
import '../../models/contract.dart';
import '../../services/contract_service.dart';
import '../../widgets/modals/guest_preparation_modal.dart';
import '../../widgets/modals/host_contract_rejection_modal.dart';
import '../../widgets/modals/host_contract_modals.dart' show DepositAgreementModal, RequestCancellationModal;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/common/app_footer.dart';

/// 호스트 계약 관리 페이지 (React UI 완전 복제)
class HostContractsPageNew extends StatefulWidget {
  const HostContractsPageNew({super.key});

  @override
  State<HostContractsPageNew> createState() => _HostContractsPageNewState();
}

class _HostContractsPageNewState extends State<HostContractsPageNew> {
  final ContractService _contractService = ContractService();
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

  // 취소 요청 모달 상태
  bool _showCancellationModal = false;
  int? _selectedContractIdForCancellation;

  // 보증금 합의 모달 상태
  bool _showDepositAgreementModal = false;
  ContractListItem? _selectedContractForAgreement;
  int? _existingDeductAmount; // 수정 모드: 기존 차감 금액
  String? _existingAgreementText; // 수정 모드: 기존 합의 내용

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
        final matches = expectedStatuses.contains(contract.status) ||
            (contract.status == ContractStatus.completed &&
                !_isDepositRefundComplete(contract));
        debugPrint(
          '🔍 [FILTER] Contract ${contract.id}: status=${contract.status}, matches=$matches',
        );
      }

      tabFiltered = _contracts
          .where(
            (c) =>
                expectedStatuses.contains(c.status) ||
                // COMPLETED이지만 보증금 환급 미완료 시 진행중으로 표시
                (c.status == ContractStatus.completed &&
                    !_isDepositRefundComplete(c)),
          )
          .toList();
    } else if (_selectedTab == 'past') {
      tabFiltered = _contracts
          .where(
            (c) =>
                c.status == ContractStatus.completed &&
                _isDepositRefundComplete(c),
          )
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
      // '계약 취소' 선택 시 취소 계열 전체 포함
      final cancelledStatuses = [
        'CANCELLED_BY_GUEST',
        'CANCELLED_BY_HOST',
        'REFUNDED',
        'APPROVAL_EXPIRED',
        'PAYMENT_EXPIRED',
      ];
      final statusFiltered = tabFiltered.where((c) {
        if (cancelledStatuses.contains(_selectedStatus)) {
          return cancelledStatuses.contains(c.status.value);
        }
        return c.status.value == _selectedStatus;
      }).toList();
      debugPrint('🔍 [FILTER] After status filter: ${statusFiltered.length}');
      return statusFiltered;
    }

    debugPrint('🔍 [FILTER] Final result: ${tabFiltered.length}');
    return tabFiltered;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF9FAFB), // bg-gray-50
      child: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 896),
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

                      // 푸터
                      const SizedBox(height: 48),
                      const AppFooter(),
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

          // 취소 요청 모달
          if (_showCancellationModal &&
              _selectedContractIdForCancellation != null)
            RequestCancellationModal(
              onClose: () {
                setState(() {
                  _showCancellationModal = false;
                  _selectedContractIdForCancellation = null;
                });
              },
              onConfirm: (reason) => _submitCancellationRequest(reason),
            ),

          // 보증금 합의 모달
          if (_showDepositAgreementModal &&
              _selectedContractForAgreement != null)
            DepositAgreementModal(
              onClose: () {
                setState(() {
                  _showDepositAgreementModal = false;
                  _selectedContractForAgreement = null;
                  _existingDeductAmount = null;
                  _existingAgreementText = null;
                });
              },
              onConfirm: (deductAmount, agreementText) =>
                  _submitDepositAgreement(deductAmount, agreementText),
              depositAmount: _selectedContractForAgreement!.deposit ?? FeeConstants.depositAmount,
              checkOutDate: _selectedContractForAgreement!.checkOutDate,
              roomCheckoutTime: _selectedContractForAgreement!.roomCheckoutTime,
              initialDeductAmount: _existingDeductAmount,
              initialAgreementText: _existingAgreementText,
            ),
        ],
      ),
    );
  }

  /// 보증금 환급이 완료된 상태인지 확인
  /// returned(반환완료) 또는 returnConfirmed(반환확정)인 경우만 완료로 간주
  bool _isDepositRefundComplete(ContractListItem c) {
    return c.depositStatus == DepositStatus.returned ||
        c.depositStatus == DepositStatus.returnConfirmed;
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
            ].contains(contract.status) ||
            (contract.status == ContractStatus.completed &&
                !_isDepositRefundComplete(contract));
      } else if (tab == 'past') {
        return contract.status == ContractStatus.completed &&
            _isDepositRefundComplete(contract);
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

  /// 상태 필터 드롭다운 (리액트 동일: 전체 상태 표시, 선택 시 탭 자동 전환)
  Widget _buildStatusDropdown() {
    return PopupMenuButton<String?>(
      initialValue: _selectedStatus,
      onSelected: (String? newStatus) {
        setState(() {
          _selectedStatus = newStatus;

          // 상태에 따라 자동으로 탭 전환 (리액트 동일)
          if (newStatus == null) {
            // 전체 선택 시 탭 유지
          } else if ([
            'PENDING_APPROVAL',
            'APPROVED',
            'PAYMENT_COMPLETED',
            'IN_PROGRESS',
          ].contains(newStatus)) {
            _selectedTab = 'in_progress';
          } else if (newStatus == 'COMPLETED') {
            _selectedTab = 'past';
          } else {
            _selectedTab = 'cancelled';
          }
        });
        _loadContracts();
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
        // 전체 상태 옵션 (리액트 코드와 동일)
        // 취소 계열 5개는 '계약 취소' 1개로 대표 표시
        final allStatuses = <String?>[
          null, // 계약 상태 (전체)
          'PENDING_APPROVAL',
          'APPROVED',
          'PAYMENT_COMPLETED',
          'IN_PROGRESS',
          'COMPLETED',
          'REJECTED',
          'CANCELLED_BY_GUEST', // 취소 계열 대표 (게스트/호스트/환불/만료 모두 포함)
        ];
        return allStatuses.map((String? status) {
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
    if (status == null) return '전체';
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
      'REFUNDED': '계약 취소',
      'APPROVAL_EXPIRED': '계약 취소',
      'PAYMENT_EXPIRED': '계약 취소',
    };

    return statusMap[status] ?? '알 수 없음';
  }

  /// 안내 메시지 박스
  Widget _buildInfoMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // bg-blue-50
        border: Border.all(color: const Color(0xFFDBEAFE)), // border-blue-100
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
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.red.shade700),
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
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey.shade500),
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
              if (contract.checkoutStatus == CheckoutStatus.holdRequested) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED), // orange-50
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFED7AA)), // orange-200
                  ),
                  child: const Text(
                    '보증금 반환 보류 신청중',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEA580C), // orange-600
                    ),
                  ),
                ),
              ],
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
                        ContractUtils.getFullImageUrl(contract.roomThumbnail),
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
                      '${FormatUtils.formatDateWithDay(contract.checkInDate)} - ${FormatUtils.formatDateWithDay(contract.checkOutDate)} (${contract.totalDays}일)',
                    ),
                    const SizedBox(height: 8),
                    _buildGuestRow(contract),
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

          // 퇴실 상태 표시 (IN_PROGRESS 또는 COMPLETED)
          _buildHostCheckoutSection(contract),

          // 버튼 영역
          if (contract.status == ContractStatus.pendingApproval) ...[
            const SizedBox(height: 16),
            _buildActionButtons(contract.id),
          ],

          // PAYMENT_COMPLETED: 계약 취소 버튼
          if (contract.status == ContractStatus.paymentCompleted) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _handleCancelByHost(contract.id),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '계약 취소',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ),
          ],

          // IN_PROGRESS + 퇴실 전(NOT_STARTED/null): 취소 요청 (항상) + 퇴실 확인 (퇴실 시간 도래 시만)
          if (contract.status == ContractStatus.inProgress &&
              (contract.checkoutStatus == null ||
               contract.checkoutStatus == CheckoutStatus.notStarted)) ...[
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                // 퇴실 시간 도래 여부 판단
                final now = DateTime.now();
                final checkOutDate = contract.checkOutDate;
                final checkoutTimeStr = contract.roomCheckoutTime ?? '11:00';
                final timeParts = checkoutTimeStr.split(':');
                final checkoutHour = int.tryParse(timeParts[0]) ?? 11;
                final checkoutMinute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
                final checkoutDateTime = DateTime(
                  checkOutDate.year, checkOutDate.month, checkOutDate.day,
                  checkoutHour, checkoutMinute,
                );
                final isCheckoutTimeReached = now.isAfter(checkoutDateTime);
                final isCheckoutRequested = contract.checkoutRequested == true;

                if (isCheckoutTimeReached || isCheckoutRequested) {
                  // 퇴실 시간 도래: 퇴실 확인 + 취소 요청 둘 다 표시
                  return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleRequestCheckout(contract.id),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '퇴실 확인',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: contract.cancellationRequested == true
                              ? null
                              : () => _handleRequestCancellation(contract.id),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: contract.cancellationRequested == true
                                  ? AppColors.gray300
                                  : const Color(0xFFF97316),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            contract.cancellationRequested == true ? '취소 요청됨' : '취소 요청',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: contract.cancellationRequested == true
                                  ? AppColors.gray300
                                  : const Color(0xFFF97316),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // 퇴실 시간 미도래: 취소 요청만 표시
                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: contract.cancellationRequested == true
                          ? null
                          : () => _handleRequestCancellation(contract.id),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: contract.cancellationRequested == true
                              ? AppColors.gray300
                              : const Color(0xFFF97316),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        contract.cancellationRequested == true ? '취소 요청됨' : '취소 요청',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: contract.cancellationRequested == true
                              ? AppColors.gray300
                              : const Color(0xFFF97316),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
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
    final configs = {
      'PENDING_APPROVAL': {
        'text': '승인 대기',
        'bgColor': const Color(0xFFFEF3C7),
        'textColor': const Color(0xFFA16207),
      },
      'APPROVED': {
        'text': '결제 대기',
        'bgColor': const Color(0xFFDBEAFE),
        'textColor': const Color(0xFF1D4ED8),
      },
      'PAYMENT_COMPLETED': {
        'text': '결제 완료',
        'bgColor': const Color(0xFFD1FAE5),
        'textColor': const Color(0xFF065F46),
      },
      'IN_PROGRESS': {
        'text': '임대 중',
        'bgColor': const Color(0xFFDBEAFE),
        'textColor': const Color(0xFF1D4ED8),
      },
      'COMPLETED': {
        'text': '계약 종료',
        'bgColor': const Color(0xFFF3F4F6),
        'textColor': const Color(0xFF6B7280),
      },
      'REJECTED': {
        'text': '승인 거절',
        'bgColor': const Color(0xFFFEE2E2),
        'textColor': const Color(0xFFDC2626),
      },
      'CANCELLED_BY_GUEST': {
        'text': '계약 취소',
        'bgColor': const Color(0xFFFEE2E2),
        'textColor': const Color(0xFFDC2626),
      },
      'CANCELLED_BY_HOST': {
        'text': '계약 취소',
        'bgColor': const Color(0xFFFEE2E2),
        'textColor': const Color(0xFFDC2626),
      },
      'REFUNDED': {
        'text': '계약 취소',
        'bgColor': const Color(0xFFFEE2E2),
        'textColor': const Color(0xFFDC2626),
      },
      'APPROVAL_EXPIRED': {
        'text': '계약 취소',
        'bgColor': const Color(0xFFFEE2E2),
        'textColor': const Color(0xFFDC2626),
      },
      'PAYMENT_EXPIRED': {
        'text': '계약 취소',
        'bgColor': const Color(0xFFFEE2E2),
        'textColor': const Color(0xFFDC2626),
      },
    };

    return configs[status.value] ??
        {
          'text': status.label,
          'bgColor': const Color(0xFFF3F4F6),
          'textColor': const Color(0xFF6B7280),
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

    return Text(message, style: AppTextStyles.bodyMedium.copyWith(color: color));
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
          children: [
            const Icon(Icons.description_outlined, size: 16, color: Color(0xFF2563EB)),
            const SizedBox(width: 6),
            Text(
              '계약 상세',
              style: AppTextStyles.labelMedium.copyWith(
                color: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestRow(ContractListItem contract) {
    final showChat = [
      ContractStatus.approved,
      ContractStatus.paymentCompleted,
      ContractStatus.inProgress,
      ContractStatus.completed,
    ].contains(contract.status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '게스트',
            style: AppTextStyles.bodyLarge.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          contract.partnerDisplayName,
          style: AppTextStyles.bodyLarge.copyWith(color: Colors.black),
        ),
        if (showChat) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              debugPrint('💬 [HOST_CONTRACTS] 채팅방으로 이동: contractId=${contract.id}');
              context.go('/chat-list?contractId=${contract.id}');
            },
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF2563EB)),
            ),
          ),
        ],
      ],
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
            style: AppTextStyles.bodyLarge.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '게스트 메시지',
            style: AppTextStyles.labelLarge.copyWith(
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.black),
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
          Text(
            '이용 금액',
            style: AppTextStyles.labelLarge.copyWith(
              color: const Color(0xFF111827),
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
                        Text(
                          '청소비',
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.black),
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
                            child: Text(
                              'EZ서비스',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '₩${FormatUtils.formatCurrency(contract.cleaningFee ?? 0)}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: const Color(0xFF111827),
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
                  '₩${FormatUtils.formatCurrency(contract.deposit ?? 0)}',
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
                  '₩${FormatUtils.formatCurrency((contract.rentalFee ?? 0) + (contract.maintenanceFee ?? 0) + (contract.cleaningFee ?? 0) + (contract.deposit ?? 0))}',
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
                  '₩${FormatUtils.formatCurrency(settlementAmount)}',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: const Color(0xFF2563EB),
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
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: Colors.black)),
        Text(
          '₩${FormatUtils.formatCurrency(amount)}',
          style: AppTextStyles.labelMedium.copyWith(
            color: const Color(0xFF111827),
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
          icon: const Icon(Icons.check, size: 16, color: Colors.white),
          label: Text(
            '승인하기',
            style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
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
          label: Text(
            '거절하기',
            style: AppTextStyles.labelLarge,
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF6B7280),
            side: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  /// 호스트 퇴실 관련 섹션
  Widget _buildHostCheckoutSection(ContractListItem contract) {
    // IN_PROGRESS 또는 COMPLETED 상태에서 checkoutStatus별 UI
    if (contract.status == ContractStatus.inProgress ||
        contract.status == ContractStatus.completed) {
      final checkoutStatus = contract.checkoutStatus;

      // GUEST_COMPLETED: 게스트 퇴실 완료 → 호스트 확인/보류 버튼
      if (checkoutStatus == CheckoutStatus.guestCompleted) {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7), // yellow-100
                  border: Border.all(color: const Color(0xFFFDE68A)), // yellow-200
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFF92400E)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '게스트가 퇴실을 완료했습니다. 확인해주세요.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF92400E), // yellow-800
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleHostCheckoutConfirm(contract.id, contract.roomId),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '퇴실 확인',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleHostCheckoutPending(contract.id),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFF97316)), // orange-500
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '퇴실 확인 보류',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF97316), // orange-500
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }

      // HOLD_REQUESTED: 보증금 반환 보류 신청 → 관리자 승인 대기
      if (checkoutStatus == CheckoutStatus.holdRequested) {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED), // orange-50
              border: Border.all(color: const Color(0xFFFED7AA)), // orange-200
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '보증금 반환 보류를 신청했습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9A3412), // orange-800
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '관리자 승인을 기다리고 있습니다.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9A3412),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // HOST_CONFIRMED: 호스트 확인 완료
      if (checkoutStatus == CheckoutStatus.hostConfirmed) {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7), // green-100
              border: Border.all(color: const Color(0xFFBBF7D0)), // green-200
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '퇴실 확인이 완료되었습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534), // green-800
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '보증금 환급 절차가 진행 중입니다.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF166534),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // HOST_PENDING: 호스트 확인 보류 + 합의 내용 제출 버튼
      if (checkoutStatus == CheckoutStatus.hostPending) {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED), // orange-50
                  border: Border.all(color: const Color(0xFFFED7AA)), // orange-200
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ 퇴실 확인이 보류되었습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9A3412), // orange-800
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '관리자가 확인 중입니다. 게스트와 합의가 되었다면 합의 내용을 제출해주세요.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9A3412),
                      ),
                    ),
                  ],
                ),
              ),
              // ACCEPTED 상태면 버튼 비노출
              if (contract.depositAgreementStatus != 'ACCEPTED') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleDepositAgreement(contract),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFFF97316), // orange-500
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      contract.depositAgreementStatus == 'SUBMITTED' ? '합의 내용 수정' : '합의 내용 제출',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }

      // AGREEMENT_SUBMITTED: 합의 내용 제출 완료
      if (checkoutStatus == CheckoutStatus.agreementSubmitted) {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // blue-50
              border: Border.all(color: const Color(0xFFBFDBFE)), // blue-200
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '합의 내용이 제출되었습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF), // blue-800
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '게스트 확인을 기다리고 있습니다.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // AUTO_RETURNED: 보증금 전액 반환 완료
      if (checkoutStatus == CheckoutStatus.autoReturned) {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7), // green-100
              border: Border.all(color: const Color(0xFFBBF7D0)), // green-200
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '보증금 전액 반환 완료',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534), // green-800
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '합의 기한이 경과하여 보증금이 게스트에게 전액 반환되었습니다.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF166534),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // COMPLETED 상태 + HOST_CONFIRMED
    if (contract.status == ContractStatus.completed &&
        contract.checkoutStatus == CheckoutStatus.hostConfirmed) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            border: Border.all(color: const Color(0xFFBBF7D0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '✅ 퇴실 확인 완료',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF166534),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// PAYMENT_COMPLETED 상태에서 호스트 계약 취소
  Future<void> _handleCancelByHost(int contractId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _CancelByHostDialog(),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      await _contractService.cancelByHost(contractId, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('계약이 취소되었습니다.'),
            backgroundColor: Color(0xFFF97316),
          ),
        );
        _loadContracts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('계약 취소 실패: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  /// IN_PROGRESS 상태에서 퇴실 확인 요청 (호스트 주도)
  Future<void> _handleRequestCheckout(int contractId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('퇴실 확인'),
        content: const Text(
          '퇴실을 확인하시겠습니까?\n계약이 종료되며 보증금 환급 절차가 진행됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('확인'),
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
            content: Text('퇴실 확인이 완료되었습니다.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _loadContracts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('퇴실 확인 실패: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  /// IN_PROGRESS 상태에서 취소 요청 (관리자 승인 필요)
  void _handleRequestCancellation(int contractId) {
    setState(() {
      _selectedContractIdForCancellation = contractId;
      _showCancellationModal = true;
    });
  }

  /// 취소 요청 API 호출 (RequestCancellationModal 콜백)
  Future<void> _submitCancellationRequest(String reason) async {
    if (_selectedContractIdForCancellation == null) return;

    setState(() {
      _showCancellationModal = false;
    });

    try {
      await _contractService.requestCancellation(
        _selectedContractIdForCancellation!,
        reason,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('취소 요청이 접수되었습니다. 관리자 승인 후 처리됩니다.'),
          backgroundColor: Color(0xFFF97316),
        ),
      );

      await _loadContracts();

      setState(() {
        _selectedContractIdForCancellation = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('취소 요청 실패: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  /// 보증금 합의 내용 제출 (DepositAgreementModal 콜백)
  Future<void> _submitDepositAgreement(int deductAmount, String agreementText) async {
    if (_selectedContractForAgreement == null) return;

    setState(() {
      _showDepositAgreementModal = false;
    });

    try {
      await _contractService.submitDepositAgreement(
        _selectedContractForAgreement!.id,
        deductAmount: deductAmount,
        agreementText: agreementText,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('합의 내용이 제출되었습니다. 게스트 확인을 기다립니다.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      await _loadContracts();

      setState(() {
        _selectedContractForAgreement = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('합의 내용 제출 실패: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  /// 합의 내용 제출/수정 모달 표시
  Future<void> _handleDepositAgreement(ContractListItem contract) async {
    // 수정 모드: 기존 합의 내용을 상세 API에서 가져옴
    if (contract.depositAgreementStatus == 'SUBMITTED') {
      try {
        final agreement = await _contractService.getDepositAgreement(contract.id);
        if (!mounted) return;
        setState(() {
          _selectedContractForAgreement = contract;
          _existingDeductAmount = agreement?.deductAmount;
          _existingAgreementText = agreement?.agreementText;
          _showDepositAgreementModal = true;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('합의 내용 조회 실패: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      }
    } else {
      // 신규 제출 모드
      setState(() {
        _selectedContractForAgreement = contract;
        _existingDeductAmount = null;
        _existingAgreementText = null;
        _showDepositAgreementModal = true;
      });
    }
  }

  /// 호스트 퇴실 확인
  Future<void> _handleHostCheckoutConfirm(int contractId, int roomId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('퇴실 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('퇴실 상태를 확인하시겠습니까?\n확인 후 보증금 환급 절차가 진행됩니다.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                border: Border.all(color: const Color(0xFFFED7AA)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 20, color: Color(0xFFF97316)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: '청소 서비스 진행을 위해 방 도어락 비밀번호가 변경되진 않았는지 반드시 확인해주세요. ',
                          ),
                          TextSpan(
                            text: '(변경 요청)',
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.of(dialogContext).pop(false);
                                context.go('/host/room-registration/$roomId?step=3');
                              },
                          ),
                        ],
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9A3412),
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
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _contractService.hostCheckoutConfirm(contractId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('퇴실 확인이 완료되었습니다.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _loadContracts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('퇴실 확인 실패: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  /// 호스트 퇴실 확인 보류 (모달 표시)
  Future<void> _handleHostCheckoutPending(int contractId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _CheckoutPendingDialog(),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      await _contractService.hostCheckoutPending(contractId, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('퇴실 확인이 보류되었습니다. 관리자가 확인합니다.'),
            backgroundColor: Color(0xFFF97316),
          ),
        );
        _loadContracts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('퇴실 보류 처리 실패: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
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

      if (!mounted) return;
      setState(() {
        _selectedContractIdForApproval = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('계약 승인 실패: $e')),
      );
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

/// 퇴실 확인 보류 사유 입력 다이얼로그
class _CheckoutPendingDialog extends StatefulWidget {
  @override
  State<_CheckoutPendingDialog> createState() => _CheckoutPendingDialogState();
}

class _CheckoutPendingDialogState extends State<_CheckoutPendingDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448), // max-w-md
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '퇴실 확인 보류',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '보류 사유를 입력해주세요. 관리자가 확인 후 처리합니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '보류 사유를 입력하세요...',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final reason = _reasonController.text.trim();
                      if (reason.isNotEmpty) {
                        Navigator.of(context).pop(reason);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316), // orange-500
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '보류하기',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 호스트 계약 취소 사유 입력 다이얼로그
class _CancelByHostDialog extends StatefulWidget {
  @override
  State<_CancelByHostDialog> createState() => _CancelByHostDialogState();
}

class _CancelByHostDialogState extends State<_CancelByHostDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '계약 취소',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '계약 취소 사유를 입력해주세요. 위약금이 발생할 수 있습니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '취소 사유를 입력하세요...',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final reason = _reasonController.text.trim();
                      if (reason.isNotEmpty) {
                        Navigator.of(context).pop(reason);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '취소하기',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
