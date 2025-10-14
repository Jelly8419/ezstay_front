import 'package:flutter/material.dart';
import '../models/room.dart';
import '../constants/app_constants.dart';

/// 매물 카드 위젯
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
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHover?.call(true);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onHover?.call(false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected || _isHovered
                  ? AppColors.primary
                  : Colors.grey[300]!,
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 사진 영역
              _buildPhotoSection(),

              // 정보 영역
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 방 이름
                    Text(
                      widget.room.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // 주소 (동까지만)
                    Text(
                      widget.room.addressWithoutDetail,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // 가격
                    Row(
                      children: [
                        if (widget.room.discount != null) ...[
                          Text(
                            '${widget.room.discount}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '${_formatPrice(widget.room.discountedWeeklyPrice)}/주',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 방 정보 (인원, 침대, 화장실, 방)
                    Row(
                      children: [
                        _buildIconInfo(Icons.people, '${widget.room.maxGuests}명'),
                        const SizedBox(width: 12),
                        _buildIconInfo(Icons.bed, '침대 ${widget.room.beds}'),
                        const SizedBox(width: 12),
                        _buildIconInfo(Icons.bathroom, '화장실 ${widget.room.bathrooms}'),
                        const SizedBox(width: 12),
                        _buildIconInfo(Icons.door_sliding, '방 ${widget.room.bedrooms}'),
                      ],
                    ),

                    // 할인 정보 (있을 경우)
                    if (widget.room.discount != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${widget.room.discount}% 할인 중',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        color: Colors.grey[200],
      ),
      child: Stack(
        children: [
          // 사진 또는 플레이스홀더
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: hasPhotos
                ? Image.network(
                    widget.room.photos[_currentPhotoIndex],
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('❌ [PROPERTY_CARD] 이미지 로드 실패: ${widget.room.photos[_currentPhotoIndex]}');
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
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home, size: 48, color: Colors.grey[500]),
          const SizedBox(height: 8),
          Text(
            '사진 없음',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
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
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }

  Widget _buildIconInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
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
