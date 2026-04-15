import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/theme/app_colors.dart';

/// PayTag 결제 WebView
///
/// PayTag 결제창 URL을 WebView로 열고 결제 결과를 JavaScript 인터페이스로 수신합니다.
/// PayTag SDK의 Tag.requestPay 콜백 결과를 Flutter로 전달합니다.
class PaymentWebView extends StatefulWidget {
  /// PayTag 결제창 URL
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
      ..addJavaScriptChannel(
        'PayTagResult',
        onMessageReceived: (JavaScriptMessage message) {
          _handlePayTagResult(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            AppLogger.e('❌ [PaymentWebView] 로드 에러: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  /// PayTag SDK 결과 처리 (JavaScript → Flutter)
  void _handlePayTagResult(String message) {

    try {
      // JSON 파싱하여 결과 처리
      // JavaScript에서 PayTagResult.postMessage(JSON.stringify({...})) 호출
      final parts = message.split('|');

      if (parts.length >= 2 && parts[0] == 'SUCCESS') {
        // SUCCESS|recvPayparam|payType|orderId|amount
        Navigator.of(context).pop({
          'success': true,
          'recvPayparam': parts.length > 1 ? parts[1] : '',
          'payType': parts.length > 2 ? parts[2] : 'CARD',
          'orderId': parts.length > 3 ? parts[3] : '',
          'amount': parts.length > 4 ? int.tryParse(parts[4]) ?? 0 : 0,
        });
      } else if (parts[0] == 'FAIL') {
        // FAIL|errorMessage
        Navigator.of(context).pop({
          'success': false,
          'errorMessage': parts.length > 1 ? parts[1] : '결제가 실패했습니다.',
        });
      } else if (parts[0] == 'CANCEL') {
        Navigator.of(context).pop({
          'success': false,
          'errorMessage': '사용자가 결제를 취소했습니다.',
        });
      }
    } catch (e) {
      AppLogger.e('❌ [PaymentWebView] 결과 파싱 실패: $e');
      Navigator.of(context).pop({
        'success': false,
        'errorMessage': '결제 결과 처리 중 오류가 발생했습니다.',
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
                        color: AppColors.textPrimary,
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
