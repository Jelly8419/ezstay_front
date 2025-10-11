import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../pages/welcome_page.dart';
import '../pages/login_page.dart';
import '../pages/mode_selection_page.dart';
import '../pages/guest_home_page.dart';
import '../pages/host_home_page.dart';
import '../pages/room_registration_page.dart';
import '../pages/pricing_page.dart';
import '../pages/room_amenities_page.dart';
import '../pages/free_services_page.dart';
import '../pages/room_description_page.dart';
import '../pages/user_info_popup.dart';
import '../pages/map_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthService authService, {GlobalKey<NavigatorState>? navigatorKey}) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: true,
      redirect: (BuildContext context, GoRouterState state) {
        final isInitialized = authService.isInitialized;
        final isLoggedIn = authService.isLoggedIn;
        final isGoingToLogin = state.matchedLocation == '/login';
        final isGoingToWelcome = state.matchedLocation == '/';

        // 초기화가 완료되지 않았으면 리다이렉트하지 않음 (로딩 중)
        if (!isInitialized) {
          return null;
        }

        // 로그인된 상태에서 로그인 페이지나 웰컴 페이지 접근 시 홈으로 리다이렉트
        if (isLoggedIn && (isGoingToLogin || isGoingToWelcome)) {
          final userMode = authService.currentUser?.mode;
          if (userMode == UserMode.host) {
            return '/host';
          } else if (userMode == UserMode.guest) {
            return '/guest';
          }
        }

        // 로그인 안 된 상태에서 보호된 페이지 접근 시 로그인으로 리다이렉트
        if (!isLoggedIn && !isGoingToLogin && !isGoingToWelcome) {
          return '/login';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'welcome',
          builder: (context, state) => const WelcomePage(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/mode-selection',
          name: 'mode-selection',
          builder: (context, state) => ModeSelectionPage(
            onModeSelected: (UserMode mode) async {
              final authService = Provider.of<AuthService>(context, listen: false);

              // 소셜 로그인 타입에 따라 처리
              final loginType = state.extra as String?;

              bool success = false;
              if (loginType == 'google') {
                success = await authService.loginWithGoogle(mode);
              } else if (loginType == 'kakao') {
                success = await authService.loginWithKakao(mode);
              }

              if (success && context.mounted) {
                context.go('/');
                // 본인인증 정보 팝업으로 이동
                await Future.delayed(const Duration(milliseconds: 100));
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserInfoPopup(isFromSignup: true),
                    ),
                  );
                }
              } else if (context.mounted) {
                context.pop();
              }
            },
          ),
        ),
        GoRoute(
          path: '/guest',
          name: 'guest',
          builder: (context, state) => const GuestHomePage(),
        ),
        GoRoute(
          path: '/host',
          name: 'host',
          builder: (context, state) => const HostHomePage(),
        ),
        GoRoute(
          path: '/host/room-registration',
          builder: (context, state) {
            return const RoomRegistrationPage(roomId: null);
          },
        ),
        GoRoute(
          path: '/host/room-registration/:roomId',
          name: 'room-registration',
          builder: (context, state) {
            final roomIdStr = state.pathParameters['roomId'];
            final roomId = roomIdStr != null ? int.tryParse(roomIdStr) : null;
            return RoomRegistrationPage(roomId: roomId);
          },
        ),
        GoRoute(
          path: '/host/pricing/:roomId',
          name: 'pricing',
          builder: (context, state) {
            final roomIdStr = state.pathParameters['roomId'];
            final roomId = roomIdStr != null ? int.tryParse(roomIdStr) : null;
            return PricingPage(roomId: roomId);
          },
        ),
        GoRoute(
          path: '/host/amenities/:roomId',
          name: 'amenities',
          builder: (context, state) {
            final roomIdStr = state.pathParameters['roomId'];
            final roomId = roomIdStr != null ? int.tryParse(roomIdStr) : null;
            return RoomAmenitiesPage(roomId: roomId);
          },
        ),
        GoRoute(
          path: '/host/free-services/:roomId',
          name: 'free-services',
          builder: (context, state) {
            final roomIdStr = state.pathParameters['roomId'];
            final roomId = roomIdStr != null ? int.tryParse(roomIdStr) : null;
            return FreeServicesPage(roomId: roomId);
          },
        ),
        GoRoute(
          path: '/host/room-description/:roomId',
          name: 'room-description',
          builder: (context, state) {
            final roomIdStr = state.pathParameters['roomId'];
            final roomId = roomIdStr != null ? int.tryParse(roomIdStr) : null;
            return RoomDescriptionPage(roomId: roomId);
          },
        ),
        GoRoute(
          path: '/map',
          name: 'map',
          builder: (context, state) => const MapScreen(),
        ),
      ],
    );
  }
}
