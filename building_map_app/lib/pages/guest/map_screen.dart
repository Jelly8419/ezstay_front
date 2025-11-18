import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:html' as html show window, EventListener, Event, MessageEvent;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/room.dart';
import '../../models/search_filters.dart';
import '../../services/room_service.dart';
import '../../config/api_config.dart';
import '../../widgets/kakao_map_web.dart';
import '../../widgets/property_card.dart';
import '../../widgets/search_filter_bar.dart';
import '../../constants/app_constants.dart' hide AppColors; // AppColors 충돌 방지
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../utils/responsive_util.dart';
import '../../widgets/common/app_gnb.dart';

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
  final PageController _mobileCardController = PageController(
    viewportFraction: 0.9, // 카드가 약간 겹쳐 보이도록
  );
  final ScrollController _listScrollController =
      ScrollController(); // 리스트 스크롤 컨트롤러
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

  // guest_home_page로부터 전달받은 날짜 필터
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int? _minPrice;
  int? _maxPrice;

  // 모바일 카드 현재 인덱스
  int _currentMobileCardIndex = 0;

  // 모바일 매물 리스트 표시 여부
  bool _showMobileCardList = false;

  // 뱃지 클릭 시간 추적 (마커 클릭과 중복 방지)
  DateTime? _lastBadgeClickTime;

  // 클러스터 필터링 관련
  bool _filteredByCluster = false; // 클러스터로 필터링 중인지 여부
  List<int> _clusterRoomIds = []; // 현재 선택된 클러스터의 방 ID 목록
  html.EventListener? _clusterClickListener; // 클러스터 클릭 이벤트 리스너

  // 초기 로드 시 photos 누락 대응
  bool _hasRetriedForPhotos = false; // photos 누락 재시도 여부 추적

  @override
  void initState() {
    super.initState();
    _loadSavedFilters();
    _setupClusterClickListener();
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    _mobileCardController.dispose();
    if (_clusterClickListener != null) {
      html.window.removeEventListener('message', _clusterClickListener);
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // guest_home_page로부터 전달받은 필터 처리
    final extra = GoRouterState.of(context).extra;
    if (extra != null && extra is Map<String, dynamic>) {
      setState(() {
        _checkInDate = extra['checkInDate'] as DateTime?;
        _checkOutDate = extra['checkOutDate'] as DateTime?;
        _minPrice = extra['minPrice'] as int?;
        _maxPrice = extra['maxPrice'] as int?;

        // SearchFilters 초기화 (전달받은 값으로)
        _initializeFiltersFromParams();
      });

      debugPrint('📅 [MAP] 전달받은 필터 - 체크인: $_checkInDate, 체크아웃: $_checkOutDate');
      debugPrint('💰 [MAP] 전달받은 필터 - 최소금액: $_minPrice, 최대금액: $_maxPrice');
    }
  }

  /// guest_home_page로부터 전달받은 파라미터로 SearchFilters 초기화
  void _initializeFiltersFromParams() {
    // DateRange 생성 (체크인/체크아웃 날짜가 모두 있을 때만)
    DateRange? dateRange;
    if (_checkInDate != null && _checkOutDate != null) {
      dateRange = DateRange(startDate: _checkInDate!, endDate: _checkOutDate!);
      debugPrint(
        '📅 [MAP] DateRange 초기화: ${dateRange.startDate} ~ ${dateRange.endDate}',
      );
    }

    // PriceRange 생성 (원 단위를 만원 단위로 변환)
    PriceRange? priceRange;
    if (_minPrice != null || _maxPrice != null) {
      final minPriceManWon = _minPrice != null ? (_minPrice! ~/ 10000) : 0;
      final maxPriceManWon = _maxPrice != null ? (_maxPrice! ~/ 10000) : null;
      priceRange = PriceRange(
        minPrice: minPriceManWon,
        maxPrice: maxPriceManWon,
      );
      debugPrint(
        '💰 [MAP] PriceRange 초기화: ${priceRange.minPrice}만원 ~ ${priceRange.maxPrice ?? "전체"}만원',
      );
    }

    // 기존 필터와 병합 (전달받은 값이 우선)
    _filters = _filters.copyWith(dateRange: dateRange, priceRange: priceRange);
  }

  /// 지도 영역 변경 시 방 검색
  Future<void> _loadRoomsByBounds(
    double swLat,
    double swLng,
    double neLat,
    double neLng, {
    int? zoom,
  }) async {
    debugPrint(
      '🎯 [MAP] _loadRoomsByBounds 호출됨! bounds: ($swLat,$swLng) ~ ($neLat,$neLng), zoom: $zoom',
    );
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

      // 현재 지도 bounds 및 줌 레벨 저장 (변경되었을 때만)
      final boundsChanged =
          _currentSwLat != swLat ||
          _currentSwLng != swLng ||
          _currentNeLat != neLat ||
          _currentNeLng != neLng ||
          _currentZoomLevel != zoom;

      // 변경 없으면 스킵
      if (!boundsChanged) {
        debugPrint('⏭️ [MAP] Bounds/Zoom 변경 없음 - 스킵');
        return; // 변경 없으면 조기 리턴
      }

      setState(() {
        _currentSwLat = swLat;
        _currentSwLng = swLng;
        _currentNeLat = neLat;
        _currentNeLng = neLng;
        _currentZoomLevel = zoom;
        _hasRetriedForPhotos = false; // 새로운 bounds에서는 재시도 플래그 리셋
      });

      // 날짜를 YYYY-MM-DD 형식 문자열로 변환
      String? checkInStr;
      String? checkOutStr;
      if (_checkInDate != null) {
        checkInStr = DateFormat('yyyy-MM-dd').format(_checkInDate!);
      }
      if (_checkOutDate != null) {
        checkOutStr = DateFormat('yyyy-MM-dd').format(_checkOutDate!);
      }

      // 디버그: API 요청 파라미터 확인
      debugPrint('📡 [MAP] API 요청 파라미터:');
      debugPrint('  - bounds: ($swLat,$swLng) ~ ($neLat,$neLng)');
      debugPrint('  - zoom: $zoom');
      debugPrint('  - checkIn: $checkInStr');
      debugPrint('  - checkOut: $checkOutStr');

      final result = await _roomService.getRoomsByMapBounds(
        swLat: swLat,
        swLng: swLng,
        neLat: neLat,
        neLng: neLng,
        zoom: zoom,
        checkIn: checkInStr,
        checkOut: checkOutStr,
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

        // 디버그: API 응답 데이터 확인
        debugPrint('📊 [MAP] API 응답 받음 - 방 개수: ${rooms.length}');
        bool hasPhotos = false;
        if (rooms.isNotEmpty) {
          final firstRoom = rooms.first;
          debugPrint('🏠 [MAP] 첫 번째 방 데이터:');
          debugPrint('  - ID: ${firstRoom['id']}');
          debugPrint('  - 이름: ${firstRoom['roomName']}');
          debugPrint('  - photos 필드 존재: ${firstRoom.containsKey('photos')}');
          if (firstRoom.containsKey('photos')) {
            final photos = firstRoom['photos'];
            debugPrint('  - photos 타입: ${photos.runtimeType}');
            debugPrint(
              '  - photos 길이: ${photos is List ? photos.length : 'N/A'}',
            );
            if (photos is List && photos.isNotEmpty) {
              debugPrint('  - 첫 번째 사진 데이터: ${photos[0]}');
              hasPhotos = true;
            } else {
              debugPrint('  ⚠️ photos 배열이 비어있음!');
            }
          } else {
            debugPrint('  ⚠️ photos 필드 없음!');
          }
        }

        // photos 누락 시 자동 재시도 (초기 로드 시 한 번만)
        if (!hasPhotos && !_hasRetriedForPhotos && rooms.isNotEmpty) {
          debugPrint('🔄 [MAP] photos 누락 감지 - 자동 재시도 시작 (1초 후)');
          _hasRetriedForPhotos = true;

          // 1초 대기 후 동일한 파라미터로 재호출
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted &&
                _currentSwLat != null &&
                _currentSwLng != null &&
                _currentNeLat != null &&
                _currentNeLng != null) {
              debugPrint('🔄 [MAP] photos 재시도 API 호출');
              _loadRoomsByBounds(
                _currentSwLat!,
                _currentSwLng!,
                _currentNeLat!,
                _currentNeLng!,
                zoom: _currentZoomLevel,
              );
            }
          });
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
    debugPrint('🚀 [MAP] _loadRooms 호출됨! 초기 로드 시작');

    // 초기 상태 설정 (빈 배열로 시작, 로딩 종료하여 지도 렌더링 허용)
    setState(() {
      _roomsForMap = []; // 빈 배열로 시작
      _isLoading = false; // 지도 렌더링을 위해 로딩 종료 (데드락 방지)
    });

    // JavaScript 지도 초기화 후 bounds_changed 이벤트가 자동으로 발생하여
    // 실제 지도 범위 내의 방만 로드됨
    debugPrint('📍 [MAP] 초기 로드 완료 - 지도 렌더링 시작, bounds_changed 이벤트 대기 중');
  }

  /// 클러스터 클릭 이벤트 리스너 설정
  void _setupClusterClickListener() {
    if (!kIsWeb) return;

    _clusterClickListener = (html.Event event) {
      final messageEvent = event as html.MessageEvent;
      if (messageEvent.data is Map &&
          messageEvent.data['type'] == 'marker_click') {
        final data = messageEvent.data;
        final clusterRoomIds =
            (data['clusterRoomIds'] as List?)?.cast<int>() ?? [];

        debugPrint('🎯 [MAP] 클러스터 클릭, 방 개수: ${clusterRoomIds.length}');

        // 빈 배열인 경우: 클러스터 필터링 해제 (전체 매물 표시)
        if (clusterRoomIds.isEmpty) {
          debugPrint('🔄 [MAP] 클러스터 필터링 해제 - 전체 매물 표시 + 카드 리스트 숨김');
          setState(() {
            _filteredByCluster = false;
            _clusterRoomIds = [];
            _selectedRoom = null;
            _currentMobileCardIndex = 0; // 모바일 카드 인덱스 리셋
            _showMobileCardList = false; // 모바일 카드 리스트 숨김 (UX 개선)
          });

          // 모바일 PageView를 첫 번째 카드로 이동
          if (ResponsiveUtil.isMobile(context) &&
              _mobileCardController.hasClients) {
            _mobileCardController.jumpToPage(0);
            debugPrint('📱 [MAP] 클러스터 필터링 해제 - PageView 첫 번째 카드로 이동');
          }
          return;
        }

        // 개별 마커(클러스터 크기 1)는 onMarkerTap 콜백이 처리하므로 여기서는 스킵
        // (중복 토글 방지: 이 리스너와 onMarkerTap 콜백이 동시에 토글하는 버그 수정)
        if (clusterRoomIds.length == 1) {
          debugPrint('📍 [MAP] 개별 마커 감지 (클러스터 크기 1) - onMarkerTap 콜백이 처리 예정, 여기서는 스킵');
          return;
        }

        // 클러스터 필터링 활성화 (클러스터 크기 >= 2)
        debugPrint(
          '📱 [MAP] 클러스터 필터링 활성화 - 모바일 리스트 토글 및 ${clusterRoomIds.length}개 매물 표시',
        );

        // 뱃지 클릭 후 300ms 이내라면 클러스터 마커 클릭 무시 (중복 토글 방지)
        if (_lastBadgeClickTime != null) {
          final timeSinceLastBadgeClick =
              DateTime.now().difference(_lastBadgeClickTime!);
          if (timeSinceLastBadgeClick.inMilliseconds < 300) {
            debugPrint(
              '⏱️ [MAP] 클러스터 마커 클릭 무시 - 최근 뱃지 클릭(${timeSinceLastBadgeClick.inMilliseconds}ms 전)',
            );
            return;
          }
        }

        // 클릭된 클러스터의 첫 번째 방 ID 가져오기
        final clickedRoomId = data['roomId'] as int?;

        setState(() {
          _filteredByCluster = true;
          _clusterRoomIds = clusterRoomIds;
          _selectedRoom = null; // 선택된 방 초기화
          _currentMobileCardIndex = 0; // 모바일 카드 인덱스를 0으로 리셋 (첫 번째 매물 표시)
          _showMobileCardList = true; // 다른 클러스터 클릭 시 카드 리스트 무조건 노출 (같은 클러스터 재클릭은 clusterRoomIds.isEmpty로 별도 처리)
        });

        // 클러스터 마커 선택 (파란색으로 표시)
        if (clickedRoomId != null) {
          _mapController.selectMarker(clickedRoomId);
          debugPrint('🔵 [MAP] 클러스터 마커 선택 - roomId: $clickedRoomId');
        }

        // 모바일 PageView를 첫 번째 카드로 이동
        if (ResponsiveUtil.isMobile(context) &&
            _mobileCardController.hasClients) {
          _mobileCardController.jumpToPage(0);
          debugPrint('📱 [MAP] 모바일 PageView를 첫 번째 카드로 이동');
        }
      }
    };
    html.window.addEventListener('message', _clusterClickListener);
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

  void _onRoomSelected(
    Room? room, {
    bool focusMap = false,
    bool shouldScroll = true,
  }) {
    debugPrint(
      '🔵 [SELECTION] _onRoomSelected 호출 - roomId: ${room?.id}, focusMap: $focusMap',
    );

    setState(() {
      _selectedRoom = room;
    });

    // 지도 포커싱 및 마커 선택
    if (room != null) {
      // 마커 선택 (흰색 → 파란색)
      debugPrint('🔵 [SELECTION] 마커 선택 - roomId: ${room.id}');
      _mapController.selectMarker(room.id);

      // 지도 포커싱
      if (focusMap) {
        _mapController.focusOnLocation(
          room.latitude,
          room.longitude,
          zoomLevel: 3,
        );
      }

      // 왼쪽 리스트에서 해당 PropertyCard로 자동 스크롤 (데스크톱만, 명시적 요청 시에만)
      if (ResponsiveUtil.isDesktop(context) && shouldScroll) {
        _scrollToSelectedRoom(room.id);
      }
    } else {
      // room이 null인 경우 마커 선택 해제 (파란색 → 흰색)
      debugPrint('⚪ [SELECTION] 마커 선택 해제');
      _mapController.selectMarker(-1);
    }
  }

  /// 선택된 방으로 리스트 스크롤
  void _scrollToSelectedRoom(int roomId) {
    final filteredRooms = _getFilteredRoomsForList();
    final index = filteredRooms.indexWhere((r) => r['id'] == roomId);

    if (index != -1 && _listScrollController.hasClients) {
      // PropertyCard 높이 추정 (이미지 4:3 비율 + 정보 영역 + 패딩)
      // 너비 약 400px 기준 → 이미지 높이 300px + 정보 150px + 패딩 = 약 470px
      const estimatedCardHeight = 470.0;
      const cardSpacing = 16.0; // 카드 간 간격
      final targetOffset = index * (estimatedCardHeight + cardSpacing);

      // jumpTo 사용하여 즉시 스크롤 (사용자 입력 차단 방지)
      _listScrollController.jumpTo(
        targetOffset.clamp(
          _listScrollController.position.minScrollExtent,
          _listScrollController.position.maxScrollExtent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // 메인 컨텐츠
          Column(
            children: [
              // GNB (데스크탑만)
              if (ResponsiveUtil.isDesktop(context)) const AppGNB(),

              // 검색 필터 바
              SearchFilterBar(
                filters: _filters,
                onFiltersChanged: _onFilterChanged,
                mapController: _mapController,
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
                                        right: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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

          // 모바일 하단 네비게이션 (React 코드 기반)
          if (ResponsiveUtil.isMobile(context))
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          icon: Icons.map,
                          label: '지도',
                          isActive: true,
                          onTap: () {
                            // 현재 페이지 (지도)
                          },
                        ),
                        _buildNavItem(
                          icon: Icons.description_outlined,
                          label: '계약서',
                          isActive: false,
                          onTap: () {
                            context.go('/guest/contracts');
                          },
                        ),
                        _buildNavItem(
                          icon: Icons.chat_bubble_outline,
                          label: '채팅',
                          isActive: false,
                          onTap: () {
                            context.go('/guest/chats');
                          },
                        ),
                        _buildNavItem(
                          icon: Icons.menu,
                          label: '더보기',
                          isActive: false,
                          onTap: () {
                            context.go('/guest/more');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 필터링된 방 목록 가져오기 (지도용 - 클러스터 필터링 제외)
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

      // 가격 범위 필터 (SearchFilters)
      if (!_filters.priceRange.isDefault) {
        final dailyRent = room['dailyRent'] as int? ?? 0;
        if (!_filters.priceRange.isInRange(dailyRent)) {
          return false;
        }
      }

      // 가격 범위 필터 (guest_home_page에서 전달받은 값, 주간 임대료 기준)
      if (_minPrice != null || _maxPrice != null) {
        final dailyRent = room['dailyRent'] as int? ?? 0;
        final weeklyRent = dailyRent * 7;  // 일일 임대료를 주간 임대료로 변환
        if (_minPrice != null && weeklyRent < _minPrice!) {
          return false;
        }
        if (_maxPrice != null && weeklyRent > _maxPrice!) {
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

  /// 리스트용 필터링 (클러스터 필터링 포함)
  List<Map<String, dynamic>> _getFilteredRoomsForList() {
    // 클러스터 필터링이 활성화된 경우 (최우선)
    if (_filteredByCluster && _clusterRoomIds.isNotEmpty) {
      debugPrint('🎯 [LIST] 클러스터 필터링 활성화: ${_clusterRoomIds.length}개 방');
      final clusterRooms = _roomsForMap.where((room) {
        final roomId = room['id'] as int?;
        return roomId != null && _clusterRoomIds.contains(roomId);
      }).toList();
      return clusterRooms;
    }

    // 클러스터 필터링이 비활성화된 경우 - 일반 필터링 적용
    return _getFilteredRooms();
  }

  Widget _buildPropertyList() {
    final filteredRooms = _getFilteredRoomsForList();

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          // 스크롤 시작 시 지도 드래그 비활성화
          _mapController.setMapDraggable(false);
        } else if (notification is ScrollEndNotification) {
          // 스크롤 종료 시 지도 드래그 활성화
          _mapController.setMapDraggable(true);
        }
        return true;
      },
      child: Listener(
        onPointerDown: (_) {},
        onPointerMove: (_) {},
        onPointerUp: (_) {},
        behavior: HitTestBehavior.opaque,
        child: ListView.builder(
          controller: _listScrollController, // 스크롤 컨트롤러 추가
          padding: const EdgeInsets.all(16),
          itemCount: filteredRooms.length,
          itemBuilder: (context, index) {
            final roomData = filteredRooms[index];

            // 백엔드 API 응답을 Room 모델 형식으로 변환
            // photos 배열 파싱 (백엔드가 [{url, order}] 형식으로 제공, 상대경로)
            final photosData = roomData['photos'] as List<dynamic>?;

            // 디버그: 개별 방의 photos 데이터 확인 (첫 번째 방만)
            if (index == 0) {
              debugPrint('🖼️ [LIST] 첫 번째 PropertyCard photos 파싱:');
              debugPrint('  - photosData 존재: ${photosData != null}');
              debugPrint('  - photosData 길이: ${photosData?.length ?? 0}');
              if (photosData != null && photosData.isNotEmpty) {
                debugPrint('  - photosData[0]: ${photosData[0]}');
              }
            }

            final photos = photosData != null && photosData.isNotEmpty
                ? photosData.map((photo) {
                    final relativeUrl = photo['url'] ?? '';
                    final fullUrl = relativeUrl.isNotEmpty
                        ? '${ApiConfig.baseUrl}$relativeUrl'
                        : '';
                    return {'url': fullUrl, 'order': photo['order'] ?? 0};
                  }).toList()
                : <Map<String, dynamic>>[];

            // 디버그: 변환 후 photos 데이터 (첫 번째 방만)
            if (index == 0) {
              debugPrint('  - 변환 후 photos 길이: ${photos.length}');
              if (photos.isNotEmpty) {
                debugPrint('  - 변환 후 photos[0]: ${photos[0]}');
              }
            }

            // discounts 객체에서 할인 정보 파싱
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
              // discounts 객체에서 할인 정보 가져오기 (nullable 유지)
              'discounts': discounts,
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
              'photos': photos, // 이미 올바른 형식으로 파싱됨
              'isNearSubway': false,
              'hostName': '호스트',
              'hostId': 1,
              'status': 'published',
            };

            final room = Room.fromJson(roomJson);

            // 디버그: Room 모델 변환 후 photos 확인 (첫 번째 방만)
            if (index == 0) {
              debugPrint('📸 [LIST] Room 모델 변환 완료:');
              debugPrint('  - room.photos.length: ${room.photos.length}');
              if (room.photos.isNotEmpty) {
                debugPrint('  - room.photos[0].url: ${room.photos[0].url}');
                debugPrint('  - room.photos[0].order: ${room.photos[0].order}');
              } else {
                debugPrint('  ⚠️ room.photos가 비어있음!');
              }
            }

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
                    // 호버 시에는 스크롤 비활성화 (마커 선택만)
                    _onRoomSelected(room, focusMap: false, shouldScroll: false);
                  } else {
                    _onRoomSelected(null, focusMap: false, shouldScroll: false);
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// 지도만 표시 (모바일/태블릿용)
  Widget _buildMapOnly() {
    final filteredRooms = _getFilteredRoomsForList();

    return Stack(
      children: [
        _buildMap(),

        // 매물 개수 뱃지 (모바일: 하단 중앙, 데스크톱: 좌측 상단)
        // 모바일에서는 슬라이드 카드 표시 시 비노출
        if (filteredRooms.isNotEmpty &&
            (!ResponsiveUtil.isMobile(context) || !_showMobileCardList))
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            // 모바일 환경에서는 하단 중앙, 데스크톱은 좌측 상단
            top: ResponsiveUtil.isMobile(context) ? null : 16,
            // 모바일: 네비게이션 위(80px)
            bottom: ResponsiveUtil.isMobile(context) ? 80 : null,
            left: ResponsiveUtil.isMobile(context) ? 0 : 16,
            right: ResponsiveUtil.isMobile(context) ? 0 : null,
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque, // 뱃지 클릭 우선 처리 (마커 클릭보다 우선)
                onTap: ResponsiveUtil.isMobile(context)
                    ? () {
                        // 뱃지 클릭 시간 기록 (마커 클릭 차단용)
                        _lastBadgeClickTime = DateTime.now();

                        setState(() {
                          _showMobileCardList = !_showMobileCardList;
                          // 뱃지 클릭 시 마커 선택 해제 (파란색 → 흰색)
                          _selectedRoom = null;
                        });

                        // 지도의 모든 마커 선택 해제
                        _mapController.selectMarker(-1);

                        debugPrint(
                          '📱 [MOBILE] 매물 개수 뱃지 클릭 - 리스트 토글: $_showMobileCardList (마커 선택 해제)',
                        );
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '매물 ${filteredRooms.length}개',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      if (ResponsiveUtil.isMobile(context)) ...[
                        const SizedBox(width: 8),
                        Icon(
                          _showMobileCardList
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          size: 20,
                          color: const Color(0xFF1F2937),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

        // 하단 슬라이드 카드 (모바일 전용 - 토글 상태에 따라 표시/숨김)
        if (ResponsiveUtil.isMobile(context) && filteredRooms.isNotEmpty)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _showMobileCardList ? 80 : -160, // 숨김 시 화면 밖으로
            left: 0,
            right: 0,
            height: 160,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showMobileCardList ? 1.0 : 0.0,
              child: Listener(
                onPointerDown: (_) {
                  // 모바일 PageView 드래그 시작 시 지도 드래그 비활성화
                  debugPrint('📱 [MOBILE] PageView 드래그 시작 - 지도 비활성화');
                  _mapController.setMapDraggable(false);
                },
                onPointerUp: (_) {
                  // 모바일 PageView 드래그 종료 시 지도 드래그 활성화 (지연 적용)
                  debugPrint('📱 [MOBILE] PageView 드래그 종료 - 지도 활성화 (150ms 지연)');
                  // 잔여 HTML 이벤트 소멸을 위해 150ms 지연 후 활성화
                  Future.delayed(const Duration(milliseconds: 150), () {
                    if (mounted) {
                      _mapController.setMapDraggable(true);
                    }
                  });
                },
                onPointerCancel: (_) {
                  // 드래그 취소 시에도 지도 드래그 활성화 (지연 적용)
                  debugPrint('📱 [MOBILE] PageView 드래그 취소 - 지도 활성화 (150ms 지연)');
                  Future.delayed(const Duration(milliseconds: 150), () {
                    if (mounted) {
                      _mapController.setMapDraggable(true);
                    }
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: PageView.builder(
                  controller: _mobileCardController,
                  itemCount: filteredRooms.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentMobileCardIndex = index;
                    });

                    // 📱 모바일 카드 스와이프 시 지도 자동 이동 비활성화
                    // - 사용자가 카드를 넘길 때마다 지도가 순간이동하는 것을 방지
                    // - 필요 시 카드 탭 이벤트에서만 지도 포커싱 수행 가능

                    //                   // 지도 포커싱
                    //                   final roomData = filteredRooms[index];
                    //                   final lat = double.tryParse(roomData['latitude'].toString());
                    //                   final lng = double.tryParse(roomData['longitude'].toString());
                    //                   if (lat != null && lng != null) {
                    //                     _mapController.focusOnLocation(lat, lng, zoomLevel: 3);
                    //                   }
                  },
                  itemBuilder: (context, index) {
                    final roomData = filteredRooms[index];
                    return _buildMobilePropertyCard(roomData);
                  },
                ),
              ),
            ),
          ),

        // 결과 없음 메시지
        if (filteredRooms.isEmpty)
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

          // roomId: -1은 개별 마커 재클릭 (선택 해제) 이벤트
          if (roomId == -1) {
            debugPrint('🔄 [MAP] 개별 마커 재클릭 - 선택 해제 + 전체 매물 표시 + 카드 리스트 숨김');
            setState(() {
              _selectedRoom = null;
              _filteredByCluster = false;
              _clusterRoomIds = [];
              _currentMobileCardIndex = 0;
              _showMobileCardList = false; // 모바일 카드 리스트 숨김 (UX 개선)
            });

            // PageView를 첫 번째 카드로 리셋 (모바일/태블릿)
            if (!ResponsiveUtil.isDesktop(context) &&
                _mobileCardController.hasClients) {
              _mobileCardController.jumpToPage(0);
              debugPrint('📱 [MOBILE] PageView 첫 번째 카드로 리셋');
            }
            return;
          }

          // 반응형 동작 분기
          if (ResponsiveUtil.isDesktop(context)) {
            // 데스크톱: 리스트에서 PropertyCard 강조 (기존 동작)
            final selectedRoomData = filteredRooms.firstWhere(
              (r) => r['id'] == roomId,
              orElse: () => filteredRooms.first,
            );

            // Room 모델로 변환
            // photos 배열 파싱 (백엔드가 [{url, order}] 형식으로 제공, 상대경로)
            final photosData = selectedRoomData['photos'] as List<dynamic>?;
            final photos = photosData != null && photosData.isNotEmpty
                ? photosData.map((photo) {
                    final relativeUrl = photo['url'] ?? '';
                    final fullUrl = relativeUrl.isNotEmpty
                        ? '${ApiConfig.baseUrl}$relativeUrl'
                        : '';
                    return {'url': fullUrl, 'order': photo['order'] ?? 0};
                  }).toList()
                : <Map<String, dynamic>>[];

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
              'photos': photos, // 이미 올바른 형식으로 파싱됨
              'isNearSubway': false,
              'hostName': '호스트',
              'hostId': 1,
              'status': 'published',
            };

            _onRoomSelected(Room.fromJson(roomJson), focusMap: false);
          } else {
            // 모바일/태블릿: 마커 클릭 시 매물 선택 및 리스트 토글

            // 뱃지 클릭 후 300ms 이내라면 마커 클릭 무시 (중복 토글 방지)
            if (_lastBadgeClickTime != null) {
              final timeSinceLastBadgeClick =
                  DateTime.now().difference(_lastBadgeClickTime!);
              if (timeSinceLastBadgeClick.inMilliseconds < 300) {
                debugPrint(
                  '⏱️ [MOBILE] 마커 클릭 무시 - 최근 뱃지 클릭(${timeSinceLastBadgeClick.inMilliseconds}ms 전)',
                );
                return;
              }
            }

            // 다른 마커 클릭: 해당 매물 선택 (상세 페이지 이동 제거)
            debugPrint('📱 [MOBILE] 개별 마커 클릭 - 해당 매물만 카드 리스트 노출: $roomId');

            // 개별 마커 클릭 시 해당 매물만 필터링하여 카드 리스트 노출
            // (같은 마커 재클릭은 roomId: -1 이벤트로 별도 처리)
            setState(() {
              _showMobileCardList = true;
              _filteredByCluster = true; // 개별 매물 필터링 활성화
              _clusterRoomIds = [roomId]; // 해당 매물만 표시
              _currentMobileCardIndex = 0; // 카드 인덱스 리셋
            });

            final selectedRoomData = filteredRooms.firstWhere(
              (r) => r['id'] == roomId,
              orElse: () => filteredRooms.first,
            );

            // Room 모델로 변환 (데스크탑과 동일한 로직)
            final photosData = selectedRoomData['photos'] as List<dynamic>?;
            final photos = photosData != null && photosData.isNotEmpty
                ? photosData.map((photo) {
                    final relativeUrl = photo['url'] ?? '';
                    final fullUrl = relativeUrl.isNotEmpty
                        ? '${ApiConfig.baseUrl}$relativeUrl'
                        : '';
                    return {'url': fullUrl, 'order': photo['order'] ?? 0};
                  }).toList()
                : <Map<String, dynamic>>[];

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
              'photos': photos,
              'isNearSubway': false,
              'hostName': '호스트',
              'hostId': 1,
              'status': 'published',
            };

            _onRoomSelected(Room.fromJson(roomJson), focusMap: false);

            // 모바일 PageView를 첫 번째 카드로 이동 (개별 마커는 1개만 있으므로 항상 0번째)
            if (ResponsiveUtil.isMobile(context) &&
                _mobileCardController.hasClients) {
              _mobileCardController.jumpToPage(0);
              debugPrint('📱 [MOBILE] 개별 마커 - PageView 첫 번째 카드로 이동');
            }
          }
        },
        onBoundsChanged: (swLat, swLng, neLat, neLng, zoom) {
          // 모바일 환경에서 슬라이드 카드가 표시 중이면 숨김 (지도 드래그 시)
          if (ResponsiveUtil.isMobile(context) && _showMobileCardList) {
            debugPrint('📱 [MOBILE] 지도 드래그 감지 - 슬라이드 카드 숨김 및 매물 개수 뱃지 재표시');
            setState(() {
              _showMobileCardList = false;
            });
          }

          // 선택된 마커가 있으면 해제 (UX 개선: 지도 드래그 시 선택 초기화)
          if (_selectedRoom != null || _filteredByCluster) {
            debugPrint('🗺️ [MAP] 지도 드래그 감지 - 선택 해제 및 전체 매물 표시');

            setState(() {
              _selectedRoom = null;
              _filteredByCluster = false;
              _clusterRoomIds = [];
              _currentMobileCardIndex = 0;
            });

            // 마커 선택 해제 (파란색 → 흰색)
            _mapController.selectMarker(-1);

            // 모바일 PageView 첫 번째 카드로 리셋
            if (!ResponsiveUtil.isDesktop(context) &&
                _mobileCardController.hasClients) {
              _mobileCardController.jumpToPage(0);
              debugPrint('📱 [MOBILE] PageView 첫 번째 카드로 리셋');
            }
          }

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

  /// 모바일 하단 슬라이드 카드
  Widget _buildMobilePropertyCard(Map<String, dynamic> roomData) {
    // photos 배열 파싱 (백엔드가 [{url, order}] 형식으로 제공, 상대경로)
    final photosData = roomData['photos'] as List<dynamic>?;
    String? firstPhotoUrl;
    if (photosData != null && photosData.isNotEmpty) {
      final relativeUrl = photosData[0]['url'] as String?;
      firstPhotoUrl = relativeUrl != null && relativeUrl.isNotEmpty
          ? '${ApiConfig.baseUrl}$relativeUrl'
          : null;
    }

    final dailyRent = roomData['dailyRent'] ?? 0;
    final roomName = roomData['roomName'] ?? '';
    final address = roomData['address'] ?? '';
    final roomId = roomData['id'] ?? 0;

    // 할인 정보 파싱 (데스크톱과 동일)
    final discounts = roomData['discounts'] as Map<String, dynamic>?;
    final quickMoveInDays = discounts?['quickMoveInDays'] as int?;
    final quickMoveInDiscount = discounts?['quickMoveInDiscount'] as int?;
    final longTermWeeks = discounts?['longTermWeeks'] as int?;
    final longTermDiscount = discounts?['longTermDiscount'] as int?;

    // 할인 여부 확인
    final hasQuickMoveIn =
        quickMoveInDays != null &&
        quickMoveInDiscount != null &&
        quickMoveInDiscount > 0;
    final hasLongTerm =
        longTermWeeks != null &&
        longTermDiscount != null &&
        longTermDiscount > 0;

    return GestureDetector(
      onTap: () {
        context.go('/guest/room/detail/$roomId');
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 썸네일 이미지
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: firstPhotoUrl != null && firstPhotoUrl.isNotEmpty
                  ? Image.network(
                      firstPhotoUrl,
                      width: 120,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 120,
                          height: 160,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.home,
                            size: 48,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 120,
                      height: 160,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.home,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
            ),

            // 정보 영역
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 방 이름
                    Text(
                      roomName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // 주소
                    Text(
                      address,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // 가격 (주간 기준)
                    Text(
                      '${NumberFormat('#,###').format(dailyRent * 7)}원/주',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),

                    // 할인 정보 (데스크탑과 동일)
                    if (hasQuickMoveIn) ...[
                      const SizedBox(height: 6),
                      Text(
                        '* $quickMoveInDays일 이내 입주시 ${_formatPrice(quickMoveInDiscount)}원 할인',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF3B82F6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (hasLongTerm) ...[
                      const SizedBox(height: 4),
                      Text(
                        '* $longTermWeeks주 이상 계약시 $longTermDiscount% 할인',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF3B82F6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 가격 포맷팅 (만원 단위)
  String _formatPrice(int price) {
    if (price >= 10000) {
      final manWon = price ~/ 10000;
      final remainder = price % 10000;
      if (remainder == 0) {
        return '$manWon만원';
      }
      return '$manWon.${(remainder / 1000).toStringAsFixed(0)}만원';
    }
    return '${price.toString()}원';
  }

  /// 드래그 가능한 스크롤 인디케이터
  Widget _buildDraggableScrollIndicator(int totalItems) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space24,
        vertical: AppSpacing.space12,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final handleWidth = totalWidth / totalItems; // 각 아이템당 핸들 너비
          final currentPosition = _currentMobileCardIndex * handleWidth;

          return GestureDetector(
            onHorizontalDragUpdate: (details) {
              // 드래그 위치를 페이지 인덱스로 변환
              final dragPosition = details.localPosition.dx.clamp(
                0.0,
                totalWidth,
              );
              final targetIndex = (dragPosition / handleWidth).floor().clamp(
                0,
                totalItems - 1,
              );

              // 현재 인덱스와 다를 때만 페이지 이동
              if (targetIndex != _currentMobileCardIndex) {
                _mobileCardController.animateToPage(
                  targetIndex,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
              }
            },
            onTapDown: (details) {
              // 탭한 위치로 즉시 이동
              final tapPosition = details.localPosition.dx.clamp(
                0.0,
                totalWidth,
              );
              final targetIndex = (tapPosition / handleWidth).floor().clamp(
                0,
                totalItems - 1,
              );

              _mobileCardController.animateToPage(
                targetIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.neutral200,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Stack(
                children: [
                  // 현재 위치 핸들
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    left: currentPosition,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: handleWidth,
                      decoration: BoxDecoration(
                        color: AppColors.primary500,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary500.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${_currentMobileCardIndex + 1}/$totalItems',
                          style: const TextStyle(
                            color: AppColors.neutral0,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 모바일 하단 네비게이션 아이템 (React 코드 기반)
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? const Color(0xFF3B82F6) : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? const Color(0xFF3B82F6) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
