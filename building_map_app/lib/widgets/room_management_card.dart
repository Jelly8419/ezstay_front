import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/room.dart';
import '../utils/contract_utils.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import 'room_status_badge.dart';
import 'room_action_dropdown.dart';

/// 방 관리 카드 위젯 (React PropertyCard 완벽 복제)
///
/// React UI 구조:
/// - 상태 배지 (카드 최상단 헤더, px-4 pt-3 pb-2)
/// - 가로 레이아웃: 이미지(왼쪽) + 정보(오른쪽)
/// - 이미지 크기: 모바일 96x96 (w-24 h-24), 데스크톱 144x128 (lg:w-36 lg:h-32)
/// - 비활성 상태 시 이미지 위 오버레이
/// - 관리 버튼: 정보 섹션 오른쪽 끝
class RoomManagementCard extends StatelessWidget {
  final Room room;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onSchedule;
  final VoidCallback? onTogglePublish;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  const RoomManagementCard({
    super.key,
    required this.room,
    this.onTap,
    this.onEdit,
    this.onSchedule,
    this.onTogglePublish,
    this.onDuplicate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1024;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12), // rounded-xl
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상태 라벨 헤더 (React: px-4 pt-3 pb-2)
          _buildStatusHeader(),

          // 가로 레이아웃: 이미지 + 정보
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지 (왼쪽)
              _buildImage(isMobile),

              // 정보 섹션 (오른쪽, flex-1)
              Expanded(
                child: _buildInfoSection(isMobile),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 상태 배지 헤더 (카드 최상단)
  /// React: px-4 pt-3 pb-2
  Widget _buildStatusHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), // px-4 pt-3 pb-2
      child: Row(
        children: [
          RoomStatusBadge(
            status: room.status,
            isActive: room.isActive,
          ),
          // 반려 사유 표시 (있는 경우)
          if (room.status == 'rejected' && room.rejectionReason != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '사유: ${room.rejectionReason}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 이미지 섹션 (비활성 오버레이 포함)
  /// React: 모바일 w-24 h-24 ml-3 mb-3, 데스크톱 lg:w-36 lg:h-32
  Widget _buildImage(bool isMobile) {
    final imageUrl = room.photos.isNotEmpty ? room.photos.first.url : null;
    final imageSize = isMobile ? 96.0 : 144.0; // w-24 = 96px, lg:w-36 = 144px
    final imageHeight = isMobile ? 96.0 : 128.0; // h-24 = 96px, lg:h-32 = 128px

    return Padding(
      padding: isMobile
          ? const EdgeInsets.only(left: 12, bottom: 12) // ml-3 mb-3
          : EdgeInsets.zero, // 데스크톱은 패딩 없음
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: isMobile
                ? BorderRadius.circular(AppRadius.sm) // rounded-lg
                : const BorderRadius.only(
                    bottomLeft: Radius.circular(12), // rounded-bl-xl
                  ),
            child: SizedBox(
              width: imageSize,
              height: imageHeight,
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: ContractUtils.getFullImageUrl(imageUrl),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _buildPlaceholder(),
                      errorWidget: (context, url, error) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),

          // 비활성 오버레이 (React: isActive === false일 때)
          if (!room.isActive)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6), // bg-black/60
                  borderRadius: isMobile
                      ? BorderRadius.circular(AppRadius.sm)
                      : const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                        ),
                ),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '비공개',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 정보 섹션
  /// React: px-3 pb-3 pt-0 lg:px-4 lg:pb-3
  Widget _buildInfoSection(bool isMobile) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 16, // px-3 lg:px-4
        0, // pt-0
        isMobile ? 12 : 16, // px-3 lg:px-4
        12, // pb-3
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 (React: text-[16px] lg:text-[17px])
          Text(
            room.roomName,
            style: AppTextStyles.headingMedium.copyWith(
              fontSize: isMobile ? 16 : 17,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // 주소 (React: text-[13px] lg:text-[14px])
          Text(
            room.address,
            style: AppTextStyles.bodyMediumSecondary.copyWith(
              fontSize: isMobile ? 13 : 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // 가격과 관리 버튼
          // React: flex-col lg:flex-row lg:items-center lg:justify-between
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPriceText(isMobile),
                    const SizedBox(height: 8),
                    RoomActionDropdown(
                      room: room,
                      onEdit: onEdit,
                      onSchedule: onSchedule,
                      onTogglePublish: onTogglePublish,
                      onDuplicate: onDuplicate,
                      onDelete: onDelete,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildPriceText(isMobile)),
                    const SizedBox(width: 12),
                    RoomActionDropdown(
                      room: room,
                      onEdit: onEdit,
                      onSchedule: onSchedule,
                      onTogglePublish: onTogglePublish,
                      onDuplicate: onDuplicate,
                      onDelete: onDelete,
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  /// 가격 텍스트
  /// React: text-[14px] lg:text-[15px]
  Widget _buildPriceText(bool isMobile) {
    if (room.dailyRent <= 0) {
      return Text(
        '가격 미정',
        style: AppTextStyles.bodyMediumSecondary.copyWith(
          fontSize: isMobile ? 14 : 15,
        ),
      );
    }

    final weeklyRent = room.weeklyRent;

    return RichText(
      text: TextSpan(
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: isMobile ? 14 : 15,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        children: [
          TextSpan(text: _formatPrice(weeklyRent)),
          TextSpan(
            text: ' / 1주',
            style: TextStyle(
              fontWeight: FontWeight.normal,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 이미지 Placeholder
  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.neutral100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 32,
            color: AppColors.neutral400,
          ),
          const SizedBox(height: 4),
          Text(
            '이미지 없음',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.neutral400,
            ),
          ),
        ],
      ),
    );
  }

  /// 가격 포맷팅 (1,000,000 → 100만)
  String _formatPrice(int price) {
    if (price >= 10000) {
      final man = price ~/ 10000;
      final remainder = price % 10000;
      if (remainder == 0) {
        return '$man만';
      } else {
        return '$man.${(remainder / 1000).toStringAsFixed(0)}만';
      }
    }
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }
}
