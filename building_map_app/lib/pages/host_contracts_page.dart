import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart' hide AppColors;
import '../models/contract.dart';
import '../services/contract_service.dart';
import '../core/theme/app_colors.dart';

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
      appBar: AppBar(
        title: const Text('계약 요청 목록'),
        backgroundColor: AppColors.primary600,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 필터
          _buildFilterSection(),

          // 계약 목록
          Expanded(
            child: _buildContractsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final filters = ContractService.getHostStatusFilters();

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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((filter) {
                  final isSelected = _selectedStatus == filter.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter.label),
                      selected: isSelected,
                      onSelected: (_) => _onStatusFilterChanged(filter.value),
                      selectedColor: AppColors.primary600,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
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

    if (_contracts.isEmpty) {
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
            itemCount: _contracts.length,
            itemBuilder: (context, index) {
              final contract = _contracts[index];
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
                          '${contract.roomArea.toStringAsFixed(1)}㎡ · ${contract.buildingType}',
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
                          '게스트: ${contract.partnerName}',
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

              // 결제 금액
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '계약 금액',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₩${_currencyFormat.format(contract.finalTotalAmount)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary600,
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
}
