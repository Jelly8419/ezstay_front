import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/room.dart';
import '../models/search_filters.dart';
import 'api_client.dart';
import '../config/api_config.dart';

/// 게스트용 방 검색 및 조회 서비스
class GuestRoomService {
  final ApiClient _apiClient;

  GuestRoomService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// 지도 범위 내의 방 목록 조회 (필터 적용)
  ///
  /// [bounds]: 지도 경계 (남서쪽, 북동쪽 좌표)
  /// [filters]: 검색 필터
  /// [page]: 페이지 번호 (기본 1)
  /// [limit]: 페이지당 항목 수 (기본 10)
  Future<List<Room>> searchRooms({
    required MapBounds bounds,
    SearchFilters? filters,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'swLat': bounds.southwest.latitude.toString(),
        'swLng': bounds.southwest.longitude.toString(),
        'neLat': bounds.northeast.latitude.toString(),
        'neLng': bounds.northeast.longitude.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
      };

      // 필터 추가
      if (filters != null) {
        if (filters.dateRange != null) {
          queryParams['startDate'] = filters.dateRange!.startDate
              .toIso8601String();
          queryParams['endDate'] = filters.dateRange!.endDate.toIso8601String();
        }

        if (filters.buildingTypes.isNotEmpty) {
          queryParams['buildingTypes'] = filters.buildingTypes.join(',');
        }

        if (filters.bedroomCounts.isNotEmpty) {
          queryParams['bedroomCounts'] = filters.bedroomCounts.join(',');
        }

        if (!filters.priceRange.isDefault) {
          queryParams['minPrice'] = (filters.priceRange.minPrice * 10000)
              .toString();
          if (filters.priceRange.maxPrice != null) {
            queryParams['maxPrice'] = (filters.priceRange.maxPrice! * 10000)
                .toString();
          }
        }

        if (filters.otherOptions.contains(OtherOptions.parking)) {
          queryParams['parking'] = 'true';
        }
        // 백엔드 필드 없어서 주석 처리
        // if (filters.otherOptions.contains(OtherOptions.subway)) {
        //   queryParams['subway'] = 'true';
        // }
        // if (filters.otherOptions.contains(OtherOptions.pet)) {
        //   queryParams['pet'] = 'true';
        // }
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/guest/rooms/search',
      ).replace(queryParameters: queryParams);

      final response = await _apiClient.get(uri, showErrorDialog: false);

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> jsonData =
            json.decode(response.body) as Map<String, dynamic>;
        final List<dynamic> data = jsonData['data'] as List<dynamic>;
        return data
            .map((json) => Room.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // API 실패 시 빈 배열 반환
      return [];
    } catch (e) {
      debugPrint('Failed to search rooms: $e');
      return [];
    }
  }

  /// 특정 방 상세 정보 조회
  Future<Room?> getRoomDetail(int roomId) async {
    try {
      final uri = Uri.parse(ApiConfig.getRoomById(roomId));
      final response = await _apiClient.get(uri);

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> jsonData =
            json.decode(response.body) as Map<String, dynamic>;
        final Map<String, dynamic> roomData =
            jsonData['data'] as Map<String, dynamic>;

        // 🔍 상세 파싱 로그 (필드별 타입 확인)
        debugPrint('🔍 [Room $roomId] 필드 검사 시작...');
        _logFieldTypes(roomData);

        try {
          return Room.fromJson(roomData);
        } catch (parseError, stackTrace) {
          debugPrint('❌ Room.fromJson 파싱 에러: $parseError');
          debugPrint('📍 스택 트레이스:\n$stackTrace');
          rethrow;
        }
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint('Failed to get room detail: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// 필드별 타입 로깅 (디버깅용)
  void _logFieldTypes(Map<String, dynamic> data) {
    final intFields = [
      'id',
      'roomCount',
      'bathroomCount',
      'livingRoomCount',
      'kitchenCount',
      'dailyRent',
      'dailyMaintenanceFee',
      'cleaningFee',
      'deposit',
      'minContractWeeks',
      'longTermWeeks',
      'longTermDiscount',
      'quickMoveIn',
      'quickMoveInDiscount',
      'maxGuests',
    ];

    for (final field in intFields) {
      final value = data[field];
      if (value == null) {
        debugPrint('  ⚠️ $field: null');
      } else {
        debugPrint('  ✓ $field: $value (${value.runtimeType})');
      }
    }

    // photos 배열 검사
    if (data['photos'] != null) {
      final photos = data['photos'] as List<dynamic>;
      debugPrint('  📷 photos: ${photos.length}개');
      for (var i = 0; i < photos.length; i++) {
        final photo = photos[i] as Map<String, dynamic>;
        debugPrint(
            '    [$i] order: ${photo['order']} (${photo['order']?.runtimeType})');
      }
    }

    // availableRentalItems 검사
    if (data['availableRentalItems'] != null) {
      final rental = data['availableRentalItems'] as Map<String, dynamic>;
      debugPrint('  🛒 availableRentalItems:');
      for (final category in ['hairDryers', 'beddingSets', 'amenityKits', 'towelSets']) {
        if (rental[category] != null) {
          final items = rental[category] as List<dynamic>;
          debugPrint('    - $category: ${items.length}개');
          for (var i = 0; i < items.length; i++) {
            final item = items[i] as Map<String, dynamic>;
            debugPrint(
                '      [$i] id: ${item['id']} (${item['id']?.runtimeType})');
          }
        } else {
          debugPrint('    - $category: null');
        }
      }
    }
  }
}

/// 지도 경계 모델
class MapBounds {
  final LatLng southwest; // 남서쪽 좌표
  final LatLng northeast; // 북동쪽 좌표

  const MapBounds({required this.southwest, required this.northeast});

  /// 경계 내에 좌표가 포함되는지 확인
  bool contains(LatLng point) {
    return point.latitude >= southwest.latitude &&
        point.latitude <= northeast.latitude &&
        point.longitude >= southwest.longitude &&
        point.longitude <= northeast.longitude;
  }
}

/// 위도/경도 모델
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng({required this.latitude, required this.longitude});

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}
