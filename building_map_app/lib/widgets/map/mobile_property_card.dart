import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../utils/contract_utils.dart';
import '../../utils/format_utils.dart';

/// 모바일 지도 하단 슬라이드 카드 위젯
class MobilePropertyCard extends StatelessWidget {
  final Map<String, dynamic> roomData;
  final void Function(int roomId) onSaveMapState;

  const MobilePropertyCard({
    super.key,
    required this.roomData,
    required this.onSaveMapState,
  });

  @override
  Widget build(BuildContext context) {
    // photos 배열 파싱 (백엔드가 [{url, order}] 형식으로 제공, 상대경로)
    final photosData = roomData['photos'] as List<dynamic>?;
    String? firstPhotoUrl;
    if (photosData != null && photosData.isNotEmpty) {
      final relativeUrl = photosData[0]['url'] as String?;
      final fullUrl = ContractUtils.getFullImageUrl(relativeUrl);
      firstPhotoUrl = fullUrl.isNotEmpty ? fullUrl : null;
    }

    final dailyRent = roomData['dailyRent'] ?? 0;
    final roomName = roomData['roomName'] ?? '';
    final address = roomData['address'] ?? '';
    final roomId = roomData['id'] ?? 0;
    final isAvailable = roomData['isAvailable'] as bool? ?? true;

    // 할인 정보 파싱 (데스크톱과 동일)
    final discounts = roomData['discounts'] as Map<String, dynamic>?;
    final quickMoveInDays = discounts?['quickMoveInDays'] as int?;
    final quickMoveInDiscount = discounts?['quickMoveInDiscount'] as int?;
    final longTermWeeks = discounts?['longTermWeeks'] as int?;
    final longTermDiscount = discounts?['longTermDiscount'] as int?;

    // 할인 여부 확인 (non-null 로컬 변수로 promote)
    final int qDays = quickMoveInDays ?? 0;
    final int qDiscount = quickMoveInDiscount ?? 0;
    final int ltWeeks = longTermWeeks ?? 0;
    final int ltDiscount = longTermDiscount ?? 0;
    final hasQuickMoveIn = qDays > 0 && qDiscount > 0;
    final hasLongTerm = ltWeeks > 0 && ltDiscount > 0;

    return GestureDetector(
      onTap: () {
        onSaveMapState(roomId);
        context.go('/guest/room/detail/$roomId');
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 210, // 고정 너비 (4분의 1 축소)
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isAvailable ? AppColors.surface : AppColors.neutral100,
          borderRadius: BorderRadius.circular(16), // rounded-2xl
          border: isAvailable
              ? null
              : Border.all(color: AppColors.neutral300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ], // shadow-xl
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Column 크기를 내용물에 맞춤
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 이미지 (180px 고정 높이)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: firstPhotoUrl != null && firstPhotoUrl.isNotEmpty
                  ? Image.network(
                      firstPhotoUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: double.infinity,
                          height: 180,
                          color: AppColors.neutral200,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.neutral400,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 180,
                          color: AppColors.neutral200,
                          child: Icon(
                            Icons.home,
                            size: 48,
                            color: AppColors.neutral400,
                          ),
                        );
                      },
                    )
                  : Container(
                      width: double.infinity,
                      height: 180,
                      color: AppColors.neutral200,
                      child: Icon(
                        Icons.home,
                        size: 48,
                        color: AppColors.neutral400,
                      ),
                    ),
            ),

            // 하단: 방 정보 (p-4 = 16px, bottom padding 최소화)
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 10, // bottom padding 최소화
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Column 크기를 내용물에 맞춤
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 방 이름 (font-bold, text-gray-900, mb-1)
                  Text(
                    roomName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isAvailable
                          ? const Color(0xFF111827)
                          : AppColors.neutral400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4), // mb-1
                  // 주소 (text-xs, text-gray-600, mb-2)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: isAvailable
                            ? const Color(0xFF4B5563)
                            : AppColors.neutral400,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            fontSize: 12,
                            color: isAvailable
                                ? const Color(0xFF4B5563)
                                : AppColors.neutral400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), // mb-2
                  // 예약 불가 배지
                  if (!isAvailable) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neutral200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '예약 불가',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.neutral500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  // 가격 (font-bold, 비가용 시 회색)
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isAvailable ? Colors.black : AppColors.neutral400,
                        height: 1.2,
                      ),
                      children: [
                        TextSpan(
                          text: FormatUtils.formatManWon(dailyRent * 7),
                        ),
                        const TextSpan(
                          text: ' / 주',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 할인 정보가 있을 때만 여백 추가 (간격 줄임)
                  if (hasQuickMoveIn || hasLongTerm) const SizedBox(height: 4),

                  // 할인 정보 (text-xs, text-blue-600, font-semibold)
                  if (hasQuickMoveIn) ...[
                    Text(
                      '• $qDays일 이내 ${FormatUtils.formatManWon(qDiscount)} 할인',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2563EB), // text-blue-600
                        fontWeight: FontWeight.w600,
                        height: 1.3, // line height 줄임
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],
                  if (hasLongTerm) ...[
                    Text(
                      '• $ltWeeks주 이상 $ltDiscount% 할인',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2563EB), // text-blue-600
                        fontWeight: FontWeight.w600,
                        height: 1.3, // line height 줄임
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
