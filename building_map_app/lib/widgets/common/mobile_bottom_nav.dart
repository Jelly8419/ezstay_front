import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/gnb_provider.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import 'gnb_notification_badge.dart';

/// 모바일 하단 네비게이션 바
///
/// 1024px 미만에서만 표시 (AppShellScaffold에서 분기).
///
/// 임대인 모드: 홈 | 방 관리 | 입주 준비 | 계약 | 더보기
/// 임차인 모드: 홈 | 지도   | 계약 | 채팅 | My
class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({super.key});

  static const Color _activeColor = AppColors.primary500;
  static const Color _inactiveColor = AppColors.neutral700; // gray-600 근사값

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final authService = context.watch<AuthService>();
    final gnbProvider = context.watch<GNBProvider>();
    final isHostMode = authService.currentUser?.mode == UserMode.host;

    final tabs = isHostMode
        ? _hostTabs(context, location, gnbProvider)
        : _guestTabs(context, location, gnbProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: tabs,
          ),
        ),
      ),
    );
  }

  // ===================== 임대인 탭 =====================

  List<Widget> _hostTabs(
    BuildContext context,
    String location,
    GNBProvider gnbProvider,
  ) {
    return [
      _buildTab(
        context: context,
        icon: Icons.home_outlined,
        label: '홈',
        isActive: _isHostHome(location),
        onTap: () => context.go('/host'),
      ),
      _buildTab(
        context: context,
        icon: Icons.meeting_room_outlined,
        label: '방 관리',
        isActive: _isRoomManagement(location),
        onTap: () => context.go('/host/room-management'),
      ),
      _buildTab(
        context: context,
        icon: Icons.cleaning_services_outlined,
        label: '입주 준비',
        isActive: _isMoveIn(location),
        onTap: () => context.go('/host/move-in'),
      ),
      _buildTab(
        context: context,
        icon: Icons.description_outlined,
        label: '계약',
        isActive: _isHostContracts(location),
        onTap: () => context.go('/host/contracts'),
      ),
      _buildTab(
        context: context,
        icon: Icons.more_horiz,
        label: '더보기',
        isActive: _isHostMore(location),
        onTap: () => context.go('/host/more'),
      ),
    ];
  }

  // ===================== 임차인 탭 =====================

  List<Widget> _guestTabs(
    BuildContext context,
    String location,
    GNBProvider gnbProvider,
  ) {
    return [
      _buildTab(
        context: context,
        icon: Icons.home_outlined,
        label: '홈',
        isActive: _isGuestHome(location),
        onTap: () => context.go('/guest'),
      ),
      _buildTab(
        context: context,
        icon: Icons.map_outlined,
        label: '지도',
        isActive: _isMap(location),
        onTap: () => context.go('/map'),
      ),
      _buildTab(
        context: context,
        icon: Icons.description_outlined,
        label: '계약',
        isActive: _isGuestContracts(location),
        onTap: () => context.go('/guest/contracts'),
      ),
      _buildChatTab(
        context: context,
        isActive: _isChat(location),
        hasUnread: gnbProvider.hasUnreadChats,
        onTap: () => context.go('/chat-list'),
      ),
      _buildTab(
        context: context,
        icon: Icons.person_outline,
        label: 'My',
        isActive: _isGuestMy(location),
        onTap: () => context.go('/guest/my-page'),
      ),
    ];
  }

  // ===================== Active 판정 =====================

  bool _isHostHome(String location) =>
      location == '/host' ||
      (location.startsWith('/host') &&
          !_isRoomManagement(location) &&
          !_isMoveIn(location) &&
          !_isHostContracts(location) &&
          !_isHostMore(location));

  bool _isRoomManagement(String location) =>
      location.startsWith('/host/room');

  bool _isMoveIn(String location) =>
      location.startsWith('/host/move-in');

  bool _isHostContracts(String location) =>
      location.startsWith('/host/contracts');

  /// "더보기" 탭 활성화 영역 — 더보기 페이지 자체와 그 안에서 진입하는 모든 자식 화면.
  /// 채팅·정산·My·고객센터 어디 있든 더보기 탭이 하이라이트되도록 묶음.
  bool _isHostMore(String location) =>
      location.startsWith('/host/more') ||
      location.startsWith('/host/settlement') ||
      location.startsWith('/host/my-page') ||
      location.startsWith('/support') ||
      location.startsWith('/chat');

  bool _isGuestHome(String location) =>
      location == '/guest' ||
      location.startsWith('/guest/room');

  bool _isMap(String location) => location.startsWith('/map');

  bool _isGuestContracts(String location) =>
      location.startsWith('/guest/contracts');

  bool _isGuestMy(String location) =>
      location.startsWith('/guest/my-page') ||
      location.startsWith('/support');

  bool _isChat(String location) => location.startsWith('/chat');

  // ===================== 위젯 빌더 =====================

  Widget _buildTab({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = isActive ? _activeColor : _inactiveColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTab({
    required BuildContext context,
    required bool isActive,
    required bool hasUnread,
    required VoidCallback onTap,
  }) {
    final color = isActive ? _activeColor : _inactiveColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GNBNotificationBadge(
              showBadge: hasUnread,
              child: Icon(Icons.chat_bubble_outline, size: 24, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              '채팅',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
