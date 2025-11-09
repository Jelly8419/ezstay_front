import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'gnb_notification_badge.dart';

/// GNB 아이콘 버튼
/// Red Dot 배지를 지원하는 아이콘 버튼입니다.
class GNBIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool showBadge;
  final String? tooltip;
  final double iconSize;

  const GNBIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.showBadge = false,
    this.tooltip,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      icon: Icon(icon, size: iconSize),
      onPressed: onPressed,
      color: AppColors.textPrimary,
      tooltip: tooltip,
      padding: EdgeInsets.all(AppSpacing.sm),
      constraints: BoxConstraints(
        minWidth: 40,
        minHeight: 40,
      ),
    );

    // Red Dot 배지가 필요한 경우
    if (showBadge) {
      return GNBNotificationBadge(
        showBadge: true,
        child: button,
      );
    }

    return button;
  }
}
