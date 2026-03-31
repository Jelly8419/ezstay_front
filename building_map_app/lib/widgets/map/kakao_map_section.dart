import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../kakao_map_web.dart';
import '../../core/theme/app_text_styles.dart';

/// 카카오맵 위젯 래퍼 — 마커/bounds 이벤트를 콜백으로 위임
class KakaoMapSection extends StatelessWidget {
  final KakaoMapWebController controller;
  final List<Map<String, dynamic>> rooms;
  final bool isDesktop;
  final bool isMobile;

  /// 마커 클릭 콜백 (roomId: -1 = 선택 해제)
  final void Function(int roomId, Map<String, dynamic> roomData) onMarkerTap;

  /// 지도 영역 변경 콜백
  final void Function(
    double swLat,
    double swLng,
    double neLat,
    double neLng,
    int zoom,
  )
  onBoundsChanged;

  const KakaoMapSection({
    super.key,
    required this.controller,
    required this.rooms,
    required this.isDesktop,
    required this.isMobile,
    required this.onMarkerTap,
    required this.onBoundsChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // dailyRent를 weeklyRent로 변환 (1000원 단위 반올림)
      final roomsForKakaoMap = rooms.map((roomData) {
        final dailyRent = roomData['dailyRent'] ?? 0;
        final weeklyRent = ((dailyRent * 7) / 1000).round() * 1000;
        return {
          'id': roomData['id'],
          'latitude': roomData['latitude'],
          'longitude': roomData['longitude'],
          'roomName': roomData['roomName'],
          'weeklyRent': weeklyRent,
          'isAvailable': roomData['isAvailable'] ?? true,
        };
      }).toList();

      return KakaoMapWeb(
        controller: controller,
        rooms: roomsForKakaoMap,
        onMarkerTap: (roomData) {
          final roomId = roomData['id'] as int;
          onMarkerTap(roomId, roomData);
        },
        onBoundsChanged: (swLat, swLng, neLat, neLng, zoom) {
          onBoundsChanged(swLat, swLng, neLat, neLng, zoom);
        },
      );
    } else {
      return Center(
        child: Text(
          '모바일 지도는 준비 중입니다.',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
        ),
      );
    }
  }
}
