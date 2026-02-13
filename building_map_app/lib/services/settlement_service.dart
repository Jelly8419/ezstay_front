import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/settlement.dart';
import 'token_service.dart';

/// 정산 관련 API 서비스
class SettlementService {
  /// API 헤더 생성 (인증 토큰 포함)
  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenService.getValidAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// 정산 목록 조회
  /// [tab] - 'pending' (정산 예정) / 'completed' (정산 완료)
  /// [roomId] - 방 ID 필터 (completed 탭에서만 동작)
  /// [startDate] - 정산일 시작 (YYYY-MM-DD, completed 탭에서만)
  /// [endDate] - 정산일 종료 (YYYY-MM-DD, completed 탭에서만)
  /// [page] - 페이지 번호
  /// [limit] - 페이지당 항목 수
  Future<SettlementListResponse?> getSettlements({
    String tab = 'pending',
    int? roomId,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    debugPrint('🚀 [SETTLEMENT SERVICE] getSettlements 호출');
    debugPrint('   - tab: $tab, roomId: $roomId, page: $page');

    try {
      final queryParams = <String, String>{
        'tab': tab,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      // completed 탭에서만 필터 적용
      if (tab == 'completed') {
        if (roomId != null) queryParams['roomId'] = roomId.toString();
        if (startDate != null) queryParams['startDate'] = startDate;
        if (endDate != null) queryParams['endDate'] = endDate;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/host/settlements')
          .replace(queryParameters: queryParams);

      debugPrint('📡 [SETTLEMENT SERVICE] GET $uri');

      final headers = await _getHeaders();
      debugPrint('📡 [SETTLEMENT SERVICE] Headers: $headers');

      final response = await http.get(uri, headers: headers).timeout(
            ApiConfig.timeout,
          );

      debugPrint('📡 [SETTLEMENT SERVICE] Status: ${response.statusCode}');
      debugPrint('📡 [SETTLEMENT SERVICE] Body 길이: ${response.body.length}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        debugPrint('✅ [SETTLEMENT SERVICE] JSON 파싱 성공');
        return SettlementListResponse.fromJson(json);
      } else {
        debugPrint('❌ [SETTLEMENT SERVICE] Error: ${response.statusCode}');
        debugPrint('❌ [SETTLEMENT SERVICE] Body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [SETTLEMENT SERVICE] Exception: $e');
      debugPrint('❌ [SETTLEMENT SERVICE] StackTrace: $stackTrace');
      return null;
    }
  }

  /// 정산 상세 조회
  /// [contractId] - 계약 ID
  Future<SettlementDetail?> getSettlementDetail(int contractId) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/host/settlements/$contractId',
      );

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(
            ApiConfig.timeout,
          );

      if (!ApiConfig.isProduction) {
        debugPrint('📡 [SETTLEMENT] GET $uri');
        debugPrint('📡 [SETTLEMENT] Status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return SettlementDetail.fromJson(json);
      } else {
        debugPrint('❌ [SETTLEMENT] Error: ${response.statusCode}');
        debugPrint('❌ [SETTLEMENT] Body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [SETTLEMENT] Exception: $e');
      return null;
    }
  }

  /// 정산 내역 엑셀 다운로드 URL 생성
  /// 브라우저에서 직접 다운로드하거나 http_parser로 처리
  String getExportUrl({
    String tab = 'all',
    int? roomId,
    String? startDate,
    String? endDate,
  }) {
    final queryParams = <String, String>{
      'tab': tab,
    };

    if (roomId != null) queryParams['roomId'] = roomId.toString();
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/host/settlements/export')
        .replace(queryParameters: queryParams);

    return uri.toString();
  }

  /// 정산 내역 엑셀 다운로드 (Blob 반환)
  Future<http.Response?> downloadExcel({
    String tab = 'all',
    int? roomId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        'tab': tab,
      };

      if (roomId != null) queryParams['roomId'] = roomId.toString();
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/host/settlements/export')
          .replace(queryParameters: queryParams);

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(
            const Duration(seconds: 30), // 엑셀 다운로드는 타임아웃 더 길게
          );

      if (!ApiConfig.isProduction) {
        debugPrint('📡 [SETTLEMENT] GET $uri');
        debugPrint('📡 [SETTLEMENT] Status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        return response;
      } else {
        debugPrint('❌ [SETTLEMENT] Export Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [SETTLEMENT] Export Exception: $e');
      return null;
    }
  }
}
