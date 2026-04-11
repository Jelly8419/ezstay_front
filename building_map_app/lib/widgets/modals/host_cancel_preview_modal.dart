import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/exceptions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/cancel_preview.dart';
import '../../services/contract_service.dart';
import '../../services/payment_service_web.dart'
    if (dart.library.io) '../../services/payment_service_stub.dart';
import '../../utils/format_utils.dart';
import '../contract/refund_row.dart';

/// 호스트 귀책 계약 취소 모달 (PAYMENT_COMPLETED 전용)
///
/// 1. 진입 시 GET /cancel-by-host/preview 호출 → 게스트 결제 내역 + 부담금 표시
/// 2-A. hostBurdenAmount = 0 → "취소하기" → POST (결제 없음)
/// 2-B. hostBurdenAmount > 0 → "결제하고 취소하기" → PayTag PG → POST
class HostCancelPreviewModal extends StatefulWidget {
  final int contractId;
  final VoidCallback onClose;
  final VoidCallback onSuccess;

  const HostCancelPreviewModal({
    super.key,
    required this.contractId,
    required this.onClose,
    required this.onSuccess,
  });

  @override
  State<HostCancelPreviewModal> createState() => _HostCancelPreviewModalState();
}

class _HostCancelPreviewModalState extends State<HostCancelPreviewModal> {
  final ContractService _contractService = ContractService();

  CancelPreviewData? _preview;
  bool _isLoadingPreview = true;
  String? _previewError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() {
      _isLoadingPreview = true;
      _previewError = null;
    });
    try {
      final preview =
          await _contractService.getCancelByHostPreview(widget.contractId);
      if (mounted) {
        setState(() {
          _preview = preview;
          _isLoadingPreview = false;
        });
      }
    } on UnauthorizedException {
      if (mounted) widget.onClose();
    } catch (e) {
      if (mounted) {
        setState(() {
          _previewError = e.toString().replaceAll('Exception: ', '');
          _isLoadingPreview = false;
        });
      }
    }
  }

  Future<void> _handleConfirm() async {
    if (!kIsWeb) {
      _showSnackBar('결제는 현재 웹에서만 지원됩니다.');
      return;
    }

    setState(() => _isSubmitting = true);

    // 1. prepare: orderId, hostBurdenAmount, customerName, customerPhone 확정
    final CancelPaymentInfo paymentInfo;
    try {
      paymentInfo = await _contractService.prepareCancelByHost(widget.contractId);
    } on UnauthorizedException {
      if (mounted) widget.onClose();
      return;
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
      return;
    }

    // 2. 부담금 없으면 PG 생략하고 바로 취소 확정
    if (paymentInfo.hostBurdenAmount == 0) {
      await _confirmCancel();
      return;
    }

    // 3. 부담금 있으면 PG 결제
    await _handlePayAndCancel(paymentInfo);
  }

  Future<void> _confirmCancel({
    String? recvPayparam,
    String? payType,
    String? orderId,
    int? amount,
  }) async {
    try {
      await _contractService.cancelByHost(
        widget.contractId,
        cancellationReason: '',
        recvPayparam: recvPayparam,
        payType: payType,
        orderId: orderId,
        amount: amount,
      );
      if (mounted) {
        widget.onClose();
        widget.onSuccess();
      }
    } on UnauthorizedException {
      if (mounted) widget.onClose();
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _handlePayAndCancel(CancelPaymentInfo paymentInfo) async {
    try {
      final webService = PaymentServiceWeb();
      if (webService.isPopupBlocked()) {
        setState(() => _isSubmitting = false);
        _showSnackBar('팝업이 차단되어 결제창을 열 수 없습니다.\n브라우저 설정에서 팝업 차단을 해제해주세요.');
        return;
      }

      // SDK 호출
      final PayTagResponse response;
      try {
        response = await webService.requestPayment(
          orderId: paymentInfo.orderId,
          amount: paymentInfo.sdkAmount,
          orderName: '계약 취소 부담금',
          payType: 'BC',
          customerName: paymentInfo.customerName,
          customerPhone: paymentInfo.customerPhone,
        ).timeout(
          const Duration(minutes: 10),
          onTimeout: () => throw Exception('결제 시간이 초과되었습니다. 다시 시도해주세요.'),
        );
      } catch (e) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          _showSnackBar(e.toString().replaceAll('Exception: ', ''));
        }
        return;
      }

      if (!response.isSuccess) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          _showSnackBar(
              response.errmsg.isNotEmpty ? response.errmsg : '결제가 취소되었습니다.');
        }
        return;
      }

      // 취소 확정
      await _confirmCancel(
        recvPayparam: response.recvPayparam,
        payType: response.payType ?? 'BC',
        orderId: paymentInfo.orderId,
        amount: paymentInfo.hostBurdenAmount,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error600),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: 540, maxHeight: screenHeight * 0.9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.modal,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            if (_isLoadingPreview)
              _buildLoading()
            else if (_previewError != null)
              _buildError()
            else
              Flexible(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.xl, AppSpacing.md, AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('계약 취소 및 환불 안내', style: AppTextStyles.headingMedium),
          ),
          IconButton(
            onPressed: _isSubmitting ? null : widget.onClose,
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: AppSpacing.paddingXl,
      child: Column(
        children: [
          Text(
            _previewError!,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _loadPreview,
              child: const Text('다시 시도'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final p = _preview!;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 환불 정책 배너
          _buildPolicyBanner(p),
          SizedBox(height: AppSpacing.lg),

          // 임대료 위약금 (호스트 부담)
          RefundRow(
            label: '임대료 ${p.refundRate}%',
            value: '-${FormatUtils.formatCurrency(p.penaltyAmount)}원',
            isWarning: true,
          ),

          // 차감 수수료
          if (p.originalPlatformFee > 0)
            RefundRow(
              label: '수수료',
              value: '-${FormatUtils.formatCurrency(p.originalPlatformFee)}원',
              isWarning: true,
            ),

          SizedBox(height: AppSpacing.lg),

          // 호스트 부담금 강조 박스
          _buildBurdenBox(p),

          SizedBox(height: AppSpacing.lg),

          // 서버 안내 메시지
          if (p.message.isNotEmpty) _buildMessageBox(p.message),

          SizedBox(height: AppSpacing.lg),

          // 액션 버튼
          _buildActions(p),
        ],
      ),
    );
  }

  Widget _buildPolicyBanner(CancelPreviewData p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.policyDisplayName.isNotEmpty)
            Text(
              '환불 정책: ${p.policyDisplayName}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          if (p.applicableRuleDescription.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              p.applicableRuleDescription,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
      ),
    );
  }

  Widget _buildBurdenBox(CancelPreviewData p) {
    final hasBurden = p.hasBurden;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: hasBurden ? AppColors.error50 : AppColors.success50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '호스트 부담금',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: hasBurden ? AppColors.error700 : AppColors.success700,
            ),
          ),
          Text(
            hasBurden
                ? '${FormatUtils.formatCurrency(p.hostBurdenAmount)}원'
                : '없음',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: hasBurden ? AppColors.error700 : AppColors.success700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(CancelPreviewData p) {
    final buttonLabel = p.hasBurden ? '결제하고 취소하기' : '취소하기';

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isSubmitting ? null : widget.onClose,
          child: Text(
            '돌아가기',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  buttonLabel,
                  style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
                ),
        ),
      ],
    );
  }
}
