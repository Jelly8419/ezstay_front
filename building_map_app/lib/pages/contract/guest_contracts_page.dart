import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart' hide AppColors, AppTextStyles;
import '../../models/contract.dart';
import '../../services/contract_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/common/app_gnb.dart';

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
  String _selectedTab = 'in_progress'; // 'in_progress', 'completed', 'cancelled'

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

  void _onTabChanged(String tab) {
    setState(() {
      _selectedTab = tab;
    });
  }

  // 탭별 계약 필터링
  List<ContractListItem> get _filteredContracts {
    if (_selectedTab == 'in_progress') {
      return _allContracts.where((c) => [
        ContractStatus.pendingApproval,
        ContractStatus.approved,
        ContractStatus.paymentCompleted,
        ContractStatus.inProgress,
      ].contains(c.status)).toList();
    } else if (_selectedTab == 'completed') {
      return _allContracts.where((c) => c.status == ContractStatus.completed).toList();
    } else if (_selectedTab == 'cancelled') {
      return _allContracts.where((c) => [
        ContractStatus.rejected,
        ContractStatus.cancelledByGuest,
        ContractStatus.cancelledByHost,
      ].contains(c.status)).toList();
    }
    return _allContracts;
  }

  // 탭별 계약 개수
  int _getTabCount(String tab) {
    if (tab == 'in_progress') {
      return _allContracts.where((c) => [
        ContractStatus.pendingApproval,
        ContractStatus.approved,
        ContractStatus.paymentCompleted,
        ContractStatus.inProgress,
      ].contains(c.status)).length;
    } else if (tab == 'completed') {
      return _allContracts.where((c) => c.status == ContractStatus.completed).length;
    } else if (tab == 'cancelled') {
      return _allContracts.where((c) => [
        ContractStatus.rejected,
        ContractStatus.cancelledByGuest,
        ContractStatus.cancelledByHost,
      ].contains(c.status)).length;
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
                constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
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
          Expanded(
            child: _buildContractsList(),
          ),
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
          _buildTabButton(
            'in_progress',
            '진행중',
            _getTabCount('in_progress'),
          ),
          const SizedBox(width: 8),
          _buildTabButton(
            'completed',
            '지난 계약',
            _getTabCount('completed'),
          ),
          const SizedBox(width: 8),
          _buildTabButton(
            'cancelled',
            '취소',
            _getTabCount('cancelled'),
          ),
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
                    color: isSelected ? Colors.white : const Color(0xFF6B7280), // gray-600
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
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
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
                ..._filteredContracts.map((contract) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildContractCard(contract),
                )),
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
          Icon(
            Icons.home_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '계약 내역이 없습니다.',
            style: TextStyle(
              fontSize: 16,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        style: TextStyle(
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
                        _buildInfoRow('호스트', contract.partnerName),
                        if (showChatButton) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              // TODO: 채팅 페이지로 이동
                              debugPrint('💬 [CHAT] Contract ID: ${contract.id}');
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
                  // TODO: 요청 취소
                  debugPrint('❌ [CANCEL] Contract ID: ${contract.id}');
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFD1D5DB), width: 2), // gray-300
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
                  // TODO: 결제하기
                  debugPrint('💳 [PAYMENT] Contract ID: ${contract.id}');
                },
                icon: const Icon(Icons.credit_card, size: 16),
                label: const Text(
                  '결제하기',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
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
                  onPressed: () {
                    // TODO: 계약 취소
                    debugPrint('❌ [CANCEL_CONTRACT] Contract ID: ${contract.id}');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    // TODO: 취소 요청
                    debugPrint('⚠️ [CANCEL_REQUEST] Contract ID: ${contract.id}');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            style: valueStyle ?? const TextStyle(
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
