import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:provider/provider.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/building.dart';
import 'data/dummy_buildings.dart';
import 'config/kakao_config.dart';
import 'services/auth_service.dart';
import 'services/error_handler_service.dart';
import 'router/app_router.dart';
import 'widgets/kakao_map_web.dart';

/// 앱의 진입점
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드
  await dotenv.load(fileName: ".env");

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
        cardTheme: const CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4DB5BD),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
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

  @override
  void initState() {
    super.initState();
  }

  /// 건물 데이터를 기반으로 마커를 생성하는 메소드
  List<Marker> _createMarkers() {
    return DummyBuildings.buildings.map((building) {
      return Marker(
        markerId: building.id.toString(),
        latLng: LatLng(building.latitude, building.longitude),
        width: 30,
        height: 40,
        markerImageSrc: 'https://t1.daumcdn.net/localimg/localimages/07/mapapidoc/marker_red.png',
      );
    }).toList();
  }

  /// 마커 탭 이벤트 처리
  void _onMarkerTap(String markerId, LatLng latLng, int zoomLevel) {
    final building = DummyBuildings.buildings.firstWhere(
      (b) => b.id.toString() == markerId,
      orElse: () => DummyBuildings.buildings.first,
    );
    _showBuildingDetails(building);
  }

  /// 건물 상세 정보를 모달로 표시하는 메소드
  void _showBuildingDetails(Building building) {
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 건물명
              Text(
                building.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              // 건물 타입
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  building.type,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A90E2),
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
                      color: const Color(0xFF4A90E2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFF4A90E2),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      building.address,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 건물 설명
              Text(
                building.description,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6C7B7F),
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
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '닫기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
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
        backgroundColor: const Color(0xFF4A90E2),
      ),
      body: kIsWeb ? _buildWebMap() : _buildNativeMap(),
    );
  }

  /// 웹용 지도 (HTML 기반 카카오 지도)
  Widget _buildWebMap() {
    debugPrint('🗺️ [MapScreen] _buildWebMap 호출됨');
    return KakaoMapWeb(
      buildings: DummyBuildings.buildings,
      onMarkerTap: _showBuildingDetails,
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