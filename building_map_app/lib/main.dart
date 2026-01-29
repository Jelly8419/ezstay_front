import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:provider/provider.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'config/kakao_config.dart';
import 'constants/app_constants.dart';
import 'services/auth_service.dart';
import 'services/error_handler_service.dart';
import 'services/room_service.dart';
import 'services/map_interaction_coordinator.dart';
import 'services/payment_service_unified.dart';
import 'providers/gnb_provider.dart';
import 'router/app_router.dart';
import 'widgets/kakao_map_web.dart';
import 'widgets/splash_screen.dart';

/// Flutter Web Focus 에러 방지를 위한 안전한 Focus Traversal Policy
/// inactive element의 renderObject 접근 시도를 안전하게 처리
class SafeFocusTraversalPolicy extends ReadingOrderTraversalPolicy {
  @override
  Iterable<FocusNode> sortDescendants(Iterable<FocusNode> descendants, FocusNode currentNode) {
    try {
      return super.sortDescendants(descendants, currentNode);
    } catch (e) {
      // inactive element 에러 무시하고 빈 리스트 반환
      debugPrint('⚠️ [SafeFocusTraversalPolicy] Focus 정렬 중 에러 무시: $e');
      return <FocusNode>[];
    }
  }

  @override
  FocusNode? findFirstFocus(FocusNode currentNode, {bool ignoreCurrentFocus = false}) {
    try {
      return super.findFirstFocus(currentNode, ignoreCurrentFocus: ignoreCurrentFocus);
    } catch (e) {
      // inactive element 에러 무시
      debugPrint('⚠️ [SafeFocusTraversalPolicy] 첫 Focus 찾기 중 에러 무시: $e');
      return null;
    }
  }
}

/// 앱의 진입점
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드 (환경별 분리)
  // 빌드 시 --dart-define=ENVIRONMENT=test/production 으로 지정
  const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  final envFile = environment == 'production'
      ? '.env.production'
      : environment == 'test'
          ? '.env.test'
          : '.env';

  debugPrint('🔧 [ENV] 환경: $environment, 로드할 파일: $envFile');

  // .env 파일 로드 시도 (실패해도 계속 진행)
  // 프로덕션 빌드에서는 --dart-define으로 전달된 값 사용
  try {
    await dotenv.load(fileName: envFile);
    debugPrint('✅ [ENV] $envFile 파일 로드 성공');
  } catch (e) {
    debugPrint('⚠️ [ENV] $envFile 파일 로드 실패 (--dart-define 값 사용): $e');
  }

  // 한국어 날짜 포맷 초기화 (intl 패키지)
  await initializeDateFormatting('ko_KR', null);

  // 웹에서 URL의 '#' 제거 (path 기반 라우팅 사용)
  usePathUrlStrategy();

  // 카카오 SDK 초기화 (dotenv 로드 후 호출 - 안전성 보장)
  kakao.KakaoSdk.init(
    nativeAppKey: KakaoConfig.restApiKey,
    javaScriptAppKey: KakaoConfig.restApiKey,
  );

  // 🔥 Firebase 초기화를 백그라운드로 이동 (await 제거)
  final firebaseInitFuture = _initializeFirebase();

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

  // 웹 결제 서비스 초기화 (토스페이먼츠 SDK)
  if (kIsWeb) {
    final paymentService = PaymentServiceUnified();
    paymentService.initializeWebSDK();
    debugPrint('✅ [MAIN] 토스페이먼츠 웹 SDK 초기화 완료');
  }

  // 🔥 자동 로그인을 백그라운드로 실행 (await 제거)
  unawaited(authService.tryAutoLogin());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(create: (_) => GNBProvider()),
        // 지도 상호작용 조정자 (이벤트 충돌 방지)
        ChangeNotifierProvider(create: (_) => MapInteractionCoordinator()),
        // Firebase 초기화 Future 제공
        Provider<Future<FirebaseApp>>.value(value: firebaseInitFuture),
      ],
      child: const MyApp(),
    ),
  );
}

/// Firebase 초기화를 별도 함수로 분리 (백그라운드 실행)
Future<FirebaseApp> _initializeFirebase() async {
  debugPrint('🔥 [MAIN] Firebase 초기화 시작 (백그라운드)...');
  try {
    late FirebaseApp app;
    if (kIsWeb) {
      // 웹에서는 명시적으로 설정 전달
      debugPrint('🔥 [MAIN] 웹 플랫폼 감지 - 수동 Firebase 초기화');
      app = await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBDwxJU7ivdjfdMOJeA7N_buRjdJLfdKUs',
          appId: '1:922042336723:web:054fdbcc6b9b219aed1b26',
          messagingSenderId: '922042336723',
          projectId: 'ezstay-864bc',
          authDomain: 'ezstay-864bc.firebaseapp.com',
          storageBucket: 'ezstay-864bc.firebasestorage.app',
          measurementId: 'G-1QZK8YMFEV',
        ),
      );
    } else {
      debugPrint('🔥 [MAIN] 네이티브 플랫폼 - 기본 Firebase 초기화');
      app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    debugPrint('✅ [MAIN] Firebase 초기화 완료 (백그라운드)');
    return app;
  } catch (e) {
    debugPrint('❌ [MAIN] Firebase 초기화 실패: $e');
    rethrow;
  }
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
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    // GoRouter를 한 번만 생성
    _router ??= AppRouter.createRouter(authService, navigatorKey: _navigatorKey);

    // 다음 프레임에서 navigator context 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _navigatorKey.currentContext != null) {
        _errorHandler.setContext(_navigatorKey.currentContext!);
      }
    });

    // 🔥 초기화 중에는 스플래시 화면 표시
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (!authService.isInitialized) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            home: const SplashScreen(),
          );
        }

        return MaterialApp.router(
          title: 'EZStay',
          debugShowCheckedModeBanner: false,
          routerConfig: _router!,
          theme: AppTheme.lightTheme(),
          // Flutter Web Focus 에러 방지: 커스텀 Focus Traversal Policy 적용
          builder: (context, child) {
            return FocusTraversalGroup(
              policy: SafeFocusTraversalPolicy(),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
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