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
import '../pages/auth/register_flow_page.dart' deferred as register_flow;
import '../pages/guest/room_detail_page.dart' deferred as room_detail;
import '../pages/guest/guest_my_page.dart' deferred as guest_my_page;
import '../pages/host/host_home_page.dart' deferred as host_home;
import '../pages/host/host_account_setup_standalone_page.dart'
    deferred as host_account_setup_standalone;
import '../pages/host/room_registration/room_registration_flow_page.dart'
    deferred as room_registration;
import '../pages/contract/guest_contracts_page.dart'
    deferred as guest_contracts;
import '../pages/contract/guest_contract_detail_page.dart'
    deferred as guest_contract_detail;
import '../pages/contract/host_contracts_page_new.dart'
    deferred as host_contracts;
import '../pages/contract/host_contract_detail_page.dart'
    deferred as host_contract_detail;
import '../pages/contract/contract_start_page.dart' deferred as contract_start;
import '../pages/chat/chat_list_page.dart' deferred as chat_list;
import '../pages/chat/chat_detail_page.dart' deferred as chat_detail;
import '../pages/host/room_management_page.dart' deferred as room_management;
import '../pages/host/room_schedule_page.dart'; // 즉시 로딩으로 변경 (Focus 에러 방지)
import '../pages/host/host_my_page.dart' deferred as host_my_page;
import '../pages/payment/payment_callback_page.dart' deferred as payment_callback;
import '../pages/support/customer_center_page.dart' deferred as customer_center;
import '../pages/support/notices_page.dart' deferred as notices;
import '../pages/support/notice_detail_page.dart' deferred as notice_detail;
import '../pages/support/faqs_page.dart' deferred as faqs;
import '../pages/support/inquiries_page.dart' deferred as inquiries;
import '../pages/support/inquiry_form_page.dart' deferred as inquiry_form;


class AppRouter {
  /// Deferred 라이브러리 로딩 위젯
  static Widget _deferredWidget(
    Future<void> Function() loadLibrary,
    Widget Function() builder,
  ) {
    return FutureBuilder(
      future: loadLibrary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return builder();
        }
        // 로딩 중 표시
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

  static GoRouter createRouter(
    AuthService authService, {
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: true,
      redirect: (BuildContext context, GoRouterState state) {
        final isInitialized = authService.isInitialized;
        final isLoggedIn = authService.isLoggedIn;
        final needsPhoneVerification = authService.needsPhoneVerification;
        final isGoingToRoot = state.matchedLocation == '/';
        final isGoingToLogin = state.matchedLocation == '/login';
        final isGoingToBypass = state.matchedLocation.startsWith('/bypass');
        final isGoingToAuthCallback = state.matchedLocation == '/auth/callback';
        final isGoingToMap = state.matchedLocation == '/map';
        final isGoingToGuest = state.matchedLocation == '/guest';
        final isGoingToRegister = state.matchedLocation.startsWith('/register');

        // 초기화가 완료되지 않았으면 리다이렉트하지 않음 (로딩 중)
        if (!isInitialized) {
          return null;
        }

        // OAuth 콜백 경로는 리다이렉트 안 함 (백엔드에서 토큰 전달)
        if (isGoingToAuthCallback) {
          return null;
        }

        // 바이패스 로그인 경로는 리다이렉트 안 함
        if (isGoingToBypass) {
          return null;
        }

        // 로그인은 되어 있지만 본인인증이 안 된 경우 회원가입 Step 2로 리다이렉트
        if (isLoggedIn && needsPhoneVerification && !isGoingToRegister) {
          return '/register?verify=true';
        }

        // 루트 경로(/) 접근 시 무조건 게스트 홈으로 리다이렉트
        // (호스트 모드는 GNB에서 명시적으로 전환할 때만 /host로 이동)
        if (isGoingToRoot) {
          return '/guest';
        }

        // 로그인된 상태에서 로그인 페이지 접근 시 게스트 홈으로 리다이렉트
        // (호스트 모드는 GNB에서 명시적으로 전환할 때만 /host로 이동)
        if (isLoggedIn && isGoingToLogin) {
          return '/guest';
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
          path: '/auth/callback',
          name: 'auth-callback',
          builder: (context, state) {
            // 백엔드에서 전달한 JWT 토큰 추출
            final token = state.uri.queryParameters['token'];
            final refreshToken = state.uri.queryParameters['refresh'];

            // 토큰이 없으면 로그인 페이지로 리다이렉트
            if (token == null || refreshToken == null) {
              debugPrint('❌ [AUTH_CALLBACK] 토큰이 없습니다.');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.go('/login');
                }
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // AuthService에 토큰 저장 및 사용자 정보 로드
            final authService = Provider.of<AuthService>(
              context,
              listen: false,
            );

            WidgetsBinding.instance.addPostFrameCallback((_) async {
              try {
                // OAuth 콜백 처리
                final success = await authService.handleOAuthCallback(
                  token,
                  refreshToken,
                );

                if (success && context.mounted) {
                  final user = authService.currentUser;
                  if (user != null) {
                    debugPrint('✅ [AUTH_CALLBACK] 로그인 완료: ${user.email}');

                    // 사용자 모드에 따라 적절한 페이지로 리다이렉트
                    if (user.mode == UserMode.host) {
                      context.go('/host');
                    } else {
                      context.go('/guest');
                    }
                  } else if (context.mounted) {
                    context.go('/login');
                  }
                } else if (context.mounted) {
                  debugPrint('❌ [AUTH_CALLBACK] 인증 실패');
                  context.go('/login');
                }
              } catch (e) {
                debugPrint('❌ [AUTH_CALLBACK] 에러: $e');
                if (context.mounted) {
                  context.go('/login');
                }
              }
            });

            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('로그인 처리 중...'),
                  ],
                ),
              ),
            );
          },
        ),
        GoRoute(
          path: '/mode-selection',
          name: 'mode-selection',
          builder: (context, state) => _deferredWidget(
            mode_selection.loadLibrary,
            () => mode_selection.ModeSelectionPage(
              onModeSelected: (UserMode mode) async {
                final authService = Provider.of<AuthService>(
                  context,
                  listen: false,
                );

                // 소셜 로그인 타입에 따라 처리
                final loginType = state.extra as String?;

                if (loginType == 'email') {
                  // 이메일 회원가입 플로우 - 회원가입 페이지로 이동
                  await register_flow.loadLibrary();
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
                  // 소셜 로그인 성공 → RegisterFlowPage로 이동 (추가 정보 입력)
                  final currentUser = authService.currentUser;
                  await register_flow.loadLibrary();

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
            // 쿼리 파라미터로 본인인증 플래그 확인
            final isVerifyMode = state.uri.queryParameters['verify'] == 'true';

            // 본인인증 모드인 경우 현재 로그인된 사용자 정보 사용
            if (isVerifyMode) {
              final authService = Provider.of<AuthService>(
                context,
                listen: false,
              );
              final currentUser = authService.currentUser;

              if (currentUser != null) {
                return _deferredWidget(
                  register_flow.loadLibrary,
                  () => register_flow.RegisterFlowPage(
                    mode: currentUser.mode,
                    isSocialLogin: true,
                    initialEmail: currentUser.email,
                    initialName: currentUser.name,
                    profileImageUrl: currentUser.profileImageUrl,
                  ),
                );
              }
            }

            // extra가 Map이면 소셜 로그인, UserMode면 일반 회원가입
            if (state.extra is Map<String, dynamic>) {
              final params = state.extra as Map<String, dynamic>;
              return _deferredWidget(
                register_flow.loadLibrary,
                () => register_flow.RegisterFlowPage(
                  mode: params['mode'] as UserMode? ?? UserMode.guest,
                  isSocialLogin: params['isSocialLogin'] as bool? ?? false,
                  initialEmail: params['email'] as String?,
                  initialName: params['name'] as String?,
                  profileImageUrl: null, // Kakao profile image if available
                ),
              );
            } else {
              // 일반 회원가입 (이메일)
              final mode = state.extra as UserMode? ?? UserMode.guest;
              return _deferredWidget(
                register_flow.loadLibrary,
                () => register_flow.RegisterFlowPage(
                  mode: mode,
                  isSocialLogin: false,
                ),
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
          path: '/guest/my-page',
          name: 'guest-my-page',
          builder: (context, state) => _deferredWidget(
            guest_my_page.loadLibrary,
            () => guest_my_page.GuestMyPage(),
          ),
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
          },
        ),
        GoRoute(
          path: '/host',
          name: 'host',
          builder: (context, state) => _deferredWidget(
            host_home.loadLibrary,
            () => host_home.HostHomePage(),
          ),
        ),
        // 게스트→호스트 전환 - 계좌 설정 페이지 (Standalone)
        GoRoute(
          path: '/host/account-setup-standalone',
          name: 'host-account-setup-standalone',
          builder: (context, state) => _deferredWidget(
            host_account_setup_standalone.loadLibrary,
            () =>
                host_account_setup_standalone.HostAccountSetupStandalonePage(),
          ),
        ),
        // 신규 방 등록 (roomId 없음)
        GoRoute(
          path: '/host/room-registration',
          name: 'room-registration',
          builder: (context, state) {
            return _deferredWidget(
              room_registration.loadLibrary,
              () => room_registration.RoomRegistrationFlowPage(roomId: null),
            );
          },
        ),
        // 기존 방 수정 (roomId 있음)
        GoRoute(
          path: '/host/room-registration/:roomId',
          name: 'room-registration-edit',
          builder: (context, state) {
            final roomId = _parseIntParameter(state.pathParameters['roomId']);

            return _deferredWidget(
              room_registration.loadLibrary,
              () => room_registration.RoomRegistrationFlowPage(roomId: roomId),
            );
          },
        ),
        // 방 관리 페이지
        GoRoute(
          path: '/host/room-management',
          name: 'room-management',
          builder: (context, state) => _deferredWidget(
            room_management.loadLibrary,
            () => room_management.RoomManagementPage(),
          ),
        ),
        // 방 일정 관리 페이지
        GoRoute(
          path: '/host/room-schedule/:roomId',
          name: 'room-schedule',
          builder: (context, state) {
            final roomId = state.pathParameters['roomId'] ?? '';
            return RoomSchedulePage(roomId: roomId); // 즉시 로딩
          },
        ),
        // 호스트 마이페이지
        GoRoute(
          path: '/host/my-page',
          name: 'host-my-page',
          builder: (context, state) => _deferredWidget(
            host_my_page.loadLibrary,
            () => host_my_page.HostMyPage(),
          ),
        ),
        GoRoute(
          path: '/map',
          name: 'map',
          builder: (context, state) => const MapScreen(),
        ),
        GoRoute(
          path: '/contract/request/:roomId',
          name: 'contract-request',
          builder: (context, state) {
            final roomId = _parseIntParameter(state.pathParameters['roomId']);

            if (roomId == null) {
              return _buildInvalidAccessPage(
                context,
                message: '잘못된 접근입니다.',
                buttonText: '홈으로 돌아가기',
                redirectPath: '/guest',
              );
            }

            final extra = state.extra as Map<String, dynamic>?;
            if (extra == null) {
              return _buildInvalidAccessPage(
                context,
                message: '예약 정보가 필요합니다.',
                buttonText: '방 상세로 돌아가기',
                redirectPath: '/guest/room/detail/$roomId',
              );
            }

            return _deferredWidget(
              contract_start.loadLibrary,
              () => contract_start.ContractStartPage(
                room: extra['room'],
                checkInDate: extra['checkInDate'],
                checkOutDate: extra['checkOutDate'],
                calculatedPricing: extra['calculatedPricing'],
                selectedRentalItems: extra['selectedRentalItems'],
              ),
            );
          },
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
                final contractId = _parseIntParameter(
                  state.pathParameters['contractId'],
                );

                if (contractId == null) {
                  return _buildInvalidAccessPage(
                    context,
                    message: '잘못된 접근입니다.',
                    buttonText: '계약 목록으로 돌아가기',
                    redirectPath: '/guest/contracts',
                  );
                }

                return _deferredWidget(
                  guest_contract_detail.loadLibrary,
                  () => guest_contract_detail.GuestContractDetailPage(
                    contractId: contractId,
                  ),
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
            () => host_contracts.HostContractsPageNew(),
          ),
          routes: [
            GoRoute(
              path: ':contractId',
              name: 'host-contract-detail',
              builder: (context, state) {
                final contractId = state.pathParameters['contractId'] ?? '';
                return _deferredWidget(
                  host_contract_detail.loadLibrary,
                  () => host_contract_detail.HostContractDetailPage(
                    contractId: int.parse(contractId),
                  ),
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
        // 결제 성공 콜백
        GoRoute(
          path: '/payment/success',
          name: 'payment-success',
          builder: (context, state) {
            final contractId = state.uri.queryParameters['contractId'];
            final paymentKey = state.uri.queryParameters['paymentKey'];
            final orderId = state.uri.queryParameters['orderId'];
            final amount = state.uri.queryParameters['amount'];

            return _deferredWidget(
              payment_callback.loadLibrary,
              () => payment_callback.PaymentCallbackPage(
                isSuccess: true,
                contractId: contractId != null ? int.tryParse(contractId) : null,
                paymentKey: paymentKey,
                orderId: orderId,
                amount: amount,
              ),
            );
          },
        ),

        // 결제 실패 콜백
        GoRoute(
          path: '/payment/fail',
          name: 'payment-fail',
          builder: (context, state) {
            final contractId = state.uri.queryParameters['contractId'];
            final errorCode = state.uri.queryParameters['code'];
            final errorMessage = state.uri.queryParameters['message'];

            return _deferredWidget(
              payment_callback.loadLibrary,
              () => payment_callback.PaymentCallbackPage(
                isSuccess: false,
                contractId: contractId != null ? int.tryParse(contractId) : null,
                errorCode: errorCode,
                errorMessage: errorMessage,
              ),
            );
          },
        ),

        GoRoute(
          path: '/bypass/:userId',
          name: 'dev-bypass',
          builder: (context, state) {
            final userId = state.pathParameters['userId'] ?? '';

            // 빌드 완료 후 로그인 실행 (setState 에러 방지)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleDevBypass(context, userId);
            });

            // 로딩 화면 표시
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
          },
        ),

        // 고객센터
        GoRoute(
          path: '/support',
          name: 'support',
          builder: (context, state) => _deferredWidget(
            customer_center.loadLibrary,
            () => customer_center.CustomerCenterPage(),
          ),
          routes: [
            // 공지사항 목록
            GoRoute(
              path: 'notices',
              name: 'notices',
              builder: (context, state) => _deferredWidget(
                notices.loadLibrary,
                () => notices.NoticesPage(),
              ),
              routes: [
                // 공지사항 상세
                GoRoute(
                  path: ':noticeId',
                  name: 'notice-detail',
                  builder: (context, state) {
                    final noticeId = _parseIntParameter(
                      state.pathParameters['noticeId'],
                    );

                    if (noticeId == null) {
                      return _buildInvalidAccessPage(
                        context,
                        message: '잘못된 접근입니다.',
                        buttonText: '공지사항 목록으로 돌아가기',
                        redirectPath: '/support/notices',
                      );
                    }

                    return _deferredWidget(
                      notice_detail.loadLibrary,
                      () => notice_detail.NoticeDetailPage(noticeId: noticeId),
                    );
                  },
                ),
              ],
            ),
            // 자주 묻는 질문
            GoRoute(
              path: 'faqs',
              name: 'faqs',
              builder: (context, state) => _deferredWidget(
                faqs.loadLibrary,
                () => faqs.FAQsPage(),
              ),
            ),
            // 문의하기 목록
            GoRoute(
              path: 'inquiries',
              name: 'inquiries',
              builder: (context, state) => _deferredWidget(
                inquiries.loadLibrary,
                () => inquiries.InquiriesPage(),
              ),
              routes: [
                // 문의 등록
                GoRoute(
                  path: 'new',
                  name: 'inquiry-new',
                  builder: (context, state) => _deferredWidget(
                    inquiry_form.loadLibrary,
                    () => inquiry_form.InquiryFormPage(),
                  ),
                ),
                // 문의 수정
                GoRoute(
                  path: ':inquiryId/edit',
                  name: 'inquiry-edit',
                  builder: (context, state) {
                    final inquiryId = _parseIntParameter(
                      state.pathParameters['inquiryId'],
                    );

                    if (inquiryId == null) {
                      return _buildInvalidAccessPage(
                        context,
                        message: '잘못된 접근입니다.',
                        buttonText: '문의 목록으로 돌아가기',
                        redirectPath: '/support/inquiries',
                      );
                    }

                    return _deferredWidget(
                      inquiry_form.loadLibrary,
                      () => inquiry_form.InquiryFormPage(inquiryId: inquiryId),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// 개발자 바이패스 로그인 처리
  static Future<void> _handleDevBypass(
    BuildContext context,
    String userId,
  ) async {
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
