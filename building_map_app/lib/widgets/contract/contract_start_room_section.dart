import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/calculated_pricing.dart';
import '../../models/room.dart';
import '../../utils/contract_utils.dart';
import '../../utils/format_utils.dart';

/// 계약 요청 페이지용 방 정보 섹션 (이미지 + 기본 정보)
/// Room 모델 기반 (ContractRoomInfoSection과 별개)
class ContractStartRoomSection extends StatelessWidget {
  final Room room;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final CalculatedPricing calculatedPricing;
  final bool isWideScreen;

  const ContractStartRoomSection({
    super.key,
    required this.room,
    required this.checkInDate,
    required this.checkOutDate,
    required this.calculatedPricing,
    required this.isWideScreen,
  });

  bool get _hasValidDates => checkInDate != null && checkOutDate != null;

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = room.photos.isNotEmpty
        ? ContractUtils.getFullImageUrl(room.photos.first.url)
        : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('기본 정보', style: AppTextStyles.headingSmall),
          const SizedBox(height: 16),
          if (isWideScreen)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: _buildRoomImageContent(thumbnailUrl),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildRoomDetails()),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoomImage(thumbnailUrl, 192),
                const SizedBox(height: 16),
                _buildRoomDetails(),
              ],
            ),
        ],
      ),
    );
  }

  /// 방 이미지 (모바일용 - width: infinity)
  Widget _buildRoomImage(String? thumbnailUrl, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: _buildRoomImageContent(thumbnailUrl),
      ),
    );
  }

  /// 방 이미지 컨텐츠 (공통)
  Widget _buildRoomImageContent(String? thumbnailUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: thumbnailUrl != null
          ? CachedNetworkImage(
              imageUrl: thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.home, color: Colors.grey),
              ),
            )
          : Container(
              color: Colors.grey[200],
              child: const Icon(Icons.home, color: Colors.grey),
            ),
    );
  }

  /// 방 상세 정보 (이름, 주소, 계약기간)
  Widget _buildRoomDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          room.roomName,
          style: AppTextStyles.headingMedium.copyWith(
            color: const Color(0xFF111827),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                '주소',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${room.address}, ${room.floor}층',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF111827),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                '계약 기간',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
            Expanded(
              child: _hasValidDates
                  ? RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFF111827),
                        ),
                        children: [
                          TextSpan(
                            text:
                                '${FormatUtils.formatDateWithDay(checkInDate!)} - ${FormatUtils.formatDateWithDay(checkOutDate!)} ',
                          ),
                          TextSpan(
                            text: '(${calculatedPricing.totalDays}일)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      '날짜가 선택되지 않았습니다',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
