import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

/// 방 등록 API 서비스
class RoomService {
  static const String baseUrl = 'http://localhost:8080/api/host/rooms';
  static const _storage = FlutterSecureStorage();

  /// 저장된 토큰 확인 (디버깅용)
  Future<void> checkToken() async {
    final accessToken = await _storage.read(key: 'access_token');
    final refreshToken = await _storage.read(key: 'refresh_token');

    debugPrint('=== 토큰 상태 확인 ===');
    debugPrint('Access Token: ${accessToken != null ? "있음 (${accessToken.length}자)" : "없음"}');
    debugPrint('Refresh Token: ${refreshToken != null ? "있음 (${refreshToken.length}자)" : "없음"}');

    if (accessToken != null) {
      debugPrint('Access Token 미리보기: ${accessToken.substring(0, accessToken.length > 50 ? 50 : accessToken.length)}...');
    }
    debugPrint('==================');
  }

  /// Authorization 헤더 가져오기
  Future<Map<String, String>> _getHeaders() async {
    final accessToken = await _storage.read(key: 'access_token');
    debugPrint('🔑 [AUTH] Access Token: ${accessToken != null ? "있음 (${accessToken.substring(0, 20)}...)" : "없음"}');

    if (accessToken == null || accessToken.isEmpty) {
      debugPrint('⚠️ [AUTH] 액세스 토큰이 없습니다! 로그인을 확인해주세요.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${accessToken ?? ''}',
    };
  }

  /// 1. 기본 정보 등록
  Future<Map<String, dynamic>?> createRoom(Map<String, dynamic> roomData) async {
    try {
      debugPrint('🏠 [ROOM] 방 기본 정보 등록 시작');
      debugPrint('📦 [ROOM] 요청 데이터: $roomData');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: await _getHeaders(),
        body: json.encode(roomData),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 [ROOM] 응답 상태: ${response.statusCode}');
      debugPrint('📄 [ROOM] 응답 내용: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        debugPrint('✅ [ROOM] 방 등록 성공 - roomId: ${data['data']['roomId']}');
        return data['data'];
      } else if (response.statusCode == 401) {
        debugPrint('❌ [ROOM] 인증 실패 (401) - 토큰이 유효하지 않거나 만료되었습니다.');
        debugPrint('📄 [ROOM] 에러 응답: ${response.body}');
        return null;
      } else {
        debugPrint('❌ [ROOM] 방 등록 실패: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [ROOM] 방 등록 에러: $e');
      return null;
    }
  }

  /// 2. 요금 설정
  Future<bool> updatePricing(int roomId, Map<String, dynamic> pricingData) async {
    try {
      debugPrint('💰 [PRICING] 요금 설정 시작 - roomId: $roomId');
      debugPrint('📦 [PRICING] 요청 데이터: $pricingData');

      final response = await http.patch(
        Uri.parse('$baseUrl/$roomId/pricing'),
        headers: await _getHeaders(),
        body: json.encode(pricingData),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 [PRICING] 응답 상태: ${response.statusCode}');
      debugPrint('📄 [PRICING] 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ [PRICING] 요금 설정 성공');
        return true;
      } else if (response.statusCode == 401) {
        debugPrint('❌ [PRICING] 인증 실패 (401) - 토큰이 유효하지 않거나 만료되었습니다.');
        return false;
      } else {
        debugPrint('❌ [PRICING] 요금 설정 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [PRICING] 요금 설정 에러: $e');
      return false;
    }
  }

  /// 3. 사진 업로드
  Future<List<Map<String, dynamic>>?> uploadPhotos(int roomId, List<XFile> photos) async {
    try {
      debugPrint('📸 [PHOTOS] 사진 업로드 시작 - roomId: $roomId, 사진 수: ${photos.length}');

      final accessToken = await _storage.read(key: 'access_token');
      debugPrint('🔑 [PHOTOS] Access Token: ${accessToken != null ? "있음 (${accessToken.substring(0, 20)}...)" : "없음"}');

      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('⚠️ [PHOTOS] 액세스 토큰이 없습니다!');
        return null;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/$roomId/photos'),
      );

      request.headers['Authorization'] = 'Bearer $accessToken';

      // 사진 파일 추가
      for (var photo in photos) {
        final bytes = await photo.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'photos',
          bytes,
          filename: photo.name,
        );
        request.files.add(multipartFile);
        debugPrint('📸 [PHOTOS] 파일 추가: ${photo.name}');
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📡 [PHOTOS] 응답 상태: ${response.statusCode}');
      debugPrint('📄 [PHOTOS] 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ [PHOTOS] 사진 업로드 성공');
        return List<Map<String, dynamic>>.from(data['data']['photoUrls']);
      } else if (response.statusCode == 401) {
        debugPrint('❌ [PHOTOS] 인증 실패 (401) - 토큰이 유효하지 않거나 만료되었습니다.');
        return null;
      } else {
        debugPrint('❌ [PHOTOS] 사진 업로드 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [PHOTOS] 사진 업로드 에러: $e');
      return null;
    }
  }

  /// 4. 편의시설 설정
  Future<bool> updateAmenities(int roomId, Map<String, dynamic> amenitiesData) async {
    try {
      debugPrint('🏨 [AMENITIES] 편의시설 설정 시작 - roomId: $roomId');
      debugPrint('📦 [AMENITIES] 요청 데이터: $amenitiesData');

      final response = await http.patch(
        Uri.parse('$baseUrl/$roomId/amenities'),
        headers: await _getHeaders(),
        body: json.encode(amenitiesData),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 [AMENITIES] 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ [AMENITIES] 편의시설 설정 성공');
        return true;
      } else {
        debugPrint('❌ [AMENITIES] 편의시설 설정 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [AMENITIES] 편의시설 설정 에러: $e');
      return false;
    }
  }

  /// 5. 무료 부가서비스 설정
  Future<bool> updateFreeServices(int roomId, Map<String, dynamic> servicesData) async {
    try {
      debugPrint('🎁 [SERVICES] 무료 부가서비스 설정 시작 - roomId: $roomId');
      debugPrint('📦 [SERVICES] 요청 데이터: $servicesData');

      final response = await http.patch(
        Uri.parse('$baseUrl/$roomId/free-services'),
        headers: await _getHeaders(),
        body: json.encode(servicesData),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 [SERVICES] 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ [SERVICES] 무료 부가서비스 설정 성공');
        return true;
      } else {
        debugPrint('❌ [SERVICES] 무료 부가서비스 설정 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [SERVICES] 무료 부가서비스 설정 에러: $e');
      return false;
    }
  }

  /// 6. 청소도구 이미지 업로드
  Future<String?> uploadCleaningToolImage(int roomId, XFile image) async {
    try {
      debugPrint('🧹 [CLEANING] 청소도구 이미지 업로드 시작 - roomId: $roomId');

      final accessToken = await _storage.read(key: 'access_token');
      debugPrint('🔑 [CLEANING] Access Token: ${accessToken != null ? "있음 (${accessToken.substring(0, 20)}...)" : "없음"}');

      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('⚠️ [CLEANING] 액세스 토큰이 없습니다!');
        return null;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/$roomId/cleaning-tool-image'),
      );

      request.headers['Authorization'] = 'Bearer $accessToken';

      final bytes = await image.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: image.name,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📡 [CLEANING] 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ [CLEANING] 청소도구 이미지 업로드 성공');
        return data['data']['imageUrl'];
      } else {
        debugPrint('❌ [CLEANING] 청소도구 이미지 업로드 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [CLEANING] 청소도구 이미지 업로드 에러: $e');
      return null;
    }
  }

  /// 7. 방 소개 및 설명
  Future<bool> updateDescription(int roomId, Map<String, dynamic> descriptionData) async {
    try {
      debugPrint('📝 [DESCRIPTION] 방 소개 설정 시작 - roomId: $roomId');
      debugPrint('📦 [DESCRIPTION] 요청 데이터: $descriptionData');

      final response = await http.patch(
        Uri.parse('$baseUrl/$roomId/description'),
        headers: await _getHeaders(),
        body: json.encode(descriptionData),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 [DESCRIPTION] 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ [DESCRIPTION] 방 소개 설정 성공');
        return true;
      } else {
        debugPrint('❌ [DESCRIPTION] 방 소개 설정 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [DESCRIPTION] 방 소개 설정 에러: $e');
      return false;
    }
  }

  /// 8. 심사 요청
  Future<bool> submitReview(int roomId) async {
    try {
      debugPrint('📋 [REVIEW] 심사 요청 시작 - roomId: $roomId');

      final response = await http.post(
        Uri.parse('$baseUrl/$roomId/submit-review'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 [REVIEW] 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ [REVIEW] 심사 요청 성공');
        return true;
      } else {
        debugPrint('❌ [REVIEW] 심사 요청 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [REVIEW] 심사 요청 에러: $e');
      return false;
    }
  }

  /// 9. 사진 순서 변경
  Future<bool> reorderPhotos(int roomId, List<int> photoIds) async {
    try {
      debugPrint('🔄 [PHOTOS] 사진 순서 변경 시작 - roomId: $roomId');

      final response = await http.patch(
        Uri.parse('$baseUrl/$roomId/photos/reorder'),
        headers: await _getHeaders(),
        body: json.encode({'photoIds': photoIds}),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 [PHOTOS] 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ [PHOTOS] 사진 순서 변경 성공');
        return true;
      } else {
        debugPrint('❌ [PHOTOS] 사진 순서 변경 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [PHOTOS] 사진 순서 변경 에러: $e');
      return false;
    }
  }

  /// 10. 사진 삭제
  Future<bool> deletePhoto(int roomId, int photoId) async {
    try {
      debugPrint('🗑️ [PHOTOS] 사진 삭제 시작 - roomId: $roomId, photoId: $photoId');

      final response = await http.delete(
        Uri.parse('$baseUrl/$roomId/photos/$photoId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 [PHOTOS] 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ [PHOTOS] 사진 삭제 성공');
        return true;
      } else {
        debugPrint('❌ [PHOTOS] 사진 삭제 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [PHOTOS] 사진 삭제 에러: $e');
      return false;
    }
  }

  /// 11. 방 정보 조회
  Future<Map<String, dynamic>?> getRoom(int roomId) async {
    try {
      debugPrint('🔍 [ROOM] 방 정보 조회 시작 - roomId: $roomId');

      final response = await http.get(
        Uri.parse('$baseUrl/$roomId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 [ROOM] 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ [ROOM] 방 정보 조회 성공');
        return data['data'];
      } else {
        debugPrint('❌ [ROOM] 방 정보 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [ROOM] 방 정보 조회 에러: $e');
      return null;
    }
  }

  /// 12. 등록 중인 방 목록 조회
  Future<List<Map<String, dynamic>>?> getInProgressRooms() async {
    try {
      debugPrint('📋 [ROOMS] 등록 중인 방 목록 조회 시작');

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 [ROOMS] 응답 상태: ${response.statusCode}');
      debugPrint('📄 [ROOMS] 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ [ROOMS] 방 목록 조회 성공');

        // API 응답 구조: data.rooms 배열
        if (data['data'] != null && data['data']['rooms'] != null && data['data']['rooms'] is List) {
          final rooms = List<Map<String, dynamic>>.from(data['data']['rooms']);
          debugPrint('📊 [ROOMS] 전체 방 개수: ${rooms.length}개');

          // draft 또는 pending_review 상태인 방만 필터링
          final inProgressRooms = rooms.where((room) {
            final status = room['status'];
            debugPrint('🔍 [ROOMS] 방 ID ${room['id']}, status: $status');
            return status == 'draft' || status == 'pending_review';
          }).toList();

          debugPrint('📊 [ROOMS] 등록 중인 방: ${inProgressRooms.length}개');
          return inProgressRooms;
        }
        return [];
      } else {
        debugPrint('❌ [ROOMS] 방 목록 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [ROOMS] 방 목록 조회 에러: $e');
      return null;
    }
  }
}
