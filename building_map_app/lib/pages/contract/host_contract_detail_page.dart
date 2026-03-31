import 'package:flutter/material.dart';
import '../../core/exceptions.dart';
import 'package:go_router/go_router.dart';
import '../../models/contract_detail.dart';
import '../../services/contract_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../constants/notice_texts.dart';
import '../../utils/contract_utils.dart';
import '../../widgets/common/responsive_page_layout.dart';
import '../../widgets/common/app_footer.dart';
import '../../widgets/contract/contract_status_banner.dart';
import '../../widgets/contract/contract_common_widgets.dart';
import '../../widgets/contract/checkout_confirmation_widget.dart';
import '../../widgets/contract/host_contract_dialogs.dart' show CheckoutPendingDialog;
import '../../widgets/contract/host_contract_detail_dialogs.dart';
import '../../widgets/contract/host_contract_amount_section.dart';
import '../../widgets/contract/host_deposit_agreement_section.dart';
import '../../widgets/contract/host_contract_basic_info_section.dart';
import '../../widgets/contract/host_contract_action_buttons.dart';
import '../../widgets/contract/host_contract_party_info_section.dart';
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
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '계약 정보를 불러오는데 실패했습니다: $e';
      });
    }
  }

  /// 호스트 퇴실 확인 처리
  Future<void> _handleHostCheckoutConfirm() async {
    final roomId = _contract?.roomId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => HostCheckoutConfirmDialog(
        roomId: roomId,
        onChangePassword: () => context.go('/host/room-registration/$roomId?step=3'),
      ),
    );

    if (confirmed != true) return;

    try {
      await _contractService.confirmHostCheckout(widget.contractId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('퇴실 확인이 완료되었습니다.')),
        );
        _loadContractDetail();
      }
    } on UnauthorizedException {
      if (mounted) context.go('/login');
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
      builder: (_) => const CheckoutPendingDialog(),
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
    } on UnauthorizedException {
      if (mounted) context.go('/login');
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
        builder: (_) => HostPenaltyPaymentConfirmDialog(penaltyAmount: penaltyAmount),
      );

      if (confirmed != true || !mounted) return;

      // 3. 위약금 결제 승인 (PayTag PG)
      // TODO: 실제 PayTag SDK 결제 플로우 연동 후 recvPayparam 전달
      await paymentService.confirmHostPenaltyPayment(
        contractId: widget.contractId,
        recvPayparam: paymentInfo['recvPayparam'] ?? 'mock_key',
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
    } on UnauthorizedException {
      if (mounted) context.go('/login');
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
  Future<void> _handleRequestCheckout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const HostRequestCheckoutDialog(),
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
    } on UnauthorizedException {
      if (mounted) context.go('/login');
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
    } on UnauthorizedException {
      if (mounted) context.go('/login');
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
            initialDeductAmount: _contract!.depositAgreement?.deductAmount,
            initialAgreementText: _contract!.depositAgreement?.agreementText,
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
            Icon(Icons.error_outline, size: 64, color: AppColors.error500),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error500),
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

          HostContractBasicInfoSection(contract: _contract!),
          const SizedBox(height: 24), // mb-6
          HostContractPartyInfoSection(contract: _contract!),
          const SizedBox(height: 24), // mb-6
          HostContractAmountSection(contract: _contract!),

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
          HostContractActionButtons(
            contract: _contract!,
            onCancelByHost: _handleCancelByHost,
            onRequestCheckout: _handleRequestCheckout,
            onRequestCancellation: _handleRequestCancellation,
          ),

          // 보증금 합의 섹션 (HOST_PENDING / AGREEMENT_SUBMITTED)
          HostDepositAgreementSection(
            contract: _contract!,
            onSubmitAgreement: _handleDepositAgreement,
          ),

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
}
