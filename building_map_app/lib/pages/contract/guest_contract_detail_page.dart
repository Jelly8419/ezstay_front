import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/exceptions.dart';
import '../../constants/notice_texts.dart';
import '../../models/contract_detail.dart';
import '../../services/contract_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../utils/contract_utils.dart';
import '../../widgets/contract/contract_status_banner.dart';
import '../../widgets/contract/contract_common_widgets.dart';
import '../../widgets/contract/checkout_confirmation_widget.dart';
import '../../widgets/contract/guest_contract_detail_dialogs.dart';
import '../../widgets/contract/guest_contract_basic_info_section.dart';
import '../../widgets/contract/guest_contract_party_info_section.dart';
import '../../widgets/contract/guest_contract_amount_section.dart';
import '../../widgets/contract/guest_contract_option_section.dart';
import '../../widgets/contract/guest_contract_cancellation_section.dart';
import '../../widgets/contract/guest_contract_payment_history_section.dart';
import '../../widgets/common/app_footer.dart';

/// 게스트 계약 상세 페이지
class GuestContractDetailPage extends StatefulWidget {
  final int contractId;

  const GuestContractDetailPage({super.key, required this.contractId});

  @override
  State<GuestContractDetailPage> createState() =>
      _GuestContractDetailPageState();
}

class _GuestContractDetailPageState extends State<GuestContractDetailPage> {
  final ContractService _contractService = ContractService();

  bool _isLoading = true;
  String? _errorMessage;
  ContractDetail? _contractDetail;

  @override
  void initState() {
    super.initState();
    _loadContractDetail();
  }

  Future<void> _loadContractDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await _contractService.getGuestContractDetail(
        widget.contractId,
      );

      if (detail == null) {
        setState(() {
          _errorMessage = '계약 정보를 찾을 수 없습니다.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _contractDetail = detail;
        _isLoading = false;
      });
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.gray50,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _contractDetail != null
          ? _buildDetailView()
          : const Center(child: Text('데이터를 불러올 수 없습니다.')),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error500),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? '오류가 발생했습니다.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadContractDetail,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  /// 게스트 퇴실 확인 처리
  Future<void> _handleGuestCheckoutConfirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const GuestCheckoutConfirmDialog(),
    );

    if (confirmed != true) return;

    try {
      await _contractService.confirmGuestCheckout(widget.contractId);
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
          SnackBar(
            content: Text(
              '퇴실 확인 실패: ${e.toString().replaceAll('Exception: ', '')}',
            ),
          ),
        );
      }
    }
  }

  Widget _buildDetailView() {
    final contract = _contractDetail!;

    return SingleChildScrollView(
      child: Column(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 896),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '계약 상세 정보',
                    style: AppTextStyles.headingMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ContractStatusBanner(contract: contract, isHost: false),
                  const SizedBox(height: 24),

                  GuestContractBasicInfoSection(contract: contract),
                  const SizedBox(height: 24),

                  GuestContractPartyInfoSection(contract: contract),
                  const SizedBox(height: 24),

                  GuestContractAmountSection(contract: contract),
                  const SizedBox(height: 24),

                  GuestContractOptionSection(contract: contract),

                  if (ContractUtils.shouldShowCheckoutConfirmation(contract)) ...[
                    const SizedBox(height: 24),
                    CheckoutConfirmationWidget(
                      contract: contract,
                      isHost: false,
                      onGuestConfirm: _handleGuestCheckoutConfirm,
                    ),
                  ],

                  const SizedBox(height: 24),
                  GuestContractCancellationSection(contract: contract),

                  const SizedBox(height: 24),
                  const NoticeContainer(
                    notices: NoticeTexts.guestContractNotices,
                  ),

                  if (contract.paymentHistory.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    GuestContractPaymentHistorySection(contract: contract),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }
}
