import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';
import 'token_service.dart';
import '../config/api_config.dart';
import '../core/exceptions.dart';

/// 방 등록 API 서비스
class RoomService {
  final _apiClient = ApiClient();

  /// 저장된 토큰 확인 (디버깅용)
  Future<void> checkToken() async {
    final accessToken = await TokenService.getAccessToken();
    final refreshToken = await TokenService.getRefreshToken();


    if (accessToken != null) {
    }
  }

  /// Authorization 헤더 가져오기 (자동 갱신 포함)
  Future<Map<String, String>> _getHeaders() async {
    // TokenService를 통해 토큰 가져오기 (자동 갱신 포함)
    final accessToken = await TokenService.getValidAccessToken(autoRefresh: true);

    if (!ApiConfig.isProduction) {
      if (accessToken == null || accessToken.isEmpty) {
        AppLogger.w('⚠️ [AUTH] 액세스 토큰이 없습니다! 로그인을 확인해주세요.');
      }
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${accessToken ?? ''}',
    };
  }

  /// 1. 기본 정보 등록
  Future<Map<String, dynamic>?> createRoom(Map<String, dynamic> roomData) async {
    try {

      final response = await _apiClient.post(
        Uri.parse(ApiConfig.roomsBaseUrl),
        headers: await _getHeaders(),
        body: json.encode(roomData),
      );

      if (response != null) {
        final data = json.decode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      AppLogger.e('❌ [ROOM] 방 등록 에러: $e');
      return null;
    }
  }

  /// 1-1. 기본 정보 수정
  Future<Map<String, dynamic>?> updateRoom(int roomId, Map<String, dynamic> roomData) async {
    try {

      final response = await _apiClient.patch(
        Uri.parse(ApiConfig.roomUrl(roomId)),
        headers: await _getHeaders(),
        body: json.encode(roomData),
      );

      if (response != null) {
        final data = json.decode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      AppLogger.e('❌ [ROOM] 방 수정 에러: $e');
      return null;
    }
  }

  /// 2. 요금 설정
  Future<bool> updatePricing(int roomId, Map<String, dynamic> pricingData) async {
    try {

      final response = await http.patch(
        Uri.parse(ApiConfig.roomPricingUrl(roomId)),
        headers: await _getHeaders(),
        body: json.encode(pricingData),
      ).timeout(ApiConfig.timeout);


      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw const UnauthorizedException();
      } else {
        AppLogger.e('❌ [PRICING] 요금 설정 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      AppLogger.e('❌ [PRICING] 요금 설정 에러: $e');
      return false;
    }
  }

  /// 3. 사진 업로드
  Future<List<Map<String, dynamic>>?> uploadPhotos(int roomId, List<XFile> photos) async {
    try {

      final accessToken = await TokenService.getValidAccessToken(autoRefresh: true);

      if (!ApiConfig.isProduction) {
      }

      if (accessToken == null || accessToken.isEmpty) {
        if (!ApiConfig.isProduction) {
          AppLogger.w('⚠️ [PHOTOS] 액세스 토큰이 없습니다!');
        }
        return null;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.roomPhotosUrl(roomId)),
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
      }

      final streamedResponse = await request.send().timeout(Duration(seconds: ApiConfig.timeoutSeconds * 3));
      final response = await http.Response.fromStream(streamedResponse);


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']['photoUrls']);
      } else if (response.statusCode == 401) {
        throw const UnauthorizedException();
      } else {
        AppLogger.e('❌ [PHOTOS] 사진 업로드 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      AppLogger.e('❌ [PHOTOS] 사진 업로드 에러: $e');
      return null;
    }
  }

  /// 4. 편의시설 설정
  Future<bool> updateAmenities(int roomId, Map<String, dynamic> amenitiesData) async {
    try {

      final response = await http.patch(
        Uri.parse(ApiConfig.roomAmenitiesUrl(roomId)),
        headers: await _getHeaders(),
        body: json.encode(amenitiesData),
      ).timeout(ApiConfig.timeout);


      if (response.statusCode == 200) {
        return true;
      } else {
        AppLogger.e('❌ [AMENITIES] 편의시설 설정 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      AppLogger.e('❌ [AMENITIES] 편의시설 설정 에러: $e');
      return false;
    }
  }

  /// 5. 이지스테이 관리 서비스 설정 (EZ Service)
  Future<bool> updateEzServices(int roomId, Map<String, dynamic> servicesData) async {
    try {

      final response = await http.patch(
        Uri.parse(ApiConfig.roomEzServicesUrl(roomId)),
        headers: await _getHeaders(),
        body: json.encode(servicesData),
      ).timeout(ApiConfig.timeout);


      if (response.statusCode == 200) {
        return true;
      } else {
        AppLogger.e('❌ [EZ_SERVICES] 이지스테이 관리 서비스 설정 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      AppLogger.e('❌ [EZ_SERVICES] 이지스테이 관리 서비스 설정 에러: $e');
      return false;
    }
  }

  /// 6. 청소도구 이미지 업로드
  Future<String?> uploadCleaningToolImage(int roomId, XFile image) async {
    try {

      final accessToken = await TokenService.getValidAccessToken(autoRefresh: true);

      if (!ApiConfig.isProduction) {
      }

      if (accessToken == null || accessToken.isEmpty) {
        if (!ApiConfig.isProduction) {
          AppLogger.w('⚠️ [CLEANING] 액세스 토큰이 없습니다!');
        }
        return null;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.roomCleaningToolUrl(roomId)),
      );

      request.headers['Authorization'] = 'Bearer $accessToken';

      final bytes = await image.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: image.name,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(Duration(seconds: ApiConfig.timeoutSeconds * 3));
      final response = await http.Response.fromStream(streamedResponse);


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['imageUrl'];
      } else {
        AppLogger.e('❌ [CLEANING] 청소도구 이미지 업로드 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      AppLogger.e('❌ [CLEANING] 청소도구 이미지 업로드 에러: $e');
      return null;
    }
  }

  /// 7. 방 소개 및 설명
  Future<bool> updateDescription(int roomId, Map<String, dynamic> descriptionData) async {
    try {

      final response = await _apiClient.patch(
        Uri.parse(ApiConfig.roomDescriptionUrl(roomId)),
        headers: await _getHeaders(),
        body: json.encode(descriptionData),
      );

      if (response != null) {
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.e('❌ [DESCRIPTION] 방 소개 설정 에러: $e');
      return false;
    }
  }

  /// 8. 심사 요청
  Future<bool> submitReview(int roomId) async {
    try {

      final response = await _apiClient.post(
        Uri.parse(ApiConfig.roomSubmitReviewUrl(roomId)),
        headers: await _getHeaders(),
      );

      if (response != null) {
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.e('❌ [REVIEW] 심사 요청 에러: $e');
      return false;
    }
  }

  /// 9. 사진 순서 변경
  Future<bool> reorderPhotos(int roomId, List<int> photoIds) async {
    try {

      final response = await http.patch(
        Uri.parse(ApiConfig.roomPhotosReorderUrl(roomId)),
        headers: await _getHeaders(),
        body: json.encode({'photoIds': photoIds}),
      ).timeout(ApiConfig.timeout);


      if (response.statusCode == 200) {
        return true;
      } else {
        AppLogger.e('❌ [PHOTOS] 사진 순서 변경 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      AppLogger.e('❌ [PHOTOS] 사진 순서 변경 에러: $e');
      return false;
    }
  }

  /// 10. 사진 삭제
  Future<bool> deletePhoto(int roomId, int photoId) async {
    try {

      final response = await http.delete(
        Uri.parse(ApiConfig.roomPhotoDeleteUrl(roomId, photoId)),
        headers: await _getHeaders(),
      ).timeout(ApiConfig.timeout);


      if (response.statusCode == 200) {
        return true;
      } else {
        AppLogger.e('❌ [PHOTOS] 사진 삭제 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      AppLogger.e('❌ [PHOTOS] 사진 삭제 에러: $e');
      return false;
    }
  }

  /// 11. 방 정보 조회
  Future<Map<String, dynamic>?> getRoom(int roomId) async {
    try {

      final response = await _apiClient.get(
        Uri.parse(ApiConfig.roomUrl(roomId)),
        headers: await _getHeaders(),
      );

      if (response != null) {
        final data = json.decode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      AppLogger.e('❌ [ROOM] 방 정보 조회 에러: $e');
      return null;
    }
  }

  /// 12. 등록 중인 방 목록 조회 (호스트용)
  Future<List<Map<String, dynamic>>?> getInProgressRooms() async {
    try {

      final response = await http.get(
        Uri.parse(ApiConfig.roomsBaseUrl),
        headers: await _getHeaders(),
      ).timeout(ApiConfig.timeout);


      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // API 응답 구조: data.rooms 배열
        if (data['data'] != null && data['data']['rooms'] != null && data['data']['rooms'] is List) {
          final rooms = List<Map<String, dynamic>>.from(data['data']['rooms']);

          // draft 상태인 방만 필터링 (pending_review는 심사 요청 완료 상태이므로 제외)
          final inProgressRooms = rooms.where((room) {
            final status = room['status'];
            return status == 'draft';
          }).toList();

          return inProgressRooms;
        }
        return [];
      } else {
        AppLogger.e('❌ [ROOMS] 방 목록 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      AppLogger.e('❌ [ROOMS] 방 목록 조회 에러: $e');
      return null;
    }
  }

  /// 13. 공개된 방 목록 조회 (게스트용 - 인증 불필요)
  Future<List<Map<String, dynamic>>?> getPublishedRooms() async {
    try {

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/rooms'),
      ).timeout(ApiConfig.timeout);


      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // API 응답 구조: data 배열 직접 반환
        if (data['data'] != null && data['data'] is List) {
          final rooms = List<Map<String, dynamic>>.from(data['data']);

          // 위도/경도 로그 출력 (디버깅용)
          for (var room in rooms) {
          }

          return rooms;
        }
        return [];
      } else {
        AppLogger.e('❌ [ROOMS] 공개된 방 목록 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      AppLogger.e('❌ [ROOMS] 공개된 방 목록 조회 에러: $e');
      return null;
    }
  }

  /// 14. 지도 영역 기반 방 검색 (게스트용 - 인증 불필요)
  Future<Map<String, dynamic>?> getRoomsByMapBounds({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
    int? zoom,
    String? checkIn,
    String? checkOut,
  }) async {
    try {
      if (zoom != null) {
      }
      if (checkIn != null && checkOut != null) {
      }

      final queryParams = {
        'swLat': swLat.toString(),
        'swLng': swLng.toString(),
        'neLat': neLat.toString(),
        'neLng': neLng.toString(),
      };

      // 줌 레벨이 있으면 추가
      if (zoom != null) {
        queryParams['zoom'] = zoom.toString();
      }

      // 체크인/체크아웃 날짜가 있으면 추가
      if (checkIn != null) {
        queryParams['checkIn'] = checkIn;
      }
      if (checkOut != null) {
        queryParams['checkOut'] = checkOut;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/rooms/map').replace(
        queryParameters: queryParams,
      );


      final response = await http.get(uri).timeout(ApiConfig.timeout);


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        AppLogger.e('❌ [MAP] 방 검색 실패: ${response.statusCode}');
        try {
          final errorData = json.decode(response.body);
          AppLogger.e('❌ [MAP] 에러: ${errorData['error']['message']}');
        } catch (e) {
          AppLogger.e('❌ [MAP] 에러 응답 파싱 실패: ${response.body}');
        }
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.e('❌ [MAP] 방 검색 에러: $e');
      AppLogger.e('❌ [MAP] 스택트레이스: $stackTrace');
      return null;
    }
  }
}
