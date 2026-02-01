import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart' hide AppColors, AppTextStyles;
import '../../models/contract.dart';
import '../../services/contract_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/common/app_gnb.dart';
import '../../widgets/modals/host_contract_modals.dart';

/// 호스트용 계약 목록 페이지
class HostContractsPage extends StatefulWidget {
  const HostContractsPage({super.key});

  @override
  State<HostContractsPage> createState() => _HostContractsPageState();
}

class _HostContractsPageState extends State<HostContractsPage> {
  final ContractService _contractService = ContractService();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'ko_KR');
  final DateFormat _dateFormat = DateFormat('yyyy.MM.dd');

  List<ContractListItem> _contracts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedStatus;

  // 탭 메뉴 state
  String? _selectedTab; // 'in_progress', 'past', 'cancelled'
  bool _showStatusDropdown = false;

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
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // 필터링된 계약 목록
  List<ContractListItem> get _filteredContracts {
    return _contracts.where((contract) {
      // 특정 상태 필터가 선택된 경우
      if (_selectedStatus != null && _selectedStatus != 'all') {
        if (contract.status.toString().split('.').last != _selectedStatus) {
          return false;
        }
      }

      // 탭 필터 적용
      if (_selectedTab == 'in_progress') {
        if (![
          ContractStatus.pendingApproval,
          ContractStatus.approved,
          ContractStatus.paymentCompleted,
          ContractStatus.inProgress
        ].contains(contract.status)) {
          return false;
        }
      }

      if (_selectedTab == 'past') {
        if (contract.status != ContractStatus.completed) {
          return false;
        }
      }

      if (_selectedTab == 'cancelled') {
        if (![
          ContractStatus.cancelledByGuest,
          ContractStatus.cancelledByHost,
          ContractStatus.rejected
        ].contains(contract.status)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // 탭별 계약 개수
  int get _inProgressCount {
    return _contracts.where((c) => [
      ContractStatus.pendingApproval,
      ContractStatus.approved,
      ContractStatus.paymentCompleted,
      ContractStatus.inProgress
    ].contains(c.status)).length;
  }

  int get _pastCount {
    return _contracts.where((c) => c.status == ContractStatus.completed).length;
  }

  int get _cancelledCount {
    return _contracts.where((c) => [
      ContractStatus.cancelledByGuest,
      ContractStatus.cancelledByHost,
      ContractStatus.rejected
    ].contains(c.status)).length;
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadContracts();
  }

  Color _getStatusColor(ContractStatus status) {
    switch (status) {
      case ContractStatus.pendingApproval:
        return Colors.orange;
      case ContractStatus.approvalExpired:
        return Colors.grey;
      case ContractStatus.approved:
      case ContractStatus.paymentExpired:
        return Colors.grey.shade600;
        return Colors.blue;
      case ContractStatus.paymentCompleted:
        return Colors.green;
      case ContractStatus.inProgress:
        return Colors.teal;
      case ContractStatus.completed:
        return Colors.grey;
      case ContractStatus.rejected:
        return Colors.red;
      case ContractStatus.cancelledByGuest:
      case ContractStatus.cancelledByHost:
        return Colors.red.shade300;
      case ContractStatus.refunded:
        return Colors.purple;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppGNB(),
      body: Column(
        children: [
          // 탭 메뉴
          _buildTabMenu(),

          // 드롭다운 필터
          _buildDropdownFilter(),

          // 안내 메시지
          _buildInfoBox(),

          // 계약 목록
          Expanded(
            child: _buildContractsList(),
          ),
        ],
      ),
    );
  }

  // 탭 메뉴
  Widget _buildTabMenu() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    label: '진행중',
                    count: _inProgressCount,
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
                    count: _pastCount,
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
                    count: _cancelledCount,
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
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary600 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '($count)',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 드롭다운 필터
  Widget _buildDropdownFilter() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 160,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showStatusDropdown = !_showStatusDropdown;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getStatusText(_selectedStatus),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          Icon(
                            _showStatusDropdown
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 드롭다운 메뉴
              if (_showStatusDropdown)
                Positioned(
                  left: 0,
                  top: 52,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDropdownItem('전체 상태', 'all'),
                          _buildDropdownItem('승인 대기', 'PENDING_APPROVAL'),
                          _buildDropdownItem('결제 대기', 'APPROVED'),
                          _buildDropdownItem('결제 완료', 'PAYMENT_COMPLETED'),
                          _buildDropdownItem('임대 중', 'IN_PROGRESS'),
                          _buildDropdownItem('계약 종료', 'COMPLETED'),
                          _buildDropdownItem('승인 거절', 'REJECTED'),
                          _buildDropdownItem('계약 취소', 'CANCELLED_BY_GUEST'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownItem(String label, String value) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = value;
          _showStatusDropdown = false;

          // 상태에 따라 자동으로 탭 활성화
          if (value == 'all') {
            _selectedTab = null;
          } else if (['PENDING_APPROVAL', 'APPROVED', 'PAYMENT_COMPLETED', 'IN_PROGRESS'].contains(value)) {
            _selectedTab = 'in_progress';
          } else if (value == 'COMPLETED') {
            _selectedTab = 'past';
          } else {
            _selectedTab = 'cancelled';
          }
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _getStatusText(String? status) {
    if (status == null) return '계약 상태';
    if (status == 'all') return '전체 상태';

    final statusMap = {
      'PENDING_APPROVAL': '승인 대기',
      'APPROVED': '결제 대기',
      'PAYMENT_COMPLETED': '결제 완료',
      'IN_PROGRESS': '임대 중',
      'COMPLETED': '계약 종료',
      'REJECTED': '승인 거절',
      'CANCELLED_BY_GUEST': '계약 취소',
      'CANCELLED_BY_HOST': '계약 취소',
    };

    return statusMap[status] ?? '계약 상태';
  }

  // 안내 메시지
  Widget _buildInfoBox() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade100),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade700,
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
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 게스트의 계약 요청을 승인하거나 거절할 수 있습니다.\n'
                      '• 승인 후 게스트가 결제하면 계약이 확정됩니다.\n'
                      '• 호스트가 계약을 취소하려면 위약금을 결제해야 합니다.\n'
                      '• 입주일 이후 취소 시 게스트와 합의 후 관리자 승인이 필요합니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade800,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContractsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
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

    if (_filteredContracts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              '계약 요청이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
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
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredContracts.length,
            itemBuilder: (context, index) {
              final contract = _filteredContracts[index];
              return _buildContractCard(contract);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContractCard(ContractListItem contract) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          final path = '/host/contracts/${contract.id}';
          debugPrint('🔍 [CONTRACTS] Navigating to: $path');
          context.go(path);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상태 배지와 날짜
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(contract.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(contract.status),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      contract.status.label,
                      style: TextStyle(
                        color: _getStatusColor(contract.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _dateFormat.format(contract.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 방 정보
              Row(
                children: [
                  if (contract.roomThumbnail != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        contract.roomThumbnail!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.home, size: 40),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.home, size: 40),
                    ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contract.roomName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contract.roomAddress,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${contract.roomArea.toStringAsFixed(0)}평 · ${contract.buildingType}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // 게스트 정보
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '게스트: ${contract.partnerDisplayName}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (contract.partnerEmail != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            contract.partnerEmail!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // 게스트 메시지가 있는 경우
              if (contract.guestMessage != null && contract.guestMessage!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.message_outlined,
                            size: 16,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '게스트 메시지',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        contract.guestMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // 계약 정보
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '체크인',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dateFormat.format(contract.checkInDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '체크아웃',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dateFormat.format(contract.checkOutDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${contract.totalDays}일',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 금액 정보 (React UI와 동일한 형식으로 항상 표시)
              _buildSimplePricingSection(contract),

              // 상태별 액션 버튼
              if (_shouldShowActionButtons(contract.status)) ...[
                const SizedBox(height: 16),
                _buildActionButtons(contract),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 액션 버튼 표시 여부 확인
  // 호스트 계약 금액 섹션 (React UI 완전 복제)
  Widget _buildSimplePricingSection(ContractListItem contract) {
    final settlementAmount = _calculateSettlementAmount(contract);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
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

          // 임대료, 관리비, 청소비 (들여쓰기)
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

          // 보증금 (구분선)
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

          // 총 계약 금액 (굵은 구분선)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFD1D5DB), width: 2)),
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
                  '₩${_currencyFormat.format(contract.finalTotalAmount)}',
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

          // 정산 예정금액 (파란색)
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
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.black),
        ),
        Text(
          '₩${_currencyFormat.format(amount)}',
          style: AppTextStyles.labelMedium.copyWith(
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  // 정산 예정금액 계산 (React와 동일한 로직)
  int _calculateSettlementAmount(ContractListItem contract) {
    final rentalFee = contract.rentalFee ?? 0;
    final maintenanceFee = contract.maintenanceFee ?? 0;
    final cleaningFee = contract.cleaningFee ?? 0;

    // EZ서비스인 경우: 청소비는 EZ가 가져가므로 호스트 정산에서 제외
    final usageFee = (contract.isEzCleaning == true)
        ? rentalFee + maintenanceFee
        : rentalFee + maintenanceFee + cleaningFee;

    // 호스트 수수료 3.3% 차감
    final commissionFee = (usageFee * 0.033).floor();

    return usageFee - commissionFee;
  }

  bool _shouldShowActionButtons(ContractStatus status) {
    return status == ContractStatus.pendingApproval ||
        status == ContractStatus.paymentCompleted ||
        status == ContractStatus.inProgress;
  }

  // 상태별 액션 버튼 빌드
  Widget _buildActionButtons(ContractListItem contract) {
    switch (contract.status) {
      case ContractStatus.pendingApproval:
        // 승인 대기: 승인하기 + 거절하기
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleReject(contract),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.red.shade400, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '거절하기',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleApprove(contract),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '승인하기',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );

      case ContractStatus.paymentCompleted:
        // 결제 완료: 입주 준비 안내 + 계약 취소
        return Column(
          children: [
            // 입주 준비 안내 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showGuestPreparationGuide(contract),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.checklist, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '입주 준비 안내 보기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            // 계약 취소 버튼
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _handleCancelContract(contract),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.orange.shade400, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '계약 취소',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ),
          ],
        );

      case ContractStatus.inProgress:
        // 이용 중: 취소 요청
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _handleRequestCancellation(contract),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: Colors.red.shade400, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '취소 요청',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade600,
              ),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // 승인 처리
  void _handleApprove(ContractListItem contract) async {
    debugPrint('🔵 [HOST_CONTRACTS] 승인하기 클릭: ${contract.id}');

    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계약 승인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('이 계약 요청을 승인하시겠습니까?'),
            const SizedBox(height: 12),
            Text(
              '게스트: ${contract.partnerDisplayName}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              '기간: ${_dateFormat.format(contract.checkInDate)} ~ ${_dateFormat.format(contract.checkOutDate)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                '승인 후 게스트가 결제하면 계약이 확정됩니다.',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
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
            ),
            child: const Text('승인하기'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // TODO: API 호출 - await _contractService.approveContract(contract.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('계약을 승인했습니다.'),
              backgroundColor: Colors.green,
            ),
          );
          _loadContracts(); // 목록 새로고침
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('승인 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // 거절 처리
  void _handleReject(ContractListItem contract) {
    debugPrint('🔴 [HOST_CONTRACTS] 거절하기 클릭: ${contract.id}');

    showDialog(
      context: context,
      builder: (context) => RejectContractModal(
        onClose: () => Navigator.of(context).pop(),
        onConfirm: (reason) async {
          Navigator.of(context).pop();

          try {
            // TODO: API 호출 - await _contractService.rejectContract(contract.id, reason);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('계약을 거절했습니다.'),
                  backgroundColor: Colors.orange,
                ),
              );
              _loadContracts(); // 목록 새로고침
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('거절 실패: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  // 계약 취소 처리 (결제 완료 상태)
  void _handleCancelContract(ContractListItem contract) async {
    debugPrint('🟠 [HOST_CONTRACTS] 계약 취소 클릭: ${contract.id}');

    // TODO: 상세 계약 정보 조회 필요 (환불 계산을 위해)
    // final fullContract = await _contractService.getContractDetail(contract.id);
    // 현재는 ContractListItem만 있으므로 간단한 확인 다이얼로그만 표시

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('계약 취소'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('이 계약을 취소하시겠습니까?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ 주의사항',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• 호스트가 계약을 취소하는 경우 위약금이 발생합니다.\n'
                    '• 환불 정책에 따라 게스트에게 환불됩니다.\n'
                    '• 취소 후 해당 기간이 다시 임대 가능 상태가 됩니다.',
                    style: AppTextStyles.bodySmall.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
            ),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // TODO: API 호출 - await _contractService.hostCancelContract(contract.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('계약을 취소했습니다.'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadContracts(); // 목록 새로고침
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('취소 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // 취소 요청 처리 (이용 중 상태)
  void _handleRequestCancellation(ContractListItem contract) {
    debugPrint('🔴 [HOST_CONTRACTS] 취소 요청 클릭: ${contract.id}');

    showDialog(
      context: context,
      builder: (context) => RequestCancellationModal(
        onClose: () => Navigator.of(context).pop(),
        onConfirm: (reason) async {
          Navigator.of(context).pop();

          try {
            // TODO: API 호출 - await _contractService.requestCancellation(contract.id, reason);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('취소 요청을 전송했습니다. 게스트의 동의를 기다립니다.'),
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 3),
                ),
              );
              _loadContracts(); // 목록 새로고침
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('취소 요청 실패: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  // 게스트 입주 준비 안내 표시 (결제 완료 상태에서 추가 버튼)
  void _showGuestPreparationGuide(ContractListItem contract) {
    showDialog(
      context: context,
      builder: (context) => GuestPreparationModal(
        onClose: () => Navigator.of(context).pop(),
        guestName: contract.partnerDisplayName,
        checkInDate: contract.checkInDate,
        roomAddress: contract.roomAddress,
      ),
    );
  }
}
