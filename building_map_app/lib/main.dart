import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:provider/provider.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/kakao_config.dart';
import 'constants/app_constants.dart';
import 'services/auth_service.dart';
import 'services/error_handler_service.dart';
import 'services/room_service.dart';
import 'router/app_router.dart';
import 'widgets/kakao_map_web.dart';

/// 앱의 진입점
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드
  await dotenv.load(fileName: ".env");

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 한국어 날짜 포맷 초기화 (table_calendar를 위함)
  await initializeDateFormatting('ko_KR', null);

  // 웹에서 URL의 '#' 제거 (path 기반 라우팅 사용)
  usePathUrlStrategy();

  // 카카오 SDK 초기화
  kakao.KakaoSdk.init(
    nativeAppKey: KakaoConfig.restApiKey,
    javaScriptAppKey: KakaoConfig.restApiKey,
  );

  // 카카오 맵 초기화
  AuthRepository.initialize(appKey: KakaoConfig.javascriptKey);

  // API 키 유효성 검사
  if (!KakaoConfig.isApiKeyValid()) {
    debugPrint('경고: Kakao API 키가 설정되지 않았거나 유효하지 않습니다.');
    debugPrint('REST API 키: ${KakaoConfig.restApiKey}');
    debugPrint('JavaScript 키: ${KakaoConfig.javascriptKey}');
  }

  // AuthService 생성 및 초기화
  final authService = AuthService();

  // 웹에서 카카오 콜백 확인
  if (kIsWeb) {
    await authService.handleKakaoWebCallback();
  }

  // 자동 로그인 시도 (초기화 완료까지 대기)
  await authService.tryAutoLogin();

  runApp(
    ChangeNotifierProvider.value(
      value: authService,
      child: const MyApp(),
    ),
  );
}

/// 메인 앱 클래스
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _errorHandler = ErrorHandlerService();
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final router = AppRouter.createRouter(authService, navigatorKey: _navigatorKey);

    // 다음 프레임에서 navigator context 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _navigatorKey.currentContext != null) {
        _errorHandler.setContext(_navigatorKey.currentContext!);
      }
    });

    return MaterialApp.router(
      title: 'EZStay',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.lightTheme(),
    );
  }
}


/// 지도 화면을 보여주는 위젯
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

/// 지도 화면의 상태를 관리하는 클래스
class _MapScreenState extends State<MapScreen> {
  late KakaoMapController mapController; // 카카오 맵 컨트롤러
  Set<Marker> markers = {}; // 지도에 표시할 마커들
  final _roomService = RoomService();
  List<Map<String, dynamic>> _rooms = []; // 서버에서 가져온 방 목록
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  /// 서버에서 공개된 방 목록을 불러오기
  Future<void> _loadRooms() async {
    try {
      final rooms = await _roomService.getPublishedRooms();
      if (mounted) {
        setState(() {
          _rooms = rooms ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [MAP] 방 목록 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 방 데이터를 기반으로 마커를 생성하는 메소드
  List<Marker> _createMarkers() {
    if (_rooms.isEmpty) {
      return [];
    }

    return _rooms.where((room) {
      // latitude와 longitude가 존재하고 유효한 경우만 마커 생성
      return room['latitude'] != null &&
             room['longitude'] != null &&
             room['latitude'].toString().isNotEmpty &&
             room['longitude'].toString().isNotEmpty;
    }).map((room) {
      final lat = double.tryParse(room['latitude'].toString());
      final lng = double.tryParse(room['longitude'].toString());

      if (lat == null || lng == null) {
        return null;
      }

      return Marker(
        markerId: room['id'].toString(),
        latLng: LatLng(lat, lng),
        width: 30,
        height: 40,
        markerImageSrc: 'https://t1.daumcdn.net/localimg/localimages/07/mapapidoc/marker_red.png',
      );
    }).whereType<Marker>().toList();
  }

  /// 마커 탭 이벤트 처리
  void _onMarkerTap(String markerId, LatLng latLng, int zoomLevel) {
    final room = _rooms.firstWhere(
      (r) => r['id'].toString() == markerId,
      orElse: () => {},
    );
    if (room.isNotEmpty) {
      _showRoomDetails(room);
    }
  }

  /// 방 상세 정보를 모달로 표시하는 메소드
  void _showRoomDetails(Map<String, dynamic> room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 핸들바
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 방 이름
                Text(
                  room['roomName'] ?? '이름 없음',
                  style: AppTextStyles.heading1,
                ),
                const SizedBox(height: 12),
                // 건물 타입
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    room['buildingType'] ?? '알 수 없음',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 주소 정보
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        room['address'] ?? '주소 없음',
                        style: AppTextStyles.bodyLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 요금 정보
                if (room['weeklyRent'] != null)
                  Row(
                    children: [
                      const Icon(Icons.attach_money, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '주간 요금: ${room['weeklyRent']}원',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                // 방 정보
                Row(
                  children: [
                    if (room['roomCount'] != null) ...[
                      const Icon(Icons.bed, color: AppColors.primary, size: 20),
                      const SizedBox(width: 4),
                      Text('방 ${room['roomCount']}개'),
                      const SizedBox(width: 16),
                    ],
                    if (room['bathroomCount'] != null) ...[
                      const Icon(Icons.bathroom, color: AppColors.primary, size: 20),
                      const SizedBox(width: 4),
                      Text('욕실 ${room['bathroomCount']}개'),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                // 방 설명
                if (room['description'] != null && room['description'].toString().isNotEmpty)
                  Text(
                    room['description'],
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                const SizedBox(height: 24),
                // 닫기 버튼
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('닫기'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 지도가 생성되었을 때 호출되는 콜백
  void _onMapCreated(KakaoMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EZStay 지도'),
      ),
      body: kIsWeb ? _buildWebMap() : _buildNativeMap(),
    );
  }

  /// 웹용 지도 (HTML 기반 카카오 지도)
  Widget _buildWebMap() {
    debugPrint('🗺️ [MapScreen] _buildWebMap 호출됨, 방 개수: ${_rooms.length}');

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return KakaoMapWeb(
      rooms: _rooms,
      onMarkerTap: _showRoomDetails,
    );
  }

  /// 네이티브(Android/iOS)용 카카오 지도
  Widget _buildNativeMap() {
    return KakaoMap(
      onMapCreated: _onMapCreated,
      onMarkerTap: _onMarkerTap,
      center: LatLng(37.5666805, 126.9784147), // 서울시청 좌표
      markers: _createMarkers(),
      currentLevel: 5,
      zoomControl: true,
    );
  }
}