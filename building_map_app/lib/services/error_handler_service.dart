import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:building_map_app/core/utils/app_logger.dart';
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
  }

  /// HTTP 응답 에러 처리
  ///
  /// 백엔드 에러코드 기준:
  ///   401 + code UNAUTHORIZED(1001) → 토큰 없음  → /login
  ///   401 + code TOKEN_EXPIRED(1003) → 토큰 만료  → /login
  ///   401 + code INVALID_TOKEN(1002) → 토큰 위조  → /login
  ///   403 + code FORBIDDEN(2001)    → 권한 없음  → 다이얼로그만
  void handleHttpError(int statusCode, String responseBody, {String? defaultMessage}) {

    if (_context == null || !_context!.mounted) {
      AppLogger.e('❌ [ERROR_HANDLER] Context가 없거나 mounted되지 않음');
      return;
    }

    String errorMessage = defaultMessage ?? '요청 처리 중 오류가 발생했습니다.';
    String? errorCode;

    try {
      final responseData = json.decode(responseBody);

      // 새 백엔드 에러코드 (문자열 또는 숫자)
      final rawCode = responseData['code'];
      if (rawCode != null) {
        errorCode = rawCode.toString();
      }

      // 메시지 필드
      if (responseData['message'] != null) {
        errorMessage = responseData['message'];
      } else if (responseData['error'] != null) {
        errorMessage = responseData['error'];
      }
    } catch (e) {
      AppLogger.e('❌ [ERROR] JSON 파싱 실패: $e');
    }

    // 인증 실패 여부 판단: 401이거나 인증 관련 에러코드
    final isAuthError = _isAuthErrorCode(statusCode, errorCode);

    // 상태 코드 + 에러코드별 메시지 결정
    final message = _resolveMessage(statusCode, errorCode, errorMessage);

    _showErrorDialog(message, statusCode, shouldRedirect: isAuthError);
  }

  /// 인증 실패 에러코드 판단
  bool _isAuthErrorCode(int statusCode, String? code) {
    if (statusCode == 401) return true;
    // 혹시 403이면서 인증 관련 코드가 오는 경우 대비 (현재 스펙상 없음)
    return false;
  }

  /// 상태코드 + 에러코드로 최종 메시지 결정
  String _resolveMessage(int statusCode, String? code, String backendMessage) {
    // 백엔드가 구체적인 메시지를 내려준 경우 우선 사용
    // 단, 인증 에러는 사용자 친화적 메시지로 통일
    if (statusCode == 401) {
      switch (code) {
        case 'TOKEN_EXPIRED':
        case '1003':
          return '세션이 만료되었습니다. 다시 로그인해주세요.';
        case 'UNAUTHORIZED':
        case '1001':
          return '로그인이 필요합니다.';
        case 'INVALID_TOKEN':
        case '1002':
          return '인증 정보가 유효하지 않습니다. 다시 로그인해주세요.';
        default:
          return '인증이 만료되었습니다. 다시 로그인해주세요.';
      }
    }

    if (statusCode == 403) {
      if (backendMessage.isNotEmpty) return backendMessage;
      return '접근 권한이 없습니다.';
    }

    if (backendMessage.isNotEmpty) return backendMessage;

    switch (statusCode) {
      case 400:
        return '잘못된 요청입니다.';
      case 404:
        return '요청한 리소스를 찾을 수 없습니다.';
      case 500:
        return '서버 오류가 발생했습니다.';
      case 503:
        return '서비스를 일시적으로 사용할 수 없습니다.';
      default:
        return '요청 처리 중 오류가 발생했습니다.';
    }
  }

  /// Exception 에러 처리
  void handleException(Exception exception, {String? customMessage}) {
    if (_context == null || !_context!.mounted) return;

    String errorMessage = customMessage ?? '예기치 않은 오류가 발생했습니다.';

    AppLogger.e('❌ [ERROR] Exception: $exception');

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

  /// 알 수 없는 에러 처리
  void handleUnknownError(Object error, {String? customMessage}) {
    if (_context == null || !_context!.mounted) return;

    String errorMessage = customMessage ?? '예기치 않은 오류가 발생했습니다.';

    AppLogger.e('❌ [ERROR] Unknown Error: $error');

    _showErrorDialog(errorMessage, null);
  }

  /// 에러 다이얼로그 표시
  void _showErrorDialog(String message, int? statusCode, {bool shouldRedirect = false}) {
    if (_context == null || !_context!.mounted) return;

    showDialog(
      context: _context!,
      barrierDismissible: !shouldRedirect, // 인증 에러는 닫기 불가
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
              Text(
                '오류',
                style: AppTextStyles.headingMedium,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
              ),
              if (statusCode != null) ...[
                const SizedBox(height: 12),
                Text(
                  '오류 코드: $statusCode',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                if (shouldRedirect && _context != null && _context!.mounted) {
                  _context!.go('/login');
                }
              },
              child: Text(
                '확인',
                style: AppTextStyles.labelLarge,
              ),
            ),
          ],
        );
      },
    );
  }
}
