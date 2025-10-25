import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'error_handler_service.dart';
import '../config/api_config.dart';

/// HTTP 요청을 래핑하고 에러 핸들링을 자동화하는 API 클라이언트
class ApiClient {
  final ErrorHandlerService _errorHandler = ErrorHandlerService();

  /// GET 요청
  Future<http.Response?> get(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
    bool showErrorDialog = true,
  }) async {
    try {
      if (!ApiConfig.isProduction) {
        debugPrint('🌐 [API] GET: $url');
      }

      final response = await http.get(url, headers: headers).timeout(timeout ?? ApiConfig.timeout);

      if (!ApiConfig.isProduction) {
        debugPrint('📡 [API] Response: ${response.statusCode}');
      }

      return _handleResponse(response, showErrorDialog);
    } on TimeoutException {
      debugPrint('⏱️ [API] Timeout: $url');
      if (showErrorDialog) {
        _errorHandler.handleTimeoutError();
      }
      return null;
    } on SocketException catch (e) {
      debugPrint('❌ [API] Network Error: $e');
      if (showErrorDialog) {
        _errorHandler.handleNetworkError();
      }
      return null;
    } on HttpException catch (e) {
      debugPrint('❌ [API] HTTP Exception: $e');
      if (showErrorDialog) {
        _errorHandler.handleException(e);
      }
      return null;
    } on FormatException catch (e) {
      debugPrint('❌ [API] Format Exception: $e');
      if (showErrorDialog) {
        _errorHandler.handleException(e);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [API] Unknown Error: $e');
      if (showErrorDialog) {
        _errorHandler.handleUnknownError(e);
      }
      return null;
    }
  }

  /// POST 요청
  Future<http.Response?> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    bool showErrorDialog = true,
  }) async {
    try {
      if (!ApiConfig.isProduction) {
        debugPrint('🌐 [API] POST: $url');
        debugPrint('📦 [API] Body: $body');
      }

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(timeout ?? ApiConfig.timeout);

      if (!ApiConfig.isProduction) {
        debugPrint('📡 [API] Response: ${response.statusCode}');
      }

      return _handleResponse(response, showErrorDialog);
    } on TimeoutException {
      debugPrint('⏱️ [API] Timeout: $url');
      if (showErrorDialog) {
        _errorHandler.handleTimeoutError();
      }
      return null;
    } on SocketException catch (e) {
      debugPrint('❌ [API] Network Error: $e');
      if (showErrorDialog) {
        _errorHandler.handleNetworkError();
      }
      return null;
    } on HttpException catch (e) {
      debugPrint('❌ [API] HTTP Exception: $e');
      if (showErrorDialog) {
        _errorHandler.handleException(e);
      }
      return null;
    } on FormatException catch (e) {
      debugPrint('❌ [API] Format Exception: $e');
      if (showErrorDialog) {
        _errorHandler.handleException(e);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [API] Unknown Error: $e');
      if (showErrorDialog) {
        _errorHandler.handleUnknownError(e);
      }
      return null;
    }
  }

  /// PUT 요청
  Future<http.Response?> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    bool showErrorDialog = true,
  }) async {
    try {
      if (!ApiConfig.isProduction) {
        debugPrint('🌐 [API] PUT: $url');
        debugPrint('📦 [API] Body: $body');
      }

      final response = await http.put(
        url,
        headers: headers,
        body: body,
      ).timeout(timeout ?? ApiConfig.timeout);

      if (!ApiConfig.isProduction) {
        debugPrint('📡 [API] Response: ${response.statusCode}');
      }

      return _handleResponse(response, showErrorDialog);
    } on TimeoutException {
      debugPrint('⏱️ [API] Timeout: $url');
      if (showErrorDialog) {
        _errorHandler.handleTimeoutError();
      }
      return null;
    } on SocketException catch (e) {
      debugPrint('❌ [API] Network Error: $e');
      if (showErrorDialog) {
        _errorHandler.handleNetworkError();
      }
      return null;
    } on HttpException catch (e) {
      debugPrint('❌ [API] HTTP Exception: $e');
      if (showErrorDialog) {
        _errorHandler.handleException(e);
      }
      return null;
    } on FormatException catch (e) {
      debugPrint('❌ [API] Format Exception: $e');
      if (showErrorDialog) {
        _errorHandler.handleException(e);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [API] Unknown Error: $e');
      if (showErrorDialog) {
        _errorHandler.handleUnknownError(e);
      }
      return null;
    }
  }

  /// PATCH 요청
  Future<http.Response?> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    bool showErrorDialog = true,
  }) async {
    try {
      if (!ApiConfig.isProduction) {
        debugPrint('🌐 [API] PATCH: $url');
        debugPrint('📦 [API] Body: $body');
      }

      final response = await http.patch(
        url,
        headers: headers,
        body: body,
      ).timeout(timeout ?? ApiConfig.timeout);

      if (!ApiConfig.isProduction) {
        debugPrint('📡 [API] Response: ${response.statusCode}');
      }

      return _handleResponse(response, showErrorDialog);
    } on TimeoutException {
      debugPrint('⏱️ [API] Timeout: $url');
      if (showErrorDialog) {
        _errorHandler.handleTimeoutError();
      }
      return null;
    } on SocketException catch (e) {
      debugPrint('❌ [API] Network Error: $e');
      if (showErrorDialog) {
        _errorHandler.handleNetworkError();
      }
      return null;
    } on HttpException catch (e) {
      debugPrint('❌ [API] HTTP Exception: $e');
      if (showErrorDialog) {
        _errorHandler.handleException(e);
      }
      return null;
    } on FormatException catch (e) {
      debugPrint('❌ [API] Format Exception: $e');
      if (showErrorDialog) {
        _errorHandler.handleException(e);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [API] Unknown Error: $e');
      if (showErrorDialog) {
        _errorHandler.handleUnknownError(e);
      }
      return null;
    }
  }

  /// DELETE 요청
  Future<http.Response?> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    bool showErrorDialog = true,
  }) async {
    try {
      if (!ApiConfig.isProduction) {
        debugPrint('🌐 [API] DELETE: $url');
      }

      final response = await http.delete(
        url,
        headers: headers,
        body: body,
      ).timeout(timeout ?? ApiConfig.timeout);

      if (!ApiConfig.isProduction) {
        debugPrint('📡 [API] Response: ${response.statusCode}');
      }

      return _handleResponse(response, showErrorDialog);
    } on TimeoutException {
      debugPrint('⏱️ [API] Timeout: $url');
      if (showErrorDialog) {
        _errorHandler.handleTimeoutError();
      }
      return null;
    } on SocketException catch (e) {
      debugPrint('❌ [API] Network Error: $e');
      if (showErrorDialog) {
        _errorHandler.handleNetworkError();
      }
      return null;
    } on HttpException catch (e) {
      debugPrint('❌ [API] HTTP Exception: $e');
      if (showErrorDialog) {
        _errorHandler.handleException(e);
      }
      return null;
    } on FormatException catch (e) {
      debugPrint('❌ [API] Format Exception: $e');
      if (showErrorDialog) {
        _errorHandler.handleException(e);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [API] Unknown Error: $e');
      if (showErrorDialog) {
        _errorHandler.handleUnknownError(e);
      }
      return null;
    }
  }

  /// 응답 처리 및 에러 핸들링
  http.Response? _handleResponse(http.Response response, bool showErrorDialog) {
    // 성공 응답 (200-299)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    // 에러 응답
    debugPrint('⚠️ [API_CLIENT] 에러 응답 감지 - statusCode: ${response.statusCode}');
    debugPrint('⚠️ [API_CLIENT] showErrorDialog: $showErrorDialog');

    if (showErrorDialog) {
      debugPrint('🔔 [API_CLIENT] ErrorHandler 호출 시작');
      _errorHandler.handleHttpError(
        response.statusCode,
        response.body,
      );
      debugPrint('🔔 [API_CLIENT] ErrorHandler 호출 완료');
    }

    return null;
  }
}
