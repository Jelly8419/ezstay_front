import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';

/// 전역 에러 핸들러 서비스
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  BuildContext? _context;

  /// 현재 BuildContext 설정
  void setContext(BuildContext context) {
    _context = context;
    debugPrint('✅ [ERROR_HANDLER] Context 설정됨');
  }

  /// HTTP 응답 에러 처리
  void handleHttpError(int statusCode, String responseBody, {String? defaultMessage}) {
    debugPrint('🔔 [ERROR_HANDLER] handleHttpError 호출됨 - statusCode: $statusCode');
    debugPrint('🔔 [ERROR_HANDLER] context: $_context, mounted: ${_context?.mounted}');

    if (_context == null || !_context!.mounted) {
      debugPrint('❌ [ERROR_HANDLER] Context가 없거나 mounted되지 않음');
      return;
    }

    String errorMessage = defaultMessage ?? '요청 처리 중 오류가 발생했습니다.';

    try {
      final responseData = json.decode(responseBody);

      // 백엔드에서 보낸 message 또는 error 필드 확인
      if (responseData['message'] != null) {
        errorMessage = responseData['message'];
      } else if (responseData['error'] != null) {
        errorMessage = responseData['error'];
      }
    } catch (e) {
      // JSON 파싱 실패 시 기본 메시지 사용
      debugPrint('❌ [ERROR] JSON 파싱 실패: $e');
    }

    // 상태 코드별 기본 메시지
    switch (statusCode) {
      case 400:
        errorMessage = errorMessage.isEmpty ? '잘못된 요청입니다.' : errorMessage;
        break;
      case 401:
        errorMessage = errorMessage.isEmpty ? '인증이 필요합니다. 다시 로그인해주세요.' : errorMessage;
        break;
      case 403:
        errorMessage = errorMessage.isEmpty ? '접근 권한이 없습니다.' : errorMessage;
        break;
      case 404:
        errorMessage = errorMessage.isEmpty ? '요청한 리소스를 찾을 수 없습니다.' : errorMessage;
        break;
      case 500:
        errorMessage = errorMessage.isEmpty ? '서버 오류가 발생했습니다.' : errorMessage;
        break;
      case 503:
        errorMessage = errorMessage.isEmpty ? '서비스를 일시적으로 사용할 수 없습니다.' : errorMessage;
        break;
    }

    _showErrorDialog(errorMessage, statusCode, shouldRedirect: statusCode == 401 || statusCode == 403);
  }

  /// Exception 에러 처리
  void handleException(Exception exception, {String? customMessage}) {
    if (_context == null || !_context!.mounted) return;

    String errorMessage = customMessage ?? '예기치 않은 오류가 발생했습니다.';

    debugPrint('❌ [ERROR] Exception: $exception');

    _showErrorDialog(errorMessage, null);
  }

  /// 네트워크 에러 처리
  void handleNetworkError({String? customMessage}) {
    if (_context == null || !_context!.mounted) return;

    String errorMessage = customMessage ?? '네트워크 연결을 확인해주세요.';

    _showErrorDialog(errorMessage, null);
  }

  /// 타임아웃 에러 처리
  void handleTimeoutError({String? customMessage}) {
    if (_context == null || !_context!.mounted) return;

    String errorMessage = customMessage ?? '요청 시간이 초과되었습니다. 다시 시도해주세요.';

    _showErrorDialog(errorMessage, null);
  }

  /// 에러 다이얼로그 표시
  void _showErrorDialog(String message, int? statusCode, {bool shouldRedirect = false}) {
    if (_context == null || !_context!.mounted) return;

    showDialog(
      context: _context!,
      barrierDismissible: !shouldRedirect, // 리다이렉트가 필요한 경우 팝업을 닫을 수 없게
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                '오류',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              if (statusCode != null) ...[
                const SizedBox(height: 12),
                Text(
                  '오류 코드: $statusCode',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                // 권한 에러인 경우 호스트 홈으로 리다이렉트
                if (shouldRedirect && _context != null && _context!.mounted) {
                  debugPrint('🔄 [ERROR_HANDLER] 권한 에러 - 호스트 홈으로 리다이렉트');
                  _context!.go('/host');
                }
              },
              child: const Text(
                '확인',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
