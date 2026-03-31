import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import '../../core/exceptions.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import '../../constants/fee_constants.dart';
import '../../models/contract.dart';
import '../../services/contract_service.dart';
import '../../widgets/modals/guest_preparation_modal.dart';
import '../../widgets/modals/host_contract_rejection_modal.dart';
import '../../widgets/modals/host_contract_modals.dart' show DepositAgreementModal, RequestCancellationModal;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/common/app_footer.dart';
import '../../widgets/contract/host_contract_dialogs.dart';
import '../../widgets/contract/host_contract_card.dart';
import '../../widgets/contract/host_info_message.dart';
import '../../widgets/contract/contract_tab_menu.dart';
import '../../widgets/contract/contract_status_helper.dart';
import '../../widgets/common/empty_state_box.dart';

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
      'in_progress'; // 'in_progress', 'completed', 'cancelled' - 기본값: 진행중
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


      setState(() {
        _contracts = contracts;
        _isLoading = false;
      });
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      AppLogger.e('❌ [HOST_CONTRACTS] Error loading contracts: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // 필터링된 계약 목록
  List<ContractListItem> get _filteredContracts {
    // 1단계: 탭 기반 필터링 (ContractStatusHelper 위임)
    final tabFiltered = ContractStatusHelper.filterByTab(_contracts, _selectedTab);

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
      return tabFiltered.where((c) {
        if (cancelledStatuses.contains(_selectedStatus)) {
          return cancelledStatuses.contains(c.status.value);
        }
        return c.status.value == _selectedStatus;
      }).toList();
    }

    return tabFiltered;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF9FAFB), // bg-gray-50
      child: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 896),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),

                          // 탭 (진행중 / 지난계약 / 취소)
                          ContractTabMenu(
                            selectedTab: _selectedTab,
                            onTabChanged: (tab) {
                              setState(() {
                                _selectedTab = tab;
                                _selectedStatus = null;
                              });
                            },
                            getTabCount: (tab) => ContractStatusHelper.countByTab(_contracts, tab),
                          ),
                          const SizedBox(height: 12),

                          // 상태 필터 드롭다운 (왼쪽 정렬)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _buildStatusDropdown(),
                          ),
                          const SizedBox(height: 24),

                          // 안내 메시지
                          const HostInfoMessage(),
                          const SizedBox(height: 24),

                          // 계약 목록
                          _buildContractList(),

                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),

                  // 푸터 (maxWidth 제한 밖)
                  const AppFooter(),
                ],
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
            _selectedTab = 'completed';
          } else {
            _selectedTab = 'cancelled';
          }
        });
        _loadContracts();
      },
      offset: const Offset(0, 48), // 버튼 아래에 메뉴 표시
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.gray200),
      ),
      color: Colors.white,
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.gray300, width: 2),
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
      return const EmptyStateBox(message: '계약 내역이 없습니다.');
    }

    // 계약 목록
    return Column(
      children: _filteredContracts
          .map((contract) => HostContractCard(
                contract: contract,
                onApprove: () => _handleApprove(contract.id),
                onReject: () => _handleReject(contract.id),
                onCancelByHost: () => _handleCancelByHost(contract.id),
                onRequestCheckout: () => _handleRequestCheckout(contract.id),
                onRequestCancellation: () => _handleRequestCancellation(contract.id),
                onCheckoutConfirm: _handleHostCheckoutConfirm,
                onCheckoutPending: _handleHostCheckoutPending,
                onDepositAgreement: _handleDepositAgreement,
              ))
          .toList(),
    );
  }

  /// PAYMENT_COMPLETED 상태에서 호스트 계약 취소
  Future<void> _handleCancelByHost(int contractId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const CancelByHostDialog(),
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
    } on UnauthorizedException {
      if (mounted) context.go('/login');
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
              backgroundColor: AppColors.primary600,
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
            backgroundColor: AppColors.green500,
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
    } on UnauthorizedException {
      if (mounted) context.go('/login');
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
          backgroundColor: AppColors.green500,
        ),
      );

      await _loadContracts();

      setState(() {
        _selectedContractForAgreement = null;
      });
    } on UnauthorizedException {
      if (mounted) context.go('/login');
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
      } on UnauthorizedException {
        if (mounted) context.go('/login');
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
                              color: AppColors.primary600,
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
              backgroundColor: AppColors.primary600,
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
            backgroundColor: AppColors.green500,
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
      builder: (context) => const CheckoutPendingDialog(),
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
    } on UnauthorizedException {
      if (mounted) context.go('/login');
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
    } on UnauthorizedException {
      if (mounted) context.go('/login');
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
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('계약 거절 실패: $e')));
    }
  }
}

