import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

/// Property Card - 매물 카드
///
/// 사용 예시:
/// ```dart
/// PropertyCard(
///   imageUrl: 'https://example.com/image.jpg',
///   title: '강남역 도보 5분 신축 원룸',
///   location: '서울시 강남구 역삼동',
///   rating: 4.8,
///   reviewCount: 128,
///   price: '₩330,000',
///   period: '주',
///   badges: ['신규', '할인'],
///   isFavorite: false,
///   onTap: () {},
///   onFavorite: () {},
/// )
/// ```
class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.price,
    this.period = '주',
    this.rating,
    this.reviewCount,
    this.badges = const [],
    this.isFavorite = false,
    this.onTap,
    this.onFavorite,
  });

  final String imageUrl;
  final String title;
  final String location;
  final String price;
  final String period;
  final double? rating;
  final int? reviewCount;
  final List<String> badges;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.radiusLg,
          boxShadow: AppShadows.shadowMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 영역
            _ImageSection(
              imageUrl: imageUrl,
              badges: badges,
              isFavorite: isFavorite,
              onFavorite: onFavorite,
            ),

            // 정보 영역
            Padding(
              padding: AppSpacing.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    title,
                    style: AppTextStyles.headingSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppSpacing.xs),

                  // 위치
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: AppSizes.iconXs,
                        color: AppColors.neutral500,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: AppTextStyles.bodySmallSecondary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm),

                  // 평점 (있을 경우)
                  if (rating != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: AppSizes.iconXs,
                          color: AppColors.warning500,
                        ),
                        SizedBox(width: 4),
                        Text(
                          rating!.toStringAsFixed(1),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (reviewCount != null) ...[
                          Text(
                            ' ($reviewCount)',
                            style: AppTextStyles.bodySmallSecondary,
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),
                  ],

                  // 가격
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: AppTextStyles.priceText,
                      ),
                      Text(
                        ' / $period',
                        style: AppTextStyles.bodySmallSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 이미지 섹션 (배지 및 좋아요 버튼 포함)
class _ImageSection extends StatelessWidget {
  const _ImageSection({
    required this.imageUrl,
    required this.badges,
    required this.isFavorite,
    this.onFavorite,
  });

  final String imageUrl;
  final List<String> badges;
  final bool isFavorite;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 이미지
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppRadius.lg),
              topRight: Radius.circular(AppRadius.lg),
            ),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.neutral100,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: AppSizes.iconXl,
                    color: AppColors.neutral400,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: AppColors.neutral100,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // 배지들
        if (badges.isNotEmpty)
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: badges
                  .map((badge) => _Badge(text: badge))
                  .toList(),
            ),
          ),

        // 좋아요 버튼
        Positioned(
          top: AppSpacing.sm,
          right: AppSpacing.sm,
          child: _FavoriteButton(
            isFavorite: isFavorite,
            onPressed: onFavorite,
          ),
        ),
      ],
    );
  }
}

/// 배지 위젯
class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  Color _getBadgeColor(String text) {
    switch (text) {
      case '신규':
      case '새 매물':
        return AppColors.badge;
      case '할인':
        return AppColors.discount;
      case '프리미엄':
        return AppColors.premium;
      case '인증':
        return AppColors.verified;
      default:
        return AppColors.primary500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _getBadgeColor(text),
        borderRadius: AppRadius.radiusSm,
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.neutral0,
        ),
      ),
    );
  }
}

/// 좋아요 버튼
class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.isFavorite,
    this.onPressed,
  });

  final bool isFavorite;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.neutral0.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? AppColors.error500 : AppColors.neutral700,
          size: AppSizes.iconSm,
        ),
      ),
    );
  }
}

/// 가로형 매물 리스트 아이템
class PropertyListItem extends StatelessWidget {
  const PropertyListItem({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.price,
    this.period = '주',
    this.rating,
    this.reviewCount,
    this.onTap,
  });

  final String imageUrl;
  final String title;
  final String location;
  final String price;
  final String period;
  final double? rating;
  final int? reviewCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Row(
          children: [
            // 썸네일
            ClipRRect(
              borderRadius: AppRadius.radiusMd,
              child: Image.network(
                imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: AppColors.neutral100,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.neutral400,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: AppSpacing.md),

            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    location,
                    style: AppTextStyles.bodySmallSecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      if (rating != null) ...[
                        Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.warning500,
                        ),
                        SizedBox(width: 2),
                        Text(
                          rating!.toStringAsFixed(1),
                          style: AppTextStyles.bodySmall,
                        ),
                        SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: Text(
                          '$price / $period',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
