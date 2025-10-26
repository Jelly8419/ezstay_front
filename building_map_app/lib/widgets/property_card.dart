import 'package:flutter/material.dart';
import '../models/room.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_colors.dart' as theme;
import '../core/theme/app_text_styles.dart' as theme;

/// 매물 카드 위젯 (모던 인터랙티브 호버 효과 적용)
class PropertyCard extends StatefulWidget {
  final Room room;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(bool)? onHover;

  const PropertyCard({
    super.key,
    required this.room,
    this.isSelected = false,
    required this.onTap,
    this.onHover,
  });

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  bool _isHovered = false;
  int _currentPhotoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isActive = _isHovered || widget.isSelected;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHover?.call(true);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onHover?.call(false);
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.hoverCard,
          curve: AppCurves.hoverCard,
          transform: _isHovered
              ? Matrix4.translationValues(0, -8, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: theme.AppColors.surface,
            borderRadius: AppRadius.radiusMd,
            border: Border.all(
              color: widget.isSelected
                  ? theme.AppColors.primary500
                  : _isHovered
                      ? theme.AppColors.primary300
                      : theme.AppColors.border,
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: isActive
                ? (widget.isSelected
                    ? AppShadows.cardSelected
                    : AppShadows.cardHover)
                : AppShadows.cardDefault,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 사진 영역
              _buildPhotoSection(),

              // 정보 영역
              Padding(
                padding: AppSpacing.paddingMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 방 이름
                    Text(
                      widget.room.roomName,
                      style: theme.AppTextStyles.headingSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSpacing.xs),

                    // 주소
                    Text(
                      widget.room.address,
                      style: theme.AppTextStyles.bodyMediumSecondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSpacing.sm),

                    // 가격
                    Row(
                      children: [
                        if (widget.room.longTermDiscount > 0) ...[
                          Text(
                            '${widget.room.longTermDiscount}%',
                            style: theme.AppTextStyles.labelMedium.copyWith(
                              color: theme.AppColors.error500,
                            ),
                          ),
                          SizedBox(width: AppSpacing.xs),
                        ],
                        Text(
                          '${_formatPrice(widget.room.weeklyRent)}/주',
                          style: theme.AppTextStyles.priceText,
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),

                    // 방 정보 (침대, 화장실, 방)
                    Row(
                      children: [
                        if (widget.room.totalBeds > 0) ...[
                          _buildIconInfo(Icons.bed, '침대 ${widget.room.totalBeds}'),
                          SizedBox(width: AppSpacing.md),
                        ],
                        _buildIconInfo(Icons.bathroom, '욕실 ${widget.room.bathroomCount}'),
                        SizedBox(width: AppSpacing.md),
                        _buildIconInfo(Icons.door_sliding, '방 ${widget.room.roomCount}'),
                      ],
                    ),

                    // 할인 정보 (있을 경우)
                    if (widget.room.longTermDiscount > 0) ...[
                      SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: theme.AppColors.error50,
                          borderRadius: AppRadius.radiusSm,
                        ),
                        child: Text(
                          '${widget.room.longTermDiscount}% 할인 중',
                          style: theme.AppTextStyles.labelSmall.copyWith(
                            color: theme.AppColors.error500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    final hasPhotos = widget.room.photos.isNotEmpty;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: AppRadius.radiusTopMd,
        color: theme.AppColors.neutral200,
      ),
      child: Stack(
        children: [
          // 사진 또는 플레이스홀더
          ClipRRect(
            borderRadius: AppRadius.radiusTopMd,
            child: hasPhotos
                ? Image.network(
                    widget.room.photos[_currentPhotoIndex].url,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('❌ [PROPERTY_CARD] 이미지 로드 실패: ${widget.room.photos[_currentPhotoIndex].url}');
                      debugPrint('❌ [PROPERTY_CARD] 에러: $error');
                      return _buildPlaceholder();
                    },
                  )
                : _buildPlaceholder(),
          ),

          // 좌우 화살표 (사진이 2개 이상일 때만) - 인피니트 롤링
          if (hasPhotos && widget.room.photos.length > 1) ...[
            // 왼쪽 화살표
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildArrowButton(
                  Icons.chevron_left,
                  () {
                    setState(() {
                      _currentPhotoIndex = (_currentPhotoIndex - 1 + widget.room.photos.length) % widget.room.photos.length;
                    });
                  },
                ),
              ),
            ),

            // 오른쪽 화살표
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildArrowButton(
                  Icons.chevron_right,
                  () {
                    setState(() {
                      _currentPhotoIndex = (_currentPhotoIndex + 1) % widget.room.photos.length;
                    });
                  },
                ),
              ),
            ),

            // 사진 인디케이터
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentPhotoIndex + 1} / ${widget.room.photos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      color: theme.AppColors.neutral200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home, size: 48, color: theme.AppColors.neutral400),
          SizedBox(height: AppSpacing.sm),
          Text(
            '사진 없음',
            style: theme.AppTextStyles.bodyMediumSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildArrowButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: theme.AppColors.neutral0.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: AppShadows.shadowMd,
        ),
        child: Icon(icon, size: 20, color: theme.AppColors.neutral800),
      ),
    );
  }

  Widget _buildIconInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.AppColors.neutral600),
        SizedBox(width: AppSpacing.xs),
        Text(
          text,
          style: theme.AppTextStyles.bodySmall.copyWith(
            color: theme.AppColors.neutral700,
          ),
        ),
      ],
    );
  }

  String _formatPrice(int price) {
    if (price >= 10000) {
      final manWon = price ~/ 10000;
      final remainder = price % 10000;
      if (remainder == 0) {
        return '$manWon만원';
      }
      return '$manWon.${(remainder / 1000).toStringAsFixed(0)}만원';
    }
    return '${price.toString()}원';
  }
}
