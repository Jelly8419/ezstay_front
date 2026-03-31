import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/contract_detail.dart';
import '../../utils/contract_utils.dart';
import '../../utils/responsive_util.dart';
import '../contract/contract_common_widgets.dart';
import '../contract/contract_status_badge.dart';

/// 호스트 계약 기본 정보 섹션
///
/// 방 이미지 + 계약번호 + 상태 배지 + 방 정보(주소/기간/확정일) — 반응형 레이아웃
class HostContractBasicInfoSection extends StatelessWidget {
  final ContractDetail contract;

  const HostContractBasicInfoSection({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: ContractDetailCard.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '기본 정보',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  if (contract.orderId != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          '계약번호: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        Text(
                          contract.orderId!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              ContractStatusBadge(status: contract.status, showIcon: false),
            ],
          ),
          const SizedBox(height: 16),

          if (isMobile) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: AppRadius.radiusSm,
                  child: _buildRoomImage(
                    contract.roomPhoto,
                    width: double.infinity,
                    height: 192,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRoomInfo(contract),
              ],
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: AppRadius.radiusSm,
                  child: _buildRoomImage(
                    contract.roomPhoto,
                    width: 128,
                    height: 128,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildRoomInfo(contract)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoomImage(String roomPhoto, {required double width, required double height}) {
    if (roomPhoto.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: ContractUtils.getFullImageUrl(roomPhoto),
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: AppColors.neutral50,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: AppColors.neutral50,
          child: Icon(Icons.image_not_supported, color: AppColors.textDisabled),
        ),
      );
    }
    return Container(
      width: width,
      height: height,
      color: AppColors.neutral50,
      child: Icon(Icons.home, size: 40, color: AppColors.textDisabled),
    );
  }

  Widget _buildRoomInfo(ContractDetail c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          c.roomName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '주소 : ',
                  style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF000000),
                      ),
                      children: [
                        TextSpan(text: c.address),
                        const TextSpan(text: ' '),
                        TextSpan(text: c.detailAddress),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
                children: [
                  const TextSpan(text: '계약 기간: '),
                  TextSpan(
                    text:
                        '${ContractUtils.formatDateString(c.checkInDate)} - ${ContractUtils.formatDateString(c.checkOutDate)} (${c.totalDays}일)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            if (c.paidAt != null &&
                ['PAYMENT_COMPLETED', 'IN_PROGRESS', 'COMPLETED']
                    .contains(c.status)) ...[
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
                  children: [
                    const TextSpan(text: '계약 확정: '),
                    TextSpan(
                      text: ContractUtils.formatDateString(c.paidAt!),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
