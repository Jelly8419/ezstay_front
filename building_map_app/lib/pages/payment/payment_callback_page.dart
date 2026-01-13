import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/payment_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 결제 성공/실패 콜백 페이지
///
/// 토스페이먼츠 결제 후 리다이렉트되는 페이지입니다.
/// - 성공: /payment/success?paymentKey=xxx&orderId=xxx&amount=xxx
/// - 실패: /payment/fail?code=xxx&message=xxx
class PaymentCallbackPage extends StatefulWidget {
  final bool isSuccess;
  final String? paymentKey;
  final String? orderId;
  final String? amount;
  final String? errorCode;
  final String? errorMessage;

  const PaymentCallbackPage({
    super.key,
    required this.isSuccess,
    this.paymentKey,
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
      final paymentKey = widget.paymentKey;
      final orderId = widget.orderId;
      final amount = widget.amount;

      if (paymentKey == null || orderId == null || amount == null) {
        throw Exception('결제 정보가 올바르지 않습니다.');
      }

      // orderId에서 contractId 추출 (예: "contract_123" -> 123)
      final contractId = _extractContractId(orderId);

      debugPrint('✅ [PaymentCallback] 결제 승인 요청');
      debugPrint('  - contractId: $contractId');
      debugPrint('  - paymentKey: $paymentKey');
      debugPrint('  - orderId: $orderId');
      debugPrint('  - amount: $amount');

      await _paymentService.confirmPayment(
        contractId: contractId,
        paymentKey: paymentKey,
        orderId: orderId,
        amount: int.parse(amount),
      );

      setState(() {
        _isProcessing = false;
      });

      debugPrint('✅ [PaymentCallback] 결제 승인 완료');
    } catch (e) {
      debugPrint('❌ [PaymentCallback] 결제 승인 실패: $e');
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });
    }
  }

  /// orderId에서 contractId 추출
  int _extractContractId(String orderId) {
    // 예: "contract_123_20240113" -> 123
    final parts = orderId.split('_');
    if (parts.length >= 2) {
      return int.parse(parts[1]);
    }
    throw Exception('잘못된 주문 ID 형식: $orderId');
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
