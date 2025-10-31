import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../models/room.dart';
import '../models/search_filters.dart';
import '../services/room_service.dart';
import '../config/api_config.dart';
import '../widgets/kakao_map_web.dart';
import '../widgets/property_card.dart';
import '../widgets/search_filter_bar.dart';
import '../constants/app_constants.dart';
import '../utils/responsive_util.dart';

/// 지도 기반 숙소 검색 화면
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final RoomService _roomService = RoomService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final KakaoMapWebController _mapController = KakaoMapWebController();
  List<Map<String, dynamic>> _roomsForMap = [];
  Room? _selectedRoom;
  SearchFilters _filters = const SearchFilters();
  bool _isLoading = true;

  // 현재 지도의 실제 bounds 추적
  double? _currentSwLat;
  double? _currentSwLng;
  double? _currentNeLat;
  double? _currentNeLng;
  int? _currentZoomLevel; // 현재 줌 레벨 추적

  @override
  void initState() {
    super.initState();
    _loadSavedFilters();
  }

  /// 지도 영역 변경 시 방 검색
  Future<void> _loadRoomsByBounds(
    double swLat,
    double swLng,
    double neLat,
    double neLng, {
    int? zoom,
  }) async {
    try {
      debugPrint('🗺️ [MAP] 지도 영역 변경 - 방 검색 시작');
      debugPrint('🔍 [MAP] 받은 줌 레벨: ${zoom ?? "null"}');

      // 줌 레벨 6 이상이면 리스트 비우기
      if (zoom != null && zoom >= 6) {
        debugPrint('🚫 [MAP] 줌 레벨 $zoom - 리스트 비우기');
        setState(() {
          _roomsForMap = [];
          _selectedRoom = null;
          _isLoading = false;
          _currentZoomLevel = zoom; // 줌 레벨 저장
        });
        return;
      }

      if (zoom != null) {
        debugPrint('✅ [MAP] 줌 레벨 전달됨: $zoom');
      } else {
        debugPrint('⚠️ [MAP] 줌 레벨이 null입니다!');
      }

      // 현재 지도 bounds 및 줌 레벨 저장
      setState(() {
        _currentSwLat = swLat;
        _currentSwLng = swLng;
        _currentNeLat = neLat;
        _currentNeLng = neLng;
        _currentZoomLevel = zoom;
      });

      final result = await _roomService.getRoomsByMapBounds(
        swLat: swLat,
        swLng: swLng,
        neLat: neLat,
        neLng: neLng,
        zoom: zoom,
      );

      if (result != null && result['rooms'] != null) {
        // 썸네일 상대경로를 절대경로로 변환 (호스트 방 등록과 동일한 방식)
        final rooms = List<Map<String, dynamic>>.from(result['rooms']);
        for (var room in rooms) {
          if (room['thumbnail'] != null &&
              room['thumbnail'].toString().startsWith('/')) {
            if (kIsWeb) {
              // 웹 환경: 서버 URL prefix 추가
              room['thumbnail'] = '${ApiConfig.baseUrl}${room['thumbnail']}';
            } else {
              // 모바일/데스크톱: 로컬 경로 (개발 환경)
              // TODO: 프로덕션에서는 서버 URL 사용
              room['thumbnail'] = 'C:\\study${room['thumbnail']}';
            }
          }
        }

        setState(() {
          _roomsForMap = rooms;
          _isLoading = false;
        });
        debugPrint('✅ [MAP] 방 ${_roomsForMap.length}개 로드 완료');
      } else {
        setState(() {
          _roomsForMap = [];
          _isLoading = false;
        });
        debugPrint('⚠️ [MAP] 검색 결과 없음 또는 백엔드 오류');

        // 사용자에게 알림
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('방 목록을 불러오는데 실패했습니다. 백엔드 서버를 확인해주세요.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [MAP] 방 검색 실패: $e');
      setState(() {
        _roomsForMap = [];
        _isLoading = false;
      });
    }
  }

  /// 초기 로드 (지도가 초기화되면 자동으로 bounds_changed 이벤트 발생)
  Future<void> _loadRooms() async {
    // 초기 로딩 상태 해제 (지도가 먼저 렌더링되어야 함)
    setState(() {
      _isLoading = false;
      _roomsForMap = []; // 빈 배열로 시작
    });

    // JavaScript 지도 초기화 후 bounds_changed 이벤트가 자동으로 발생하여
    // 실제 지도 범위 내의 방만 로드됨
    debugPrint('📍 [MAP] 초기 로드 대기 중 - 지도 초기화 후 자동 로드');
  }

  /// 저장된 필터 로드
  Future<void> _loadSavedFilters() async {
    try {
      final savedFiltersJson = await _storage.read(key: 'guest_search_filters');
      if (savedFiltersJson != null) {
        final filtersMap =
            json.decode(savedFiltersJson) as Map<String, dynamic>;
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
    // 프론트엔드 필터링이므로 API 재호출 불필요
    // _buildPropertyList()가 자동으로 필터링 적용
  }

  void _onRoomSelected(Room? room, {bool focusMap = false}) {
    setState(() {
      _selectedRoom = room;
    });

    // 지도 포커싱
    if (focusMap && room != null) {
      _mapController.focusOnLocation(
        room.latitude,
        room.longitude,
        zoomLevel: 3,
      );
    }
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
                : ResponsiveLayout(
                    // 모바일: 지도만 표시
                    mobile: _buildMapOnly(),

                    // 태블릿: 지도만 표시
                    tablet: _buildMapOnly(),

                    // 데스크톱: 리스트 + 지도
                    desktop: Row(
                      children: [
                        // 왼쪽: 매물 리스트 (반응형 너비: 화면의 30%, 최소 300px, 최대 450px)
                        if (_roomsForMap.isNotEmpty)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              // 부모의 너비를 기준으로 반응형 계산
                              final screenWidth = MediaQuery.of(
                                context,
                              ).size.width;
                              final listWidth = (screenWidth * 0.3).clamp(
                                300.0,
                                450.0,
                              );

                              return Container(
                                width: listWidth,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    right: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                child: _buildPropertyList(),
                              );
                            },
                          ),

                        // 오른쪽: 지도
                        Expanded(
                          child: Stack(
                            children: [
                              _buildMap(),

                              // 결과 없음 메시지 (줌 레벨에 따라 다른 메시지 표시)
                              if (_roomsForMap.isEmpty)
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _currentZoomLevel != null &&
                                              _currentZoomLevel! >= 6
                                          ? '지도를 확대해서 매물을 찾아주세요.'
                                          : '조건에 일치하는 결과가 없습니다.',
                                      style: const TextStyle(
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
          ),
        ],
      ),
    );
  }

  /// 필터링된 방 목록 가져오기 (리스트와 지도 공통 사용)
  List<Map<String, dynamic>> _getFilteredRooms() {
    // 1단계: 지도 영역 내 매물 필터링 (bounds 기반)
    final visibleRooms = _roomsForMap.where((room) {
      // 백엔드 응답에 위도/경도가 없으면 제외
      if (room['latitude'] == null || room['longitude'] == null) return false;

      final lat = double.tryParse(room['latitude'].toString());
      final lng = double.tryParse(room['longitude'].toString());

      if (lat == null || lng == null) return false;

      // bounds가 아직 설정되지 않았으면 모두 표시 (초기 로딩)
      if (_currentSwLat == null ||
          _currentSwLng == null ||
          _currentNeLat == null ||
          _currentNeLng == null) {
        return true;
      }

      // 실제 지도 bounds 내에 있는지 확인
      final isInBounds =
          lat >= _currentSwLat! &&
          lat <= _currentNeLat! &&
          lng >= _currentSwLng! &&
          lng <= _currentNeLng!;

      return isInBounds;
    }).toList();

    // 2단계: 검색 필터 적용
    final filteredRooms = visibleRooms.where((room) {
      // 건물 유형 필터
      if (_filters.buildingTypes.isNotEmpty) {
        final buildingType = room['buildingType']?.toString() ?? '';
        if (!_filters.buildingTypes.contains(buildingType)) {
          return false;
        }
      }

      // 방 개수 필터
      if (_filters.bedroomCounts.isNotEmpty) {
        final roomCount = room['roomCount'] as int? ?? 1;
        // 3은 "3개 이상" 의미
        if (_filters.bedroomCounts.contains(3)) {
          // 3개 이상 필터가 선택된 경우
          if (roomCount >= 3) {
            // roomCount가 3 이상이면 통과
          } else if (!_filters.bedroomCounts.contains(roomCount)) {
            // roomCount가 3 미만이고, 해당 개수가 선택되지 않았으면 제외
            return false;
          }
        } else {
          // 3개 이상 필터가 선택되지 않은 경우
          if (!_filters.bedroomCounts.contains(roomCount)) {
            return false;
          }
        }
      }

      // 가격 범위 필터
      if (!_filters.priceRange.isDefault) {
        final dailyRent = room['dailyRent'] as int? ?? 0;
        if (!_filters.priceRange.isInRange(dailyRent)) {
          return false;
        }
      }

      // 주차 가능 필터
      if (_filters.otherOptions.contains(OtherOptions.parking)) {
        final parking = room['parkingAvailable'] as bool? ?? false;
        if (!parking) return false;
      }

      return true;
    }).toList();

    return filteredRooms;
  }

  Widget _buildPropertyList() {
    final filteredRooms = _getFilteredRooms();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredRooms.length,
      itemBuilder: (context, index) {
        final roomData = filteredRooms[index];

        // 백엔드 API 응답을 Room 모델 형식으로 변환
        final thumbnail = roomData['thumbnail'];
        final photos = thumbnail != null && thumbnail.toString().isNotEmpty
            ? [thumbnail.toString()]
            : <String>[];

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
          'longTermWeeks': 12,
          'longTermDiscount': 0,
          'quickMoveInDiscount': 0,
          'dailyMaintenanceFee': 0,
          'includeElectricity': false,
          'includeWater': false,
          'includeGas': false,
          'includeInternet': false,
          'cleaningFee': 0,
          'minContractWeeks': 4,
          'refundPolicy': 'moderate',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'photos': photos
              .map((url) => {'id': 0, 'url': url, 'order': 1})
              .toList(),
          'isNearSubway': false,
          'hostName': '호스트',
          'hostId': 1,
          'status': 'published',
        };

        final room = Room.fromJson(roomJson);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PropertyCard(
            room: room,
            isSelected: _selectedRoom?.id == room.id,
            onTap: () {
              // 상세 페이지로 이동 (GoRouter 사용)
              context.go('/guest/room/detail/${room.id}');
            },
            onHover: (isHovered) {
              if (isHovered) {
                _onRoomSelected(room, focusMap: false);
              } else {
                _onRoomSelected(null, focusMap: false);
              }
            },
          ),
        );
      },
    );
  }

  /// 지도만 표시 (모바일/태블릿용)
  Widget _buildMapOnly() {
    return Stack(
      children: [
        _buildMap(),

        // 결과 없음 메시지
        if (_roomsForMap.isEmpty)
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
              child: Text(
                _currentZoomLevel != null && _currentZoomLevel! >= 6
                    ? '지도를 확대해서 매물을 찾아주세요.'
                    : '조건에 일치하는 결과가 없습니다.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMap() {
    if (kIsWeb) {
      // 필터링된 방 목록을 카카오맵에 맞게 변환
      final filteredRooms = _getFilteredRooms();
      final roomsForKakaoMap = filteredRooms.map((roomData) {
        // dailyRent를 weeklyRent로 계산 (1000원 단위 반올림)
        final dailyRent = roomData['dailyRent'] ?? 0;
        final weeklyRent = ((dailyRent * 7) / 1000).round() * 1000;

        return {
          'id': roomData['id'],
          'latitude': roomData['latitude'],
          'longitude': roomData['longitude'],
          'roomName': roomData['roomName'],
          'weeklyRent': weeklyRent, // 계산된 주간 임대료
        };
      }).toList();

      return KakaoMapWeb(
        controller: _mapController,
        rooms: roomsForKakaoMap,
        onMarkerTap: (roomData) {
          final roomId = roomData['id'] as int;

          // 반응형 동작 분기
          if (ResponsiveUtil.isDesktop(context)) {
            // 데스크톱: 리스트에서 PropertyCard 강조 (기존 동작)
            final selectedRoomData = filteredRooms.firstWhere(
              (r) => r['id'] == roomId,
              orElse: () => filteredRooms.first,
            );

            // Room 모델로 변환
            final thumbnail = selectedRoomData['thumbnail'];
            final photos = thumbnail != null && thumbnail.toString().isNotEmpty
                ? [thumbnail.toString()]
                : <String>[];

            final roomJson = {
              'id': selectedRoomData['id'] ?? 0,
              'roomName': selectedRoomData['roomName'] ?? '',
              'address': selectedRoomData['address'] ?? '',
              'latitude': selectedRoomData['latitude'] ?? 0.0,
              'longitude': selectedRoomData['longitude'] ?? 0.0,
              'area': '0',
              'floor': '1',
              'buildingType': selectedRoomData['buildingType'] ?? '오피스텔',
              'parkingAvailable': false,
              'elevatorAvailable': false,
              'roomCount': selectedRoomData['roomCount'] ?? 1,
              'bathroomCount': selectedRoomData['bathroomCount'] ?? 1,
              'livingRoomCount': 1,
              'kitchenCount': 1,
              'isDuplex': false,
              'dailyRent': selectedRoomData['dailyRent'] ?? 0,
              'longTermWeeks': 12,
              'longTermDiscount': 0,
              'quickMoveInDiscount': 0,
              'dailyMaintenanceFee': 0,
              'includeElectricity': false,
              'includeWater': false,
              'includeGas': false,
              'includeInternet': false,
              'cleaningFee': 0,
              'minContractWeeks': 4,
              'refundPolicy': 'moderate',
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
              'photos': photos
                  .map((url) => {'id': 0, 'url': url, 'order': 1})
                  .toList(),
              'isNearSubway': false,
              'hostName': '호스트',
              'hostId': 1,
              'status': 'published',
            };

            _onRoomSelected(Room.fromJson(roomJson), focusMap: false);
          } else {
            // 모바일/태블릿: 상세페이지로 즉시 이동
            context.go('/guest/room/detail/$roomId');
          }
        },
        onBoundsChanged: (swLat, swLng, neLat, neLng, zoom) {
          // 지도 영역 변경 시 백엔드 API 호출 (줌 레벨 포함)
          _loadRoomsByBounds(swLat, swLng, neLat, neLng, zoom: zoom);
        },
      );
    } else {
      // 모바일 버전은 나중에 구현
      return Center(
        child: Text(
          '모바일 지도는 준비 중입니다.',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }
  }
}
