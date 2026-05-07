import 'package:building_map_app/core/utils/app_logger.dart';
import 'dart:async';
import 'dart:html' as html show window;
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
import 'core/theme/app_theme.dart';
import 'core/theme/app_text_styles.dart';
import 'services/auth_service.dart';
import 'services/error_handler_service.dart';
import 'services/launch_status_service.dart';
import 'services/map_interaction_coordinator.dart';
import 'services/payment_service_unified.dart';
import 'providers/gnb_provider.dart';
import 'providers/map_state_provider.dart';
import 'providers/promotion_provider.dart';
import 'providers/move_in/move_in_list_provider.dart';
import 'router/app_router.dart';
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
      AppLogger.w('⚠️ [SafeFocusTraversalPolicy] Focus 정렬 중 에러 무시: $e');
      return <FocusNode>[];
    }
  }

  @override
  FocusNode? findFirstFocus(FocusNode currentNode, {bool ignoreCurrentFocus = false}) {
    try {
      return super.findFirstFocus(currentNode, ignoreCurrentFocus: ignoreCurrentFocus);
    } catch (e) {
      // inactive element 에러 무시
      AppLogger.w('⚠️ [SafeFocusTraversalPolicy] 첫 Focus 찾기 중 에러 무시: $e');
      return null;
    }
  }
}

/// Flutter 내부 에러(assertion, unhandled exception) 발생 시 표시할 커스텀 위젯
///
/// [ErrorWidget.builder]에 등록되며, 기본 빨간 화면 대신 표시됩니다.
/// GoRouter context가 없는 시점에도 동작해야 하므로 Navigator.pushNamed 대신
/// html.window.location.href로 홈 이동 처리합니다.
class _AppErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const _AppErrorWidget(this.details);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.home_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 8),
              Text(
                'EZstay',
                style: AppTextStyles.headingSmall.copyWith(
                  color: const Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 32),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE3F2FD),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFF1565C0),
                      size: 36,
                    ),
                  ),
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ERROR',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '일시적인 오류가 발생했습니다',
                style: AppTextStyles.headingSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '잠시 후 다시 시도해주세요.\n문제가 지속되면 고객센터로 문의해주세요.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF6B7280),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // GoRouter context 없이 홈으로 이동
                    if (kIsWeb) {
                      html.window.location.href = '/';
                    } else if (context.mounted) {
                      Navigator.of(context, rootNavigator: true)
                          .pushNamedAndRemoveUntil('/', (_) => false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '홈으로 이동',
                    style: AppTextStyles.labelLarge,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '문의: support@ezstay.io',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 앱의 진입점
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Flutter framework 내부 에러(assertion 포함)를 커스텀 위젯으로 교체
  // 기본 빨간 화면 대신 EZStay 디자인의 에러 화면 표시
  ErrorWidget.builder = (FlutterErrorDetails details) {
    AppLogger.e('❌ [ErrorWidget] Flutter 에러: ${details.exceptionAsString()}');
    return _AppErrorWidget(details);
  };

  // Flutter 프레임워크 에러를 가로채서 로그만 남기고 앱 유지
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.e(
      '❌ [FlutterError] ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
    );
    // layout/assertion 에러는 ErrorWidget으로 처리되므로 FlutterError.presentError 호출 안 함
  };

  // .env 파일 로드 (환경별 분리)
  // 빌드 시 --dart-define=ENVIRONMENT=test/production 으로 지정
  const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  final envFile = environment == 'production'
      ? '.env.production'
      : environment == 'test'
          ? '.env.test'
          : '.env';


  // .env 파일 로드 시도 (실패해도 계속 진행)
  // 프로덕션 빌드에서는 --dart-define으로 전달된 값 사용
  try {
    await dotenv.load(fileName: envFile);
  } catch (e) {
    AppLogger.w('⚠️ [ENV] $envFile 파일 로드 실패 (--dart-define 값 사용): $e');
  }

  // 한국어 날짜 포맷 초기화 (intl 패키지)
  // 웹 DDC 빌드에서 deferred loading 타이밍 이슈로 실패할 수 있으므로 try-catch 처리
  try {
    await initializeDateFormatting('ko_KR', null);
  } catch (e) {
    AppLogger.w('⚠️ [MAIN] 한국어 날짜 포맷 초기화 실패 (기본 포맷 사용): $e');
  }

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
    AppLogger.w('경고: Kakao API 키가 설정되지 않았거나 유효하지 않습니다.');
  }

  // AuthService 생성 및 초기화
  final authService = AuthService();

  // 런칭 상태 서비스 (앱 부팅 시 1회 선조회, 실패해도 true 폴백으로 진행)
  final launchStatusService = LaunchStatusService();
  unawaited(launchStatusService.ensureLoaded());

  // 웹에서 카카오 콜백 확인
  if (kIsWeb) {
    await authService.handleKakaoWebCallback();
  }

  // 웹 결제 서비스 초기화 (PayTag SDK)
  // SDK 초기화 실패 시에도 앱이 계속 작동하도록 try-catch
  if (kIsWeb) {
    try {
      PaymentServiceUnified(); // 생성자에서 PayTag SDK 자동 초기화
    } catch (e) {
      AppLogger.w('⚠️ [MAIN] PayTag SDK 초기화 실패: $e');
      AppLogger.w('⚠️ [MAIN] 결제 기능이 비활성화됩니다. 앱은 계속 작동합니다.');
    }
  }

  // 🔥 자동 로그인을 백그라운드로 실행 (await 제거)
  unawaited(authService.tryAutoLogin());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: launchStatusService),
        ChangeNotifierProvider(create: (_) => GNBProvider()),
        // 지도 상호작용 조정자 (이벤트 충돌 방지)
        ChangeNotifierProvider(create: (_) => MapInteractionCoordinator()),
        // 지도 검색 상태 보존 (방 상세 진입 후 뒤로가기 시 위치 복원)
        ChangeNotifierProvider(create: (_) => MapStateProvider()),
        // 진행 중 프로모션 이벤트 전역 상태
        ChangeNotifierProvider(create: (_) => PromotionProvider()),
        // 입주 준비 서비스 — 호스트 케이스 목록 (홈 화면 진입 시 load)
        ChangeNotifierProvider(create: (_) => MoveInListProvider()),
        // Firebase 초기화 Future 제공
        Provider<Future<FirebaseApp>>.value(value: firebaseInitFuture),
      ],
      child: const MyApp(),
    ),
  );
}

/// Firebase 초기화를 별도 함수로 분리 (백그라운드 실행)
Future<FirebaseApp> _initializeFirebase() async {
  try {
    // 웹은 index.html의 env_config.js → window.firebaseConfig로 JS SDK가 먼저 초기화함
    // Flutter SDK는 DefaultFirebaseOptions를 통해 동일하게 처리
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return app;
  } catch (e) {
    AppLogger.e('❌ [MAIN] Firebase 초기화 실패: $e');
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
          // Flutter Web Focus 에러 방지 + 텍스트 선택 활성화
          builder: (context, child) {
            return FocusTraversalGroup(
              policy: SafeFocusTraversalPolicy(),
              // Overlay를 먼저 제공한 후 SelectionArea 적용
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) => SelectionArea(
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

