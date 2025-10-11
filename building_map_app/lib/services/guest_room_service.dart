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
          queryParams['startDate'] = filters.dateRange!.startDate.toIso8601String();
          queryParams['endDate'] = filters.dateRange!.endDate.toIso8601String();
        }

        if (filters.buildingTypes.isNotEmpty) {
          queryParams['buildingTypes'] = filters.buildingTypes.join(',');
        }

        if (filters.bedroomCounts.isNotEmpty) {
          queryParams['bedroomCounts'] = filters.bedroomCounts.join(',');
        }

        if (!filters.priceRange.isDefault) {
          queryParams['minPrice'] = (filters.priceRange.minPrice * 10000).toString();
          if (filters.priceRange.maxPrice != null) {
            queryParams['maxPrice'] = (filters.priceRange.maxPrice! * 10000).toString();
          }
        }

        if (filters.otherOptions.contains(OtherOptions.parking)) {
          queryParams['parking'] = 'true';
        }
        if (filters.otherOptions.contains(OtherOptions.subway)) {
          queryParams['subway'] = 'true';
        }
        if (filters.otherOptions.contains(OtherOptions.pet)) {
          queryParams['pet'] = 'true';
        }
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/guest/rooms/search').replace(
        queryParameters: queryParams,
      );

      final response = await _apiClient.get(uri, showErrorDialog: false);

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body) as Map<String, dynamic>;
        final List<dynamic> data = jsonData['data'] as List<dynamic>;
        return data.map((json) => Room.fromJson(json as Map<String, dynamic>)).toList();
      }

      // API 실패 시 더미 데이터 반환 (개발 중)
      if (!ApiConfig.isProduction) {
        return _filterDummyRooms(bounds, filters);
      }
      return _filterDummyRooms(bounds, filters); // 개발 중이므로 항상 더미 데이터 반환
    } catch (e) {
      debugPrint('Failed to search rooms: $e');
      // API 실패 시 더미 데이터 반환 (개발 중)
      return _filterDummyRooms(bounds, filters);
    }
  }

  /// 특정 방 상세 정보 조회
  Future<Room?> getRoomDetail(int roomId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/guest/rooms/$roomId');
      final response = await _apiClient.get(uri);

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body) as Map<String, dynamic>;
        return Room.fromJson(jsonData['data'] as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      debugPrint('Failed to get room detail: $e');
      return null;
    }
  }

  /// 더미 데이터 필터링 (개발용)
  List<Room> _filterDummyRooms(MapBounds bounds, SearchFilters? filters) {
    // 나중에 dummy_rooms.dart에서 가져올 예정
    List<Room> rooms = _getDummyRooms();

    // 지도 범위 필터링
    rooms = rooms.where((room) {
      return room.latitude >= bounds.southwest.latitude &&
          room.latitude <= bounds.northeast.latitude &&
          room.longitude >= bounds.southwest.longitude &&
          room.longitude <= bounds.northeast.longitude;
    }).toList();

    // 검색 필터 적용
    if (filters != null) {
      if (filters.buildingTypes.isNotEmpty) {
        rooms = rooms.where((room) => filters.buildingTypes.contains(room.buildingType)).toList();
      }

      if (filters.bedroomCounts.isNotEmpty) {
        rooms = rooms.where((room) {
          if (filters.bedroomCounts.contains(3)) {
            // 3개 이상
            return room.bedrooms >= 3 || filters.bedroomCounts.contains(room.bedrooms);
          }
          return filters.bedroomCounts.contains(room.bedrooms);
        }).toList();
      }

      if (!filters.priceRange.isDefault) {
        rooms = rooms.where((room) {
          return filters.priceRange.isInRange(room.weeklyPrice);
        }).toList();
      }

      if (filters.otherOptions.contains(OtherOptions.parking)) {
        rooms = rooms.where((room) => room.isParkingAvailable).toList();
      }

      if (filters.otherOptions.contains(OtherOptions.subway)) {
        rooms = rooms.where((room) => room.isNearSubway).toList();
      }

      if (filters.otherOptions.contains(OtherOptions.pet)) {
        rooms = rooms.where((room) => room.isPetFriendly).toList();
      }
    }

    return rooms;
  }

  /// 더미 데이터 생성 (개발용)
  List<Room> _getDummyRooms() {
    return [
      Room(
        id: 1,
        name: '개봉역 바로 앞!',
        address: '서울시 구로구 개봉동',
        addressDetail: '123-45',
        latitude: 37.4990,
        longitude: 126.8566,
        buildingType: BuildingTypes.apartment,
        bedrooms: 1,
        bathrooms: 1,
        beds: 1,
        maxGuests: 2,
        weeklyPrice: 240000,
        monthlyPrice: 800000,
        photos: ['https://via.placeholder.com/400x300'],
        amenities: ['WiFi', '에어컨', '세탁기'],
        freeServices: ['청소도구'],
        isParkingAvailable: false,
        isPetFriendly: false,
        isNearSubway: true,
        discount: null,
        description: '개봉역 바로 앞 편리한 위치',
        hostName: '김호스트',
        hostId: 1,
      ),
      Room(
        id: 2,
        name: '넓은 2인용 방',
        address: '서울시 구로구 구로동',
        addressDetail: '234-56',
        latitude: 37.4956,
        longitude: 126.8871,
        buildingType: BuildingTypes.officetel,
        bedrooms: 2,
        bathrooms: 1,
        beds: 2,
        maxGuests: 4,
        weeklyPrice: 570000,
        monthlyPrice: 2000000,
        photos: ['https://via.placeholder.com/400x300'],
        amenities: ['WiFi', '에어컨', '주차'],
        freeServices: ['청소도구', '세탁'],
        isParkingAvailable: true,
        isPetFriendly: false,
        isNearSubway: false,
        discount: 10,
        description: '가족 단위 손님에게 적합',
        hostName: '이호스트',
        hostId: 2,
      ),
      Room(
        id: 3,
        name: '분사우겐 즐을 수있숙',
        address: '서울시 영등포구 영등포동',
        addressDetail: '345-67',
        latitude: 37.5173,
        longitude: 126.9074,
        buildingType: BuildingTypes.house,
        bedrooms: 1,
        bathrooms: 1,
        beds: 1,
        maxGuests: 2,
        weeklyPrice: 220000,
        monthlyPrice: 750000,
        photos: ['https://via.placeholder.com/400x300'],
        amenities: ['WiFi', '주방'],
        freeServices: [],
        isParkingAvailable: false,
        isPetFriendly: true,
        isNearSubway: false,
        discount: null,
        description: '조용하고 깨끗한 원룸',
        hostName: '박호스트',
        hostId: 3,
      ),
      Room(
        id: 4,
        name: 'Revive',
        address: '서울시 강남구 역삼동',
        addressDetail: '456-78',
        latitude: 37.4979,
        longitude: 127.0276,
        buildingType: BuildingTypes.hotel,
        bedrooms: 1,
        bathrooms: 1,
        beds: 2,
        maxGuests: 3,
        weeklyPrice: 480000,
        monthlyPrice: 1600000,
        photos: ['https://via.placeholder.com/400x300'],
        amenities: ['WiFi', '에어컨', '주방', '세탁기'],
        freeServices: ['청소도구', '세탁'],
        isParkingAvailable: true,
        isPetFriendly: false,
        isNearSubway: true,
        discount: null,
        description: '강남역 근처 호텔형 숙소',
        hostName: '최호스트',
        hostId: 4,
      ),
      Room(
        id: 5,
        name: '멍아리개 충은 숙소',
        address: '서울시 마포구 서교동',
        addressDetail: '567-89',
        latitude: 37.5563,
        longitude: 126.9224,
        buildingType: BuildingTypes.apartment,
        bedrooms: 2,
        bathrooms: 2,
        beds: 3,
        maxGuests: 4,
        weeklyPrice: 420000,
        monthlyPrice: 1400000,
        photos: ['https://via.placeholder.com/400x300'],
        amenities: ['WiFi', '에어컨', '주방'],
        freeServices: ['청소도구'],
        isParkingAvailable: false,
        isPetFriendly: true,
        isNearSubway: true,
        discount: 15,
        description: '반려동물 동반 가능한 넓은 아파트',
        hostName: '정호스트',
        hostId: 5,
      ),
    ];
  }
}

/// 지도 경계 모델
class MapBounds {
  final LatLng southwest; // 남서쪽 좌표
  final LatLng northeast; // 북동쪽 좌표

  const MapBounds({
    required this.southwest,
    required this.northeast,
  });

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

  const LatLng({
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}
