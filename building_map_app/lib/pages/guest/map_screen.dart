import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:html' as html show window, EventListener, Event, MessageEvent;
import 'package:go_router/go_router.dart';
import '../../utils/contract_utils.dart';
import '../../utils/format_utils.dart';
import '../../utils/map_filter_utils.dart';
import '../../models/room.dart';
import '../../models/search_filters.dart';
import '../../services/room_service.dart';
import '../../widgets/kakao_map_web.dart';
import '../../widgets/search_filter_bar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../utils/responsive_util.dart';
import '../../widgets/common/app_gnb.dart';
import '../../widgets/common/mobile_bottom_nav.dart';
import '../../services/auth_service.dart';
import '../../services/map_interaction_coordinator.dart';
import '../../services/region_alert_service.dart';
import '../../widgets/map/kakao_map_section.dart';
import '../../widgets/map/map_only_layout.dart';
import '../../widgets/map/opening_notice_card.dart';
import '../../widgets/map/property_list_panel.dart';
import '../../widgets/common/custom_toast.dart';
import '../../widgets/modals/region_alert_modal.dart';
import 'package:provider/provider.dart';
import '../../core/utils/seo_helper.dart';

/// 지도 기반 숙소 검색 화면
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final RoomService _roomService = RoomService();
  final KakaoMapWebController _mapController = KakaoMapWebController();
  final PageController _mobileCardController = PageController(
    viewportFraction: 0.63, // 카드 너비 210px + 마진 16px ≈ 화면의 63%
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

  // 클러스터 필터링 관련
  bool _filteredByCluster = false; // 클러스터로 필터링 중인지 여부
  List<int> _clusterRoomIds = []; // 현재 선택된 클러스터의 방 ID 목록
  html.EventListener? _clusterClickListener; // 클러스터 클릭 이벤트 리스너

  // 초기 로드 시 photos 누락 대응

  // 지도 초기화 후 localStorage 복원 여부 (onBoundsChanged 최초 1회)
  bool _mapRestoreAttempted = false;

  // ────────────────────────────────────────────────
  // 🚧 PRE-LAUNCH FLAG: 정식 런칭 전까지 true로 유지.
  //    true: 지도 드래그 시 API 요청 차단 + OpeningNoticeCard 항상 표시
  //    false: 정상 동작 (런칭 후 이 줄만 주석 해제)
  // static const bool _isPreLaunch = false;
  static const bool _isPreLaunch = true;
  // ────────────────────────────────────────────────


  // 캐시된 반응형 값 (JS 콜백에서 안전하게 사용)
  bool _isMobile = false;
  bool _isDesktop = true;

  @override
  void initState() {
    super.initState();
    _loadSavedFilters();
    _setupClusterClickListener();
    _setupCoordinatorListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SeoHelper.updatePage(
        title: '지도로 단기 숙소 검색 | EZStay',
        description: '원하는 지역의 단기임대 숙소를 지도에서 직접 찾아보세요. 원룸, 오피스텔, 아파트 단기 계약.',
        canonicalPath: '/map',
      );
    });
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    _mobileCardController.dispose();
    if (_clusterClickListener != null) {
      html.window.removeEventListener('message', _clusterClickListener);
    }
    _removeCoordinatorListener();
    super.dispose();
  }

  /// 🎯 Coordinator 리스너 설정: 모드 변경 시 지도 드래그 자동 제어
  void _setupCoordinatorListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 🔒 위젯이 dispose된 후에는 콜백 처리하지 않음
      if (!mounted) return;

      final coordinator = Provider.of<MapInteractionCoordinator>(
        context,
        listen: false,
      );
      coordinator.addListener(_onCoordinatorModeChanged);
    });
  }

  /// 🎯 Coordinator 리스너 제거
  void _removeCoordinatorListener() {
    try {
      final coordinator = Provider.of<MapInteractionCoordinator>(
        context,
        listen: false,
      );
      coordinator.removeListener(_onCoordinatorModeChanged);
    } catch (e) {
      // context가 이미 dispose된 경우 무시
    }
  }

  /// 🎯 Coordinator 모드 변경 시 호출
  void _onCoordinatorModeChanged() {
    if (!mounted) return;

    final coordinator = Provider.of<MapInteractionCoordinator>(
      context,
      listen: false,
    );

    // idle 모드일 때만 지도 드래그 허용, 그 외에는 차단
    final shouldEnableDrag = coordinator.currentMode == InteractionMode.idle;
    _mapController.setMapDraggable(shouldEnableDrag);

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 반응형 값 캐시 (JS 콜백에서 context 접근 없이 사용)
    _isMobile = ResponsiveUtil.isMobile(context);
    _isDesktop = ResponsiveUtil.isDesktop(context);

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

    }
  }

  /// guest_home_page로부터 전달받은 파라미터로 SearchFilters 초기화
  void _initializeFiltersFromParams() {
    // DateRange 생성 (체크인/체크아웃 날짜가 모두 있을 때만)
    DateRange? dateRange;
    if (_checkInDate != null && _checkOutDate != null) {
      dateRange = DateRange(startDate: _checkInDate!, endDate: _checkOutDate!);
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
    bool forceRefresh = false,
  }) async {
    // 🚧 PRE-LAUNCH: API 요청 차단
    if (_isPreLaunch) {
      setState(() => _isLoading = false);
      return;
    }
    try {

      // 줌 레벨 6 이상이면 리스트 비우기
      if (zoom != null && zoom >= 6) {
        setState(() {
          _roomsForMap = [];
          _selectedRoom = null;
          _isLoading = false;
          _currentZoomLevel = zoom; // 줌 레벨 저장
        });
        return;
      }

      if (zoom == null) {
        AppLogger.w('⚠️ [MAP] 줌 레벨이 null입니다!');
      }

      // 현재 지도 bounds 및 줌 레벨 저장 (변경되었을 때만)
      final boundsChanged =
          _currentSwLat != swLat ||
          _currentSwLng != swLng ||
          _currentNeLat != neLat ||
          _currentNeLng != neLng ||
          _currentZoomLevel != zoom;

      // 변경 없으면 스킵 (forceRefresh 시 강제 호출)
      if (!boundsChanged && !forceRefresh) {
        return; // 변경 없으면 조기 리턴
      }

      setState(() {
        _currentSwLat = swLat;
        _currentSwLng = swLng;
        _currentNeLat = neLat;
        _currentNeLng = neLng;
        _currentZoomLevel = zoom;
      });

      // 날짜를 YYYY-MM-DD 형식 문자열로 변환
      String? checkInStr;
      String? checkOutStr;
      if (_checkInDate != null) {
        checkInStr = FormatUtils.formatDateApi(_checkInDate!);
      }
      if (_checkOutDate != null) {
        checkOutStr = FormatUtils.formatDateApi(_checkOutDate!);
      }

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
        // 썸네일 상대경로를 절대경로로 변환
        final rooms = List<Map<String, dynamic>>.from(result['rooms']);
        for (var room in rooms) {
          if (room['thumbnail'] != null) {
            room['thumbnail'] = ContractUtils.getFullImageUrl(room['thumbnail'].toString());
          }
        }

        setState(() {
          _roomsForMap = rooms;
          _isLoading = false;
        });
      } else {
        setState(() {
          _roomsForMap = [];
          _isLoading = false;
        });
        AppLogger.w('⚠️ [MAP] 검색 결과 없음 또는 백엔드 오류');

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
      AppLogger.e('❌ [MAP] 방 검색 실패: $e');
      setState(() {
        _roomsForMap = [];
        _isLoading = false;
      });
    }
  }

  /// 초기 로드 (지도가 초기화되면 자동으로 bounds_changed 이벤트 발생)
  Future<void> _loadRooms() async {

    // 초기 상태 설정 (빈 배열로 시작, 로딩 종료하여 지도 렌더링 허용)
    setState(() {
      _roomsForMap = []; // 빈 배열로 시작
      _isLoading = false; // 지도 렌더링을 위해 로딩 종료 (데드락 방지)
    });

    // JavaScript 지도 초기화 후 bounds_changed 이벤트가 자동으로 발생하여
    // 실제 지도 범위 내의 방만 로드됨
  }

  /// 클러스터 클릭 이벤트 리스너 설정
  void _setupClusterClickListener() {
    if (!kIsWeb) return;

    _clusterClickListener = (html.Event event) {
      // 🔒 위젯이 dispose된 후에는 콜백 처리하지 않음
      if (!mounted) return;

      final messageEvent = event as html.MessageEvent;
      if (messageEvent.data is Map &&
          messageEvent.data['type'] == 'marker_click') {
        final data = messageEvent.data;
        final clusterRoomIds =
            (data['clusterRoomIds'] as List?)?.cast<int>() ?? [];


        // 빈 배열인 경우: 클러스터 필터링 해제 (전체 매물 표시)
        if (clusterRoomIds.isEmpty) {
          setState(() {
            _filteredByCluster = false;
            _clusterRoomIds = [];
            _selectedRoom = null;
            _currentMobileCardIndex = 0; // 모바일 카드 인덱스 리셋
            _showMobileCardList = false; // 모바일 카드 리스트 숨김 (UX 개선)
          });

          // 모바일 PageView를 첫 번째 카드로 이동
          if (_isMobile &&
              _mobileCardController.hasClients) {
            _mobileCardController.jumpToPage(0);
          }
          return;
        }

        // 개별 마커(클러스터 크기 1)는 onMarkerTap 콜백이 처리하므로 여기서는 스킵
        // (중복 토글 방지: 이 리스너와 onMarkerTap 콜백이 동시에 토글하는 버그 수정)
        if (clusterRoomIds.length == 1) {
          return;
        }

        // 클러스터 필터링 활성화 (클러스터 크기 >= 2)

        // 🎯 Coordinator: 클러스터 클릭 이벤트 처리 가능 여부 확인
        final coordinator = Provider.of<MapInteractionCoordinator>(
          context,
          listen: false,
        );
        if (!coordinator.canProcessEvent(EventType.clusterClick)) {
          return;
        }

        // 클릭된 클러스터의 첫 번째 방 ID 가져오기
        final clickedRoomId = data['roomId'] as int?;

        setState(() {
          _filteredByCluster = true;
          _clusterRoomIds = clusterRoomIds;
          _selectedRoom = null; // 선택된 방 초기화
          _currentMobileCardIndex = 0; // 모바일 카드 인덱스를 0으로 리셋 (첫 번째 매물 표시)
          _showMobileCardList =
              true; // 다른 클러스터 클릭 시 카드 리스트 무조건 노출 (같은 클러스터 재클릭은 clusterRoomIds.isEmpty로 별도 처리)
        });

        // 클러스터 마커 선택 (파란색으로 표시)
        if (clickedRoomId != null) {
          _mapController.selectMarker(clickedRoomId);
        }

        // 모바일 PageView를 첫 번째 카드로 이동
        if (_isMobile &&
            _mobileCardController.hasClients) {
          _mobileCardController.jumpToPage(0);
        }
      }
    };
    html.window.addEventListener('message', _clusterClickListener);
  }

  /// 저장된 필터 로드 (localStorage - 방 상세 뒤로가기 시에만 복원)
  void _loadSavedFilters() {
    // 필터는 _restoreMapStateIfNeeded에서 지도 상태와 함께 복원됨
    _loadRooms();
  }

  /// _filters.dateRange → _checkInDate/_checkOutDate 동기화
  void _syncDatesFromFilters() {
    if (_filters.dateRange != null) {
      _checkInDate = _filters.dateRange!.startDate;
      _checkOutDate = _filters.dateRange!.endDate;
    } else {
      _checkInDate = null;
      _checkOutDate = null;
    }
  }

  void _onFilterChanged(SearchFilters newFilters) {
    final dateChanged = _filters.dateRange != newFilters.dateRange;

    setState(() {
      _filters = newFilters;
    });

    // 날짜 필터가 변경된 경우 → API 재호출 (isAvailable 갱신 필요)
    if (dateChanged) {
      _syncDatesFromFilters();
      if (_currentSwLat != null &&
          _currentSwLng != null &&
          _currentNeLat != null &&
          _currentNeLng != null) {
        _loadRoomsByBounds(
          _currentSwLat!,
          _currentSwLng!,
          _currentNeLat!,
          _currentNeLng!,
          zoom: _currentZoomLevel,
          forceRefresh: true,
        );
      }
    }
    // 날짜 외 필터: 프론트엔드 필터링이므로 API 재호출 불필요
  }

  /// 방 상세 진입 전 현재 지도 상태(줌/위치/마커/필터)를 localStorage에 저장
  void _saveMapState(int roomId) {
    if (_currentSwLat == null || _currentNeLat == null) return;
    final data = jsonEncode({
      'lat': (_currentSwLat! + _currentNeLat!) / 2,
      'lng': (_currentSwLng! + _currentNeLng!) / 2,
      'zoom': _currentZoomLevel ?? 5,
      'selectedRoomId': roomId,
      'filters': _filters.toJson(),
    });
    html.window.localStorage['map_restore_state'] = data;
  }

  /// localStorage에서 지도 상태(줌/위치/마커/필터) 복원 (카카오맵 초기화 완료 후 호출)
  void _restoreMapStateIfNeeded() {
    final raw = html.window.localStorage['map_restore_state'];
    if (raw == null) return;
    html.window.localStorage.remove('map_restore_state');

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final lat = (data['lat'] as num).toDouble();
      final lng = (data['lng'] as num).toDouble();
      final zoom = (data['zoom'] as num).toInt();
      final selectedRoomId = data['selectedRoomId'] as int?;

      // 필터 복원
      if (data['filters'] != null) {
        setState(() {
          _filters = SearchFilters.fromJson(
              data['filters'] as Map<String, dynamic>);
          _syncDatesFromFilters();
        });
      }

      _mapController.focusOnLocation(lat, lng, zoomLevel: zoom);
      if (selectedRoomId != null) {
        _mapController.selectMarker(selectedRoomId);
      }
    } catch (_) {
      // 파싱 실패 시 무시
    }
  }

  void _onRoomSelected(
    Room? room, {
    bool focusMap = false,
    bool shouldScroll = true,
  }) {

    setState(() {
      _selectedRoom = room;
    });

    // 지도 포커싱 및 마커 선택
    if (room != null) {
      // 마커 선택 (흰색 → 파란색)
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
                        desktop: _buildDesktopLayout(),
                      ),
              ),
            ],
          ),

          // 모바일 하단 네비게이션
          if (!ResponsiveUtil.isDesktop(context))
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: MobileBottomNav(),
            ),
        ],
      ),
    );
  }

  /// 데스크톱 레이아웃: 좌측 리스트 + 우측 지도
  Widget _buildDesktopLayout() {
    final filteredRooms = _getFilteredRoomsForList();
    return Row(
      children: [
        // 왼쪽: 매물 리스트 (반응형 너비: 화면의 30%, 최소 300px, 최대 450px)
        if (filteredRooms.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final listWidth = (screenWidth * 0.3).clamp(300.0, 450.0);
              return Container(
                width: listWidth,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    right: BorderSide(color: AppColors.textPrimary),
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
                Positioned.fill(
                  child: Center(
                    child: _buildEmptyMessage(
                      _currentZoomLevel != null && _currentZoomLevel! >= 6
                          ? '지도를 확대해서 방을 찾아주세요.'
                          : '현재 위치에 조건이 일치하는 방이 없습니다.',
                    ),
                  ),
                ),

              // 필터링 결과 없음 메시지
              if (!_isLoading &&
                  filteredRooms.isEmpty &&
                  _roomsForMap.isNotEmpty)
                Positioned.fill(
                  child: Center(
                    child: _buildEmptyMessage('일치하는 조건의 방이 없습니다'),
                  ),
                ),

              // 오픈 전 안내 overlay 카드
              if (_roomsForMap.isEmpty)
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: OpeningNoticeCard(
                      onAlertTap: _handleMapAlertRequest,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 데스크톱 지도 위 빈 상태 안내 메시지 컨테이너
  Widget _buildEmptyMessage(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        message,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 필터링된 방 목록 가져오기 (지도용 - 클러스터 필터링 제외)
  List<Map<String, dynamic>> _getFilteredRooms() {
    return MapFilterUtils.filterRooms(
      rooms: _roomsForMap,
      filters: _filters,
      swLat: _currentSwLat,
      swLng: _currentSwLng,
      neLat: _currentNeLat,
      neLng: _currentNeLng,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
    );
  }

  /// 리스트용 필터링 (클러스터 필터링 포함)
  List<Map<String, dynamic>> _getFilteredRoomsForList() {
    return MapFilterUtils.filterRoomsForList(
      rooms: _roomsForMap,
      filters: _filters,
      filteredByCluster: _filteredByCluster,
      clusterRoomIds: _clusterRoomIds,
      swLat: _currentSwLat,
      swLng: _currentSwLng,
      neLat: _currentNeLat,
      neLng: _currentNeLng,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
    );
  }

  Widget _buildPropertyList() {
    return PropertyListPanel(
      filteredRooms: _getFilteredRoomsForList(),
      selectedRoomId: _selectedRoom?.id,
      scrollController: _listScrollController,
      onSaveMapState: _saveMapState,
      onRoomHover: (room) {
        _onRoomSelected(room, focusMap: false, shouldScroll: false);
      },
    );
  }

  /// 오픈 알림 신청 (지도 화면용)
  Future<void> _handleMapAlertRequest() async {
    // 로그인 상태 확인
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isLoggedIn) {
      context.go('/login');
      return;
    }
    final result = await RegionAlertService().requestAlert();
    if (!mounted) return;
    if (result == null) {
      CustomToast.error(context, '알림 신청에 실패했습니다. 다시 시도해주세요.');
      return;
    }
    await RegionAlertModal.show(
      context,
      alreadyRegistered: result.alreadyRegistered,
    );
  }

  /// 지도만 표시 (모바일/태블릿용)
  Widget _buildMapOnly() {
    return MapOnlyLayout(
      mapWidget: _buildMap(),
      filteredRooms: _getFilteredRoomsForList(),
      isLoading: _isLoading,
      showMobileCardList: _showMobileCardList,
      currentMobileCardIndex: _currentMobileCardIndex,
      currentZoomLevel: _currentZoomLevel,
      mobileCardController: _mobileCardController,
      openingNoticeWidget: _roomsForMap.isEmpty
          ? OpeningNoticeCard(onAlertTap: _handleMapAlertRequest)
          : null,
      onBadgeTap: () {
        setState(() {
          _showMobileCardList = !_showMobileCardList;
          _selectedRoom = null;
        });
      },
      onPageChanged: (index) {
        setState(() {
          _currentMobileCardIndex = index;
        });
      },
      onSaveMapState: _saveMapState,
      onDeselectMarker: () {
        _mapController.selectMarker(-1);
      },
    );
  }

  Widget _buildMap() {
    return KakaoMapSection(
      controller: _mapController,
      rooms: _getFilteredRooms(),
      isDesktop: _isDesktop,
      isMobile: _isMobile,
      onMarkerTap: _handleMarkerTap,
      onBoundsChanged: _handleBoundsChanged,
    );
  }

  /// 마커 클릭 이벤트 처리 (roomId: -1 = 선택 해제)
  void _handleMarkerTap(int roomId, Map<String, dynamic> roomData) {
    if (!mounted) return;

    if (roomId == -1) {
      setState(() {
        _selectedRoom = null;
        _filteredByCluster = false;
        _clusterRoomIds = [];
        _currentMobileCardIndex = 0;
        _showMobileCardList = false;
      });
      if (!_isDesktop && _mobileCardController.hasClients) {
        _mobileCardController.jumpToPage(0);
      }
      return;
    }

    final filteredRooms = _getFilteredRooms();
    final selectedRoomData = filteredRooms.firstWhere(
      (r) => r['id'] == roomId,
      orElse: () => filteredRooms.first,
    );

    if (_isDesktop) {
      setState(() {
        _filteredByCluster = true;
        _clusterRoomIds = [roomId];
      });
      _onRoomSelected(
        Room.fromJson(_buildRoomJson(selectedRoomData, roomData)),
        focusMap: false,
      );
    } else {
      // 🎯 Coordinator: 마커 클릭 이벤트 처리 가능 여부 확인
      final coordinator = Provider.of<MapInteractionCoordinator>(
        context,
        listen: false,
      );
      if (!coordinator.canProcessEvent(EventType.markerClick)) return;

      setState(() {
        _showMobileCardList = true;
        _filteredByCluster = true;
        _clusterRoomIds = [roomId];
        _currentMobileCardIndex = 0;
      });
      _onRoomSelected(
        Room.fromJson(_buildRoomJson(selectedRoomData, roomData)),
        focusMap: false,
      );
      if (_isMobile && _mobileCardController.hasClients) {
        _mobileCardController.jumpToPage(0);
      }
    }
  }

  /// 지도 영역 변경 이벤트 처리
  void _handleBoundsChanged(
    double swLat,
    double swLng,
    double neLat,
    double neLng,
    int zoom,
  ) {
    if (!mounted) return;

    // 카카오맵 초기화 완료 후 최초 1회: localStorage 지도 상태 복원
    if (!_mapRestoreAttempted) {
      _mapRestoreAttempted = true;
      _restoreMapStateIfNeeded();
    }

    // 줌 레벨 6 이상이면 매물 초기화 후 즉시 종료
    if (zoom >= 6) {
      setState(() {
        _roomsForMap = [];
      });
      return;
    }

    // 모바일 환경에서 슬라이드 카드가 표시 중이면 숨김 (지도 드래그 시)
    if (_isMobile && _showMobileCardList) {
      setState(() {
        _showMobileCardList = false;
      });
    }

    // 선택된 마커가 있으면 해제 (UX 개선: 지도 드래그 시 선택 초기화)
    if (_selectedRoom != null || _filteredByCluster) {
      setState(() {
        _selectedRoom = null;
        _filteredByCluster = false;
        _clusterRoomIds = [];
        _currentMobileCardIndex = 0;
      });
      _mapController.selectMarker(-1);
      if (!_isDesktop && _mobileCardController.hasClients) {
        _mobileCardController.jumpToPage(0);
      }
    }

    _loadRoomsByBounds(swLat, swLng, neLat, neLng, zoom: zoom);
  }

  /// 마커 클릭 시 Room.fromJson에 필요한 JSON 맵 빌드 (공통 헬퍼)
  Map<String, dynamic> _buildRoomJson(
    Map<String, dynamic> selectedRoomData,
    Map<String, dynamic> rawMarkerData,
  ) {
    final photosData = selectedRoomData['photos'] as List<dynamic>?;
    final photos = photosData != null && photosData.isNotEmpty
        ? photosData.map((photo) {
            final relativeUrl = photo['url'] ?? '';
            final fullUrl = ContractUtils.getFullImageUrl(relativeUrl);
            return {'url': fullUrl, 'order': photo['order'] ?? 0};
          }).toList()
        : <Map<String, dynamic>>[];

    return {
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
      'minContractDays': 28,
      'refundPolicy': 'moderate',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'photos': photos,
      'isNearSubway': false,
      'isAvailable': rawMarkerData['isAvailable'] ?? true,
      'hostName': '임대인',
      'hostId': 1,
      'status': 'published',
    };
  }


  /// 드래그 가능한 스크롤 인디케이터
}
