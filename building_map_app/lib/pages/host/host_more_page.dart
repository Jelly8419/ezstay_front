import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/gnb_provider.dart';
import '../../widgets/common/responsive_page_layout.dart';

/// 호스트 모바일 "더보기" 페이지
///
/// 모바일 하단 탭이 5개로 제한되어 메인에 들어가지 못한 메뉴를 정리해 노출.
/// 메뉴: 채팅 / 정산 / My / 고객센터
class HostMorePage extends StatelessWidget {
  const HostMorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final hasUnreadChats = context.watch<GNBProvider>().hasUnreadChats;

    return ResponsivePageLayout(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('더보기', style: AppTextStyles.headingLarge),
            ),
            SizedBox(height: AppSpacing.md),
            _MoreItem(
              icon: Icons.chat_bubble_outline,
              label: '채팅',
              showBadge: hasUnreadChats,
              onTap: () => context.go('/chat-list'),
            ),
            _MoreItem(
              icon: Icons.account_balance_wallet_outlined,
              label: '정산',
              onTap: () => context.go('/host/settlement'),
            ),
            _MoreItem(
              icon: Icons.person_outline,
              label: 'My',
              onTap: () => context.go('/host/my-page'),
            ),
            _MoreItem(
              icon: Icons.help_outline,
              label: '고객센터',
              onTap: () => context.go('/support'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool showBadge;
  final VoidCallback onTap;

  const _MoreItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.textSecondary),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyLarge),
            ),
            if (showBadge)
              Container(
                width: 8,
                height: 8,
                margin: EdgeInsets.only(right: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.error500,
                  shape: BoxShape.circle,
                ),
              ),
            Icon(Icons.chevron_right, size: 20, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}
