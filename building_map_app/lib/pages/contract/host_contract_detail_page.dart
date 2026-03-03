import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/contract_detail.dart';
import '../../services/contract_service.dart';
import '../../constants/app_constants.dart';
import '../../constants/fee_constants.dart';
import '../../constants/notice_texts.dart';
import '../../utils/format_utils.dart';
import '../../utils/contract_utils.dart';
import '../../utils/responsive_util.dart';
import '../../widgets/common/responsive_page_layout.dart';
import '../../widgets/common/app_footer.dart';
import '../../widgets/contract/contract_status_banner.dart';
import '../../widgets/contract/contract_status_badge.dart';
import '../../widgets/contract/contract_common_widgets.dart';
import '../../widgets/contract/checkout_confirmation_widget.dart';
import '../../widgets/modals/host_contract_modals.dart' show DepositAgreementModal, RequestCancellationModal;
import '../../widgets/modals/refund_calculation_modal.dart';
import '../../services/payment_service.dart';

/// 호스트 계약 상세 페이지
class HostContractDetailPage extends StatefulWidget {
  final int contractId;

  const HostContractDetailPage({
    super.key,
    required this.contractId,
  });

  @override
  State<HostContractDetailPage> createState() =>
      _HostContractDetailPageState();
}

class _HostContractDetailPageState extends State<HostContractDetailPage> {
  final ContractService _contractService = ContractService();

  ContractDetail? _contract;
  bool _isLoading = true;
  String? _errorMessage;

  // 모달 상태
  bool _showCancellationModal = false;
  bool _showDepositAgreementModal = false;

  @override
  void initState() {
    super.initState();
    _loadContractDetail();
  }

  /// 계약 상세 정보 로드
  Future<void> _loadContractDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final contract =
          await _contractService.getGuestContractDetail(widget.contractId);

      if (contract != null) {
        setState(() {
          _contract = contract;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = '계약 정보를 불러올 수 없습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '계약 정보를 불러오는데 실패했습니다: $e';
      });
    }
  }

  /// 호스트 수수료 계산 (3.3%)
  int _getHostCommissionFee() {
    if (_contract == null) return 0;
    final baseAmount = _contract!.isEzCleaning
        ? _contract!.rentalFee + _contract!.maintenanceFee
        : _contract!.rentalFee +
            _contract!.maintenanceFee +
            _contract!.cleaningFee;
    return FeeConstants.calculateHostFee(baseAmount);
  }

  /// 실 정산 금액 계산
  int _getActualSettlementAmount() {
    if (_contract == null) return 0;
    final baseAmount = _contract!.isEzCleaning
        ? _contract!.rentalFee + _contract!.maintenanceFee
        : _contract!.rentalFee +
            _contract!.maintenanceFee +
            _contract!.cleaningFee;
    return baseAmount - _getHostCommissionFee();
  }

  /// 호스트 퇴실 확인 처리
  Future<void> _handleHostCheckoutConfirm() async {
    try {
      await _contractService.confirmHostCheckout(widget.contractId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('퇴실 확인이 완료되었습니다.')),
        );
        _loadContractDetail(); // 상태 갱신
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('퇴실 확인 실패: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    }
  }

  /// 호스트 퇴실확인 보류 신청 (정책 7.6.2)
  Future<void> _handleHostCheckoutHold() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _CheckoutPendingDialog(),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      await _contractService.hostCheckoutPending(widget.contractId, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('퇴실 확인이 보류되었습니다. 관리자가 확인합니다.'),
            backgroundColor: Color(0xFFF97316),
          ),
        );
        _loadContractDetail(); // 상태 갱신
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('퇴실 보류 처리 실패: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  /// PAYMENT_COMPLETED 상태에서 호스트 계약 취소
  /// 호스트 귀책 취소: 환불 계산 모달 → 위약금 결제 → 취소 확정
  Future<void> _handleCancelByHost() async {
    if (_contract == null) return;

    final contract = _contract!.toContract();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => RefundCalculationModal(
        contract: contract,
        isHost: true,
        refundPolicySnapshot: _contract!.refundPolicySnapshot,
        onClose: () => Navigator.of(dialogContext).pop(),
        onConfirm: (penaltyAmount) async {
          Navigator.of(dialogContext).pop();

          if (penaltyAmount != null && penaltyAmount > 0) {
            // 위약금이 있는 경우: 호스트 위약금 결제 플로우
            await _processHostPenaltyPayment(penaltyAmount.toInt());
          } else {
            // 위약금이 없는 경우 (무료 취소 기간): 바로 취소
            await _executeCancelByHost('호스트 귀책 취소 (무료 취소 기간)');
          }
        },
      ),
    );
  }

  /// 호스트 위약금 결제 처리
  Future<void> _processHostPenaltyPayment(int penaltyAmount) async {
    final paymentService = PaymentService();

    try {
      // 1. 위약금 결제 정보 조회
      final paymentInfo = await paymentService.getHostPenaltyPaymentInfo(
        widget.contractId,
      );

      if (!mounted) return;

      // 2. 결제 정보 확인 다이얼로그
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('위약금 결제'),
          content: Text(
            '호스트 귀책 취소를 위해 위약금을 결제해야 합니다.\n\n'
            '위약금: ${FormatUtils.formatCurrency(penaltyAmount)}원\n'
            '(임대료 위약금 + 게스트 서비스 수수료)\n\n'
            '결제 후 게스트에게 전액 환불 및 보전 지급이 처리됩니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('결제하기'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      // 3. Mock 결제 승인 (실제 PG 연동 시 교체)
      await paymentService.confirmHostPenaltyPayment(
        contractId: widget.contractId,
        paymentKey: paymentInfo['paymentKey'] ?? 'mock_key',
        orderId: paymentInfo['orderId'] ?? '',
        amount: penaltyAmount,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('위약금 결제 완료. 계약이 취소되었습니다.'),
            backgroundColor: Color(0xFFF97316),
          ),
        );
        _loadContractDetail();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '위약금 결제 실패: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  /// 호스트 취소 실행 (위약금 없는 경우)
  Future<void> _executeCancelByHost(String reason) async {
    try {
      await _contractService.cancelByHost(widget.contractId, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('계약이 취소되었습니다.'),
            backgroundColor: Color(0xFFF97316),
          ),
        );
        _loadContractDetail();
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
  Future<void> _handleRequestCheckout() async {
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
      await _contractService.requestCheckout(widget.contractId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('퇴실 확인이 완료되었습니다.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _loadContractDetail();
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
  void _handleRequestCancellation() {
    setState(() {
      _showCancellationModal = true;
    });
  }

  /// 취소 요청 API 호출
  Future<void> _submitCancellationRequest(String reason) async {
    setState(() {
      _showCancellationModal = false;
    });

    try {
      await _contractService.requestCancellation(widget.contractId, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('취소 요청이 접수되었습니다. 관리자 승인 후 처리됩니다.'),
            backgroundColor: Color(0xFFF97316),
          ),
        );
        _loadContractDetail();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('취소 요청 실패: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  /// 합의 내용 제출 모달 표시
  void _handleDepositAgreement() {
    setState(() {
      _showDepositAgreementModal = true;
    });
  }

  /// 보증금 합의 내용 제출 API 호출
  Future<void> _submitDepositAgreement(int deductAmount, String agreementText) async {
    setState(() {
      _showDepositAgreementModal = false;
    });

    try {
      await _contractService.submitDepositAgreement(
        widget.contractId,
        deductAmount: deductAmount,
        agreementText: agreementText,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('합의 내용이 제출되었습니다. 게스트 확인을 기다립니다.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _loadContractDetail();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('합의 내용 제출 실패: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ColoredBox(
          color: const Color(0xFFF9FAFB), // bg-gray-50
          child: ResponsivePageLayout(
            useCardStyle: false, // 배경색 유지 (각 섹션이 이미 카드)
            maxWidth: 896, // max-w-4xl (React 기준)
            child: _buildBodyWithFooter(),
          ),
        ),

        // 취소 요청 모달
        if (_showCancellationModal)
          RequestCancellationModal(
            onClose: () {
              setState(() {
                _showCancellationModal = false;
              });
            },
            onConfirm: (reason) => _submitCancellationRequest(reason),
          ),

        // 보증금 합의 모달
        if (_showDepositAgreementModal && _contract != null)
          DepositAgreementModal(
            onClose: () {
              setState(() {
                _showDepositAgreementModal = false;
              });
            },
            onConfirm: (deductAmount, agreementText) =>
                _submitDepositAgreement(deductAmount, agreementText),
            depositAmount: _contract!.deposit,
            checkOutDate: DateTime.tryParse(_contract!.checkOutDate) ?? DateTime.now(),
          ),
      ],
    );
  }

  Widget _buildBodyWithFooter() {
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
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadContractDetail,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_contract == null) {
      return const Center(
        child: Text('계약 정보가 없습니다.'),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 페이지 제목
          Padding(
            padding: const EdgeInsets.only(bottom: 16), // mb-4
            child: Text(
              '계약 상세 정보',
              style: const TextStyle(
                fontSize: 20, // text-xl
                fontWeight: FontWeight.w700, // font-bold
                color: Color(0xFF111827), // gray-900
              ),
            ),
          ),

          // 계약 상태 배너
          ContractStatusBanner(
            contract: _contract!,
            isHost: true,
          ),
          const SizedBox(height: 24),

          _buildBasicInfoSection(),
          const SizedBox(height: 24), // mb-6
          _buildPartyInfoSection(),
          const SizedBox(height: 24), // mb-6
          _buildContractAmountSection(),

          // 퇴실 확인 위젯 (IN_PROGRESS + 퇴실일 도래 시)
          if (ContractUtils.shouldShowCheckoutConfirmation(_contract)) ...[
            const SizedBox(height: 24),
            CheckoutConfirmationWidget(
              contract: _contract!,
              isHost: true,
              onHostConfirm: _handleHostCheckoutConfirm,
              onHostHold: _handleHostCheckoutHold,
            ),
          ],

          // 상태별 액션 버튼 섹션
          _buildActionButtonsSection(),

          // 보증금 합의 섹션 (HOST_PENDING / AGREEMENT_SUBMITTED)
          _buildDepositAgreementSection(),

          const SizedBox(height: 24), // mb-6
          ContractDetailCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '계약 안내사항',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                const NoticeContainer(
                  notices: NoticeTexts.hostContractNotices,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const AppFooter(),
        ],
      ),
    );
  }


  /// 상태별 액션 버튼 섹션
  Widget _buildActionButtonsSection() {
    if (_contract == null) return const SizedBox.shrink();

    final status = _contract!.status;
    final checkoutStatus = _contract!.checkoutStatus;

    // PAYMENT_COMPLETED: 계약 취소 버튼
    if (status == 'PAYMENT_COMPLETED') {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _handleCancelByHost,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
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
      );
    }

    // IN_PROGRESS + NOT_STARTED: 퇴실 확인 (퇴실 시간 도래 또는 퇴실 요청됨) + 취소 요청
    if (status == 'IN_PROGRESS' &&
        (checkoutStatus == null || checkoutStatus == 'NOT_STARTED')) {
      // 퇴실 시간 도래 여부 판단
      final now = DateTime.now();
      final checkOutDate = DateTime.tryParse(_contract!.checkOutDate);
      final checkoutTimeStr = _contract!.roomCheckoutTime ?? '11:00';
      final timeParts = checkoutTimeStr.split(':');
      final checkoutHour = int.tryParse(timeParts[0]) ?? 11;
      final checkoutMinute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;

      bool isCheckoutTimeReached = false;
      if (checkOutDate != null) {
        final checkoutDateTime = DateTime(
          checkOutDate.year, checkOutDate.month, checkOutDate.day,
          checkoutHour, checkoutMinute,
        );
        isCheckoutTimeReached = now.isAfter(checkoutDateTime);
      }
      final isCheckoutRequested = _contract!.checkoutRequestedAt != null;
      final shouldShowCheckoutButton = isCheckoutTimeReached || isCheckoutRequested;

      if (shouldShowCheckoutButton) {
        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleRequestCheckout,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _handleRequestCancellation,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '취소 요청',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // 퇴실 시간 미도래 & 퇴실 요청 없음: 취소 요청만 표시
        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _handleRequestCancellation,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFDC2626)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '취소 요청',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }

  /// 보증금 합의 섹션 (HOST_PENDING / AGREEMENT_SUBMITTED)
  Widget _buildDepositAgreementSection() {
    if (_contract == null) return const SizedBox.shrink();

    final status = _contract!.status;
    final checkoutStatus = _contract!.checkoutStatus;

    // HOST_PENDING: 합의 내용 제출 안내 + 데드라인 카운트다운 + 버튼
    if (status == 'IN_PROGRESS' && checkoutStatus == 'HOST_PENDING') {
      // 데드라인 계산 (정책 7.9.1): 관리자 보류 승인 시점 + 10일
      // holdApprovedAt이 없으면 퇴실일 + 10일로 폴백 (서버 미지원 시)
      final agreement = _contract!.depositAgreement;
      DateTime? deadline = agreement?.agreementDeadline;
      if (deadline == null) {
        final checkOutDate = DateTime.tryParse(_contract!.checkOutDate);
        if (checkOutDate != null) {
          deadline = checkOutDate.add(const Duration(days: 10));
        }
      }

      final now = DateTime.now();
      final isExpired = deadline != null && now.isAfter(deadline);
      final daysRemaining = deadline != null
          ? deadline.difference(now).inDays
          : null;

      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFED7AA)), // orange-200
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '보증금 합의',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED), // orange-50
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ 퇴실 확인이 보류되었습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9A3412),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '게스트와 합의가 되었다면 합의 내용을 제출해주세요.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF9A3412)),
                    ),
                    if (daysRemaining != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        isExpired
                            ? '⏰ 제출 기한이 만료되었습니다. 보증금이 게스트에게 전액 반환됩니다.'
                            : '⏰ 제출 기한: $daysRemaining일 남음',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isExpired
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFF97316),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isExpired ? null : _handleDepositAgreement,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD1D5DB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '합의 내용 제출',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // AGREEMENT_SUBMITTED: 제출 완료 + 합의 내용 표시
    if (status == 'IN_PROGRESS' && checkoutStatus == 'AGREEMENT_SUBMITTED') {
      final agreement = _contract!.depositAgreement;
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)), // blue-200
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '보증금 합의',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF), // blue-50
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
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '게스트 확인을 기다리고 있습니다.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF)),
                    ),
                  ],
                ),
              ),
              if (agreement != null) ...[
                const SizedBox(height: 16),
                _buildAgreementDetailRow(
                  '보증금 차감 금액',
                  '${FormatUtils.formatCurrency(agreement.deductAmount)}원',
                ),
                const SizedBox(height: 8),
                _buildAgreementDetailRow(
                  '환급 예정 금액',
                  '${FormatUtils.formatCurrency((_contract!.deposit) - agreement.deductAmount)}원',
                ),
                const SizedBox(height: 8),
                const Text(
                  '합의 내용',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    agreement.agreementText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                if (agreement.submittedAt != null) ...[
                  const SizedBox(height: 8),
                  _buildAgreementDetailRow(
                    '제출 시각',
                    DateTime.tryParse(agreement.submittedAt!) != null
                        ? FormatUtils.formatDateTime(DateTime.parse(agreement.submittedAt!))
                        : agreement.submittedAt!,
                  ),
                ],
              ],
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// 합의 상세 정보 행
  Widget _buildAgreementDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  /// 기본 정보 섹션
  Widget _buildBasicInfoSection() {
    final isMobile = ResponsiveUtil.isMobile(context);

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(color: const Color(0xFFE5E7EB)), // gray-200 테두리 추가
        boxShadow: ContractDetailCard.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 제목 + 상태 배지 (flex justify-between)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "기본 정보" 제목 (text-lg = 18px)
                  const Text(
                    '기본 정보',
                    style: TextStyle(
                      fontSize: 18, // text-lg
                      fontWeight: FontWeight.w700, // font-bold
                      color: Color(0xFF111827), // gray-900
                    ),
                  ),
                  // 계약 번호 (승인된 경우만 표시)
                  if (_contract!.orderId != null) ...[
                    const SizedBox(height: 8), // mt-2
                    Row(
                      children: [
                        const Text(
                          '계약번호: ',
                          style: TextStyle(
                            fontSize: 14, // text-sm
                            color: Color(0xFF4B5563), // gray-600
                          ),
                        ),
                        Text(
                          _contract!.orderId!,
                          style: const TextStyle(
                            fontSize: 14, // text-sm
                            fontWeight: FontWeight.w700, // font-bold
                            color: Color(0xFF2563EB), // blue-600
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              // 상태 배지
              ContractStatusBadge(status: _contract!.status, showIcon: false),
            ],
          ),
          const SizedBox(height: 16),

          // 방 정보 (반응형 레이아웃)
          if (isMobile) ...[
            // 모바일: 세로 레이아웃
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 방 이미지 (전체 너비)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                  child: _contract!.roomPhoto.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: ContractUtils.getFullImageUrl(_contract!.roomPhoto),
                          width: double.infinity,
                          height: 192, // h-48
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: double.infinity,
                            height: 192,
                            color: AppColors.grey50,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: double.infinity,
                            height: 192,
                            color: AppColors.grey50,
                            child: Icon(Icons.image_not_supported,
                                color: AppColors.textHint),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          height: 192,
                          color: AppColors.grey50,
                          child: Icon(Icons.home,
                              size: 40, color: AppColors.textHint),
                        ),
                ),
                const SizedBox(height: 12),
                // 방 정보 텍스트
                _buildRoomInfo(),
              ],
            ),
          ] else ...[
            // 데스크톱: 가로 레이아웃
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 방 이미지 (고정 크기)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                  child: _contract!.roomPhoto.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: ContractUtils.getFullImageUrl(_contract!.roomPhoto),
                          width: 128, // lg:w-32
                          height: 128, // lg:h-32
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 128,
                            height: 128,
                            color: AppColors.grey50,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 128,
                            height: 128,
                            color: AppColors.grey50,
                            child: Icon(Icons.image_not_supported,
                                color: AppColors.textHint),
                          ),
                        )
                      : Container(
                          width: 128,
                          height: 128,
                          color: AppColors.grey50,
                          child: Icon(Icons.home,
                              size: 40, color: AppColors.textHint),
                        ),
                ),
                const SizedBox(width: 16),
                // 방 정보 텍스트
                Expanded(child: _buildRoomInfo()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 당사자 정보 섹션
  Widget _buildPartyInfoSection() {
    final isMobile = ResponsiveUtil.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          _buildHostCard(),
          const SizedBox(height: 16),
          _buildGuestCard(),
        ],
      );
    } else {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildHostCard()),
            const SizedBox(width: 16),
            Expanded(child: _buildGuestCard()),
          ],
        ),
      );
    }
  }

  /// 호스트 카드
  Widget _buildHostCard() {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(color: const Color(0xFFE5E7EB)), // gray-200 테두리
        boxShadow: ContractDetailCard.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '호스트 정보',
            style: TextStyle(
              fontSize: 16, // text-base
              fontWeight: FontWeight.w700, // font-bold
              color: Color(0xFF111827), // gray-900
            ),
          ),
          const SizedBox(height: 16), // mb-4

          // space-y-3
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아바타 + 이름
              Row(
                children: [
                  // 아바타 (w-12 h-12)
                  Container(
                    width: 48, // w-12
                    height: 48, // h-12
                    decoration: const BoxDecoration(
                      color: Color(0xFFDBEAFE), // blue-100
                      shape: BoxShape.circle,
                    ),
                    child: _contract!.hostProfileImage != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: ContractUtils.getFullImageUrl(_contract!.hostProfileImage!),
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.person, color: Color(0xFF2563EB)), // blue-600
                            ),
                          )
                        : const Icon(Icons.person, color: Color(0xFF2563EB)), // blue-600
                  ),
                  const SizedBox(width: 12), // gap-3
                  // 이름 영역
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '이름',
                          style: TextStyle(
                            fontSize: 14, // text-sm
                            color: Color(0xFF4B5563), // gray-600
                          ),
                        ),
                        Text(
                          _contract!.hostName,
                          style: const TextStyle(
                            fontSize: 14, // text-sm
                            fontWeight: FontWeight.w700, // font-bold
                            color: Color(0xFF111827), // gray-900
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12), // space-y-3

              // 연락처 (pl-15)
              Padding(
                padding: const EdgeInsets.only(left: 60), // pl-15 (15 * 4 = 60px)
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '연락처',
                      style: TextStyle(
                        fontSize: 14, // text-sm
                        color: Color(0xFF4B5563), // gray-600
                      ),
                    ),
                    // 호스트는 자신의 전화번호를 항상 볼 수 있음
                    if (_contract!.hostPhoneNumber != null)
                      Text(
                        _contract!.hostPhoneNumber!,
                        style: const TextStyle(
                          fontSize: 14, // text-sm
                          fontWeight: FontWeight.w700, // font-bold
                          color: Color(0xFF111827), // gray-900
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

  /// 게스트 카드
  Widget _buildGuestCard() {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(color: const Color(0xFFE5E7EB)), // gray-200 테두리
        boxShadow: ContractDetailCard.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '게스트 정보',
            style: TextStyle(
              fontSize: 16, // text-base
              fontWeight: FontWeight.w700, // font-bold
              color: Color(0xFF111827), // gray-900
            ),
          ),
          const SizedBox(height: 16), // mb-4

          // space-y-3
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아바타 + 이름
              Row(
                children: [
                  // 아바타 (w-12 h-12)
                  Container(
                    width: 48, // w-12
                    height: 48, // h-12
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7), // green-100
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Color(0xFF16A34A)), // green-600
                  ),
                  const SizedBox(width: 12), // gap-3
                  // 이름 영역
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '이름',
                          style: TextStyle(
                            fontSize: 14, // text-sm
                            color: Color(0xFF4B5563), // gray-600
                          ),
                        ),
                        Text(
                          _contract!.guestName,
                          style: const TextStyle(
                            fontSize: 14, // text-sm
                            fontWeight: FontWeight.w700, // font-bold
                            color: Color(0xFF111827), // gray-900
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12), // space-y-3

              // 연락처 (pl-15)
              Padding(
                padding: const EdgeInsets.only(left: 60), // pl-15 (15 * 4 = 60px)
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '연락처',
                      style: TextStyle(
                        fontSize: 14, // text-sm
                        color: Color(0xFF4B5563), // gray-600
                      ),
                    ),
                    // 전화번호는 결제 완료 후 상태에서만 표시
                    Text(
                      ContractUtils.shouldShowPhoneNumber(_contract!.status)
                          ? _contract!.guestPhone
                          : '결제 완료 후 확인 가능',
                      style: TextStyle(
                        fontSize: 14, // text-sm
                        fontWeight: FontWeight.w700, // font-bold
                        color: ContractUtils.shouldShowPhoneNumber(_contract!.status)
                            ? const Color(0xFF111827) // gray-900
                            : const Color(0xFF111827), // gray-900
                      ),
                    ),
                  ],
                ),
              ),

              // 게스트 메시지 (있을 경우 회색 박스로 표시)
              if (_contract!.guestMessage != null &&
                  _contract!.guestMessage!.isNotEmpty) ...[
                const SizedBox(height: 12), // mt-3
                Container(
                  padding: const EdgeInsets.all(12), // p-3 = 12px
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB), // gray-50
                    borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                    border: Border.all(color: const Color(0xFFE5E7EB)), // gray-200
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.message_outlined,
                          size: 16, color: Color(0xFF4B5563)), // gray-600, w-4 h-4
                      const SizedBox(width: 8), // gap-2
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '게스트 메시지',
                              style: TextStyle(
                                fontSize: 12, // text-xs
                                fontWeight: FontWeight.w700, // font-bold
                                color: Color(0xFF374151), // gray-700
                              ),
                            ),
                            const SizedBox(height: 4), // mb-1
                            Text(
                              _contract!.guestMessage!,
                              style: const TextStyle(
                                fontSize: 14, // text-sm
                                color: Color(0xFF1F2937), // gray-800
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 계약 금액 섹션 (호스트 특화)
  Widget _buildContractAmountSection() {
    final commissionFee = _getHostCommissionFee();
    final settlementAmount = _getActualSettlementAmount();
    final totalContractAmount = _contract!.rentalFee +
        _contract!.maintenanceFee +
        _contract!.cleaningFee +
        _contract!.deposit;

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(color: const Color(0xFFE5E7EB)), // gray-200 테두리
        boxShadow: ContractDetailCard.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 (text-lg = 18px)
          Text(
            '계약 금액',
            style: const TextStyle(
              fontSize: 18, // text-lg
              fontWeight: FontWeight.w700, // font-bold
              color: Color(0xFF111827), // gray-900
            ),
          ),
          const SizedBox(height: 16),

          // Gray-50 배경 박스로 모든 금액 정보 감싸기
          Container(
            padding: const EdgeInsets.all(16), // p-4
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB), // gray-50
              borderRadius: BorderRadius.circular(AppRadius.radiusSm),
              border: Border.all(color: const Color(0xFFE5E7EB)), // gray-200
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이용 금액 서브타이틀
                const Text(
                  '이용 금액',
                  style: TextStyle(
                    fontSize: 14, // text-sm
                    fontWeight: FontWeight.w700, // font-bold
                    color: Color(0xFF111827), // gray-900
                  ),
                ),
                const SizedBox(height: 8), // mb-2

                // 세부 금액들 (pl-3 indented)
                Padding(
                  padding: const EdgeInsets.only(left: 12), // pl-3
                  child: Column(
                    children: [
                      // 렌탈료
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '임대료',
                            style: TextStyle(
                              fontSize: 14, // text-sm
                              color: Color(0xFF374151), // gray-700
                            ),
                          ),
                          Text(
                            FormatUtils.formatKRW(_contract!.rentalFee),
                            style: const TextStyle(
                              fontSize: 14, // text-sm
                              fontWeight: FontWeight.w700, // font-bold
                              color: Color(0xFF111827), // gray-900
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 관리비
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '관리비',
                            style: TextStyle(
                              fontSize: 14, // text-sm
                              color: Color(0xFF374151), // gray-700
                            ),
                          ),
                          Text(
                            FormatUtils.formatKRW(_contract!.maintenanceFee),
                            style: const TextStyle(
                              fontSize: 14, // text-sm
                              fontWeight: FontWeight.w700, // font-bold
                              color: Color(0xFF111827), // gray-900
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 청소비 또는 EZ 청소 서비스 배지
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '청소비',
                                style: TextStyle(
                                  fontSize: 14, // text-sm
                                  color: Color(0xFF374151), // gray-700
                                ),
                              ),
                              if (_contract!.isEzCleaning) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB), // blue-600
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'EZ서비스',
                                    style: TextStyle(
                                      fontSize: 12, // text-xs
                                      fontWeight: FontWeight.w700, // font-bold
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            FormatUtils.formatKRW(_contract!.cleaningFee),
                            style: const TextStyle(
                              fontSize: 14, // text-sm
                              fontWeight: FontWeight.w700, // font-bold
                              color: Color(0xFF111827), // gray-900
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 보증금 (게스트 퇴실 후 환급)
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Text(
                            '보증금 ',
                            style: TextStyle(
                              fontSize: 14, // text-sm
                              fontWeight: FontWeight.w700, // font-bold
                              color: Color(0xFF111827), // gray-900
                            ),
                          ),
                          Text(
                            '(게스트 퇴실 후 환급)',
                            style: TextStyle(
                              fontSize: 12, // text-xs
                              fontWeight: FontWeight.w400, // font-normal
                              color: Color(0xFF6B7280), // gray-500
                            ),
                          ),
                        ],
                      ),
                      Text(
                        FormatUtils.formatKRW(_contract!.deposit),
                        style: const TextStyle(
                          fontSize: 14, // text-sm
                          fontWeight: FontWeight.w700, // font-bold
                          color: Color(0xFF111827), // gray-900
                        ),
                      ),
                    ],
                  ),
                ),

                // 총 계약 금액
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFD1D5DB), width: 2), // border-t-2 gray-300
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '총 계약 금액',
                        style: TextStyle(
                          fontSize: 14, // text-sm
                          fontWeight: FontWeight.w700, // font-bold
                          color: Color(0xFF111827), // gray-900
                        ),
                      ),
                      Text(
                        FormatUtils.formatKRW(totalContractAmount),
                        style: const TextStyle(
                          fontSize: 18, // text-lg
                          fontWeight: FontWeight.w700, // font-bold
                          color: Color(0xFF111827), // gray-900
                        ),
                      ),
                    ],
                  ),
                ),

                // 호스트 계약수수료
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '호스트 계약수수료',
                        style: TextStyle(
                          fontSize: 14, // text-sm
                          color: Color(0xFF000000), // rgb(0,0,0)
                        ),
                      ),
                      Text(
                        '- ${FormatUtils.formatKRW(commissionFee)}',
                        style: const TextStyle(
                          fontSize: 16, // text-[16px]
                          fontWeight: FontWeight.w700, // font-bold
                          color: Color(0xFF000000), // rgb(0,0,0)
                        ),
                      ),
                    ],
                  ),
                ),

                // 정산 예정금액 (no space!)
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '정산 예정금액',
                        style: TextStyle(
                          fontSize: 14, // text-sm
                          fontWeight: FontWeight.w700, // font-bold
                          color: Color(0xFF2563EB), // blue-600
                        ),
                      ),
                      Text(
                        FormatUtils.formatKRW(settlementAmount),
                        style: const TextStyle(
                          fontSize: 18, // text-lg
                          fontWeight: FontWeight.w700, // font-bold
                          color: Color(0xFF2563EB), // blue-600
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  /// 방 정보 (이름, 주소, 계약 기간, 계약 확정)
  Widget _buildRoomInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 방 이름 (text-lg font-bold text-gray-900)
        Text(
          _contract!.roomName,
          style: const TextStyle(
            fontSize: 18, // text-lg
            fontWeight: FontWeight.w700, // font-bold
            color: Color(0xFF111827), // gray-900
          ),
        ),
        const SizedBox(height: 12), // mb-3

        // space-y-2 text-sm 섹션
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 주소 (라벨 포함)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '주소 : ',
                  style: TextStyle(
                    fontSize: 14, // text-sm
                    color: Color(0xFF374151), // gray-700
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14, // text-sm
                        color: Color(0xFF000000), // rgb(0,0,0)
                      ),
                      children: [
                        TextSpan(text: _contract!.address),
                        const TextSpan(text: ' '),
                        TextSpan(text: _contract!.detailAddress),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8), // space-y-2

            // 계약 기간 (inline 텍스트)
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14, // text-sm
                  color: Color(0xFF374151), // gray-700
                ),
                children: [
                  const TextSpan(text: '계약 기간: '),
                  TextSpan(
                    text: '${ContractUtils.formatDateString(_contract!.checkInDate)} - ${ContractUtils.formatDateString(_contract!.checkOutDate)} (${_contract!.totalDays}일)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700, // font-bold
                      color: Color(0xFF111827), // gray-900
                    ),
                  ),
                ],
              ),
            ),

            // 계약 확정 (결제 완료 후 상태에서만 표시)
            if (_contract!.paidAt != null &&
                ['PAYMENT_COMPLETED', 'IN_PROGRESS', 'COMPLETED']
                    .contains(_contract!.status)) ...[
              const SizedBox(height: 8), // space-y-2
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14, // text-sm
                    color: Color(0xFF374151), // gray-700
                  ),
                  children: [
                    const TextSpan(text: '계약 확정: '),
                    TextSpan(
                      text: ContractUtils.formatDateString(_contract!.paidAt!),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700, // font-bold
                        color: Color(0xFF374151), // gray-700
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

}

/// 퇴실 확인 보류 사유 입력 다이얼로그 (정책 7.6.2)
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
        constraints: const BoxConstraints(maxWidth: 448),
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
                      backgroundColor: const Color(0xFFF97316),
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
