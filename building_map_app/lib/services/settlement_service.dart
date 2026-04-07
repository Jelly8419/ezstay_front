import 'package:building_map_app/core/utils/app_logger.dart';
import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
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


      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers).timeout(
            ApiConfig.timeout,
          );


      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return SettlementListResponse.fromJson(json);
      } else {
        AppLogger.e('❌ [SETTLEMENT SERVICE] Error: ${response.statusCode}');
        AppLogger.e('❌ [SETTLEMENT SERVICE] Body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.e('❌ [SETTLEMENT SERVICE] Exception: $e');
      AppLogger.e('❌ [SETTLEMENT SERVICE] StackTrace: $stackTrace');
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

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return SettlementDetail.fromJson(json);
      } else {
        AppLogger.e('❌ [SETTLEMENT] Error: ${response.statusCode}');
        AppLogger.e('❌ [SETTLEMENT] Body: ${response.body}');
        return null;
      }
    } catch (e) {
      AppLogger.e('❌ [SETTLEMENT] Exception: $e');
      return null;
    }
  }

  /// 보증금 차감 상세 조회
  /// GET /api/host/settlements/:contractId/deposit-deduction
  Future<DepositDeductionDetailResponse?> getDepositDeductionDetail(int contractId) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/host/settlements/$contractId/deposit-deduction',
      );
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(ApiConfig.timeout);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return DepositDeductionDetailResponse.fromJson(json);
      } else {
        AppLogger.e('❌ [SETTLEMENT] Deduction Error: ${response.statusCode}');
        AppLogger.e('❌ [SETTLEMENT] Deduction Body: ${response.body}');
        return null;
      }
    } catch (e) {
      AppLogger.e('❌ [SETTLEMENT] Deduction Exception: $e');
      return null;
    }
  }

  /// 정산 내역 엑셀 다운로드
  /// Authorization 헤더를 포함한 HTTP GET 요청으로 파일을 받아 dart:html로 다운로드 트리거
  Future<bool> downloadExcel({
    String tab = 'all',
    int? roomId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{'tab': tab};
      if (roomId != null) queryParams['roomId'] = roomId.toString();
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/host/settlements/export')
          .replace(queryParameters: queryParams);

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final blob = web.Blob(
          [response.bodyBytes.toJS].toJS,
          web.BlobPropertyBag(type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
        );
        final url = web.URL.createObjectURL(blob);
        (web.document.createElement('a') as web.HTMLAnchorElement)
          ..href = url
          ..setAttribute('download', '정산내역.xlsx')
          ..click();
        web.URL.revokeObjectURL(url);
        return true;
      } else {
        AppLogger.e('❌ [SETTLEMENT] Export Error: ${response.statusCode}');
        AppLogger.e('❌ [SETTLEMENT] Export Body: ${response.body}');
        return false;
      }
    } catch (e) {
      AppLogger.e('❌ [SETTLEMENT] Export Exception: $e');
      return false;
    }
  }

}
