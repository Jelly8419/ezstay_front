import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/room.dart';
import '../../services/map_interaction_coordinator.dart';
import '../../utils/contract_utils.dart';
import '../../widgets/property_card.dart';

/// 데스크톱 좌측 매물 리스트 패널
class PropertyListPanel extends StatelessWidget {
  final List<Map<String, dynamic>> filteredRooms;
  final int? selectedRoomId;
  final ScrollController scrollController;

  /// 방 카드 탭 콜백 (지도 상태 저장 + 라우팅은 내부 처리)
  final void Function(int roomId) onSaveMapState;

  /// 호버/언호버 콜백
  final void Function(Room? room) onRoomHover;

  const PropertyListPanel({
    super.key,
    required this.filteredRooms,
    required this.selectedRoomId,
    required this.scrollController,
    required this.onSaveMapState,
    required this.onRoomHover,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final coordinator = Provider.of<MapInteractionCoordinator>(
          context,
          listen: false,
        );
        if (notification is ScrollStartNotification) {
          coordinator.enterMode(InteractionMode.listScrolling);
        } else if (notification is ScrollEndNotification) {
          coordinator.exitMode();
        }
        return true;
      },
      child: Listener(
        onPointerDown: (_) {},
        onPointerMove: (_) {},
        onPointerUp: (_) {},
        behavior: HitTestBehavior.opaque,
        child: ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: filteredRooms.length,
          itemBuilder: (context, index) {
            final roomData = filteredRooms[index];

            final photosData = roomData['photos'] as List<dynamic>?;
            final photos = photosData != null && photosData.isNotEmpty
                ? photosData.map((photo) {
                    final relativeUrl = photo['url'] ?? '';
                    final fullUrl = ContractUtils.getFullImageUrl(relativeUrl);
                    return {'url': fullUrl, 'order': photo['order'] ?? 0};
                  }).toList()
                : <Map<String, dynamic>>[];

            final discounts = roomData['discounts'] as Map<String, dynamic>?;

            final roomJson = {
              'id': roomData['id'] ?? 0,
              'roomName': roomData['roomName'] ?? '',
              'address': roomData['address'] ?? '',
              'latitude': roomData['latitude'] ?? 0.0,
              'longitude': roomData['longitude'] ?? 0.0,
              'area': '0',
              'floor': '1',
              'buildingType': roomData['buildingType'] ?? '오피스텔',
              'parkingAvailable': false,
              'elevatorAvailable': false,
              'roomCount': roomData['roomCount'] ?? 1,
              'bathroomCount': roomData['bathroomCount'] ?? 1,
              'livingRoomCount': 1,
              'kitchenCount': 1,
              'isDuplex': false,
              'dailyRent': roomData['dailyRent'] ?? 0,
              'discounts': discounts,
              'dailyMaintenanceFee': 0,
              'includeElectricity': false,
              'includeWater': false,
              'includeGas': false,
              'includeInternet': false,
              'cleaningFee': 0,
              'minContractDays': 28,
              'refundPolicy': 'moderate',
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
              'photos': photos,
              'isNearSubway': false,
              'isAvailable': roomData['isAvailable'] ?? true,
              'hostName': '호스트',
              'hostId': 1,
              'status': 'published',
            };

            final room = Room.fromJson(roomJson);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PropertyCard(
                room: room,
                isSelected: selectedRoomId == room.id,
                onTap: () {
                  onSaveMapState(room.id);
                  context.go('/guest/room/detail/${room.id}');
                },
                onHover: (isHovered) {
                  onRoomHover(isHovered ? room : null);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
