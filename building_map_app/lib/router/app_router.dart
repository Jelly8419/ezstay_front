import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../widgets/common/app_shell_scaffold.dart';

// 즉시 로딩 (자주 사용하는 페이지)
import '../pages/auth/login_page.dart';
import '../pages/guest/guest_home_page.dart';
import '../pages/guest/map_screen.dart';

// 지연 로딩 (필요할 때만 로드) - 웹 번들 크기 최적화
import '../pages/auth/mode_selection_page.dart' deferred as mode_selection;
import '../pages/auth/register_flow_page.dart' deferred as register_flow;
import '../pages/guest/room_detail_page.dart' deferred as room_detail;
import '../pages/guest/guest_my_page.dart' deferred as guest_my_page;
import '../pages/guest/guest_refund_account_page.dart'
    deferred as guest_refund_account;
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
import '../pages/chat/auto_message_management_page.dart'
    deferred as auto_message_management;
import '../pages/host/room_management_page.dart' deferred as room_management;
import '../pages/host/room_schedule_page.dart'; // 즉시 로딩으로 변경 (Focus 에러 방지)
import '../pages/host/host_my_page.dart' deferred as host_my_page;
import '../pages/payment/payment_callback_page.dart' deferred as payment_callback;
import '../pages/payment/rental_payment_callback_page.dart'
    deferred as rental_payment_callback;
import '../pages/support/customer_center_page.dart' deferred as customer_center;
import '../pages/support/notices_page.dart' deferred as notices;
import '../pages/support/notice_detail_page.dart' deferred as notice_detail;
import '../pages/support/faqs_page.dart' deferred as faqs;
import '../pages/support/inquiries_page.dart' deferred as inquiries;
import '../pages/support/inquiry_form_page.dart' deferred as inquiry_form;
import '../pages/notification/notification_page.dart'
    deferred as notification_page;
import '../pages/host/host_settlement_account_page.dart'
    deferred as host_settlement_account;
import '../pages/host/host_settlement_page.dart' deferred as host_settlement;
import '../pages/host/host_settlement_detail_page.dart'
    deferred as host_settlement_detail;
import '../pages/host/host_settlement_deduction_page.dart'
    deferred as host_settlement_deduction;
import '../pages/auth/account_suspended_page.dart' deferred as account_suspended;
import '../pages/legal/terms_of_service_page.dart' deferred as terms_of_service;
import '../pages/legal/privacy_policy_page.dart' deferred as privacy_policy;
import '../pages/auth/reset_password_page.dart' deferred as reset_password;
import '../pages/auth/kmc_callback_page.dart' deferred as kmc_callback;
import '../pages/error_page.dart';


class AppRouter {
  /// Deferred 라이브러리 로딩 위젯
  ///
  /// 지연 로딩 실패 시 에러 화면을 표시하고 새로고침 옵션을 제공합니다.
  /// 브라우저 캐시 불일치, 네트워크 문제 등으로 인한 로딩 실패를 처리합니다.
  /// .part.js 로딩 실패가 캐시 불일치인지 판별
  static bool _isPartJsCacheMismatch(Object error) {
    final msg = error.toString();
    return msg.contains('.part.js') && msg.contains('failed');
  }

  /// Deferred 라이브러리 로딩 (최대 3회 자동 재시도)
  ///
  /// .part.js 캐시 불일치 감지 시 에러 UI에서 강제 새로고침 유도
  static Future<void> _loadWithRetry(Future<void> Function() loadLibrary) async {
    const maxRetries = 3;
    for (var i = 0; i < maxRetries; i++) {
      try {
        await loadLibrary();
        return;
      } catch (e) {
        AppLogger.w('⚠️ [Deferred] 로딩 재시도 ${i + 1}/$maxRetries: $e');
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
      }
    }
  }

  /// Deferred 로딩 에러 UI (공통)
  ///
  /// 캐시 불일치(.part.js 실패) 감지 시 업데이트 안내,
  /// 그 외에는 일반 에러 안내를 표시합니다.
  static Widget _buildDeferredErrorContent(BuildContext context, Object error) {
    final isCacheMismatch = _isPartJsCacheMismatch(error);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCacheMismatch ? Icons.update : Icons.error_outline,
            size: 64,
            color: isCacheMismatch ? Colors.orange : Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            isCacheMismatch ? '새 버전이 있습니다' : '페이지를 불러올 수 없습니다',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isCacheMismatch
                ? '앱이 업데이트되었습니다.\nCtrl+Shift+R을 눌러 새로고침해주세요.'
                : '네트워크 상태를 확인하고 다시 시도해주세요.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/'),
            icon: Icon(isCacheMismatch ? Icons.refresh : Icons.home),
            label: Text(isCacheMismatch ? '홈으로 이동' : '홈으로 이동'),
          ),
        ],
      ),
    );
  }

  static Widget _deferredWidget(
    Future<void> Function() loadLibrary,
    Widget Function() builder,
  ) {
    return FutureBuilder(
      future: _loadWithRetry(loadLibrary),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          AppLogger.e('❌ [Deferred] 라이브러리 로딩 최종 실패: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: _buildDeferredErrorContent(context, snapshot.error!),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return builder();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  /// ShellRoute용 Deferred 라이브러리 로딩 위젯 (Scaffold 미포함)
  static Widget _deferredShellWidget(
    Future<void> Function() loadLibrary,
    Widget Function() builder,
  ) {
    return FutureBuilder(
      future: _loadWithRetry(loadLibrary),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          AppLogger.e('❌ [Deferred] 라이브러리 로딩 최종 실패: ${snapshot.error}');
          return Center(
            child: _buildDeferredErrorContent(context, snapshot.error!),
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return builder();
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  /// Path 파라미터를 int로 파싱하는 헬퍼 함수
  static int? _parseIntParameter(String? value) {
    return value != null ? int.tryParse(value) : null;
  }

  /// 잘못된 접근 에러 페이지 빌더 (독립 라우트용, Scaffold 포함)
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

  /// 잘못된 접근 에러 위젯 (ShellRoute 내부용, Scaffold 미포함)
  static Widget _buildShellInvalidAccessWidget(
    BuildContext context, {
    required String message,
    required String buttonText,
    required String redirectPath,
  }) {
    return Center(
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
    );
  }

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static GoRouter createRouter(
    AuthService authService, {
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    final rootKey = navigatorKey ?? _rootNavigatorKey;
    return GoRouter(
      navigatorKey: rootKey,
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: authService,
      errorBuilder: (context, state) => const ErrorPage(),
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

        // KMC 본인인증 콜백 경로는 리다이렉트 안 함
        if (state.matchedLocation == '/kmc/callback') {
          return null;
        }

        // 바이패스 로그인 경로는 리다이렉트 안 함
        if (isGoingToBypass) {
          return null;
        }

        // 계정 정지 상태인 경우 정지 안내 페이지로 리다이렉트
        final isAccountSuspended = authService.isAccountSuspended;
        final isGoingToSuspended = state.matchedLocation == '/account-suspended';
        if (isLoggedIn && isAccountSuspended && !isGoingToSuspended && !isGoingToLogin) {
          return '/account-suspended';
        }
        // 정지 상태가 아닌데 정지 페이지로 접근하면 홈으로 리다이렉트
        if (isGoingToSuspended && (!isLoggedIn || !isAccountSuspended)) {
          return '/guest';
        }

        // 로그인은 되어 있지만 본인인증이 안 된 경우 소셜 회원가입 플로우로 리다이렉트
        // /register로 가는 중이면 통과 (mode 파라미터 유지)
        if (isLoggedIn && needsPhoneVerification && !isGoingToRegister) {
          // localStorage pending_register_mode 우선 사용 (웹 OAuth 후 가장 신뢰할 수 있는 값)
          final pendingMode = authService.peekPendingRegisterMode();
          final existingMode = state.uri.queryParameters['mode'];
          final modeStr = pendingMode ?? existingMode ?? (authService.currentUser?.mode == UserMode.host ? 'host' : 'guest');
          return '/register?social=true&mode=$modeStr';
        }

        // 호스트인데 계좌 미등록 시, 호스트 전용 페이지 접근하면 계좌 등록 Step3로 강제 이동
        final user = authService.currentUser;
        if (isLoggedIn &&
            user != null &&
            user.mode == UserMode.host &&
            !user.hasBank &&
            !needsPhoneVerification &&
            !isGoingToRegister &&
            !isGoingToLogin &&
            state.matchedLocation.startsWith('/host')) {
          return '/register?hostAccount=true';
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

        // 로그인 안 된 상태에서 보호된 페이지 접근 시 로그인 페이지로 리다이렉트
        if (!isLoggedIn &&
            !isGoingToLogin &&
            !isGoingToGuest &&
            !isGoingToMap &&
            !isGoingToRegister &&
            (state.matchedLocation.startsWith('/host') ||
                state.matchedLocation.contains('/contracts') ||
                state.matchedLocation.contains('/chat') ||
                state.matchedLocation.contains('/notifications') ||
                state.matchedLocation.contains('/mypage'))) {
          return '/login';
        }

        return null;
      },
      routes: [
        // ============================================
        // ShellRoute: AppGNB를 공통으로 제공하는 라우트
        // 내부 페이지는 Scaffold/AppGNB를 포함하지 않음
        // ============================================
        ShellRoute(
          builder: (context, state, child) => AppShellScaffold(child: child),
          routes: [
            GoRoute(
              path: '/login',
              name: 'login',
              builder: (context, state) => const LoginPage(),
            ),
            GoRoute(
              path: '/reset-password',
              name: 'reset-password',
              builder: (context, state) => _deferredWidget(
                reset_password.loadLibrary,
                () => reset_password.ResetPasswordPage(),
              ),
            ),
            // KMC 본인인증 콜백 (KMC가 인증 완료 후 이 URL로 결과 POST)
            GoRoute(
              path: '/kmc/callback',
              name: 'kmc-callback',
              builder: (context, state) {
                final apiToken = state.uri.queryParameters['apiToken'];
                final certNum = state.uri.queryParameters['certNum'];
                return _deferredWidget(
                  kmc_callback.loadLibrary,
                  () => kmc_callback.KmcCallbackPage(
                    apiToken: apiToken,
                    certNum: certNum,
                  ),
                );
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
                  return _buildShellInvalidAccessWidget(
                    context,
                    message: '잘못된 접근입니다.',
                    buttonText: '지도로 돌아가기',
                    redirectPath: '/map',
                  );
                }
                return _deferredShellWidget(
                  room_detail.loadLibrary,
                  () => room_detail.RoomDetailPage(roomId: roomId),
                );
              },
            ),
            GoRoute(
              path: '/host',
              name: 'host',
              builder: (context, state) => _deferredShellWidget(
                host_home.loadLibrary,
                () => host_home.HostHomePage(),
              ),
            ),
            // 신규 방 등록 (roomId 없음)
            GoRoute(
              path: '/host/room-registration',
              name: 'room-registration',
              builder: (context, state) {
                return _deferredShellWidget(
                  room_registration.loadLibrary,
                  () => room_registration.RoomRegistrationFlowPage(roomId: null),
                );
              },
            ),
            // 기존 방 수정 (roomId 있음, ?step=N 으로 초기 단계 지정 가능)
            GoRoute(
              path: '/host/room-registration/:roomId',
              name: 'room-registration-edit',
              builder: (context, state) {
                final roomId = _parseIntParameter(state.pathParameters['roomId']);
                final step = int.tryParse(state.uri.queryParameters['step'] ?? '');
                return _deferredShellWidget(
                  room_registration.loadLibrary,
                  () => room_registration.RoomRegistrationFlowPage(
                    key: ValueKey('room-edit-$roomId-step-$step'),
                    roomId: roomId,
                    initialStep: step,
                  ),
                );
              },
            ),
            // 방 관리 페이지
            GoRoute(
              path: '/host/room-management',
              name: 'room-management',
              builder: (context, state) => _deferredShellWidget(
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
            // 게스트 계약
            GoRoute(
              path: '/guest/contracts',
              name: 'guest-contracts',
              builder: (context, state) => _deferredShellWidget(
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
                      return _buildShellInvalidAccessWidget(
                        context,
                        message: '잘못된 접근입니다.',
                        buttonText: '계약 목록으로 돌아가기',
                        redirectPath: '/guest/contracts',
                      );
                    }
                    return _deferredShellWidget(
                      guest_contract_detail.loadLibrary,
                      () => guest_contract_detail.GuestContractDetailPage(
                        contractId: contractId,
                      ),
                    );
                  },
                ),
              ],
            ),
            // 호스트 계약
            GoRoute(
              path: '/host/contracts',
              name: 'host-contracts',
              builder: (context, state) => _deferredShellWidget(
                host_contracts.loadLibrary,
                () => host_contracts.HostContractsPageNew(),
              ),
              routes: [
                GoRoute(
                  path: ':contractId',
                  name: 'host-contract-detail',
                  builder: (context, state) {
                    final contractId = state.pathParameters['contractId'] ?? '';
                    return _deferredShellWidget(
                      host_contract_detail.loadLibrary,
                      () => host_contract_detail.HostContractDetailPage(
                        contractId: int.parse(contractId),
                      ),
                    );
                  },
                ),
              ],
            ),
            // 채팅 목록
            GoRoute(
              path: '/chat-list',
              name: 'chat-list',
              builder: (context, state) {
                final contractIdStr = state.uri.queryParameters['contractId'];
                final contractId = contractIdStr != null ? int.tryParse(contractIdStr) : null;
                return _deferredShellWidget(
                  chat_list.loadLibrary,
                  () => chat_list.ChatListPage(initialContractId: contractId),
                );
              },
              routes: [
                GoRoute(
                  path: ':chatRoomId',
                  name: 'chat-list-detail',
                  builder: (context, state) {
                    final chatRoomId = state.pathParameters['chatRoomId'];
                    return _deferredShellWidget(
                      chat_list.loadLibrary,
                      () => chat_list.ChatListPage(initialChatRoomId: chatRoomId),
                    );
                  },
                ),
              ],
            ),
            // 이용약관
            GoRoute(
              path: '/terms',
              name: 'terms',
              builder: (context, state) => _deferredShellWidget(
                terms_of_service.loadLibrary,
                () => terms_of_service.TermsOfServicePage(),
              ),
            ),
            // 개인정보 처리방침
            GoRoute(
              path: '/privacy',
              name: 'privacy',
              builder: (context, state) => _deferredShellWidget(
                privacy_policy.loadLibrary,
                () => privacy_policy.PrivacyPolicyPage(),
              ),
            ),
            // 알림 페이지 (GNB 포함)
            GoRoute(
              path: '/notifications',
              name: 'notifications',
              builder: (context, state) => _deferredShellWidget(
                notification_page.loadLibrary,
                () => notification_page.NotificationPage(),
              ),
            ),
            // 고객센터
            GoRoute(
              path: '/support',
              name: 'support',
              builder: (context, state) {
                final tab = state.uri.queryParameters['tab'];
                return _deferredShellWidget(
                  customer_center.loadLibrary,
                  () => customer_center.CustomerCenterPage(initialTab: tab),
                );
              },
              routes: [
                GoRoute(
                  path: 'notices',
                  name: 'notices',
                  builder: (context, state) => _deferredShellWidget(
                    notices.loadLibrary,
                    () => notices.NoticesPage(),
                  ),
                  routes: [
                    GoRoute(
                      path: ':noticeId',
                      name: 'notice-detail',
                      builder: (context, state) {
                        final noticeId = _parseIntParameter(
                          state.pathParameters['noticeId'],
                        );
                        if (noticeId == null) {
                          return _buildShellInvalidAccessWidget(
                            context,
                            message: '잘못된 접근입니다.',
                            buttonText: '공지사항 목록으로 돌아가기',
                            redirectPath: '/support?tab=notices',
                          );
                        }
                        return _deferredShellWidget(
                          notice_detail.loadLibrary,
                          () => notice_detail.NoticeDetailPage(noticeId: noticeId),
                        );
                      },
                    ),
                  ],
                ),
                GoRoute(
                  path: 'faqs',
                  name: 'faqs',
                  builder: (context, state) => _deferredShellWidget(
                    faqs.loadLibrary,
                    () => faqs.FAQsPage(),
                  ),
                ),
                GoRoute(
                  path: 'inquiries',
                  name: 'inquiries',
                  builder: (context, state) => _deferredShellWidget(
                    inquiries.loadLibrary,
                    () => inquiries.InquiriesPage(),
                  ),
                  routes: [
                    GoRoute(
                      path: 'new',
                      name: 'inquiry-new',
                      builder: (context, state) => _deferredShellWidget(
                        inquiry_form.loadLibrary,
                        () => inquiry_form.InquiryFormPage(),
                      ),
                    ),
                    GoRoute(
                      path: ':inquiryId/edit',
                      name: 'inquiry-edit',
                      builder: (context, state) {
                        final inquiryId = _parseIntParameter(
                          state.pathParameters['inquiryId'],
                        );
                        if (inquiryId == null) {
                          return _buildShellInvalidAccessWidget(
                            context,
                            message: '잘못된 접근입니다.',
                            buttonText: '문의 목록으로 돌아가기',
                            redirectPath: '/support?tab=inquiries',
                          );
                        }
                        return _deferredShellWidget(
                          inquiry_form.loadLibrary,
                          () => inquiry_form.InquiryFormPage(inquiryId: inquiryId),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            // 계약 요청 (ShellRoute: AppGNB 제공)
            GoRoute(
              path: '/contract/request/:roomId',
              name: 'contract-request',
              builder: (context, state) {
                final roomId = _parseIntParameter(state.pathParameters['roomId']);

                if (roomId == null) {
                  return _buildShellInvalidAccessWidget(
                    context,
                    message: '잘못된 접근입니다.',
                    buttonText: '홈으로 돌아가기',
                    redirectPath: '/guest',
                  );
                }

                final extra = state.extra as Map<String, dynamic>?;
                if (extra == null) {
                  return _buildShellInvalidAccessWidget(
                    context,
                    message: '예약 정보가 필요합니다.',
                    buttonText: '방 상세로 돌아가기',
                    redirectPath: '/guest/room/detail/$roomId',
                  );
                }

                return _deferredShellWidget(
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
          ],
        ),

        // ============================================
        // 독립 라우트: 자체 Scaffold/AppBar를 관리하는 페이지
        // ============================================

        // 계약 시점 방 스냅샷 (게스트)
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/guest/contracts/:contractId/room-snapshot',
          name: 'guest-contract-room-snapshot',
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
            return Material(
              child: _deferredWidget(
                room_detail.loadLibrary,
                () => room_detail.RoomDetailPage(
                  roomId: 0,
                  isSnapshot: true,
                  contractId: contractId,
                ),
              ),
            );
          },
        ),

        // 계약 시점 방 스냅샷 (호스트)
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/host/contracts/:contractId/room-snapshot',
          name: 'host-contract-room-snapshot',
          builder: (context, state) {
            final contractId = _parseIntParameter(
              state.pathParameters['contractId'],
            );
            if (contractId == null) {
              return _buildInvalidAccessPage(
                context,
                message: '잘못된 접근입니다.',
                buttonText: '계약 목록으로 돌아가기',
                redirectPath: '/host/contracts',
              );
            }
            return Material(
              child: _deferredWidget(
                room_detail.loadLibrary,
                () => room_detail.RoomDetailPage(
                  roomId: 0,
                  isSnapshot: true,
                  isHostViewing: true,
                  contractId: contractId,
                ),
              ),
            );
          },
        ),

        GoRoute(
          path: '/auth/callback',
          name: 'auth-callback',
          builder: (context, state) {
            // 백엔드에서 전달한 JWT 토큰 추출
            final token = state.uri.queryParameters['token'];
            final refreshToken = state.uri.queryParameters['refresh'];
            // localStorage에서 pending register mode 읽기 (웹 OAuth 리다이렉트 후 복원)
            final authServiceForMode = Provider.of<AuthService>(context, listen: false);
            final pendingMode = authServiceForMode.popPendingRegisterMode();
            AppLogger.d('[AUTH_CALLBACK] fullUri=${state.uri} | pendingMode=$pendingMode');

            // 토큰이 없으면 로그인 페이지로 리다이렉트
            if (token == null || refreshToken == null) {
              AppLogger.e('❌ [AUTH_CALLBACK] 토큰이 없습니다.');
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
                  // localStorage에서 읽은 pending mode가 있으면 회원가입 플로우
                  if (pendingMode == 'host' || pendingMode == 'guest') {
                    context.go('/register?social=true&mode=$pendingMode');
                    return;
                  }

                  final user = authService.currentUser;
                  if (user != null) {
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
                  AppLogger.e('❌ [AUTH_CALLBACK] 인증 실패');
                  context.go('/login');
                }
              } catch (e) {
                AppLogger.e('❌ [AUTH_CALLBACK] 에러: $e');
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
                    final modeStr = mode == UserMode.host ? 'host' : 'guest';
                    context.go('/register?mode=$modeStr');
                  }
                  return;
                }

                // 소셜 로그인 처리 (google, kakao)
                bool success = false;
                if (loginType == 'google') {
                  success = await authService.loginWithGoogle(mode);
                } else if (loginType == 'kakao') {
                  final result = await authService.loginWithKakao(mode);
                  success = !result.isFailure;
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
            final queryParams = state.uri.queryParameters;
            final authService = Provider.of<AuthService>(context, listen: false);
            final currentUser = authService.currentUser;

            // mode 파라미터 파싱 (쿼리 파라미터 우선, extra 폴백)
            UserMode parseMode() {
              final modeStr = queryParams['mode'];
              AppLogger.d('[REGISTER] uri=${state.uri}, mode=$modeStr, extra=${state.extra}');
              if (modeStr == 'host') return UserMode.host;
              if (modeStr == 'guest') return UserMode.guest;
              if (state.extra is UserMode) return state.extra as UserMode;
              return UserMode.guest;
            }

            // 소셜 회원가입: ?social=true&mode=host|guest
            // (웹 OAuth 리다이렉트 / needsPhoneVerification redirect 공통)
            if (queryParams['social'] == 'true') {
              final mode = parseMode();
              return _deferredWidget(
                register_flow.loadLibrary,
                () => register_flow.RegisterFlowPage(
                  mode: mode,
                  isSocialLogin: true,
                  initialEmail: currentUser?.email,
                  initialName: currentUser?.name,
                  profileImageUrl: currentUser?.profileImageUrl,
                ),
              );
            }

            // 이메일 일반 회원가입: ?mode=host|guest (또는 extra=UserMode)
            final mode = parseMode();
            return _deferredWidget(
              register_flow.loadLibrary,
              () => register_flow.RegisterFlowPage(
                mode: mode,
                isSocialLogin: false,
              ),
            );
          },
        ),
        // 게스트 마이페이지 (모바일: 커스텀 AppBar, 데스크톱: AppGNB)
        GoRoute(
          path: '/guest/my-page',
          name: 'guest-my-page',
          builder: (context, state) => _deferredWidget(
            guest_my_page.loadLibrary,
            () => guest_my_page.GuestMyPage(),
          ),
          routes: [
            // 게스트 환급 계좌 등록/수정 페이지
            GoRoute(
              path: 'refund-account',
              name: 'guest-refund-account',
              builder: (context, state) => _deferredWidget(
                guest_refund_account.loadLibrary,
                () => guest_refund_account.GuestRefundAccountPage(),
              ),
            ),
          ],
        ),
        // 호스트 마이페이지 (모바일: 커스텀 AppBar, 데스크톱: AppGNB)
        GoRoute(
          path: '/host/my-page',
          name: 'host-my-page',
          builder: (context, state) => _deferredWidget(
            host_my_page.loadLibrary,
            () => host_my_page.HostMyPage(),
          ),
        ),
        // 호스트 정산계좌 등록/수정 페이지
        GoRoute(
          path: '/host/my-page/settlement-account',
          name: 'host-settlement-account',
          builder: (context, state) => _deferredWidget(
            host_settlement_account.loadLibrary,
            () => host_settlement_account.HostSettlementAccountPage(),
          ),
        ),
        // 게스트→호스트 전환 - 계좌 설정 페이지
        GoRoute(
          path: '/host/account-setup-standalone',
          name: 'host-account-setup-standalone',
          builder: (context, state) => _deferredWidget(
            host_account_setup_standalone.loadLibrary,
            () =>
                host_account_setup_standalone.HostAccountSetupStandalonePage(),
          ),
        ),
        // 호스트 정산 페이지
        GoRoute(
          path: '/host/settlement',
          name: 'host-settlement',
          builder: (context, state) => _deferredWidget(
            host_settlement.loadLibrary,
            () => host_settlement.HostSettlementPage(),
          ),
        ),
        // 호스트 정산 상세 페이지
        GoRoute(
          path: '/host/settlement/:contractId',
          name: 'host-settlement-detail',
          builder: (context, state) {
            final contractId = int.tryParse(state.pathParameters['contractId'] ?? '') ?? 0;
            return _deferredWidget(
              host_settlement_detail.loadLibrary,
              () => host_settlement_detail.HostSettlementDetailPage(
                contractId: contractId,
              ),
            );
          },
        ),
        // 호스트 보증금 차감 상세 페이지
        GoRoute(
          path: '/host/settlement/deduction/:contractId',
          name: 'host-settlement-deduction',
          builder: (context, state) {
            final contractId = int.tryParse(state.pathParameters['contractId'] ?? '') ?? 0;
            return _deferredWidget(
              host_settlement_deduction.loadLibrary,
              () => host_settlement_deduction.HostSettlementDeductionPage(
                contractId: contractId,
              ),
            );
          },
        ),
        // 지도 (body에 조건부 AppGNB 배치)
        GoRoute(
          path: '/map',
          name: 'map',
          builder: (context, state) => const MapScreen(),
        ),
        // 알림 페이지는 ShellRoute(GNB)로 이동됨
        // 채팅 상세 (커스텀 AppBar)
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
        // 호스트 자동메시지 관리
        GoRoute(
          path: '/host/chat/auto-message',
          name: 'auto-message-management',
          builder: (context, state) => _deferredWidget(
            auto_message_management.loadLibrary,
            () => auto_message_management.AutoMessageManagementPage(),
          ),
        ),
        // 결제 성공 콜백
        GoRoute(
          path: '/payment/success',
          name: 'payment-success',
          builder: (context, state) {
            final contractId = state.uri.queryParameters['contractId'];
            final recvPayparam = state.uri.queryParameters['recvPayparam'];
            final payType = state.uri.queryParameters['payType'];
            final orderId = state.uri.queryParameters['orderId'];
            final amount = state.uri.queryParameters['amount'];

            return _deferredWidget(
              payment_callback.loadLibrary,
              () => payment_callback.PaymentCallbackPage(
                isSuccess: true,
                contractId: contractId != null ? int.tryParse(contractId) : null,
                recvPayparam: recvPayparam,
                payType: payType,
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

        // 렌탈 결제 성공 콜백
        GoRoute(
          path: '/rental-payment/success',
          name: 'rental-payment-success',
          builder: (context, state) {
            final rentalOrderId = state.uri.queryParameters['rentalOrderId'];
            final paymentKey = state.uri.queryParameters['paymentKey'];
            final orderId = state.uri.queryParameters['orderId'];
            final amount = state.uri.queryParameters['amount'];

            return _deferredWidget(
              rental_payment_callback.loadLibrary,
              () => rental_payment_callback.RentalPaymentCallbackPage(
                isSuccess: true,
                rentalOrderId:
                    rentalOrderId != null ? int.tryParse(rentalOrderId) : null,
                paymentKey: paymentKey, // 렌탈은 paymentKey 필드에 recv_payparam 값 전달 (API 호환)
                orderId: orderId,
                amount: amount,
              ),
            );
          },
        ),

        // 렌탈 결제 실패 콜백
        GoRoute(
          path: '/rental-payment/fail',
          name: 'rental-payment-fail',
          builder: (context, state) {
            final rentalOrderId = state.uri.queryParameters['rentalOrderId'];
            final errorCode = state.uri.queryParameters['code'];
            final errorMessage = state.uri.queryParameters['message'];

            return _deferredWidget(
              rental_payment_callback.loadLibrary,
              () => rental_payment_callback.RentalPaymentCallbackPage(
                isSuccess: false,
                rentalOrderId:
                    rentalOrderId != null ? int.tryParse(rentalOrderId) : null,
                errorCode: errorCode,
                errorMessage: errorMessage,
              ),
            );
          },
        ),

        // 계정 정지 안내 페이지
        GoRoute(
          path: '/account-suspended',
          name: 'account-suspended',
          builder: (context, state) {
            final authService = Provider.of<AuthService>(
              context,
              listen: false,
            );
            return _deferredWidget(
              account_suspended.loadLibrary,
              () => account_suspended.AccountSuspendedPage(
                reason: authService.suspensionReason,
              ),
            );
          },
        ),

        GoRoute(
          path: '/bypass/:userId',
          name: 'dev-bypass',
          builder: (context, state) {
            final userId = state.pathParameters['userId'] ?? '';
            final key = state.uri.queryParameters['key'];

            // 빌드 완료 후 로그인 실행 (setState 에러 방지)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleDevBypass(context, userId, key: key);
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

      ],
    );
  }

  /// 개발자 바이패스 로그인 처리
  static Future<void> _handleDevBypass(
    BuildContext context,
    String userId, {
    String? key,
  }) async {
    final authService = Provider.of<AuthService>(context, listen: false);

    final success = await authService.loginWithDevBypass(userId, key: key);

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
