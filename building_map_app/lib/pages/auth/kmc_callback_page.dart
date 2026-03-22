// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// KMC 본인인증 결과 수신 페이지
///
/// KMC 인증 완료 후 백엔드가 이 페이지로 리다이렉트합니다.
/// apiToken과 certNum을 부모 창으로 전달하고 팝업을 닫습니다.
///
/// 전달 방식 (우선순위):
/// 1. window.opener.postMessage - 팝업 → 부모 창 직접 전달
/// 2. BroadcastChannel - 백엔드 리다이렉트로 opener가 끊어진 경우
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendResultToParent();
    });
  }

  /// 부모 창으로 KMC 인증 결과 전달 후 팝업 닫기
  void _sendResultToParent() {
    final apiToken = widget.apiToken ?? '';
    final certNum = widget.certNum ?? '';

    debugPrint(
        '📨 [KMC Callback] 결과 수신 - apiToken: ${apiToken.isNotEmpty ? "있음" : "없음"}, certNum: ${certNum.isNotEmpty ? "있음" : "없음"}');

    try {
      js.context.callMethod('eval', [
        '''
        (function() {
          var apiToken = ${_jsString(apiToken)};
          var certNum = ${_jsString(certNum)};
          var result = {
            type: 'KMC_RESULT',
            apiToken: apiToken,
            certNum: certNum
          };

          console.log('[KMC Callback] 결과 전달 시작 - apiToken:', apiToken ? '있음' : '없음', ', certNum:', certNum ? '있음' : '없음');

          // 1차: window.opener로 직접 전달
          if (window.opener && !window.opener.closed) {
            try {
              window.opener.postMessage(result, '*');
              console.log('[KMC Callback] opener.postMessage 전송 성공');
            } catch(e) {
              console.log('[KMC Callback] opener.postMessage 실패:', e);
            }
          } else {
            console.log('[KMC Callback] opener 없음 또는 닫힘');
          }

          // 2차: BroadcastChannel로 항상 전달 (opener가 있어도 cross-origin일 수 있음)
          try {
            var bc = new BroadcastChannel('kmc_auth');
            bc.postMessage(result);
            console.log('[KMC Callback] BroadcastChannel 전송 성공');
            setTimeout(function() { bc.close(); }, 1000);
          } catch(e) {
            console.log('[KMC Callback] BroadcastChannel 실패:', e);
          }

          // 팝업 닫기 비활성화 (디버깅용 - 콘솔 로그 확인 후 복원)
          // setTimeout(function() {
          //   window.close();
          // }, 1500);
        })();
      '''
      ]);
    } catch (e) {
      debugPrint('❌ [KMC Callback] 결과 전달 에러: $e');
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
