import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/contract_detail.dart';
import '../../utils/contract_utils.dart';
import '../../utils/format_utils.dart';
import 'contract_status_badge.dart';

/// 게스트 계약 상세 — 기본 정보 섹션
/// (방 사진, 방 이름, 주소, 계약 기간, 결제 금액, 상태 배지)
class GuestContractBasicInfoSection extends StatelessWidget {
  final ContractDetail contract;

  const GuestContractBasicInfoSection({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 제목 + 계약번호 (왼쪽), 상태 배지 (오른쪽)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '기본 정보',
                      style: AppTextStyles.headingMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    if (contract.orderId != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '계약번호: ',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 14,
                              color: AppColors.gray600,
                            ),
                          ),
                          Text(
                            contract.orderId!,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blue600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              ContractStatusBadge(status: contract.status),
            ],
          ),

          const SizedBox(height: 16),

          // 방 사진 + 정보 (가로 배치)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 방 사진 (128x128)
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.gray50,
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: ContractUtils.getFullImageUrl(contract.roomPhoto),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.gray50,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.gray50,
                    child: Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: AppColors.gray600,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          contract.roomName,
                          style: AppTextStyles.headingMedium.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        _RoomInfoButton(contractId: contract.id),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 주소
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            '주소',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 16,
                              color: AppColors.gray600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ContractUtils.getAddressDisplay(contract),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 16,
                                  color: AppColors.gray900,
                                ),
                              ),
                              if (ContractUtils.shouldShowAddressNotice(contract.status))
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '결제 완료 후 상세주소가 공개됩니다',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 12,
                                      color: AppColors.gray600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 계약 기간
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            '계약 기간',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 16,
                              color: AppColors.gray600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${ContractUtils.formatDateString(contract.checkInDate)} ~ ${ContractUtils.formatDateString(contract.checkOutDate)} (${contract.totalDays}일)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 16,
                              color: AppColors.gray900,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 결제 금액
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            '결제 금액',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 16,
                              color: AppColors.gray600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${FormatUtils.formatCurrency(contract.finalTotalAmount)}원',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 16,
                              color: AppColors.gray900,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 방 정보 버튼 — 계약 당시 방 스냅샷 페이지로 이동
class _RoomInfoButton extends StatelessWidget {
  final int contractId;

  const _RoomInfoButton({required this.contractId});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/guest/contracts/$contractId/room-snapshot');
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
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              color: AppColors.gray600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
