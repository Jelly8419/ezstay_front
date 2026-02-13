import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// GNB 알림 배지 (Red Dot)
/// 아이콘 우측 상단에 빨간 점을 표시합니다.
class GNBNotificationBadge extends StatelessWidget {
  final Widget child;
  final bool showBadge;
  final double badgeSize;

  const GNBNotificationBadge({
    super.key,
    required this.child,
    this.showBadge = false,
    this.badgeSize = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (showBadge)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: AppColors.error500,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surface,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
