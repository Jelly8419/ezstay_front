// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// KMC 본인인증 결과 수신 페이지
///
/// KMC 인증 완료 후 이 페이지로 apiToken과 certNum이 전달됩니다.
/// 이 페이지는 부모 창(팝업을 연 페이지)으로 postMessage를 보내고
/// 팝업 창을 닫습니다.
///
/// 라우트: /kmc/callback?apiToken=...&certNum=...
class KmcCallbackPage extends StatefulWidget {
  final String? apiToken;
  final String? certNum;

  const KmcCallbackPage({
    super.key,
    this.apiToken,
    this.certNum,
  });

  @override
  State<KmcCallbackPage> createState() => _KmcCallbackPageState();
}

class _KmcCallbackPageState extends State<KmcCallbackPage> {
  @override
  void initState() {
    super.initState();
    // 페이지 로드 후 즉시 부모 창으로 결과 전달
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendResultToParent();
    });
  }

  /// 부모 창으로 KMC 인증 결과를 postMessage로 전달하고 팝업 닫기
  void _sendResultToParent() {
    final apiToken = widget.apiToken ?? '';
    final certNum = widget.certNum ?? '';

    debugPrint('📨 [KMC Callback] 결과 수신 - apiToken: ${apiToken.isNotEmpty ? "있음" : "없음"}, certNum: ${certNum.isNotEmpty ? "있음" : "없음"}');

    try {
      // 부모 창(opener)이 있으면 postMessage로 결과 전달
      js.context.callMethod('eval', ['''
        (function() {
          var apiToken = ${_jsString(apiToken)};
          var certNum = ${_jsString(certNum)};

          if (window.opener) {
            // PC: 팝업에서 부모 창으로 전달
            window.opener.postMessage({
              type: 'KMC_RESULT',
              apiToken: apiToken,
              certNum: certNum
            }, '*');
            window.close();
          } else {
            // 모바일 또는 opener 없는 경우: 리다이렉트
            // Flutter SPA이므로 history 조작
            var baseUrl = window.location.origin;
            window.location.href = baseUrl + '/#/kmc/complete?apiToken='
              + encodeURIComponent(apiToken)
              + '&certNum=' + encodeURIComponent(certNum);
          }
        })();
      ''']);
    } catch (e) {
      debugPrint('❌ [KMC Callback] postMessage 전달 에러: $e');
    }
  }

  /// JavaScript 문자열 이스케이프
  static String _jsString(String value) {
    final escaped = value
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
    return "'$escaped'";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary500),
            const SizedBox(height: 24),
            const Text(
              '본인인증 결과를 처리하고 있습니다...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '잠시만 기다려주세요.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
