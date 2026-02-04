import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/rental_order_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 렌탈 아이템 추가 결제 콜백 페이지
///
/// 토스페이먼츠 렌탈 결제 후 리다이렉트되는 페이지입니다.
/// - 성공: /rental-payment/success?rentalOrderId=xxx&paymentKey=xxx&orderId=xxx&amount=xxx
/// - 실패: /rental-payment/fail?rentalOrderId=xxx&code=xxx&message=xxx
class RentalPaymentCallbackPage extends StatefulWidget {
  final bool isSuccess;
  final int? rentalOrderId;
  final String? paymentKey;
  final String? orderId;
  final String? amount;
  final String? errorCode;
  final String? errorMessage;

  const RentalPaymentCallbackPage({
    super.key,
    required this.isSuccess,
    this.rentalOrderId,
    this.paymentKey,
    this.orderId,
    this.amount,
    this.errorCode,
    this.errorMessage,
  });

  @override
  State<RentalPaymentCallbackPage> createState() =>
      _RentalPaymentCallbackPageState();
}

class _RentalPaymentCallbackPageState extends State<RentalPaymentCallbackPage> {
  final RentalOrderService _rentalOrderService = RentalOrderService();
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

      // 미결제 주문 취소 시도
      if (widget.rentalOrderId != null) {
        try {
          await _rentalOrderService.cancelPendingOrder(widget.rentalOrderId!);
          debugPrint(
            '🗑️ [RentalPaymentCallback] 미결제 주문 취소: ${widget.rentalOrderId}',
          );
        } catch (e) {
          debugPrint('⚠️ [RentalPaymentCallback] 주문 취소 실패: $e');
        }
      }
      return;
    }

    // 결제 성공 - 백엔드 승인 처리
    try {
      final rentalOrderId = widget.rentalOrderId;
      final paymentKey = widget.paymentKey;
      final orderId = widget.orderId;
      final amount = widget.amount;

      if (rentalOrderId == null ||
          paymentKey == null ||
          orderId == null ||
          amount == null) {
        throw Exception('결제 정보가 올바르지 않습니다.');
      }

      debugPrint('✅ [RentalPaymentCallback] 렌탈 결제 승인 요청');
      debugPrint('  - rentalOrderId: $rentalOrderId');
      debugPrint('  - paymentKey: $paymentKey');
      debugPrint('  - orderId: $orderId');
      debugPrint('  - amount: $amount');

      await _rentalOrderService.confirmPayment(
        rentalOrderId: rentalOrderId,
        paymentKey: paymentKey,
        orderId: orderId,
        amount: int.parse(amount),
      );

      setState(() {
        _isProcessing = false;
      });

      debugPrint('✅ [RentalPaymentCallback] 렌탈 결제 승인 완료');
    } catch (e) {
      debugPrint('❌ [RentalPaymentCallback] 렌탈 결제 승인 실패: $e');
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
        Text('옵션 상품 결제 승인 처리 중...', style: AppTextStyles.bodyLarge),
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
        Text('옵션 상품 결제가 완료되었습니다!', style: AppTextStyles.headingMedium),
        const SizedBox(height: 12),
        Text(
          '추가 주문이 성공적으로 처리되었습니다.',
          style: AppTextStyles.bodyMediumSecondary,
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
