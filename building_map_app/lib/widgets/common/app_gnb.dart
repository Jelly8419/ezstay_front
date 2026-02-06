import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../../providers/gnb_provider.dart';
import 'ezstay_logo.dart';
import 'gnb_icon_button.dart';
import 'gnb_menu_dropdown.dart';

/// GNB (Global Navigation Bar)
/// 로그인 상태와 호스트/게스트 모드에 따라 다른 UI를 표시합니다.
class AppGNB extends StatefulWidget implements PreferredSizeWidget {
  const AppGNB({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  State<AppGNB> createState() => _AppGNBState();
}

class _AppGNBState extends State<AppGNB> {
  bool _hasCheckedUnread = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, GNBProvider>(
      builder: (context, authService, gnbProvider, child) {
        final isLoggedIn = authService.isLoggedIn;
        final isHostMode = authService.currentUser?.mode == UserMode.host;

        // 로그인 상태이고 아직 미확인 알림을 체크하지 않았으면 체크
        if (isLoggedIn && !_hasCheckedUnread) {
          _hasCheckedUnread = true;
          final userMode = isHostMode ? 'host' : 'guest';
          // 비동기로 미확인 알림 체크 (UI 블로킹 없음)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            gnbProvider.checkUnreadNotifications(userMode);
          });
        }

        // 로그아웃 시 상태 리셋
        if (!isLoggedIn && _hasCheckedUnread) {
          _hasCheckedUnread = false;
        }

        // 🐛 디버깅: 사용자 상태 로그
        debugPrint('🔍 [GNB] isLoggedIn: $isLoggedIn, isHostMode: $isHostMode');
        debugPrint('🔍 [GNB] currentUser: ${authService.currentUser?.email}, mode: ${authService.currentUser?.mode}');

        return Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    // 로고
                    _buildLogo(context),

                    // 중앙 메뉴 (호스트 모드에서만 표시)
                    if (isLoggedIn && isHostMode) ...[
                      SizedBox(width: AppSpacing.xl),
                      _buildHostCenterMenu(context),
                    ],

                    Spacer(),

                    // 우측 액션
                    _buildActions(
                      context,
                      authService,
                      gnbProvider,
                      isLoggedIn,
                      isHostMode,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 로고
  Widget _buildLogo(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const EZStayLogo(width: 40, height: 40),
          SizedBox(width: AppSpacing.sm),
          Text(
            'EZstay',
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.primary500,
            ),
          ),
        ],
      ),
    );
  }

  /// 호스트 모드 중앙 메뉴 (방 관리, 계약, 정산)
  Widget _buildHostCenterMenu(BuildContext context) {
    return Row(
      children: [
        _buildTextButton(
          context,
          label: '방 관리',
          onPressed: () => context.go('/host/room-management'),
        ),
        SizedBox(width: AppSpacing.md),
        _buildTextButton(
          context,
          label: '계약',
          onPressed: () => context.go('/host/contracts'),
        ),
        SizedBox(width: AppSpacing.md),
        _buildTextButton(
          context,
          label: '정산',
          onPressed: () {
            // TODO: 정산 페이지 라우트 추가 필요
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('정산 페이지 준비 중입니다.'),
                backgroundColor: AppColors.primary500,
              ),
            );
          },
        ),
      ],
    );
  }

  /// 텍스트 버튼
  Widget _buildTextButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 우측 액션
  Widget _buildActions(
    BuildContext context,
    AuthService authService,
    GNBProvider gnbProvider,
    bool isLoggedIn,
    bool isHostMode,
  ) {
    // 로그인 전
    if (!isLoggedIn) {
      return _buildGuestLoggedOutActions(context, isHostMode);
    }

    // 로그인 후
    return _buildLoggedInActions(
      context,
      authService,
      gnbProvider,
      isHostMode,
    );
  }

  /// 게스트 모드 - 로그인 전 액션
  Widget _buildGuestLoggedOutActions(BuildContext context, bool isHostMode) {
    return Row(
      children: [
        // 호스트 모드로 전환 버튼
        OutlinedButton(
          onPressed: () {
            // 로그인 페이지로 이동 (호스트 모드 안내)
            context.go('/login');
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: BorderSide(color: AppColors.border),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.radiusMd,
            ),
          ),
          child: Text(
            '호스트 모드로 전환',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(width: AppSpacing.md),

        // 로그인/회원가입 버튼
        ElevatedButton(
          onPressed: () => context.go('/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary500,
            foregroundColor: AppColors.neutral0,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.radiusMd,
            ),
            elevation: 0,
          ),
          child: Text(
            '로그인/회원가입',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.neutral0,
            ),
          ),
        ),
      ],
    );
  }

  /// 로그인 후 액션 (게스트/호스트 공통)
  Widget _buildLoggedInActions(
    BuildContext context,
    AuthService authService,
    GNBProvider gnbProvider,
    bool isHostMode,
  ) {
    return Row(
      children: [
        // 모드 전환 버튼
        OutlinedButton(
          onPressed: () => _switchMode(context, authService, isHostMode),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: BorderSide(color: AppColors.border),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.radiusMd,
            ),
          ),
          child: Text(
            isHostMode ? '게스트 모드로 전환' : '호스트 모드로 전환',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(width: AppSpacing.md),

        // 알림 아이콘
        GNBIconButton(
          icon: Icons.notifications_outlined,
          showBadge: gnbProvider.hasUnreadNotifications,
          onPressed: () {
            // 알림 페이지로 이동 (읽음 처리는 알림 페이지에서 수행)
            context.push('/notifications');
          },
          tooltip: '알림',
        ),

        // 채팅 아이콘
        GNBIconButton(
          icon: Icons.chat_bubble_outline,
          showBadge: gnbProvider.hasUnreadChats,
          onPressed: () {
            gnbProvider.markChatsAsRead();
            // 채팅 목록 페이지로 이동
            context.push('/chat-list');
          },
          tooltip: '채팅',
        ),

        SizedBox(width: AppSpacing.sm),

        // 메뉴 드롭다운
        GNBMenuDropdown(
          authService: authService,
          isHostMode: isHostMode,
        ),
      ],
    );
  }

  /// 모드 전환
  void _switchMode(
    BuildContext context,
    AuthService authService,
    bool isCurrentlyHostMode,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isCurrentlyHostMode ? '게스트 모드로 전환' : '호스트 모드로 전환',
          style: AppTextStyles.headingSmall,
        ),
        content: Text(
          isCurrentlyHostMode
              ? '게스트 모드로 전환하시겠습니까?\n숙소 검색 및 예약 기능을 사용할 수 있습니다.'
              : '호스트 모드로 전환하시겠습니까?\n숙소 등록 및 관리 기능을 사용할 수 있습니다.',
          style: AppTextStyles.bodyMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              '취소',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final newMode = isCurrentlyHostMode ? UserMode.guest : UserMode.host;

              // 게스트→호스트 전환 시 체크
              if (!isCurrentlyHostMode && newMode == UserMode.host) {
                final currentUser = authService.currentUser;

                if (currentUser != null) {
                  // 1. 본인인증 완료 + 계좌 등록 완료 → 바로 호스트 홈으로
                  if (currentUser.phoneVerified && currentUser.hasBank) {
                    debugPrint('✅ [GNB] 본인인증+계좌 모두 완료 → 호스트 모드 전환');
                    await authService.switchUserMode(newMode);
                    // 모드 전환 후 미읽은 알림 재체크
                    if (context.mounted) {
                      context.read<GNBProvider>().checkUnreadNotifications('host');
                      context.go('/host');
                    }
                    return;
                  }

                  // 2. 본인인증 완료 + 계좌 미등록 → 계좌 입력 페이지
                  if (currentUser.phoneVerified && !currentUser.hasBank) {
                    debugPrint('⚠️ [GNB] 본인인증 완료, 계좌 미등록 → 계좌 입력 페이지');
                    if (context.mounted) {
                      context.go('/host/account-setup-standalone');
                    }
                    return;
                  }
                }

                // 3. 본인인증 필요 → 호스트 가입 플로우로 이동
                debugPrint('⚠️ [GNB] 본인인증 필요 → 호스트 가입 플로우');
                if (context.mounted) {
                  context.go('/register/host/kakao');
                }
                return;
              }

              // 호스트→게스트 전환 (단순 모드 변경)
              await authService.switchUserMode(newMode);

              if (context.mounted) {
                // 모드 전환 후 미읽은 알림 재체크
                final newUserMode = isCurrentlyHostMode ? 'guest' : 'host';
                context.read<GNBProvider>().checkUnreadNotifications(newUserMode);
                final route = isCurrentlyHostMode ? '/' : '/host';
                context.go(route);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              foregroundColor: AppColors.neutral0,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.radiusSm,
              ),
            ),
            child: Text(
              '전환하기',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
