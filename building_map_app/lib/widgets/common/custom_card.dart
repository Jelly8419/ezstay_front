import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

/// 공통 카드 위젯
///
/// 떠있는 느낌을 주는 카드 스타일을 제공합니다.
/// property_card와 동일한 스타일을 사용합니다.
class CustomCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final double? elevation;
  final Color? color;
  final Border? border;

  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.elevation,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: elevation ?? 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: (elevation ?? 0.08) / 2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: card,
      );
    }

    return card;
  }
}

/// 호버 효과가 있는 카드 위젯
class HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final bool isSelected;

  const HoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.isSelected = false,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppConstants.defaultAnimationDuration,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(
            color: widget.isSelected || _isHovered
                ? AppColors.primary
                : Colors.grey[300]!,
            width: widget.isSelected ? 2 : 1,
          ),
          boxShadow: _isHovered || widget.isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            child: widget.padding != null
                ? Padding(padding: widget.padding!, child: widget.child)
                : widget.child,
          ),
        ),
      ),
    );
  }
}
