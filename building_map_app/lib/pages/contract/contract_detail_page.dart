import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/contract.dart';
import '../../models/payment_method.dart';
import '../../services/contract_service.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';

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

  // 결제 관련 State
  PaymentMethod? _selectedPaymentMethod;

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
      case ContractStatus.paymentExpired:
        return Colors.grey.shade600;
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

    // 게스트 & 승인된 계약 - 결제 버튼 표시
    final canPay = isGuest && _contract!.status == ContractStatus.approved;

    // 승인 이후 상태에서는 채팅 버튼 표시
    final canChat = _contract!.status == ContractStatus.approved ||
        _contract!.status == ContractStatus.paymentCompleted ||
        _contract!.status == ContractStatus.inProgress ||
        _contract!.status == ContractStatus.completed;

    if (canApprove) {
      return _buildHostActionButtons();
    } else if (canWithdraw) {
      return _buildGuestActionButtons();
    } else if (canPay) {
      return _buildPaymentButton();
    } else if (canChat) {
      return _buildChatButton();
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

    // 채팅 버튼 표시 여부 확인
    final canChat = _contract!.status == ContractStatus.approved ||
        _contract!.status == ContractStatus.paymentCompleted ||
        _contract!.status == ContractStatus.inProgress ||
        _contract!.status == ContractStatus.completed;

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
            crossAxisAlignment: CrossAxisAlignment.start,
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
              // 채팅하기 버튼 (승인 이후 상태에서만 표시)
              if (canChat)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: _navigateToChat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 24),
                          SizedBox(height: 4),
                          Text(
                            '채팅하기',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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

  /// 결제 수단 선택 모달 표시
  Future<void> _showPaymentMethodModal() async {
    final selectedMethod = await showModalBottomSheet<PaymentMethod>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPaymentMethodModal(),
    );

    if (selectedMethod != null && mounted) {
      setState(() => _selectedPaymentMethod = selectedMethod);
      await _processPayment();
    }
  }

  /// 결제 수단 선택 모달 UI
  Widget _buildPaymentMethodModal() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 모달 헤더
              _buildModalHeader(),

              // 결제 수단 리스트 (스크롤 가능)
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: PaymentMethod.values
                      .map((method) => _buildModalPaymentCard(method, setModalState))
                      .toList(),
                ),
              ),

              // 하단 고정 버튼
              _buildModalBottomButton(),
            ],
          ),
        );
      },
    );
  }

  /// 모달 헤더
  Widget _buildModalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '결제 수단 선택',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, size: 28, color: Colors.grey.shade600),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 모달 내 결제 수단 카드
  Widget _buildModalPaymentCard(PaymentMethod method, StateSetter setModalState) {
    final isSelected = _selectedPaymentMethod == method;

    return GestureDetector(
      onTap: () {
        setModalState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // 아이콘 (원형 배경)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                method.icon,
                size: 28,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  /// 모달 하단 고정 버튼
  Widget _buildModalBottomButton() {
    final canPay = _selectedPaymentMethod != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: canPay
                ? () {
                    Navigator.pop(context, _selectedPaymentMethod);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: canPay ? AppColors.primary : Colors.grey.shade300,
              foregroundColor: canPay ? Colors.white : Colors.grey.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: canPay ? 4 : 0,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  canPay ? Icons.payment : Icons.touch_app,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  canPay
                      ? '₩${_currencyFormat.format(_contract!.finalTotalAmount)} 결제하기'
                      : '결제 수단을 선택해주세요',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
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

  /// 결제 버튼 (게스트 & 승인된 계약) - 모달 방식
  Widget _buildPaymentButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -4),
            blurRadius: 12,
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
                onPressed: _showPaymentMethodModal,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payment, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      '₩${_currencyFormat.format(_contract!.finalTotalAmount)} 결제하기',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 채팅 버튼 (승인 이후 상태)
  Widget _buildChatButton() {
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
              child: ElevatedButton.icon(
                onPressed: () => _navigateToChat(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text(
                  '채팅하기',
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

  /// 채팅으로 이동
  void _navigateToChat() {
    if (_contract == null) return;

    // 채팅 목록 페이지로 이동
    // (채팅방은 백엔드 API를 통해 계약 ID로 자동 조회됨)
    Navigator.pushNamed(
      context,
      '/chat-list',
    );
  }

  /// 결제 처리
  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null || _contract == null) return;

    // 결제 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('결제 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('아래 내용으로 결제를 진행하시겠습니까?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildDialogInfoRow('결제 수단', _selectedPaymentMethod!.label),
                  const Divider(height: 16),
                  _buildDialogInfoRow(
                    '결제 금액',
                    '₩${_currencyFormat.format(_contract!.finalTotalAmount)}',
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '결제 후 계약이 확정되며, 취소 시 수수료가 발생할 수 있습니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('결제하기'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // TODO: 토스페이먼츠 API 연동
      // 현재는 UI만 구현된 상태로, 실제 결제 로직은 사업자등록 후 추가 예정

      // 임시 지연 (실제 API 호출 시뮬레이션)
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('결제 기능은 토스페이먼츠 연동 후 활성화됩니다.'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );

      // 실제 구현 시:
      // final paymentResult = await PaymentService.processPayment(
      //   contractId: _contract!.id,
      //   paymentMethod: _selectedPaymentMethod!,
      //   amount: _contract!.finalTotalAmount,
      // );
      //
      // if (paymentResult.success) {
      //   // 계약 정보 새로고침
      //   await _loadContractDetail();
      //
      //   // 성공 다이얼로그 표시
      //   showDialog(...);
      // }

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 다이얼로그 정보 행
  Widget _buildDialogInfoRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            color: Colors.grey.shade900,
          ),
        ),
      ],
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
