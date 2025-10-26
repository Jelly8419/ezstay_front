import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';

/// 모던 플랫폼 스타일의 호버 효과가 있는 카드 위젯
///
/// 재사용 가능한 카드 컴포넌트로, 마우스 호버 시 부드럽게 위로 올라가며
/// 그림자가 강조되는 효과를 제공합니다.
///
/// 사용 예시:
/// ```dart
/// HoverCard(
///   onTap: () => print('탭됨'),
///   isSelected: false,
///   enableHoverLift: true,
///   child: Column(
///     children: [
///       Text('제목'),
///       Text('내용'),
///     ],
///   ),
/// )
/// ```
class HoverCard extends StatefulWidget {
  /// 카드 내부 컨텐츠
  final Widget child;

  /// 카드 클릭 시 실행될 콜백
  final VoidCallback? onTap;

  /// 호버 상태 변경 시 실행될 콜백
  final Function(bool isHovered)? onHoverChanged;

  /// 카드가 선택된 상태인지 여부
  final bool isSelected;

  /// 호버 시 위로 올라가는 효과 활성화 여부
  final bool enableHoverLift;

  /// 카드의 위로 올라가는 높이 (픽셀)
  final double liftHeight;

  /// 카드의 둥근 모서리 반지름
  final BorderRadius? borderRadius;

  /// 카드의 배경색
  final Color? backgroundColor;

  /// 카드의 패딩
  final EdgeInsetsGeometry? padding;

  /// 카드의 테두리
  final Border? border;

  /// 애니메이션 지속 시간
  final Duration? animationDuration;

  /// 애니메이션 커브
  final Curve? animationCurve;

  const HoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.onHoverChanged,
    this.isSelected = false,
    this.enableHoverLift = true,
    this.liftHeight = 8.0,
    this.borderRadius,
    this.backgroundColor,
    this.padding,
    this.border,
    this.animationDuration,
    this.animationCurve,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  void _handleHoverEnter(PointerEvent event) {
    setState(() => _isHovered = true);
    widget.onHoverChanged?.call(true);
  }

  void _handleHoverExit(PointerEvent event) {
    setState(() => _isHovered = false);
    widget.onHoverChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _isHovered || widget.isSelected;

    return MouseRegion(
      onEnter: _handleHoverEnter,
      onExit: _handleHoverExit,
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: widget.animationDuration ?? AppDurations.hoverCard,
          curve: widget.animationCurve ?? AppCurves.hoverCard,
          transform: widget.enableHoverLift && _isHovered
              ? Matrix4.translationValues(0, -widget.liftHeight, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppColors.surface,
            borderRadius: widget.borderRadius ?? AppRadius.radiusMd,
            border: widget.border ??
                Border.all(
                  color: widget.isSelected
                      ? AppColors.primary500
                      : _isHovered
                          ? AppColors.primary300
                          : AppColors.border,
                  width: widget.isSelected ? 2 : 1,
                ),
            boxShadow: isActive
                ? (widget.isSelected
                    ? AppShadows.cardSelected
                    : AppShadows.cardHover)
                : AppShadows.cardDefault,
          ),
          child: widget.padding != null
              ? Padding(
                  padding: widget.padding!,
                  child: widget.child,
                )
              : widget.child,
        ),
      ),
    );
  }
}

/// 호버 효과만 있는 간단한 래퍼 위젯
///
/// 기존 위젯에 호버 효과만 추가하고 싶을 때 사용합니다.
///
/// 사용 예시:
/// ```dart
/// HoverEffect(
///   onTap: () {},
///   child: PropertyCard(...),
/// )
/// ```
class HoverEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Function(bool isHovered)? onHoverChanged;
  final bool enableLift;
  final double liftHeight;

  const HoverEffect({
    super.key,
    required this.child,
    this.onTap,
    this.onHoverChanged,
    this.enableLift = true,
    this.liftHeight = 8.0,
  });

  @override
  State<HoverEffect> createState() => _HoverEffectState();
}

class _HoverEffectState extends State<HoverEffect> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHoverChanged?.call(true);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onHoverChanged?.call(false);
      },
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.hoverCard,
          curve: AppCurves.hoverCard,
          transform: widget.enableLift && _isHovered
              ? Matrix4.translationValues(0, -widget.liftHeight, 0)
              : Matrix4.identity(),
          child: widget.child,
        ),
      ),
    );
  }
}

/// 모던 플랫폼 스타일의 이미지 카드
///
/// 이미지 + 정보를 표시하는 카드 레이아웃
///
/// 사용 예시:
/// ```dart
/// ImageInfoCard(
///   imageUrl: 'https://...',
///   title: '강남역 도보 5분',
///   subtitle: '서울시 강남구',
///   badge: '신규',
///   onTap: () {},
/// )
/// ```
class ImageInfoCard extends StatelessWidget {
  final String? imageUrl;
  final Widget? imageWidget;
  final String title;
  final String? subtitle;
  final String? badge;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSelected;
  final double? imageHeight;

  const ImageInfoCard({
    super.key,
    this.imageUrl,
    this.imageWidget,
    required this.title,
    this.subtitle,
    this.badge,
    this.trailing,
    this.onTap,
    this.isSelected = false,
    this.imageHeight = 200,
  });

  @override
  Widget build(BuildContext context) {
    return HoverCard(
      onTap: onTap,
      isSelected: isSelected,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 영역
          if (imageUrl != null || imageWidget != null)
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.md),
              ),
              child: Stack(
                children: [
                  imageWidget ??
                      Image.network(
                        imageUrl!,
                        width: double.infinity,
                        height: imageHeight,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: imageHeight,
                            color: AppColors.neutral200,
                            child: Icon(
                              Icons.broken_image,
                              size: 48,
                              color: AppColors.neutral400,
                            ),
                          );
                        },
                      ),

                  // 배지
                  if (badge != null)
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary500,
                          borderRadius: AppRadius.radiusSm,
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: AppColors.neutral0,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // 정보 영역
          Padding(
            padding: AppSpacing.paddingMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (trailing != null) ...[
                  SizedBox(height: AppSpacing.sm),
                  trailing!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
