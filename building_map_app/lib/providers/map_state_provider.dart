import 'package:flutter/foundation.dart';

/// 지도 검색 화면 상태 보존용 Provider
///
/// 방 상세 페이지에서 뒤로가기 시 이전 지도 위치/줌/선택 방을 복원합니다.
class MapStateProvider extends ChangeNotifier {
  double? swLat;
  double? swLng;
  double? neLat;
  double? neLng;
  int? zoomLevel;
  int? selectedRoomId;

  bool get hasSavedState => swLat != null && neLat != null;

  void save({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
    required int zoomLevel,
    int? selectedRoomId,
  }) {
    this.swLat = swLat;
    this.swLng = swLng;
    this.neLat = neLat;
    this.neLng = neLng;
    this.zoomLevel = zoomLevel;
    this.selectedRoomId = selectedRoomId;
  }

  void clear() {
    swLat = swLng = neLat = neLng = null;
    zoomLevel = null;
    selectedRoomId = null;
  }
}
