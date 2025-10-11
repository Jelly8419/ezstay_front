import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/room.dart';
import '../models/search_filters.dart';
import '../services/guest_room_service.dart';
import '../widgets/kakao_map_web.dart';
import '../widgets/property_card.dart';
import '../widgets/search_filter_bar.dart';
import '../constants/app_constants.dart';

/// 지도 기반 숙소 검색 화면
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final GuestRoomService _roomService = GuestRoomService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<Room> _rooms = [];
  List<Room> _filteredRooms = [];
  Room? _selectedRoom;
  SearchFilters _filters = const SearchFilters();
  bool _isLoading = true;
  bool _showPropertyList = true;

  // 서울 시청 기본 좌표
  final double _initialLat = 37.5665;
  final double _initialLng = 126.9780;
  final double _initialZoom = 12.0;

  @override
  void initState() {
    super.initState();
    _loadSavedFilters();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);

    try {
      // 서울 전역을 커버하는 범위로 검색
      final bounds = MapBounds(
        southwest: const LatLng(latitude: 37.4, longitude: 126.7),
        northeast: const LatLng(latitude: 37.7, longitude: 127.2),
      );

      final rooms = await _roomService.searchRooms(
        bounds: bounds,
        filters: _filters,
        limit: 50,
      );

      setState(() {
        _rooms = rooms;
        _filteredRooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load rooms: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 저장된 필터 로드
  Future<void> _loadSavedFilters() async {
    try {
      final savedFiltersJson = await _storage.read(key: 'guest_search_filters');
      if (savedFiltersJson != null) {
        final filtersMap = json.decode(savedFiltersJson) as Map<String, dynamic>;
        setState(() {
          _filters = SearchFilters.fromJson(filtersMap);
        });
      }
    } catch (e) {
      debugPrint('Failed to load saved filters: $e');
    }
    _loadRooms();
  }

  /// 필터 저장
  Future<void> _saveFilters(SearchFilters filters) async {
    try {
      final filtersJson = json.encode(filters.toJson());
      await _storage.write(key: 'guest_search_filters', value: filtersJson);
    } catch (e) {
      debugPrint('Failed to save filters: $e');
    }
  }

  void _onFilterChanged(SearchFilters newFilters) {
    setState(() {
      _filters = newFilters;
    });
    _saveFilters(newFilters);
    _loadRooms();
  }

  void _onRoomSelected(Room? room) {
    setState(() {
      _selectedRoom = room;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('숙소 검색'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 검색 필터 바
          SearchFilterBar(
            filters: _filters,
            onFiltersChanged: _onFilterChanged,
          ),

          // 지도 및 리스트 영역
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      // 왼쪽: 매물 리스트
                      if (_showPropertyList && _filteredRooms.isNotEmpty)
                        Container(
                          width: 400,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              right: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: _buildPropertyList(),
                        ),

                      // 오른쪽: 지도
                      Expanded(
                        child: Stack(
                          children: [
                            _buildMap(),

                            // 결과 없음 메시지
                            if (_filteredRooms.isEmpty)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    '조건에 일치하는 결과가 없습니다.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredRooms.length,
      itemBuilder: (context, index) {
        final room = _filteredRooms[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PropertyCard(
            room: room,
            isSelected: _selectedRoom?.id == room.id,
            onTap: () => _onRoomSelected(room),
            onHover: (isHovered) {
              if (isHovered) {
                _onRoomSelected(room);
              } else {
                _onRoomSelected(null);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildMap() {
    if (kIsWeb) {
      // KakaoMapWeb에서 요구하는 형식으로 rooms 데이터 변환 (가격 정보 포함)
      final roomsForMap = _filteredRooms.map((room) {
        return {
          'id': room.id,
          'latitude': room.latitude,
          'longitude': room.longitude,
          'roomName': room.name,
          'weeklyPrice': room.weeklyPrice,
        };
      }).toList();

      return KakaoMapWeb(
        rooms: roomsForMap,
        onMarkerTap: (roomData) {
          final roomId = roomData['id'] as int;
          final room = _filteredRooms.firstWhere(
            (r) => r.id == roomId,
            orElse: () => _filteredRooms.first,
          );
          _onRoomSelected(room);
        },
        onZoomChanged: (zoomLevel) {
          // 줌 레벨이 10 이상이면 리스트 숨김
          setState(() {
            _showPropertyList = zoomLevel < 10;
          });
        },
      );
    } else {
      // 모바일 버전은 나중에 구현
      return Center(
        child: Text(
          '모바일 지도는 준비 중입니다.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }
  }
}
