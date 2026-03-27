import 'package:http/http.dart' as http;
import 'package:building_map_app/core/utils/app_logger.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'error_handler_service.dart';
import '../config/api_config.dart';
import '../core/exceptions.dart';

/// HTTP 요청을 래핑하고 에러 핸들링을 자동화하는 API 클라이언트
class ApiClient {
  final ErrorHandlerService _errorHandler = ErrorHandlerService();

  /// 공통 HTTP 요청 실행 및 에러 핸들링
  Future<http.Response?> _executeRequest({
    required String method,
    required Uri url,
    required Future<http.Response> Function() request,
    Object? body,
    bool showErrorDialog = true,
  }) async {
    try {
      if (!ApiConfig.isProduction) {
        if (body != null) {
        }
      }

      final response = await request();

      if (!ApiConfig.isProduction) {
      }

      return _handleResponse(response, showErrorDialog);
    } on TimeoutException {
      if (showErrorDialog) {
        _errorHandler.handleTimeoutError();
      }
      return null;
    } on SocketException catch (e) {
      AppLogger.e('❌ [API] Network Error: $e');
      if (showErrorDialog) {
        _errorHandler.handleNetworkError();
      }
      return null;
    } on HttpException catch (e) {
      AppLogger.e('❌ [API] HTTP Exception: $e');
      if (showErrorDialog) {
        _errorHandler.handleException(e);
      }
      return null;
    } on FormatException catch (e) {
      AppLogger.e('❌ [API] Format Exception: $e');
      if (showErrorDialog) {
        _errorHandler.handleException(e);
      }
      return null;
    } catch (e) {
      AppLogger.e('❌ [API] Unknown Error: $e');
      if (showErrorDialog) {
        _errorHandler.handleUnknownError(e);
      }
      return null;
    }
  }

  /// GET 요청
  Future<http.Response?> get(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
    bool showErrorDialog = true,
  }) async {
    return _executeRequest(
      method: 'GET',
      url: url,
      request: () => http.get(url, headers: headers).timeout(timeout ?? ApiConfig.timeout),
      showErrorDialog: showErrorDialog,
    );
  }

  /// POST 요청
  Future<http.Response?> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    bool showErrorDialog = true,
  }) async {
    return _executeRequest(
      method: 'POST',
      url: url,
      body: body,
      request: () => http.post(url, headers: headers, body: body).timeout(timeout ?? ApiConfig.timeout),
      showErrorDialog: showErrorDialog,
    );
  }

  /// PUT 요청
  Future<http.Response?> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    bool showErrorDialog = true,
  }) async {
    return _executeRequest(
      method: 'PUT',
      url: url,
      body: body,
      request: () => http.put(url, headers: headers, body: body).timeout(timeout ?? ApiConfig.timeout),
      showErrorDialog: showErrorDialog,
    );
  }

  /// PATCH 요청
  Future<http.Response?> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    bool showErrorDialog = true,
  }) async {
    return _executeRequest(
      method: 'PATCH',
      url: url,
      body: body,
      request: () => http.patch(url, headers: headers, body: body).timeout(timeout ?? ApiConfig.timeout),
      showErrorDialog: showErrorDialog,
    );
  }

  /// DELETE 요청
  Future<http.Response?> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    bool showErrorDialog = true,
  }) async {
    return _executeRequest(
      method: 'DELETE',
      url: url,
      body: body,
      request: () => http.delete(url, headers: headers, body: body).timeout(timeout ?? ApiConfig.timeout),
      showErrorDialog: showErrorDialog,
    );
  }

  /// 응답 처리 및 에러 핸들링
  ///
  /// 401 응답 → UnauthorizedException throw (showErrorDialog 값 무관)
  /// 나머지 에러 → showErrorDialog=true 이면 다이얼로그, false 이면 null 반환
  http.Response? _handleResponse(http.Response response, bool showErrorDialog) {
    // 성공 응답 (200-299)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    AppLogger.w('⚠️ [API_CLIENT] 에러 응답 감지 - statusCode: ${response.statusCode}');

    // 401: 인증 실패 → UnauthorizedException throw (항상, showErrorDialog 무관)
    if (response.statusCode == 401) {
      String? code;
      try {
        final data = json.decode(response.body);
        final rawCode = data['code'];
        if (rawCode != null) code = rawCode.toString();
      } catch (_) {}

      throw UnauthorizedException(_authMessage(code));
    }

    // 나머지 에러
    if (showErrorDialog) {
      AppLogger.e('🔔 [API_CLIENT] ErrorHandler 호출');
      _errorHandler.handleHttpError(response.statusCode, response.body);
    }

    return null;
  }

  /// 에러코드별 메시지
  String _authMessage(String? code) {
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
}
