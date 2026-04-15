import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/contract.dart';
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
        border: Border.all(color: AppColors.gray200),
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
                  Text(
                    '기본 정보',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  if (contract.orderId != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '계약번호: ',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.neutral600,
                          ),
                        ),
                        Text(
                          contract.orderId!,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue600,
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
    final isPaid = [
      ContractStatus.paymentCompleted,
      ContractStatus.inProgress,
      ContractStatus.completed,
    ].contains(ContractStatus.fromString(c.status));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              c.roomName,
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.gray900,
              ),
            ),
            _HostRoomInfoButton(contractId: c.id),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '주소 : ',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral700),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray900),
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
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral700),
                children: [
                  const TextSpan(text: '계약 기간: '),
                  TextSpan(
                    text: '${ContractUtils.formatDateString(c.checkInDate)} - ${ContractUtils.formatDateString(c.checkOutDate)} (${c.totalDays}일)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                  ),
                ],
              ),
            ),
            if (c.paidAt != null && isPaid) ...[
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral700),
                  children: [
                    const TextSpan(text: '계약 확정: '),
                    TextSpan(
                      text: ContractUtils.formatDateString(c.paidAt!),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
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

/// 방 정보 버튼 — 계약 당시 방 스냅샷 페이지로 이동 (호스트용)
class _HostRoomInfoButton extends StatelessWidget {
  final int contractId;

  const _HostRoomInfoButton({required this.contractId});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/host/contracts/$contractId/room-snapshot');
          });
        },
        borderRadius: BorderRadius.circular(20),
        hoverColor: AppColors.gray50,
        splashColor: AppColors.gray200,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray300),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '방 정보',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.gray600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
