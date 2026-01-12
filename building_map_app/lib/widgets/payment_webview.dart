import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/payment_config.dart';
import '../core/theme/app_colors.dart';

/// 토스페이먼츠 결제 WebView
///
/// 토스 결제창 URL을 WebView로 열고 성공/실패 리다이렉트를 감지합니다.
class PaymentWebView extends StatefulWidget {
  /// 토스 결제창 URL
  final String paymentUrl;

  /// 계약 ID
  final int contractId;

  const PaymentWebView({
    super.key,
    required this.paymentUrl,
    required this.contractId,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            _checkRedirectUrl(url);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            debugPrint('❌ [PaymentWebView] 로드 에러: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  /// 성공/실패 URL 리다이렉트 감지
  void _checkRedirectUrl(String url) {
    debugPrint('🌐 [PaymentWebView] URL 변경: $url');

    // 성공 URL로 리다이렉트됨
    if (url.startsWith(PaymentConfig.successUrl)) {
      final uri = Uri.parse(url);
      final paymentKey = uri.queryParameters['paymentKey'];
      final orderId = uri.queryParameters['orderId'];
      final amount = uri.queryParameters['amount'];

      debugPrint('✅ [PaymentWebView] 결제 성공 감지');
      debugPrint('  - paymentKey: $paymentKey');
      debugPrint('  - orderId: $orderId');
      debugPrint('  - amount: $amount');

      if (paymentKey != null && orderId != null && amount != null) {
        Navigator.of(context).pop({
          'success': true,
          'paymentKey': paymentKey,
          'orderId': orderId,
          'amount': int.parse(amount),
        });
      } else {
        Navigator.of(context).pop({
          'success': false,
          'errorMessage': '결제 정보가 올바르지 않습니다.',
        });
      }
    }
    // 실패 URL로 리다이렉트됨
    else if (url.startsWith(PaymentConfig.failUrl)) {
      final uri = Uri.parse(url);
      final errorCode = uri.queryParameters['code'];
      final errorMessage = uri.queryParameters['message'];

      debugPrint('❌ [PaymentWebView] 결제 실패 감지');
      debugPrint('  - errorCode: $errorCode');
      debugPrint('  - errorMessage: $errorMessage');

      Navigator.of(context).pop({
        'success': false,
        'errorCode': errorCode,
        'errorMessage': errorMessage ?? '결제가 취소되었습니다.',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결제하기'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop({
              'success': false,
              'errorMessage': '사용자가 결제를 취소했습니다.',
            });
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primary500,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '결제창을 불러오는 중...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
