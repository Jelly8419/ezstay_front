import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/contract.dart';
import '../services/contract_service.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';

/// 계약 상세 페이지 (호스트/게스트 공통)
class ContractDetailPage extends StatefulWidget {
  final String contractId;

  const ContractDetailPage({
    super.key,
    required this.contractId,
  });

  @override
  State<ContractDetailPage> createState() => _ContractDetailPageState();
}

class _ContractDetailPageState extends State<ContractDetailPage> {
  final ContractService _contractService = ContractService();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'ko_KR');
  final DateFormat _dateFormat = DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR');
  final DateFormat _dateTimeFormat = DateFormat('yyyy.MM.dd HH:mm', 'ko_KR');

  Contract? _contract;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadContractDetail();
  }

  Future<void> _loadContractDetail() async {
    debugPrint('🔍 [CONTRACT_DETAIL] contractId: ${widget.contractId}');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contractIdInt = int.parse(widget.contractId);
      debugPrint('🔍 [CONTRACT_DETAIL] Parsed contractId: $contractIdInt');

      final contract = await _contractService.getContractDetail(contractIdInt);
      debugPrint('✅ [CONTRACT_DETAIL] Contract loaded: ${contract.id}');

      setState(() {
        _contract = contract;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ [CONTRACT_DETAIL] Error: $e');
      debugPrint('❌ [CONTRACT_DETAIL] StackTrace: $stackTrace');

      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
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
    final bottomBar = _buildBottomBar();

    return Scaffold(
      appBar: AppBar(
        title: const Text('계약 상세'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          // bottomNavigationBar 대신 body 내부에 버튼 배치
          if (bottomBar != null) bottomBar,
        ],
      ),
    );
  }

  Widget? _buildBottomBar() {
    if (_contract == null || _isLoading) return null;

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.id;
    final contractHostId = _contract!.hostId.toString();
    final contractGuestId = _contract!.guestId.toString();

    final isHost = currentUserId == contractHostId;
    final isGuest = currentUserId == contractGuestId;
    final canApprove = isHost && _contract!.status == ContractStatus.pendingApproval;
    final canWithdraw = isGuest && _contract!.status == ContractStatus.pendingApproval;

    if (canApprove) {
      return _buildHostActionButtons();
    } else if (canWithdraw) {
      return _buildGuestActionButtons();
    }
    return null;
  }

  Widget _buildBody() {
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadContractDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_contract == null) {
      return const Center(
        child: Text('계약 정보를 불러올 수 없습니다.'),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상태 배지
              _buildStatusSection(),

              // 방 정보
              _buildRoomSection(),

              // 계약 기간
              _buildPeriodSection(),

              // 금액 정보
              _buildPriceSection(),

              // 렌탈 아이템
              if (_contract!.rentalItems != null && _contract!.rentalItems!.isNotEmpty)
                _buildRentalItemsSection(),

              // 게스트/호스트 정보
              _buildPartiesSection(),

              // 메시지
              _buildMessagesSection(),

              // 특별 요청사항
              if (_contract!.specialRequests != null && _contract!.specialRequests!.isNotEmpty)
                _buildSpecialRequestsSection(),

              // 계약 진행 상태
              _buildTimelineSection(),

              // 디버깅 정보 (임시)
              if (!ApiConfig.isProduction) _buildDebugInfo(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getStatusColor(_contract!.status).withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '계약 상태',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor(_contract!.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _contract!.status.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '계약 ID',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '#${_contract!.id}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSection() {
    if (_contract!.room == null) return const SizedBox.shrink();

    final room = _contract!.room!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '방 정보',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (room.thumbnail != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    room.thumbnail!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.home, size: 50),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.home, size: 50),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      room.address,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${room.area.toStringAsFixed(1)}㎡ · ${room.buildingType}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '계약 기간',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '체크인',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _dateFormat.format(_contract!.checkInDate),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: Colors.grey.shade400,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '체크아웃',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _dateFormat.format(_contract!.checkOutDate),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '총 ${_contract!.totalDays}일${_contract!.totalWeeks != null && _contract!.totalWeeks! > 0 ? " (${_contract!.totalWeeks}주)" : ""}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '금액 정보',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('임대료', _contract!.rentalFee),
          _buildPriceRow('관리비', _contract!.maintenanceFee),
          _buildPriceRow('청소비용', _contract!.cleaningFee),
          if (_contract!.rentalItemsFee > 0)
            _buildPriceRow('렌탈 아이템', _contract!.rentalItemsFee),
          if (_contract!.platformFee > 0)
            _buildPriceRow('플랫폼 수수료', _contract!.platformFee),
          if (_contract!.discountAmount > 0) ...[
            const Divider(height: 24),
            _buildPriceRow(
              '할인',
              -_contract!.discountAmount,
              color: Colors.red,
            ),
            if (_contract!.discountType != null && _contract!.discountType != DiscountType.none)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  '(${_contract!.discountType!.label})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
          const Divider(height: 24),
          _buildPriceRow(
            '소계',
            _contract!.totalUsageFee,
            bold: true,
          ),
          const SizedBox(height: 8),
          _buildPriceRow('보증금', _contract!.deposit),
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '최종 결제 금액',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '₩${_currencyFormat.format(_contract!.finalTotalAmount)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          if (_contract!.installmentMonths > 0) ...[
            const SizedBox(height: 12),
            Text(
              '${_contract!.installmentMonths}개월 할부',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, int amount, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              color: color ?? Colors.grey.shade800,
            ),
          ),
          Text(
            '₩${_currencyFormat.format(amount)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              color: color ?? Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalItemsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '렌탈 아이템',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _contract!.rentalItems.toString(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartiesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '계약 당사자',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (_contract!.host != null) ...[
            _buildPersonInfo('호스트', _contract!.host!),
            const SizedBox(height: 12),
          ],
          if (_contract!.guest != null) ...[
            _buildPersonInfo('게스트', _contract!.guest!),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonInfo(String role, UserInfo user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person,
                size: 18,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.phone,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                user.phone,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          if (user.email != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.email,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  user.email!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessagesSection() {
    if (_contract!.guestMessage == null && _contract!.hostMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '메시지',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (_contract!.guestMessage != null) ...[
            _buildMessageCard('게스트 메시지', _contract!.guestMessage!, Colors.blue),
            const SizedBox(height: 12),
          ],
          if (_contract!.hostMessage != null) ...[
            _buildMessageCard('호스트 메시지', _contract!.hostMessage!, Colors.green),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageCard(String title, String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.message_outlined,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialRequestsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '특별 요청사항',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _contract!.specialRequests.toString(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    final events = <_TimelineEvent>[];

    events.add(_TimelineEvent(
      title: '계약 요청',
      date: _contract!.createdAt,
      icon: Icons.description,
      color: Colors.blue,
    ));

    if (_contract!.approvedAt != null) {
      events.add(_TimelineEvent(
        title: '승인됨',
        date: _contract!.approvedAt!,
        icon: Icons.check_circle,
        color: Colors.green,
      ));
    }

    if (_contract!.rejectedAt != null) {
      events.add(_TimelineEvent(
        title: '거절됨',
        date: _contract!.rejectedAt!,
        icon: Icons.cancel,
        color: Colors.red,
      ));
    }

    if (_contract!.paidAt != null) {
      events.add(_TimelineEvent(
        title: '결제 완료',
        date: _contract!.paidAt!,
        icon: Icons.payment,
        color: Colors.green,
      ));
    }

    if (_contract!.checkedInAt != null) {
      events.add(_TimelineEvent(
        title: '체크인',
        date: _contract!.checkedInAt!,
        icon: Icons.login,
        color: Colors.teal,
      ));
    }

    if (_contract!.checkedOutAt != null) {
      events.add(_TimelineEvent(
        title: '체크아웃',
        date: _contract!.checkedOutAt!,
        icon: Icons.logout,
        color: Colors.grey,
      ));
    }

    if (_contract!.cancelledAt != null) {
      events.add(_TimelineEvent(
        title: '취소',
        date: _contract!.cancelledAt!,
        icon: Icons.close,
        color: Colors.red,
      ));
    }

    if (events.length <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '계약 진행 상태',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          ...events.asMap().entries.map((entry) {
            final isLast = entry.key == events.length - 1;
            return _buildTimelineItem(entry.value, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(_TimelineEvent event, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: event.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: event.color,
                  width: 2,
                ),
              ),
              child: Icon(
                event.icon,
                size: 20,
                color: event.color,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dateTimeFormat.format(event.date),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 승인/거절 버튼
  /// 호스트 액션 버튼 (승인/거절)
  Widget _buildHostActionButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : () => _showRejectDialog(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.red.shade400, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              '거절',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade400,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : () => _approveContract(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
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
                          : const Text(
                              '승인',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 게스트 액션 버튼 (철회)
  Widget _buildGuestActionButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () => _showWithdrawDialog(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
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
                    : const Text(
                        '계약 요청 철회',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 계약 승인
  Future<void> _approveContract() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계약 승인'),
        content: const Text('이 계약을 승인하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('승인'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      await _contractService.approveContract(_contract!.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('계약이 승인되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );

      // 계약 정보 새로고침
      await _loadContractDetail();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// 디버깅 정보 표시 (개발 환경 전용)
  Widget _buildDebugInfo() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.id;
    final contractHostId = _contract?.hostId.toString();
    final contractStatus = _contract?.status;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        border: Border.all(color: Colors.orange, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🐛 디버깅 정보',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('현재 사용자 ID: $currentUserId'),
          Text('계약 호스트 ID: $contractHostId'),
          Text('계약 상태: $contractStatus'),
          Text('일치 여부: ${currentUserId == contractHostId}'),
          Text('버튼 표시 여부: ${currentUserId == contractHostId && contractStatus == ContractStatus.pendingApproval}'),
        ],
      ),
    );
  }

  /// 거절 다이얼로그 표시
  /// 계약 철회 다이얼로그
  Future<void> _showWithdrawDialog() async {
    String? selectedReason;

    final reasons = [
      '더 나은 조건의 방을 찾았어요',
      '입주 계획이 변경되었어요',
      '예산이 맞지 않아요',
      '호스트와 연락이 어려워요',
      '방 상태가 기대와 달라요',
      '기타 사유',
    ];

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('계약 요청 철회'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('철회 사유를 선택해주세요.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('사유를 선택하세요'),
                    value: selectedReason,
                    items: reasons.map((reason) {
                      return DropdownMenuItem<String>(
                        value: reason,
                        child: Text(reason),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '철회 후에는 다시 요청하셔야 합니다.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedReason == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('철회 사유를 선택해주세요.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, selectedReason);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('철회'),
            ),
          ],
        ),
      ),
    );

    if (reason == null) return;

    setState(() => _isProcessing = true);

    try {
      await _contractService.withdrawContract(_contract!.id, reason);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('계약 요청이 철회되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );

      // 계약 정보 새로고침
      await _loadContractDetail();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// 계약 거절 다이얼로그
  Future<void> _showRejectDialog() async {
    final messageController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계약 거절'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('거절 사유를 입력해주세요.'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '거절 사유를 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (messageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('거절 사유를 입력해주세요.'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('거절'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      messageController.dispose();
      return;
    }

    final message = messageController.text.trim();
    messageController.dispose();

    setState(() => _isProcessing = true);

    try {
      await _contractService.rejectContract(_contract!.id, message);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('계약이 거절되었습니다.'),
          backgroundColor: Colors.orange,
        ),
      );

      // 계약 정보 새로고침
      await _loadContractDetail();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

class _TimelineEvent {
  final String title;
  final DateTime date;
  final IconData icon;
  final Color color;

  _TimelineEvent({
    required this.title,
    required this.date,
    required this.icon,
    required this.color,
  });
}
