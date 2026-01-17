import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/room.dart';
import 'api_client.dart';
import 'token_service.dart';

/// 방 관리 서비스 (호스트 전용)
///
/// 호스트가 등록한 방 목록 조회 및 관리 기능을 제공합니다.
/// - 방 목록 조회 (검색, 필터링, 페이지네이션)
/// - 게시 상태 변경 (게시/비공개 전환)
/// - 방 삭제 (소프트 삭제)
/// - 방 복제
class RoomManagementService {
  final ApiClient _apiClient = ApiClient();

  /// 인증 헤더 생성
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await TokenService.getAccessToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  /// 방 목록 조회
  ///
  /// [status] - 방 상태 필터 (draft, pending_review, approved, rejected)
  /// [isActive] - 게시 여부 필터 (true: 게시중, false: 게시중단)
  /// [search] - 검색어 (방 이름 또는 주소)
  /// [page] - 페이지 번호 (1부터 시작)
  /// [limit] - 페이지당 개수 (기본 20)
  ///
  /// 반환값:
  /// - success: true인 경우 rooms 리스트 반환
  /// - null: 에러 발생 시
  Future<Map<String, dynamic>?> getRooms({
    String? status,
    bool? isActive,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      // 쿼리 파라미터 생성
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/host/rooms').replace(
        queryParameters: queryParams,
      );

      debugPrint('🌐 [ROOM_MGMT_SERVICE] API 요청: $uri');
      final response = await _apiClient.get(uri, headers: headers);

      if (response == null) {
        debugPrint('❌ [ROOM_MGMT_SERVICE] API 응답이 null');
        return null;
      }

      debugPrint('📡 [ROOM_MGMT_SERVICE] 응답 상태 코드: ${response.statusCode}');
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      debugPrint('📦 [ROOM_MGMT_SERVICE] 응답 전체 구조: ${data.keys}');

      // API 응답 구조 확인 및 정규화
      Map<String, dynamic> normalizedData;

      if (data['data'] != null && data['data']['rooms'] != null) {
        // 구조: { data: { rooms: [...] } }
        debugPrint('✅ [ROOM_MGMT_SERVICE] 응답 구조: data.rooms');
        normalizedData = {
          'rooms': data['data']['rooms'],
        };
      } else if (data['rooms'] != null) {
        // 구조: { rooms: [...] }
        debugPrint('✅ [ROOM_MGMT_SERVICE] 응답 구조: rooms');
        normalizedData = data;
      } else {
        debugPrint('❌ [ROOM_MGMT_SERVICE] rooms 배열을 찾을 수 없음');
        return null;
      }

      final rooms = normalizedData['rooms'] as List;
      debugPrint('✅ [ROOM_MGMT_SERVICE] 방 목록 조회 성공: ${rooms.length}개');

      if (rooms.isNotEmpty) {
        final firstRoom = rooms[0];
        debugPrint('📋 [ROOM_MGMT_SERVICE] 첫 번째 방 원본 데이터:');
        debugPrint('  - status: ${firstRoom['status']}');
        debugPrint('  - isActive: ${firstRoom['isActive']}');
      }

      return normalizedData;
    } catch (e) {
      debugPrint('❌ [RoomManagementService] 방 목록 조회 실패: $e');
      return null;
    }
  }

  /// 게시 상태 변경 (게시/비공개 전환)
  ///
  /// [roomId] - 방 ID
  /// [isActive] - 변경할 게시 상태 (true: 게시, false: 비공개)
  ///
  /// 반환값:
  /// - true: 성공
  /// - false: 실패
  Future<bool> togglePublishStatus(int roomId, bool isActive) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/host/rooms/$roomId/status');

      final body = jsonEncode({
        'isActive': isActive,
      });

      final response = await _apiClient.patch(uri, headers: headers, body: body);

      if (response == null) {
        return false;
      }

      if (!ApiConfig.isProduction) {
        debugPrint('✅ [RoomManagementService] 게시 상태 변경 성공: roomId=$roomId, isActive=$isActive');
      }

      return true;
    } catch (e) {
      debugPrint('❌ [RoomManagementService] 게시 상태 변경 실패: $e');
      return false;
    }
  }

  /// 방 삭제 (소프트 삭제)
  ///
  /// [roomId] - 방 ID
  ///
  /// 반환값:
  /// - true: 성공
  /// - false: 실패
  Future<bool> deleteRoom(int roomId) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/host/rooms/$roomId');

      final response = await _apiClient.delete(uri, headers: headers);

      if (response == null) {
        return false;
      }

      if (!ApiConfig.isProduction) {
        debugPrint('✅ [RoomManagementService] 방 삭제 성공: roomId=$roomId');
      }

      return true;
    } catch (e) {
      debugPrint('❌ [RoomManagementService] 방 삭제 실패: $e');
      return false;
    }
  }

  /// 방 복제
  ///
  /// [roomId] - 원본 방 ID
  /// [copyPhotos] - 사진 복사 여부 (기본 true)
  /// [copyAmenities] - 편의시설 복사 여부 (기본 true)
  /// [copyServices] - 부가서비스 복사 여부 (기본 true)
  /// [copyDescription] - 방 소개 복사 여부 (기본 true)
  ///
  /// 반환값:
  /// - 새로 생성된 방 정보 (Room 객체)
  /// - null: 실패
  Future<Room?> duplicateRoom(
    int roomId, {
    bool copyPhotos = true,
    bool copyAmenities = true,
    bool copyServices = true,
    bool copyDescription = true,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/host/rooms/$roomId/duplicate');

      final body = jsonEncode({
        'copyPhotos': copyPhotos,
        'copyAmenities': copyAmenities,
        'copyServices': copyServices,
        'copyDescription': copyDescription,
      });

      final response = await _apiClient.post(uri, headers: headers, body: body);

      if (response == null) {
        return null;
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (!ApiConfig.isProduction) {
        debugPrint('✅ [RoomManagementService] 방 복제 성공: 원본=$roomId, 복제=${data['room']['id']}');
      }

      return Room.fromJson(data['room']);
    } catch (e) {
      debugPrint('❌ [RoomManagementService] 방 복제 실패: $e');
      return null;
    }
  }

  /// 방 목록을 Room 객체 리스트로 변환
  ///
  /// [data] - API 응답 데이터 (getRooms의 반환값)
  ///
  /// 반환값:
  /// - Room 객체 리스트
  List<Room> parseRooms(Map<String, dynamic>? data) {
    if (data == null || data['rooms'] == null) {
      debugPrint('⚠️ [ROOM_MGMT_SERVICE] parseRooms: data 또는 rooms가 null');
      return [];
    }

    try {
      final List<dynamic> roomsJson = data['rooms'];
      debugPrint('🔄 [ROOM_MGMT_SERVICE] parseRooms: ${roomsJson.length}개 파싱 시작');

      final rooms = roomsJson.map((json) => Room.fromJson(json)).toList();

      if (rooms.isNotEmpty) {
        debugPrint('✅ [ROOM_MGMT_SERVICE] parseRooms 완료:');
        debugPrint('  - 첫 번째 방 status (정규화 후): ${rooms.first.status}');
        debugPrint('  - 첫 번째 방 isActive: ${rooms.first.isActive}');
      }

      return rooms;
    } catch (e) {
      debugPrint('❌ [RoomManagementService] 방 목록 파싱 실패: $e');
      return [];
    }
  }
}
