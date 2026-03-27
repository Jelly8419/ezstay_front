import 'package:building_map_app/core/utils/app_logger.dart';
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/material.dart';
import '../services/kmc_service.dart';

/// KMC 본인인증 헬퍼
///
/// 웹 환경에서 window.open() 팝업으로 KMC 인증 페이지를 열고
/// postMessage로 결과를 수신합니다.
///
/// 사용법:
/// ```dart
/// final result = await KmcWebViewHelper.openKmcVerification(
///   context: context,
///   requestResult: kmcRequestResult,
/// );
/// if (result != null) {
///   final verifyResult = await KmcService.verifyResult(
///     apiToken: result['apiToken']!,
///     certNum: result['certNum']!,
///   );
/// }
/// ```
class KmcWebViewHelper {
  /// KMC 인증창 열기
  ///
  /// Returns: {'apiToken': '...', 'certNum': '...'} 또는 null (취소/실패)
  static Future<Map<String, String>?> openKmcVerification({
    required BuildContext context,
    required KmcRequestResult requestResult,
  }) async {
    final completer = Completer<Map<String, String>?>();

    final formHtml = _buildKmcFormHtml(requestResult);

    _openKmcPopup(formHtml, completer);

    return completer.future;
  }

  /// 팝업 창으로 KMC 인증 열기
  static void _openKmcPopup(
    String formHtml,
    Completer<Map<String, String>?> completer,
  ) {
    try {
      // JavaScript를 통해 팝업 열고 form HTML 작성
      final popupRef = js.context.callMethod('open', [
        '',
        'KMCISWindow',
        'width=425,height=550,resizable=0,scrollbars=no,status=0,titlebar=0,toolbar=0,left=435,top=250',
      ]);

      if (popupRef == null) {
        AppLogger.w('⚠️ [KMC] 팝업 차단됨');
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        return;
      }

      // JS에서 팝업 참조 저장 (닫힘 감지용)
      js.context['_kmcPopupRef'] = popupRef;

      // 팝업에 form HTML 작성 및 자동 submit
      final popupDoc = popupRef['document'];
      popupDoc.callMethod('write', [formHtml]);
      popupDoc.callMethod('close', []);

      // postMessage 리스너 등록
      Timer? pollTimer;
      Timer? timeoutTimer;

      void cleanup() {
        pollTimer?.cancel();
        timeoutTimer?.cancel();
        // JS 콜백 정리
        try {
          js.context.deleteProperty('_kmcMessageHandler');
          js.context.deleteProperty('_kmcPopupRef');
          js.context.deleteProperty('_kmcPopupState');
          js.context.callMethod('eval', [
            'if (window._kmcBroadcastChannel) { window._kmcBroadcastChannel.close(); window._kmcBroadcastChannel = null; }'
          ]);
        } catch (_) {}
      }

      // JS에서 postMessage 수신 → Dart 콜백 호출
      js.context['_kmcMessageHandler'] = (js.JsObject event) {
        try {
          final data = event['data'];
          if (data != null) {
            final jsObj = js.JsObject.fromBrowserObject(data);
            final type = jsObj['type']?.toString();

            if (type == 'KMC_RESULT') {
              final apiToken = jsObj['apiToken']?.toString() ?? '';
              final certNum = jsObj['certNum']?.toString() ?? '';


              cleanup();

              if (apiToken.isNotEmpty && certNum.isNotEmpty) {
                if (!completer.isCompleted) {
                  completer.complete({
                    'apiToken': apiToken,
                    'certNum': certNum,
                  });
                }
              } else {
                if (!completer.isCompleted) {
                  completer.complete(null);
                }
              }
            }
          }
        } catch (e) {
          AppLogger.e('❌ [KMC] postMessage 파싱 에러: $e');
        }
      };

      // addEventListener로 message 이벤트 수신 (opener가 살아있는 경우)
      // + BroadcastChannel 수신 (백엔드 리다이렉트로 opener가 끊어진 경우)
      js.context.callMethod('eval', ['''
        window.addEventListener('message', function _kmcListener(event) {
          if (event.data && event.data.type === 'KMC_RESULT') {
            window._kmcMessageHandler(event);
            window.removeEventListener('message', _kmcListener);
          }
        });

        try {
          window._kmcBroadcastChannel = new BroadcastChannel('kmc_auth');
          window._kmcBroadcastChannel.onmessage = function(event) {
            if (event.data && event.data.type === 'KMC_RESULT') {
              console.log('[KMC] BroadcastChannel로 인증 결과 수신');
              window._kmcMessageHandler({data: event.data});
              window._kmcBroadcastChannel.close();
              window._kmcBroadcastChannel = null;
            }
          };
        } catch(e) {
          console.log('[KMC] BroadcastChannel 미지원:', e);
        }
      ''']);

      // 팝업 닫힘 감지 — cross-origin에서 popup.closed가 true를 반환하는 문제 대응
      // popup.closed를 사용하지 않고, location 접근 가능 여부로 판단
      pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        try {
          js.context.callMethod('eval', ['''
            (function() {
              var popup = window._kmcPopupRef;
              if (!popup) {
                window._kmcPopupState = 'closed';
                return;
              }
              try {
                // cross-origin이면 location.href 접근 시 에러 → 아직 열려있음 (다른 도메인)
                var href = popup.location.href;
                // same-origin 접근 성공 → about:blank이거나 실제 닫힘 확인
                if (popup.closed) {
                  window._kmcPopupState = 'closed';
                } else {
                  window._kmcPopupState = 'open_same_origin';
                }
              } catch(e) {
                // cross-origin 에러 → 다른 도메인에 있음 (KMC 인증 중)
                window._kmcPopupState = 'open_cross_origin';
              }
            })()
          ''']);

          final state = js.context['_kmcPopupState']?.toString() ?? 'unknown';

          if (state == 'closed') {
            // 팝업이 실제로 닫힘 → BroadcastChannel 결과 대기 (3초)
            Timer(const Duration(seconds: 3), () {
              if (!completer.isCompleted) {
                cleanup();
                completer.complete(null);
              }
            });
            timer.cancel();
          }
        } catch (_) {
          // 에러 시 무시 (팝업 아직 열려있는 것으로 간주)
        }
      });

      // 5분 타임아웃
      timeoutTimer = Timer(const Duration(minutes: 5), () {
        if (!completer.isCompleted) {
          cleanup();
          try {
            popupRef.callMethod('close', []);
          } catch (_) {}
          completer.complete(null);
        }
      });
    } catch (e) {
      AppLogger.e('❌ [KMC] 팝업 열기 에러: $e');
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }
  }

  /// KMC 인증 form HTML 생성
  ///
  /// 팝업에 로드되면 자동으로 KMC 인증 페이지로 form submit합니다.
  static String _buildKmcFormHtml(KmcRequestResult request) {
    final trCertEscaped = _escapeHtml(request.trCert);
    final trUrlEscaped = _escapeHtml(request.trUrl);

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>본인인증</title>
  <style>
    body {
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #f5f5f5;
    }
    .loading {
      text-align: center;
      color: #666;
    }
    .spinner {
      border: 3px solid #e0e0e0;
      border-top: 3px solid #4A90E2;
      border-radius: 50%;
      width: 32px;
      height: 32px;
      animation: spin 1s linear infinite;
      margin: 0 auto 16px;
    }
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  </style>
</head>
<body>
  <div class="loading">
    <div class="spinner"></div>
    <p>본인인증 페이지로 이동 중...</p>
  </div>
  <form name="reqKMCISForm" method="post" action="https://www.kmcert.com/kmcis/web/kmcisReq.jsp">
    <input type="hidden" name="tr_cert" value="$trCertEscaped">
    <input type="hidden" name="tr_url" value="$trUrlEscaped">
    <input type="hidden" name="tr_ver" value="V2">
  </form>
  <script>
    window.name = "KMCISWindow";
    document.reqKMCISForm.submit();
  </script>
</body>
</html>
''';
  }

  /// HTML 특수문자 이스케이프
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }
}
