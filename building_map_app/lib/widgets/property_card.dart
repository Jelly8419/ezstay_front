import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import '../models/room.dart';
import '../utils/contract_utils.dart';
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
            color: widget.room.isAvailable
                ? theme.AppColors.surface
                : theme.AppColors.neutral100,
            borderRadius: AppRadius.radiusMd,
            border: Border.all(
              color: !widget.room.isAvailable
                  ? theme.AppColors.neutral300
                  : widget.isSelected
                  ? theme.AppColors.primary500
                  : _isHovered
                  ? theme.AppColors.primary300
                  : theme.AppColors.border,
              width: widget.isSelected && widget.room.isAvailable ? 2 : 1,
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
                      style: theme.AppTextStyles.headingSmall.copyWith(
                        color: widget.room.isAvailable
                            ? null
                            : theme.AppColors.neutral400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSpacing.xs),

                    // 주소
                    Text(
                      widget.room.address,
                      style: theme.AppTextStyles.bodyMediumSecondary.copyWith(
                        color: widget.room.isAvailable
                            ? null
                            : theme.AppColors.neutral400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSpacing.sm),

                    // 예약 불가 배지
                    if (!widget.room.isAvailable) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.AppColors.neutral200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '예약 불가',
                          style: theme.AppTextStyles.bodySmall.copyWith(
                            color: theme.AppColors.neutral500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                    ],

                    // 가격 (검은색, 비가용 시 회색)
                    Text(
                      '${_formatPrice(widget.room.weeklyRent)}원/주',
                      style: theme.AppTextStyles.priceText.copyWith(
                        color: widget.room.isAvailable
                            ? Colors.black
                            : theme.AppColors.neutral400,
                      ),
                    ),

                    // 할인 정보 텍스트 (파란색, 배경 없음) - 가용 시에만 표시
                    if (widget.room.isAvailable) ...[
                      if (_hasQuickMoveInDiscount()) ...[
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          '* ${widget.room.quickMoveIn}일 이내 입주시 ${_formatPrice(widget.room.quickMoveInDiscount!)}원 할인',
                          style: theme.AppTextStyles.bodySmall.copyWith(
                            color: theme.AppColors.primary500,
                          ),
                        ),
                      ],
                      if (_hasLongTermDiscount()) ...[
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          '* ${widget.room.longTermWeeks}주 이상 계약시 ${widget.room.longTermDiscount}% 할인',
                          style: theme.AppTextStyles.bodySmall.copyWith(
                            color: theme.AppColors.primary500,
                          ),
                        ),
                      ],
                    ],

                    SizedBox(height: AppSpacing.sm),

                    // 방 정보 (최대 인원 표시)
                    _buildIconInfo(
                      Icons.people,
                      '최대 ${widget.room.maxGuests}명',
                    ),
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

    // 디버그: PropertyCard에서 받은 photos 확인 (첫 렌더링만)
    if (_currentPhotoIndex == 0 && !hasPhotos) {
      AppLogger.w('⚠️ [CARD] PropertyCard - photos 없음 (room.id: ${widget.room.id})');
    } else if (_currentPhotoIndex == 0 && hasPhotos) {
    }

    return AspectRatio(
      aspectRatio: 4 / 3, // 4:3 비율
      child: Container(
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
                      ContractUtils.getFullImageUrl(widget.room.photos[_currentPhotoIndex].url),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: theme.AppColors.neutral200,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.AppColors.neutral400,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
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
                  child: _buildArrowButton(Icons.chevron_left, () {
                    setState(() {
                      _currentPhotoIndex =
                          (_currentPhotoIndex - 1 + widget.room.photos.length) %
                          widget.room.photos.length;
                    });
                  }),
                ),
              ),

              // 오른쪽 화살표
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildArrowButton(Icons.chevron_right, () {
                    setState(() {
                      _currentPhotoIndex =
                          (_currentPhotoIndex + 1) % widget.room.photos.length;
                    });
                  }),
                ),
              ),

              // 사진 인디케이터
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentPhotoIndex + 1} / ${widget.room.photos.length}',
                      style: theme.AppTextStyles.caption.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
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
          Text('사진 없음', style: theme.AppTextStyles.bodyMediumSecondary),
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

  /// 가격을 콤마 구분 포맷으로 변환 (예: 1,446,000원)
  String _formatPrice(int price) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return price.toString().replaceAllMapped(formatter, (Match m) => '${m[1]},');
  }

  /// 빠른입주 할인 정보가 있는지 확인 (quickMoveIn AND quickMoveInDiscount 둘 다 필요)
  bool _hasQuickMoveInDiscount() {
    return widget.room.quickMoveIn != null &&
           widget.room.quickMoveInDiscount != null &&
           widget.room.quickMoveInDiscount! > 0;
  }

  /// 장기계약 할인 정보가 있는지 확인 (longTermWeeks AND longTermDiscount 둘 다 필요)
  bool _hasLongTermDiscount() {
    return widget.room.longTermWeeks != null &&
           widget.room.longTermDiscount != null &&
           widget.room.longTermDiscount! > 0;
  }
}
