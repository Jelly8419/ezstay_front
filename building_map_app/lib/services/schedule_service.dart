import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/token_service.dart';

/// 일정 관리 서비스
/// 방 일정 조회, 계약 불가 기간 생성/삭제 등을 처리
class ScheduleService {
  /// API 요청 헤더 생성
  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// 통합 일정 조회 (방 정보 + 계약 + 불가 기간)
  /// GET /api/host/rooms/:roomId/schedule
  Future<Map<String, dynamic>> getSchedule({
    required int roomId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final headers = await _getHeaders();

      // Query parameters 구성
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/host/rooms/$roomId/schedule')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else if (response.statusCode == 404) {
        throw Exception('방을 찾을 수 없습니다.');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? '일정 조회 실패');
      }
    } catch (e) {
      throw Exception('일정 조회 중 오류 발생: $e');
    }
  }

  /// 계약 불가 기간 생성
  /// POST /api/host/rooms/:roomId/blocked-periods
  Future<Map<String, dynamic>> createBlockedPeriod({
    required int roomId,
    required String startDate,
    required String endDate,
    String? reason,
  }) async {
    try {
      final headers = await _getHeaders();

      final body = json.encode({
        'startDate': startDate,
        'endDate': endDate,
        if (reason != null) 'reason': reason,
      });

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/host/rooms/$roomId/blocked-periods'),
        headers: headers,
        body: body,
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'];
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        if (errorData['code'] == 4303) {
          throw Exception('과거 날짜는 선택할 수 없습니다.');
        } else if (errorData['code'] == 4302) {
          throw Exception('종료일은 시작일보다 이후여야 합니다.');
        }
        throw Exception(errorData['message'] ?? '입력값이 유효하지 않습니다.');
      } else if (response.statusCode == 409) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? '해당 기간에 이미 확정된 계약이 있습니다.');
      } else if (response.statusCode == 404) {
        throw Exception('방을 찾을 수 없습니다.');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? '계약 불가 기간 설정 실패');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 계약 불가 기간 삭제
  /// DELETE /api/host/rooms/:roomId/blocked-periods/:blockedId
  Future<void> deleteBlockedPeriod({
    required int roomId,
    required int blockedId,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/host/rooms/$roomId/blocked-periods/$blockedId'),
        headers: headers,
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return; // 성공
      } else if (response.statusCode == 404) {
        final errorData = json.decode(response.body);
        if (errorData['code'] == 4304) {
          throw Exception('계약 불가 기간을 찾을 수 없습니다.');
        }
        throw Exception('방을 찾을 수 없습니다.');
      } else if (response.statusCode == 403) {
        throw Exception('삭제 권한이 없습니다.');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? '계약 불가 기간 삭제 실패');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 계약 불가 기간 부분 해제 (기간 분할)
  /// POST /api/host/rooms/:roomId/blocked-periods/unblock
  Future<Map<String, dynamic>> unblockPeriod({
    required int roomId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final headers = await _getHeaders();

      final body = json.encode({
        'startDate': startDate,
        'endDate': endDate,
      });

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/host/rooms/$roomId/blocked-periods/unblock'),
        headers: headers,
        body: body,
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? '입력값이 유효하지 않습니다.');
      } else if (response.statusCode == 404) {
        throw Exception('방을 찾을 수 없습니다.');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? '계약 가능 전환 실패');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 방의 계약 목록 조회
  /// GET /api/host/rooms/:roomId/contracts
  Future<List<Map<String, dynamic>>> getContracts({
    required int roomId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final headers = await _getHeaders();

      // Query parameters 구성
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/host/rooms/$roomId/contracts')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']['contracts']);
      } else if (response.statusCode == 404) {
        throw Exception('방을 찾을 수 없습니다.');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? '계약 목록 조회 실패');
      }
    } catch (e) {
      throw Exception('계약 목록 조회 중 오류 발생: $e');
    }
  }

  /// 방의 계약 불가 기간 목록 조회
  /// GET /api/host/rooms/:roomId/blocked-periods
  Future<List<Map<String, dynamic>>> getBlockedPeriods({
    required int roomId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final headers = await _getHeaders();

      // Query parameters 구성
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/host/rooms/$roomId/blocked-periods')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']['blockedPeriods']);
      } else if (response.statusCode == 404) {
        throw Exception('방을 찾을 수 없습니다.');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? '계약 불가 기간 목록 조회 실패');
      }
    } catch (e) {
      throw Exception('계약 불가 기간 목록 조회 중 오류 발생: $e');
    }
  }

  /// 방 기본 정보 조회
  /// GET /api/host/rooms/:roomId/schedule-info
  Future<Map<String, dynamic>> getRoomScheduleInfo({
    required int roomId,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/host/rooms/$roomId/schedule-info'),
        headers: headers,
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else if (response.statusCode == 404) {
        throw Exception('방을 찾을 수 없습니다.');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? '방 정보 조회 실패');
      }
    } catch (e) {
      throw Exception('방 정보 조회 중 오류 발생: $e');
    }
  }
}
