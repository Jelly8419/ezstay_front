import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import '../../core/exceptions.dart';
import 'package:go_router/go_router.dart';
import '../../services/payment_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 결제 성공/실패 콜백 페이지
///
/// PayTag 결제 후 리다이렉트되는 페이지입니다.
/// - 성공: /payment/success?contractId=xxx&recvPayparam=xxx&payType=xxx&orderId=xxx&amount=xxx
/// - 실패: /payment/fail?contractId=xxx&code=xxx&message=xxx
class PaymentCallbackPage extends StatefulWidget {
  final bool isSuccess;
  final int? contractId;
  final String? recvPayparam;
  final String? payType;
  final String? orderId;
  final String? amount;
  final String? errorCode;
  final String? errorMessage;

  const PaymentCallbackPage({
    super.key,
    required this.isSuccess,
    this.contractId,
    this.recvPayparam,
    this.payType,
    this.orderId,
    this.amount,
    this.errorCode,
    this.errorMessage,
  });

  @override
  State<PaymentCallbackPage> createState() => _PaymentCallbackPageState();
}

class _PaymentCallbackPageState extends State<PaymentCallbackPage> {
  final PaymentService _paymentService = PaymentService();
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _processPayment();
  }

  Future<void> _processPayment() async {
    if (!widget.isSuccess) {
      // 결제 실패
      setState(() {
        _isProcessing = false;
        _errorMessage = widget.errorMessage ?? '결제가 취소되었습니다.';
      });
      return;
    }

    // 결제 성공 - 백엔드 승인 처리
    try {
      final contractId = widget.contractId;
      final recvPayparam = widget.recvPayparam;
      final orderId = widget.orderId;
      final amount = widget.amount;

      if (contractId == null || recvPayparam == null || orderId == null || amount == null) {
        throw Exception('결제 정보가 올바르지 않습니다.');
      }


      await _paymentService.confirmPayment(
        contractId: contractId,
        recvPayparam: recvPayparam,
        orderId: orderId,
        amount: int.parse(amount),
        payType: widget.payType,
      );

      setState(() {
        _isProcessing = false;
      });

    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      AppLogger.e('❌ [PaymentCallback] 결제 승인 실패: $e');
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isProcessing)
                  _buildProcessingUI()
                else if (_errorMessage != null)
                  _buildErrorUI()
                else
                  _buildSuccessUI(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 처리 중 UI
  Widget _buildProcessingUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: AppColors.primary500),
        const SizedBox(height: 24),
        Text('결제 승인 처리 중...', style: AppTextStyles.bodyLarge),
        const SizedBox(height: 12),
        Text('잠시만 기다려주세요', style: AppTextStyles.bodySmallSecondary),
      ],
    );
  }

  /// 성공 UI
  Widget _buildSuccessUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success500.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            color: AppColors.success500,
            size: 48,
          ),
        ),
        const SizedBox(height: 24),
        Text('결제가 완료되었습니다!', style: AppTextStyles.headingMedium),
        const SizedBox(height: 12),
        Text('계약이 승인되었습니다.', style: AppTextStyles.bodyMediumSecondary),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              context.go('/guest/contracts');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              '계약 목록으로 이동',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 에러 UI
  Widget _buildErrorUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.error500.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.error_outline, color: AppColors.error500, size: 48),
        ),
        const SizedBox(height: 24),
        Text(
          '결제 처리 중 오류가 발생했습니다',
          style: AppTextStyles.headingMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _errorMessage ?? '알 수 없는 오류',
          style: AppTextStyles.bodyMediumSecondary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              context.go('/guest/contracts');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              '계약 목록으로 돌아가기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
