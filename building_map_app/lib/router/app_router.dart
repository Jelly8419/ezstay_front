import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

// 즉시 로딩 (자주 사용하는 페이지)
import '../pages/auth/login_page.dart';
import '../pages/guest/guest_home_page.dart';
import '../pages/guest/map_screen.dart';

// 지연 로딩 (필요할 때만 로드) - 웹 번들 크기 최적화
import '../pages/auth/mode_selection_page.dart' deferred as mode_selection;
import '../pages/auth/register_page.dart' deferred as register;
import '../pages/guest/room_detail_page.dart' deferred as room_detail;
import '../pages/host/host_home_page.dart' deferred as host_home;
import '../pages/host/room_registration/room_registration_page.dart' deferred as room_registration;
import '../pages/host/room_registration/pricing_page.dart' deferred as pricing;
import '../pages/host/room_registration/room_amenities_page.dart' deferred as amenities;
import '../pages/host/room_registration/free_services_page.dart' deferred as free_services;
import '../pages/host/room_registration/room_description_page.dart' deferred as room_description;
import '../pages/contract/guest_contracts_page.dart' deferred as guest_contracts;
import '../pages/contract/host_contracts_page.dart' deferred as host_contracts;
import '../pages/contract/contract_detail_page.dart' deferred as contract_detail;
import '../pages/chat/chat_list_page.dart' deferred as chat_list;
import '../pages/chat/chat_detail_page.dart' deferred as chat_detail;
import '../pages/support/support_center_page.dart' deferred as support_center;
import '../pages/support/notice_list_page.dart' deferred as notice_list;
import '../pages/support/notice_detail_page.dart' deferred as notice_detail;
import '../pages/support/faq_list_page.dart' deferred as faq_list;
import '../pages/support/inquiry_list_page.dart' deferred as inquiry_list;
import '../pages/support/inquiry_form_page.dart' deferred as inquiry_form;
import '../pages/support/inquiry_detail_page.dart' deferred as inquiry_detail;

class AppRouter {
  /// Deferred 라이브러리 로딩 위젯
  static Widget _deferredWidget(Future<void> Function() loadLibrary, Widget Function() builder) {
    return FutureBuilder(
      future: loadLibrary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return builder();
        }
        // 로딩 중 표시
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  /// Path 파라미터를 int로 파싱하는 헬퍼 함수
  static int? _parseIntParameter(String? value) {
    return value != null ? int.tryParse(value) : null;
  }

  /// 잘못된 접근 에러 페이지 빌더
  static Widget _buildInvalidAccessPage(
    BuildContext context, {
    required String message,
    required String buttonText,
    required String redirectPath,
  }) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(redirectPath),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  static GoRouter createRouter(AuthService authService, {GlobalKey<NavigatorState>? navigatorKey}) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: true,
      redirect: (BuildContext context, GoRouterState state) {
        final isInitialized = authService.isInitialized;
        final isLoggedIn = authService.isLoggedIn;
        final isGoingToRoot = state.matchedLocation == '/';
        final isGoingToLogin = state.matchedLocation == '/login';
        final isGoingToBypass = state.matchedLocation.startsWith('/bypass');
        final isGoingToMap = state.matchedLocation == '/map';
        final isGoingToGuest = state.matchedLocation == '/guest';

        // 초기화가 완료되지 않았으면 리다이렉트하지 않음 (로딩 중)
        if (!isInitialized) {
          return null;
        }

        // 바이패스 로그인 경로는 리다이렉트 안 함
        if (isGoingToBypass) {
          return null;
        }

        // 루트 경로(/) 접근 시 사용자 모드에 따라 리다이렉트
        if (isGoingToRoot) {
          if (isLoggedIn) {
            final userMode = authService.currentUser?.mode;
            if (userMode == UserMode.host) {
              return '/host';
            } else {
              return '/guest';
            }
          } else {
            // 로그인 안 된 경우 게스트 홈으로
            return '/guest';
          }
        }

        // 로그인된 상태에서 로그인 페이지 접근 시 홈으로 리다이렉트
        if (isLoggedIn && isGoingToLogin) {
          final userMode = authService.currentUser?.mode;
          if (userMode == UserMode.host) {
            return '/host';
          } else {
            return '/guest';
          }
        }

        // 로그인 안 된 상태에서 호스트 전용 페이지 접근 시 게스트 홈으로 리다이렉트
        if (!isLoggedIn &&
            !isGoingToLogin &&
            !isGoingToGuest &&
            !isGoingToMap &&
            state.matchedLocation.startsWith('/host')) {
          return '/guest';
        }

        // 로그인 안 된 상태에서 계약 관리 등 보호된 페이지 접근 시 로그인 페이지로
        if (!isLoggedIn &&
            !isGoingToLogin &&
            !isGoingToGuest &&
            !isGoingToMap &&
            (state.matchedLocation.contains('/contracts') ||
             state.matchedLocation.contains('/chat'))) {
          return '/login';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/mode-selection',
          name: 'mode-selection',
          builder: (context, state) => _deferredWidget(
            mode_selection.loadLibrary,
            () => mode_selection.ModeSelectionPage(
              onModeSelected: (UserMode mode) async {
                final authService = Provider.of<AuthService>(context, listen: false);

                // 소셜 로그인 타입에 따라 처리
                final loginType = state.extra as String?;

                if (loginType == 'email') {
                  // 이메일 회원가입 플로우 - 회원가입 페이지로 이동
                  await register.loadLibrary();
                  if (context.mounted) {
                    context.push('/register', extra: mode);
                  }
                  return;
                }

                // 소셜 로그인 처리 (google, kakao)
                bool success = false;
                if (loginType == 'google') {
                  success = await authService.loginWithGoogle(mode);
                } else if (loginType == 'kakao') {
                  success = await authService.loginWithKakao(mode);
                }

                if (success && context.mounted) {
                  // 소셜 로그인 성공 → RegisterPage로 이동 (추가 정보 입력)
                  final currentUser = authService.currentUser;
                  await register.loadLibrary();

                  if (context.mounted) {
                    context.push(
                      '/register',
                      extra: {
                        'mode': mode,
                        'email': currentUser?.email,
                        'name': currentUser?.name,
                        'isSocialLogin': true,
                      },
                    );
                  }
                } else if (context.mounted) {
                  context.pop();
                }
              },
            ),
          ),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) {
            // extra가 Map이면 소셜 로그인, UserMode면 일반 회원가입
            if (state.extra is Map<String, dynamic>) {
              final params = state.extra as Map<String, dynamic>;
              return _deferredWidget(
                register.loadLibrary,
                () => register.RegisterPage(
                  mode: params['mode'] as UserMode? ?? UserMode.guest,
                  initialEmail: params['email'] as String?,
                  initialName: params['name'] as String?,
                  isSocialLogin: params['isSocialLogin'] as bool? ?? false,
                ),
              );
            } else {
              // 일반 회원가입 (이메일)
              final mode = state.extra as UserMode? ?? UserMode.guest;
              return _deferredWidget(
                register.loadLibrary,
                () => register.RegisterPage(mode: mode),
              );
            }
          },
        ),
        GoRoute(
          path: '/guest',
          name: 'guest',
          builder: (context, state) => const GuestHomePage(),
        ),
        GoRoute(
          path: '/guest/room/detail/:roomId',
          name: 'room-detail',
          builder: (context, state) {
            final roomId = _parseIntParameter(state.pathParameters['roomId']);

            if (roomId == null) {
              return _buildInvalidAccessPage(
                context,
                message: '잘못된 접근입니다.',
                buttonText: '지도로 돌아가기',
                redirectPath: '/map',
              );
            }

            return _deferredWidget(
              room_detail.loadLibrary,
              () => room_detail.RoomDetailPage(roomId: roomId),
            );
          }
        ),
        GoRoute(
          path: '/host',
          name: 'host',
          builder: (context, state) => _deferredWidget(
            host_home.loadLibrary,
            () => host_home.HostHomePage(),
          ),
        ),
        GoRoute(
          path: '/host/room-registration',
          builder: (context, state) {
            return _deferredWidget(
              room_registration.loadLibrary,
              () => room_registration.RoomRegistrationPage(roomId: null),
            );
          },
        ),
        GoRoute(
          path: '/host/room-registration/:roomId',
          name: 'room-registration',
          builder: (context, state) {
            final roomId = _parseIntParameter(state.pathParameters['roomId']);
            return _deferredWidget(
              room_registration.loadLibrary,
              () => room_registration.RoomRegistrationPage(roomId: roomId),
            );
          },
        ),
        GoRoute(
          path: '/host/pricing/:roomId',
          name: 'pricing',
          builder: (context, state) {
            final roomId = _parseIntParameter(state.pathParameters['roomId']);
            return _deferredWidget(
              pricing.loadLibrary,
              () => pricing.PricingPage(roomId: roomId),
            );
          },
        ),
        GoRoute(
          path: '/host/amenities/:roomId',
          name: 'amenities',
          builder: (context, state) {
            final roomId = _parseIntParameter(state.pathParameters['roomId']);
            return _deferredWidget(
              amenities.loadLibrary,
              () => amenities.RoomAmenitiesPage(roomId: roomId),
            );
          },
        ),
        GoRoute(
          path: '/host/free-services/:roomId',
          name: 'free-services',
          builder: (context, state) {
            final roomId = _parseIntParameter(state.pathParameters['roomId']);
            return _deferredWidget(
              free_services.loadLibrary,
              () => free_services.FreeServicesPage(roomId: roomId),
            );
          },
        ),
        GoRoute(
          path: '/host/room-description/:roomId',
          name: 'room-description',
          builder: (context, state) {
            final roomId = _parseIntParameter(state.pathParameters['roomId']);
            return _deferredWidget(
              room_description.loadLibrary,
              () => room_description.RoomDescriptionPage(roomId: roomId),
            );
          },
        ),
        GoRoute(
          path: '/map',
          name: 'map',
          builder: (context, state) => const MapScreen(),
        ),
        GoRoute(
          path: '/guest/contracts',
          name: 'guest-contracts',
          builder: (context, state) => _deferredWidget(
            guest_contracts.loadLibrary,
            () => guest_contracts.GuestContractsPage(),
          ),
          routes: [
            GoRoute(
              path: ':contractId',
              name: 'guest-contract-detail',
              builder: (context, state) {
                final contractId = state.pathParameters['contractId'] ?? '';
                return _deferredWidget(
                  contract_detail.loadLibrary,
                  () => contract_detail.ContractDetailPage(contractId: contractId),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/host/contracts',
          name: 'host-contracts',
          builder: (context, state) => _deferredWidget(
            host_contracts.loadLibrary,
            () => host_contracts.HostContractsPage(),
          ),
          routes: [
            GoRoute(
              path: ':contractId',
              name: 'host-contract-detail',
              builder: (context, state) {
                final contractId = state.pathParameters['contractId'] ?? '';
                return _deferredWidget(
                  contract_detail.loadLibrary,
                  () => contract_detail.ContractDetailPage(contractId: contractId),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/chat-list',
          name: 'chat-list',
          builder: (context, state) => _deferredWidget(
            chat_list.loadLibrary,
            () => chat_list.ChatListPage(),
          ),
        ),
        GoRoute(
          path: '/chat-detail',
          name: 'chat-detail',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>?;
            final chatRoomId = args?['chatRoomId'] as String?;
            final contractId = args?['contractId'] as int?;

            if (chatRoomId == null) {
              return _buildInvalidAccessPage(
                context,
                message: '잘못된 접근입니다.',
                buttonText: '채팅 목록으로 돌아가기',
                redirectPath: '/chat-list',
              );
            }

            return _deferredWidget(
              chat_detail.loadLibrary,
              () => chat_detail.ChatDetailPage(
                chatRoomId: chatRoomId,
                contractId: contractId,
              ),
            );
          },
        ),
        // 고객센터 라우트
        GoRoute(
          path: '/support',
          name: 'support-center',
          builder: (context, state) {
            return _deferredWidget(
              support_center.loadLibrary,
              () => support_center.SupportCenterPage(),
            );
          },
          routes: [
            // 공지사항 목록
            GoRoute(
              path: 'notices',
              name: 'notice-list',
              builder: (context, state) => _deferredWidget(
                notice_list.loadLibrary,
                () => notice_list.NoticeListPage(),
              ),
            ),
            // 공지사항 상세
            GoRoute(
              path: 'notice/:noticeId',
              name: 'notice-detail',
              builder: (context, state) {
                final noticeId = _parseIntParameter(state.pathParameters['noticeId']);

                if (noticeId == null) {
                  return _buildInvalidAccessPage(
                    context,
                    message: '잘못된 접근입니다.',
                    buttonText: '고객센터로 돌아가기',
                    redirectPath: '/support',
                  );
                }

                return _deferredWidget(
                  notice_detail.loadLibrary,
                  () => notice_detail.NoticeDetailPage(noticeId: noticeId),
                );
              },
            ),
            // FAQ 목록
            GoRoute(
              path: 'faqs',
              name: 'faq-list',
              builder: (context, state) => _deferredWidget(
                faq_list.loadLibrary,
                () => faq_list.FAQListPage(),
              ),
            ),
            // 문의 목록
            GoRoute(
              path: 'inquiries',
              name: 'inquiry-list',
              builder: (context, state) => _deferredWidget(
                inquiry_list.loadLibrary,
                () => inquiry_list.InquiryListPage(),
              ),
            ),
            // 문의 작성
            GoRoute(
              path: 'inquiry/form',
              name: 'inquiry-form',
              builder: (context, state) => _deferredWidget(
                inquiry_form.loadLibrary,
                () => inquiry_form.InquiryFormPage(),
              ),
            ),
            GoRoute(
              path: 'inquiry/:inquiryId',
              name: 'inquiry-detail',
              builder: (context, state) {
                final inquiryId = _parseIntParameter(state.pathParameters['inquiryId']);

                if (inquiryId == null) {
                  return _buildInvalidAccessPage(
                    context,
                    message: '잘못된 접근입니다.',
                    buttonText: '문의 목록으로 돌아가기',
                    redirectPath: '/support?tab=inquiry',
                  );
                }

                return _deferredWidget(
                  inquiry_detail.loadLibrary,
                  () => inquiry_detail.InquiryDetailPage(inquiryId: inquiryId),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/bypass/:userId',
          name: 'dev-bypass',
          builder: (context, state) {
            final userId = state.pathParameters['userId'] ?? '';

            // 개발 환경에서만 동작
            return FutureBuilder(
              future: _handleDevBypass(context, userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('개발자 바이패스 로그인 중...'),
                        ],
                      ),
                    ),
                  );
                }

                // 로그인 완료 후 리다이렉트는 redirect 로직에서 처리
                return const GuestHomePage();
              },
            );
          },
        ),
      ],
    );
  }

  /// 개발자 바이패스 로그인 처리
  static Future<void> _handleDevBypass(BuildContext context, String userId) async {
    final authService = Provider.of<AuthService>(context, listen: false);

    final success = await authService.loginWithDevBypass(userId);

    if (success && context.mounted) {
      // 로그인 성공 시 사용자 모드에 따라 리다이렉트
      final userMode = authService.currentUser?.mode;
      if (userMode == UserMode.host) {
        context.go('/host');
      } else {
        context.go('/guest');
      }
    } else if (context.mounted) {
      // 로그인 실패 시 게스트 홈으로
      context.go('/guest');
    }
  }
}
