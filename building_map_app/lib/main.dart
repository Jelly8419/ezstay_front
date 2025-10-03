import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/building.dart';
import 'models/user.dart';
import 'data/dummy_buildings.dart';
import 'config/api_config.dart';
import 'config/kakao_config.dart';
import 'services/auth_service.dart';
import 'router/app_router.dart';

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

  // API 키 유효성 검사
  if (!ApiConfig.isApiKeyValid()) {
    debugPrint('경고: Google Maps API 키가 설정되지 않았거나 유효하지 않습니다.');
    debugPrint('API 키: ${ApiConfig.googleMapsApiKey}');
  }

  if (!KakaoConfig.isApiKeyValid()) {
    debugPrint('경고: Kakao API 키가 설정되지 않았거나 유효하지 않습니다.');
    debugPrint('API 키: ${KakaoConfig.restApiKey}');
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
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final router = AppRouter.createRouter(authService);

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
  GoogleMapController? mapController; // 구글 맵 컨트롤러
  Set<Marker> markers = {}; // 지도에 표시할 마커들

  /// 초기 카메라 위치 (서울시청 좌표)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.5666805, 126.9784147), // 서울시청 좌표
    zoom: 11.0,
  );

  @override
  void initState() {
    super.initState();
    _createMarkers(); // 마커 생성
  }

  /// 건물 데이터를 기반으로 마커를 생성하는 메소드
  void _createMarkers() {
    markers = DummyBuildings.buildings.map((building) {
      return Marker(
        markerId: MarkerId(building.id.toString()),
        position: LatLng(building.latitude, building.longitude),
        infoWindow: InfoWindow(
          title: building.name,
          snippet: building.type,
        ),
        onTap: () => _showBuildingDetails(building), // 마커 탭 시 상세 정보 표시
      );
    }).toSet();
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
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EZStay 지도'),
        backgroundColor: const Color(0xFF4A90E2),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated, // 지도 생성 콜백
        initialCameraPosition: _initialPosition, // 초기 카메라 위치
        markers: markers, // 마커 표시
        myLocationEnabled: true, // 내 위치 표시
        myLocationButtonEnabled: true, // 내 위치 버튼 활성화
        zoomControlsEnabled: true, // 줌 컨트롤 활성화
        mapToolbarEnabled: true, // 지도 툴바 활성화
      ),
    );
  }
}