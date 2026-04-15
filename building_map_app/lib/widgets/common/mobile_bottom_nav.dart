import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/gnb_provider.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

/// 모바일 하단 네비게이션 바
///
/// React MobileBottomNav 컴포넌트를 1:1 수치 매칭으로 변환.
/// 1024px 미만에서만 표시 (lg:hidden 대응).
/// 탭: 지도, 계약, 채팅(unread 배지), 더보기
class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({super.key});

  // React 색상 수치 그대로 매칭
  static const Color _activeColor = AppColors.primary500; // #3B82F6
  static const Color _inactiveColor = Color(0xFF4B5563); // Tailwind gray-600
  static const Color _badgeColor = Color(0xFFEF4444); // Tailwind red-500

  @override
  Widget build(BuildContext context) {
    // 1024px 이상이면 표시하지 않음 (lg:hidden)
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1024) return const SizedBox.shrink();

    final location = GoRouterState.of(context).matchedLocation;
    final authService = context.watch<AuthService>();
    final gnbProvider = context.watch<GNBProvider>();
    final isHostMode = authService.currentUser?.mode == UserMode.host;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, // bg-white
        border: Border(
          top: BorderSide(
            color: AppColors.border, // border-gray-200 (#E5E7EB)
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6), // py-1.5 = 6px
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 지도
              _buildTab(
                context: context,
                icon: Icons.map_outlined,
                label: '지도',
                isActive: _isActiveMap(location),
                onTap: () => context.go('/map'),
              ),
              // 계약
              _buildTab(
                context: context,
                icon: Icons.description_outlined,
                label: '계약',
                isActive: _isActiveContracts(location),
                onTap: () {
                  final route =
                      isHostMode ? '/host/contracts' : '/guest/contracts';
                  context.go(route);
                },
              ),
              // 채팅
              _buildChatTab(
                context: context,
                isActive: _isActiveChat(location),
                hasUnread: gnbProvider.hasUnreadChats,
                onTap: () => context.go('/chat-list'),
              ),
              // 더보기
              _buildTab(
                context: context,
                icon: Icons.more_horiz,
                label: '더보기',
                isActive: _isActiveMore(location),
                onTap: () {
                  final route =
                      isHostMode ? '/host/my-page' : '/guest/my-page';
                  context.go(route);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// active 판정: 지도
  bool _isActiveMap(String location) {
    return location == '/map';
  }

  /// active 판정: 계약
  bool _isActiveContracts(String location) {
    return location.contains('/contracts');
  }

  /// active 판정: 채팅
  bool _isActiveChat(String location) {
    return location.startsWith('/chat');
  }

  /// active 판정: 더보기
  bool _isActiveMore(String location) {
    return location.contains('/my-page') || location.contains('/support');
  }

  /// 일반 탭 버튼
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
        padding: const EdgeInsets.symmetric(
          horizontal: 24, // px-6 = 24px
          vertical: 6, // py-1.5 = 6px
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24, // w-6 h-6 = 24px
              color: color,
            ),
            const SizedBox(height: 2), // gap-0.5 = 2px
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

  /// 채팅 탭 (unread 배지 포함)
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
        padding: const EdgeInsets.symmetric(
          horizontal: 24, // px-6 = 24px
          vertical: 6, // py-1.5 = 6px
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 24, // w-6 h-6 = 24px
                  color: color,
                ),
                const SizedBox(height: 2), // gap-0.5 = 2px
                Text(
                  '채팅',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                  ),
                ),
              ],
            ),
            // unread 배지
            if (hasUnread)
              Positioned(
                top: -4, // absolute top-1 = 4px (아이콘 기준 위로)
                right: -16, // absolute right-4 = 16px (아이콘 기준 오른쪽으로)
                child: Container(
                  width: 20, // w-5 = 20px
                  height: 20, // h-5 = 20px
                  decoration: const BoxDecoration(
                    color: _badgeColor, // bg-red-500
                    shape: BoxShape.circle, // rounded-full
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'N',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
