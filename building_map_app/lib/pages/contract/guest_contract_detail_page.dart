import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/exceptions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../utils/format_utils.dart';
import '../../constants/notice_texts.dart';
import '../../config/payment_config.dart';
import '../../models/contract_detail.dart';
import '../../services/contract_service.dart';
import '../../services/guest_payment_service.dart';
import '../../services/payment_service_web.dart'
    if (dart.library.io) '../../services/payment_service_stub.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/payment_webview.dart';
import '../../widgets/payment_method_modal.dart';
import '../../widgets/common/app_footer.dart';
import '../../utils/contract_utils.dart';
import '../../widgets/contract/contract_status_banner.dart';
import '../../widgets/contract/contract_common_widgets.dart';
import '../../widgets/contract/checkout_confirmation_widget.dart';
import '../../widgets/contract/guest_contract_detail_dialogs.dart';
import '../../widgets/contract/guest_contract_basic_info_section.dart';
import '../../widgets/contract/guest_contract_party_info_section.dart';
import '../../widgets/contract/guest_contract_amount_section.dart';
import '../../widgets/contract/guest_contract_option_section.dart';
import '../../widgets/contract/guest_contract_payment_history_section.dart';

/// 게스트 계약 상세 페이지 (React UI 기반)
class GuestContractDetailPage extends StatefulWidget {
  final int contractId;

  const GuestContractDetailPage({super.key, required this.contractId});

  @override
  State<GuestContractDetailPage> createState() =>
      _GuestContractDetailPageState();
}

class _GuestContractDetailPageState extends State<GuestContractDetailPage> {
  final ContractService _contractService = ContractService();
  final GuestPaymentService _guestPaymentService = GuestPaymentService();

  bool _isLoading = true;
  String? _errorMessage;
  ContractDetail? _contractDetail;

  // 결제 관련
  bool _isPaymentProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadContractDetail();
  }

  /// 계약 상세 정보 로드
  Future<void> _loadContractDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 계약 상세 조회 (rentalOrders.activeItems에서 옵션 상품 완전한 정보 포함)
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

      // rentalOrders.activeItems에서 완전한 정보를 가져오므로 추가 API 호출 불필요
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
      child: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorView()
                : _contractDetail != null
                ? _buildDetailView()
                : const Center(child: Text('데이터를 불러올 수 없습니다.')),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  /// 에러 뷰
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
    // 퇴실 확인 전 경고 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const GuestCheckoutConfirmDialog(),
    );

    if (confirmed != true) return;

    try {
      await _contractService.confirmGuestCheckout(widget.contractId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('퇴실 확인이 완료되었습니다.')));
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

  /// 상세 정보 뷰 (React: max-w-4xl mx-auto px-4 py-6)
  Widget _buildDetailView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 896,
              ), // max-w-4xl = 56rem = 896px
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // React: h2 className="font-bold text-xl text-gray-900 mb-6"
                  Text(
                    '계약 상세 정보',
                    style: AppTextStyles.headingLarge.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray900, // text-gray-900
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 계약 상태 배너
                  ContractStatusBanner(
                    contract: _contractDetail!,
                    isHost: false,
                  ),
                  const SizedBox(height: 24),

                  GuestContractBasicInfoSection(contract: _contractDetail!),
                  const SizedBox(height: 24),

                  GuestContractPartyInfoSection(contract: _contractDetail!),
                  const SizedBox(height: 24),

                  GuestContractAmountSection(contract: _contractDetail!),

                  // 옵션 상품 섹션 (React: 항상 표시, 없으면 "선택한 옵션이 없습니다")
                  const SizedBox(height: 24),
                  GuestContractOptionSection(contract: _contractDetail!),

                  // 퇴실 확인 위젯 (IN_PROGRESS + 퇴실일 도래 시)
                  if (ContractUtils.shouldShowCheckoutConfirmation(_contractDetail)) ...[
                    const SizedBox(height: 24),
                    CheckoutConfirmationWidget(
                      contract: _contractDetail!,
                      isHost: false,
                      onGuestConfirm: _handleGuestCheckoutConfirm,
                    ),
                  ],

                  const SizedBox(height: 24),
                  _buildCancellationPolicySection(),

                  const SizedBox(height: 24),
                  const NoticeContainer(
                    notices: NoticeTexts.guestContractNotices,
                  ),

                  if (_contractDetail!.paymentHistory.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    GuestContractPaymentHistorySection(contract: _contractDetail!),
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





  /// 취소 정책 섹션 (계약 요청 페이지와 동일한 UI)
  Widget _buildCancellationPolicySection() {
    final contract = _contractDetail!;
    final snapshot = contract.refundPolicySnapshot;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // React: 제목 = "환불 규정"
          Text(
            '환불 규정',
            style: AppTextStyles.headingMedium.copyWith(
              fontSize: 18, // text-lg
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827), // text-gray-900
            ),
          ),

          const SizedBox(height: 16),

          const SizedBox(height: 12),

          // React: 환불 규정 상세 내용 (whitespace-pre-wrap)
          // 환불 정책 규칙 표시
          if (snapshot != null && snapshot.rules.isNotEmpty) ...[
            ...snapshot.rules.map((rule) {
              return BulletText(text: NoticeTexts.cancellationText(rule.description, rule.refundRate));
            }),
          ] else ...[
            // Fallback: 기존 상세 설명
            Text(
              contract.refundPolicyDetail.isNotEmpty
                  ? contract.refundPolicyDetail
                  : '환불 정책 정보를 불러올 수 없습니다.',
              style: const TextStyle(
                fontSize: 14, // text-sm
                color: Color(0xFF374151), // text-gray-700
                height: 1.5, // leading-relaxed
              ),
            ),
          ],
        ],
      ),
    );
  }


  /// 하단 고정 바 (게스트 전용 - APPROVED 상태 시 결제 버튼)
  Widget _buildBottomBar() {
    if (_contractDetail == null) return const SizedBox.shrink();

    final contract = _contractDetail!;

    // APPROVED 상태일 때만 결제 버튼 표시
    if (contract.status == 'APPROVED') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isPaymentProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isPaymentProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.payment, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '₩${FormatUtils.formatCurrency(contract.finalTotalAmount)} 결제하기',
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

    return const SizedBox.shrink();
  }

  /// 결제 처리
  Future<void> _processPayment() async {
    if (_contractDetail == null) return;

    setState(() => _isPaymentProcessing = true);

    try {
      // Mock 모드일 경우 백엔드 Mock API 호출
      if (PaymentConfig.useMockMode) {
        await _processPaymentWithMock();
        return;
      }

      // 1. 백엔드에서 결제 정보 조회
      final paymentInfo = await _guestPaymentService.getPaymentInfo(
        widget.contractId,
      );

      // 2. 웹/모바일 구분 처리
      if (kIsWeb) {
        // 웹: PayTag SDK로 결제 (콜백 방식)
        await _processPaymentWeb(paymentInfo);
      } else {
        // 모바일: WebView로 결제창 열기
        await _processPaymentMobile(paymentInfo);
      }
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      AppLogger.e('❌ [GuestContractDetail] 결제 오류: $e');
      _showErrorDialog('결제 중 오류가 발생했습니다.\n${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isPaymentProcessing = false);
      }
    }
  }

  /// 웹에서 결제 처리 (PayTag SDK)
  Future<void> _processPaymentWeb(Map<String, dynamic> paymentInfo) async {
    // 1. 결제수단 선택 모달 표시
    final selectedMethod = await showPaymentMethodModal(
      context,
      totalAmount: paymentInfo['amount'] as int,
    );

    if (selectedMethod == null || !mounted) return; // 취소

    try {
      // 2. 선택된 payType으로 PayTag SDK 호출
      await _guestPaymentService.requestWebPayment(
        contractId: widget.contractId,
        paymentInfo: paymentInfo,
        payType: selectedMethod.value,
      );

      if (mounted) {
        // TODO: 오픈 후 가상계좌 추가 시 입금 안내 다이얼로그 활성화
        _showSuccessDialog('결제가 완료되었습니다!');
        await _loadContractDetail();
      }
    } on PopupBlockedException {
      if (mounted) {
        _showPopupBlockedDialog();
      }
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        _showErrorDialog('결제 실패: ${e.toString()}');
      }
    }
  }

  /// 팝업 차단 안내 다이얼로그
  void _showPopupBlockedDialog() {
    showDialog(
      context: context,
      builder: (context) => const GuestPopupBlockedDialog(),
    );
  }

  /// 모바일에서 결제 처리 (WebView)
  Future<void> _processPaymentMobile(Map<String, dynamic> paymentInfo) async {
    try {
      // TODO: 모바일 PayTag WebView 결제 플로우 구현
      // WebView에서 PayTag SDK를 로드하고 결제 후 결과를 JavaScript 인터페이스로 수신
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => PaymentWebView(
            paymentUrl: paymentInfo['paymentUrl'] as String? ?? '',
            contractId: widget.contractId,
          ),
          fullscreenDialog: true,
        ),
      );

      // 결제 결과 처리
      if (result != null && result['success'] == true) {
        // 결제 성공 - 백엔드 승인 API 호출
        await _confirmPayment(
          recvPayparam: result['recvPayparam'] as String,
          orderId: result['orderId'] as String,
          amount: result['amount'] as int,
          payType: result['payType'] as String?,
        );
      } else {
        // 결제 실패 또는 취소
        final errorMessage =
            result?['errorMessage'] as String? ?? '결제가 취소되었습니다.';
        _showErrorDialog(errorMessage);
      }
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        _showErrorDialog('결제 처리 실패: ${e.toString()}');
      }
    }
  }

  /// Mock 결제 처리
  Future<void> _processPaymentWithMock() async {
    try {
      await _guestPaymentService.processMockPayment(widget.contractId);

      if (mounted) {
        _showSuccessDialog('[Mock] 결제가 완료되었습니다!');
        await _loadContractDetail();
      }
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        _showErrorDialog('[Mock] 결제 실패: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isPaymentProcessing = false);
      }
    }
  }

  /// 결제 승인
  Future<void> _confirmPayment({
    required String recvPayparam,
    required String orderId,
    required int amount,
    String? payType,
  }) async {
    try {
      await _guestPaymentService.confirmMobilePayment(
        contractId: widget.contractId,
        recvPayparam: recvPayparam,
        orderId: orderId,
        amount: amount,
        payType: payType,
      );

      if (mounted) {
        _showSuccessDialog('결제가 완료되었습니다!');
        await _loadContractDetail();
      }
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        _showErrorDialog('결제 승인 실패: ${e.toString()}');
      }
    }
  }

  /// 성공 다이얼로그
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => GuestPaymentSuccessDialog(message: message),
    );
  }

  // TODO: 오픈 후 가상계좌 추가 시 아래 메서드들 주석 해제
  // void _showVbankInfoDialog(Map<String, dynamic> result) { ... }
  // Widget _vbankInfoRow(String label, String value) { ... }
  // String _bankCodeToName(String code) { ... }

  /// 에러 다이얼로그
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => GuestPaymentErrorDialog(message: message),
    );
  }
}
