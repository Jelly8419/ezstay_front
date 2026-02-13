import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/format_utils.dart';
import '../../utils/contract_utils.dart';
import '../../constants/app_constants.dart' hide AppColors, AppTextStyles;
import '../../models/contract.dart';
import '../../services/contract_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../utils/responsive_util.dart';
import '../../widgets/modals/host_contract_modals.dart';
import '../../widgets/common/app_footer.dart';

/// 호스트용 계약 목록 페이지
class HostContractsPage extends StatefulWidget {
  const HostContractsPage({super.key});

  @override
  State<HostContractsPage> createState() => _HostContractsPageState();
}

class _HostContractsPageState extends State<HostContractsPage> {
  final ContractService _contractService = ContractService();
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

  // React UI와 동일한 상태 뱃지 색상 (bg/text)
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
        return const Color(0xFFF3F4F6); // gray-100
      case ContractStatus.rejected:
      case ContractStatus.cancelledByGuest:
      case ContractStatus.cancelledByHost:
        return const Color(0xFFF3F4F6); // gray-100
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _getStatusTextColor(ContractStatus status) {
    switch (status) {
      case ContractStatus.pendingApproval:
        return const Color(0xFFB45309); // yellow-700
      case ContractStatus.approved:
        return const Color(0xFF1D4ED8); // blue-700
      case ContractStatus.paymentCompleted:
        return const Color(0xFF15803D); // green-700
      case ContractStatus.inProgress:
        return const Color(0xFF7E22CE); // purple-700
      case ContractStatus.completed:
        return const Color(0xFF374151); // gray-700
      case ContractStatus.rejected:
      case ContractStatus.cancelledByGuest:
      case ContractStatus.cancelledByHost:
        return const Color(0xFF374151); // gray-700
      default:
        return const Color(0xFF374151);
    }
  }

  // React UI와 동일한 상태 표시 텍스트
  String _getStatusLabel(ContractStatus status) {
    switch (status) {
      case ContractStatus.pendingApproval:
        return '승인 대기';
      case ContractStatus.approved:
        return '결제 대기';
      case ContractStatus.paymentCompleted:
        return '결제 완료';
      case ContractStatus.inProgress:
        return '임대 중';
      case ContractStatus.completed:
        return '계약 종료';
      case ContractStatus.rejected:
        return '승인 거절';
      case ContractStatus.cancelledByGuest:
      case ContractStatus.cancelledByHost:
        return '계약 취소';
      default:
        return status.label;
    }
  }

  // 상태별 안내 메시지 (React UI 동일)
  String? _getStatusMessage(ContractStatus status) {
    switch (status) {
      case ContractStatus.pendingApproval:
        return '게스트의 계약 요청을 검토해주세요.';
      case ContractStatus.approved:
        return '게스트가 결제하면 계약이 확정됩니다.';
      case ContractStatus.paymentCompleted:
        return '입주일에 맞춰 게스트를 맞이해주세요.';
      default:
        return null;
    }
  }

  Color? _getStatusMessageColor(ContractStatus status) {
    switch (status) {
      case ContractStatus.pendingApproval:
        return const Color(0xFFCA8A04); // yellow-600
      case ContractStatus.approved:
        return const Color(0xFF2563EB); // blue-600
      case ContractStatus.paymentCompleted:
        return const Color(0xFF16A34A); // green-600
      default:
        return null;
    }
  }

  // 요일 포함 날짜 포맷 (React formatDateWithDay 동일)
  String _formatDateWithDay(DateTime date) {
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final weekday = weekdays[date.weekday % 7];
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year.$month.$day($weekday)';
  }

  // 계약 기간 포맷 (React formatContractPeriod 동일)
  String _formatContractPeriod(DateTime checkIn, DateTime checkOut) {
    return '${_formatDateWithDay(checkIn)} - ${_formatDateWithDay(checkOut)}';
  }


  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF9FAFB), // bg-gray-50
      child: RefreshIndicator(
        onRefresh: _loadContracts,
        child: ListView(
          children: [
            const SizedBox(height: 24), // py-6

            // 탭 메뉴
            _buildTabMenu(),

            // 드롭다운 필터
            _buildDropdownFilter(),

            // 안내 메시지
            _buildInfoBox(),

            // 계약 목록
            _buildContractsList(),

            // 푸터
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  // 탭 메뉴 (React: bg-white rounded-xl p-4 shadow-sm mb-3, gap-2)
  Widget _buildTabMenu() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12), // mb-3
          padding: const EdgeInsets.all(16), // p-4
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12), // rounded-xl
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
              const SizedBox(width: 8), // gap-2
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
              const SizedBox(width: 8), // gap-2
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
      borderRadius: BorderRadius.circular(8), // rounded-lg
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), // py-2.5 px-4
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF3F4F6), // blue-600 / gray-100
          borderRadius: BorderRadius.circular(8), // rounded-lg
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF4B5563), // text-gray-600
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2), // mt-0.5
            Text(
              '($count)',
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
                fontSize: 14, // text-sm
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 드롭다운 필터 (React: w-40 sm:w-48, mb-6)
  Widget _buildDropdownFilter() {
    final isMobile = ResponsiveUtil.isMobile(context);
    final dropdownWidth = isMobile ? 160.0 : 192.0; // w-40 / sm:w-48

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), // mb-6
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: dropdownWidth,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showStatusDropdown = !_showStatusDropdown;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // py-2.5 px-4
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFD1D5DB), width: 2), // border-2 border-gray-300
                        borderRadius: BorderRadius.circular(8), // rounded-lg
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
                              fontSize: 14, // text-sm
                              fontWeight: FontWeight.w700, // font-bold
                              color: Color(0xFF374151), // text-gray-700
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 16, // w-4 h-4
                            color: Color(0xFF374151),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 드롭다운 메뉴 (React: mt-2, rounded-lg, shadow-lg)
              if (_showStatusDropdown)
                Positioned(
                  left: 0,
                  top: 50,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8), // rounded-lg
                    child: Container(
                      width: dropdownWidth,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E7EB)), // border-gray-200
                        borderRadius: BorderRadius.circular(8), // rounded-lg
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
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
      hoverColor: const Color(0xFFF9FAFB), // hover:bg-gray-50
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // px-4 py-2.5
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14, // text-sm
            fontWeight: FontWeight.w700, // font-bold
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

  // 안내 메시지 (React: bg-blue-50 border-blue-100 rounded-xl p-4 mb-6)
  Widget _buildInfoBox() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24), // mb-6
          padding: const EdgeInsets.all(16), // p-4
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF), // bg-blue-50
            border: Border.all(color: const Color(0xFFDBEAFE)), // border-blue-100
            borderRadius: BorderRadius.circular(12), // rounded-xl
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2), // mt-0.5
                child: Icon(
                  Icons.info_outline,
                  color: Color(0xFF2563EB), // text-blue-600
                  size: 20, // w-5 h-5
                ),
              ),
              const SizedBox(width: 12), // gap-3
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '안내사항',
                      style: TextStyle(
                        fontWeight: FontWeight.w700, // font-bold
                        color: Color(0xFF1E3A5F), // text-blue-900
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4), // mb-1
                    // React: text-sm text-blue-800 space-y-1 (각 li)
                    ...[
                      '• 게스트의 계약 요청을 검토해주세요.',
                      '• 승인 후 게스트가 결제하면 계약이 확정됩니다.',
                      '• 호스트가 계약을 취소하려면 위약금을 결제해야 합니다.',
                      '• 입주일 이후 취소 시 게스트와 합의 후 관리자 승인이 필요합니다.',
                    ].map((text) => Padding(
                      padding: const EdgeInsets.only(bottom: 4), // space-y-1
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 14, // text-sm
                          color: Color(0xFF1E40AF), // text-blue-800
                        ),
                      ),
                    )),
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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Center(
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
        ),
      );
    }

    if (_filteredContracts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Center(
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
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ..._filteredContracts.map(
                (contract) => _buildContractCard(contract),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContractCard(ContractListItem contract) {
    final isMobile = ResponsiveUtil.isMobile(context);
    final statusMessage = _getStatusMessage(contract.status);
    final statusMsgColor = _getStatusMessageColor(contract.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)), // border-gray-200
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24), // p-6
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 상태 뱃지 + 안내 메시지 + 상세 버튼 ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 뱃지 + 안내 메시지
                Expanded(
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusBadge(contract.status),
                            if (statusMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                statusMessage,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: statusMsgColor,
                                ),
                              ),
                            ],
                          ],
                        )
                      : Row(
                          children: [
                            _buildStatusBadge(contract.status),
                            if (statusMessage != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                statusMessage,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: statusMsgColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
                // 상세 버튼
                InkWell(
                  onTap: () {
                    context.go('/host/contracts/${contract.id}');
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.description_outlined, size: 16, color: const Color(0xFF2563EB)),
                        if (!isMobile) ...[
                          const SizedBox(width: 6),
                          const Text(
                            '계약 상세',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 방 사진 + 정보 (반응형) ──
            isMobile ? _buildRoomInfoMobile(contract) : _buildRoomInfoDesktop(contract),

            // ── 게스트 메시지 ──
            if (contract.guestMessage != null && contract.guestMessage!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB), // bg-gray-50
                  border: Border.all(color: const Color(0xFFE5E7EB)), // border-gray-200
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '게스트 메시지',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contract.guestMessage!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── 계약 금액 정보 ──
            _buildSimplePricingSection(contract),

            // ── 상태별 액션 버튼 ──
            if (_shouldShowActionButtons(contract.status)) ...[
              const SizedBox(height: 16),
              _buildActionButtons(contract),
            ],
          ],
        ),
      ),
    );
  }

  // 상태 뱃지 위젯 (React getStatusBadge 동일)
  Widget _buildStatusBadge(ContractStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusBgColor(status),
        borderRadius: BorderRadius.circular(9999), // rounded-full
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _getStatusTextColor(status),
        ),
      ),
    );
  }

  // 모바일 방 정보 레이아웃 (세로: 이미지 → 정보)
  Widget _buildRoomInfoMobile(ContractListItem contract) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 전체폭 이미지
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: contract.roomThumbnail != null
              ? Image.network(
                  ContractUtils.getFullImageUrl(contract.roomThumbnail),
                  width: double.infinity,
                  height: 192, // h-48
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 192,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.home, size: 48),
                    );
                  },
                )
              : Container(
                  width: double.infinity,
                  height: 192,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.home, size: 48),
                ),
        ),

        const SizedBox(height: 16),

        // 방 이름
        Text(
          contract.roomName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),

        const SizedBox(height: 12),

        // 주소 (세로 배치)
        const Text(
          '주소',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B5563), // gray-600
          ),
        ),
        const SizedBox(height: 4),
        Text(
          contract.roomAddress,
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),

        const SizedBox(height: 12),

        // 계약 기간 (세로 배치)
        const Text(
          '계약 기간',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: _formatContractPeriod(contract.checkInDate, contract.checkOutDate),
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
              TextSpan(
                text: ' (${contract.totalDays}일)',
                style: const TextStyle(fontSize: 16, color: Color(0xFF4B5563)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 게스트 (세로 배치)
        const Text(
          '게스트',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              contract.partnerDisplayName,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            if ([ContractStatus.approved, ContractStatus.paymentCompleted,
                 ContractStatus.inProgress, ContractStatus.completed]
                .contains(contract.status)) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _handleGoToChat(contract.id),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // 데스크톱 방 정보 레이아웃 (가로: 이미지 | 정보)
  Widget _buildRoomInfoDesktop(ContractListItem contract) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이미지 128x128
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: contract.roomThumbnail != null
              ? Image.network(
                  ContractUtils.getFullImageUrl(contract.roomThumbnail),
                  width: 128,
                  height: 128,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 128,
                      height: 128,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.home, size: 48),
                    );
                  },
                )
              : Container(
                  width: 128,
                  height: 128,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.home, size: 48),
                ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 방 이름
              Text(
                contract.roomName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 8),

              // 주소 (가로: 라벨 80px 고정 | 값)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 80,
                    child: Text(
                      '주소',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      contract.roomAddress,
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 계약 기간 (가로)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 80,
                    child: Text(
                      '계약 기간',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: _formatContractPeriod(contract.checkInDate, contract.checkOutDate),
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                          ),
                          TextSpan(
                            text: ' (${contract.totalDays}일)',
                            style: const TextStyle(fontSize: 16, color: Color(0xFF4B5563)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 게스트 (가로 + 채팅 아이콘)
              Row(
                children: [
                  const SizedBox(
                    width: 80,
                    child: Text(
                      '게스트',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  Text(
                    contract.partnerDisplayName,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  if ([ContractStatus.approved, ContractStatus.paymentCompleted,
                       ContractStatus.inProgress, ContractStatus.completed]
                      .contains(contract.status)) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _handleGoToChat(contract.id),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF2563EB)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 채팅방으로 이동
  void _handleGoToChat(int contractId) {
    // TODO: 실제 API 호출로 대체
    debugPrint('💬 [HOST_CONTRACTS] 채팅방으로 이동: contractId=$contractId');
    context.go('/chat-list?contractId=$contractId');
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
                      '₩${FormatUtils.formatCurrency(contract.cleaningFee ?? 0)}',
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
                  '₩${FormatUtils.formatCurrency(contract.finalTotalAmount)}',
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
                  '₩${FormatUtils.formatCurrency(settlementAmount)}',
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
          '₩${FormatUtils.formatCurrency(amount)}',
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

  // 상태별 액션 버튼 빌드 (React UI 완전 일치)
  Widget _buildActionButtons(ContractListItem contract) {
    final isMobile = ResponsiveUtil.isMobile(context);

    switch (contract.status) {
      case ContractStatus.pendingApproval:
        // React: 승인하기(blue-600) 먼저 + 거절하기(white, border-gray-300) - gap-3
        return Row(
          children: [
            // 승인하기 (React: flex-1 sm:flex-none px-6 py-2.5 bg-blue-600 text-white rounded-lg font-bold)
            Expanded(
              flex: isMobile ? 1 : 0,
              child: ElevatedButton.icon(
                onPressed: () => _handleApprove(contract),
                icon: const Icon(Icons.check, size: 16),
                label: const Text(
                  '승인하기',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24), // py-2.5 px-6
                  backgroundColor: const Color(0xFF2563EB), // bg-blue-600
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // rounded-lg
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12), // gap-3
            // 거절하기 (React: flex-1 sm:flex-none px-6 py-2.5 bg-white border-2 border-gray-300 text-gray-700 rounded-lg font-bold)
            Expanded(
              flex: isMobile ? 1 : 0,
              child: OutlinedButton.icon(
                onPressed: () => _handleReject(contract),
                icon: const Icon(Icons.close, size: 16),
                label: const Text(
                  '거절하기',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF374151), // text-gray-700
                  side: const BorderSide(color: Color(0xFFD1D5DB), width: 2), // border-2 border-gray-300
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );

      case ContractStatus.paymentCompleted:
        // React: 계약 취소 버튼만 (bg-white border-2 border-gray-300 text-gray-700 rounded-lg font-bold text-sm)
        return Row(
          children: [
            OutlinedButton(
              onPressed: () => _handleCancelContract(contract),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // px-4 py-2
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '계약 취소',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: '계약 취소 버튼 클릭 시, 환불 안내를 확인하실 수 있습니다.',
              child: Icon(Icons.info_outline, size: 16, color: const Color(0xFF9CA3AF)),
            ),
          ],
        );

      case ContractStatus.inProgress:
        // React: 퇴실확인(blue-600) + 취소요청(white, border-gray-300) + InfoTooltip
        return Wrap(
          spacing: 8, // gap-2
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // 퇴실 확인 (React: px-4 py-2 bg-blue-600 text-white rounded-lg font-bold text-sm)
            ElevatedButton(
              onPressed: () => _handleCheckoutConfirm(contract),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '퇴실 확인',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            // 취소 요청 (React: px-4 py-2 bg-white border-2 border-gray-300 text-gray-700 rounded-lg font-bold text-sm)
            OutlinedButton(
              onPressed: () => _handleRequestCancellation(contract),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '취소 요청',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            Tooltip(
              message: '취소 요청 버튼 클릭 시, 계약 취소 안내를 확인하실 수 있습니다.',
              child: Icon(Icons.info_outline, size: 16, color: const Color(0xFF9CA3AF)),
            ),
          ],
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
              '기간: ${FormatUtils.formatDate(contract.checkInDate)} ~ ${FormatUtils.formatDate(contract.checkOutDate)}',
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

  // 퇴실 확인 처리 (React handleCheckoutConfirm)
  void _handleCheckoutConfirm(ContractListItem contract) async {
    debugPrint('🟢 [HOST_CONTRACTS] 퇴실 확인 클릭: ${contract.id}');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('퇴실 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('게스트의 퇴실을 확인하시겠습니까?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: const Text(
                '퇴실 처리 후 계약이 종료되며 보증금 환급 절차가 진행됩니다.',
                style: TextStyle(fontSize: 14, color: Color(0xFF1E40AF)),
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
              backgroundColor: const Color(0xFF2563EB),
            ),
            child: const Text('퇴실 확인'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // TODO: API 호출 - PATCH /api/contracts/{contractId}/checkout
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('퇴실이 정상적으로 처리되었습니다. 보증금 환급 절차가 진행됩니다.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          _loadContracts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('퇴실 처리 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
