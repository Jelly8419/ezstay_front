import 'package:flutter/material.dart';
import '../../core/exceptions.dart';
import 'package:go_router/go_router.dart';
import '../../models/contract_detail.dart';
import '../../services/contract_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../constants/notice_texts.dart';
import '../../utils/contract_utils.dart';
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
          SnackBar(
            content: const Text('퇴실 확인이 보류되었습니다. 관리자가 확인합니다.'),
            backgroundColor: AppColors.warning500,
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
            content: Text('퇴실 보류 처리 실패: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error600,
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
          SnackBar(
            content: const Text('퇴실 확인이 완료되었습니다.'),
            backgroundColor: AppColors.success500,
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
            backgroundColor: AppColors.error600,
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
          SnackBar(
            content: const Text('취소 요청이 접수되었습니다. 관리자 승인 후 처리됩니다.'),
            backgroundColor: AppColors.warning500,
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
            backgroundColor: AppColors.error600,
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
          SnackBar(
            content: const Text('합의 내용이 제출되었습니다. 게스트 확인을 기다립니다.'),
            backgroundColor: AppColors.success500,
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
            backgroundColor: AppColors.error600,
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
          color: AppColors.gray50,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 896),
                    child: Padding(
                      padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width >= 1024 ? 24 : 16,
                      ),
                      child: _buildBody(),
                    ),
                  ),
                ),
                const AppFooter(),
              ],
            ),
          ),
        ),

        if (_showCancellationModal)
          RequestCancellationModal(
            onClose: () => setState(() => _showCancellationModal = false),
            onConfirm: (reason) => _submitCancellationRequest(reason),
          ),

        if (_showDepositAgreementModal && _contract != null)
          DepositAgreementModal(
            onClose: () => setState(() => _showDepositAgreementModal = false),
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
      return const Center(child: Text('계약 정보가 없습니다.'));
    }

    final contract = _contract!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '계약 상세 정보',
              style: AppTextStyles.headingLarge.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
          ),

          ContractStatusBanner(contract: contract, isHost: true),
          const SizedBox(height: 24),

          HostContractBasicInfoSection(contract: contract),
          const SizedBox(height: 24),
          HostContractPartyInfoSection(contract: contract),
          const SizedBox(height: 24),
          HostContractAmountSection(contract: contract),

          if (ContractUtils.shouldShowCheckoutConfirmation(contract)) ...[
            const SizedBox(height: 24),
            CheckoutConfirmationWidget(
              contract: contract,
              isHost: true,
              onHostConfirm: _handleHostCheckoutConfirm,
              onHostHold: _handleHostCheckoutHold,
            ),
          ],

          HostContractActionButtons(
            contract: contract,
            onRequestCheckout: _handleRequestCheckout,
            onRequestCancellation: _handleRequestCancellation,
          ),

          HostDepositAgreementSection(
            contract: contract,
            onSubmitAgreement: _handleDepositAgreement,
          ),

          const SizedBox(height: 24),
          ContractDetailCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '계약 안내사항',
                  style: AppTextStyles.headingMedium.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 12),
                const NoticeContainer(notices: NoticeTexts.hostContractNotices),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      );
  }
}
