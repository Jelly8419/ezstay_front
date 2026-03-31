import '../models/search_filters.dart';

/// 지도 화면 매물 필터링 유틸리티
class MapFilterUtils {
  MapFilterUtils._();

  /// 지도 bounds + 검색 필터 적용 (지도용, 클러스터 필터링 제외)
  static List<Map<String, dynamic>> filterRooms({
    required List<Map<String, dynamic>> rooms,
    required SearchFilters filters,
    double? swLat,
    double? swLng,
    double? neLat,
    double? neLng,
    int? minPrice,
    int? maxPrice,
  }) {
    // 1단계: 지도 bounds 내 매물 필터링
    final visibleRooms = rooms.where((room) {
      if (room['latitude'] == null || room['longitude'] == null) return false;

      final lat = double.tryParse(room['latitude'].toString());
      final lng = double.tryParse(room['longitude'].toString());

      if (lat == null || lng == null) return false;

      // bounds가 아직 설정되지 않았으면 모두 표시 (초기 로딩)
      if (swLat == null || swLng == null || neLat == null || neLng == null) {
        return true;
      }

      return lat >= swLat && lat <= neLat && lng >= swLng && lng <= neLng;
    }).toList();

    // 2단계: 검색 필터 적용
    return visibleRooms.where((room) {
      // 건물 유형 필터
      if (filters.buildingTypes.isNotEmpty) {
        final buildingType = room['buildingType']?.toString() ?? '';
        if (!filters.buildingTypes.contains(buildingType)) return false;
      }

      // 방 개수 필터
      if (filters.bedroomCounts.isNotEmpty) {
        final roomCount = room['roomCount'] as int? ?? 1;
        if (filters.bedroomCounts.contains(3)) {
          if (roomCount < 3 && !filters.bedroomCounts.contains(roomCount)) {
            return false;
          }
        } else {
          if (!filters.bedroomCounts.contains(roomCount)) return false;
        }
      }

      // 가격 범위 필터 (SearchFilters)
      if (!filters.priceRange.isDefault) {
        final dailyRent = room['dailyRent'] as int? ?? 0;
        if (!filters.priceRange.isInRange(dailyRent)) return false;
      }

      // 가격 범위 필터 (guest_home_page 전달값, 주간 임대료 기준)
      if (minPrice != null || maxPrice != null) {
        final weeklyRent = (room['dailyRent'] as int? ?? 0) * 7;
        if (minPrice != null && weeklyRent < minPrice) return false;
        if (maxPrice != null && weeklyRent > maxPrice) return false;
      }

      // 주차 가능 필터
      if (filters.otherOptions.contains(OtherOptions.parking)) {
        final parking = room['parkingAvailable'] as bool? ?? false;
        if (!parking) return false;
      }

      return true;
    }).toList();
  }

  /// 리스트용 필터링 (클러스터 필터링 우선 적용)
  static List<Map<String, dynamic>> filterRoomsForList({
    required List<Map<String, dynamic>> rooms,
    required SearchFilters filters,
    required bool filteredByCluster,
    required List<int> clusterRoomIds,
    double? swLat,
    double? swLng,
    double? neLat,
    double? neLng,
    int? minPrice,
    int? maxPrice,
  }) {
    if (filteredByCluster && clusterRoomIds.isNotEmpty) {
      return rooms.where((room) {
        final roomId = room['id'] as int?;
        return roomId != null && clusterRoomIds.contains(roomId);
      }).toList();
    }

    return filterRooms(
      rooms: rooms,
      filters: filters,
      swLat: swLat,
      swLng: swLng,
      neLat: neLat,
      neLng: neLng,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }
}
