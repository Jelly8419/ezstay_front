import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/contract_detail.dart';
import '../../utils/contract_utils.dart';
import '../../core/theme/app_text_styles.dart';
import '../../utils/responsive_util.dart';
import '../contract/contract_common_widgets.dart';

/// 이름(닉네임) 형태 포맷 — 닉네임 없으면 이름만
String _formatName(String name, String? nickname) {
  if (nickname == null || nickname.isEmpty) return name;
  return '$name($nickname)';
}

/// 호스트/게스트 당사자 정보 섹션 (반응형)
class HostContractPartyInfoSection extends StatelessWidget {
  final ContractDetail contract;

  const HostContractPartyInfoSection({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          _buildHostCard(contract),
          const SizedBox(height: 16),
          _buildGuestCard(contract),
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildHostCard(contract)),
          const SizedBox(width: 16),
          Expanded(child: _buildGuestCard(contract)),
        ],
      ),
    );
  }

  Widget _buildHostCard(ContractDetail c) {
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
          Text(
            '임대인 정보',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.blue100,
                      shape: BoxShape.circle,
                    ),
                    child: c.hostProfileImage != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: ContractUtils.getFullImageUrl(c.hostProfileImage!),
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.person, color: AppColors.blue600),
                            ),
                          )
                        : Icon(Icons.person, color: AppColors.blue600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '이름',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral600),
                        ),
                        Text(
                          _formatName(c.hostName, c.hostNickname),
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '연락처',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral600),
                    ),
                    if (c.hostPhoneNumber != null)
                      Text(
                        c.hostPhoneNumber!,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
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

  Widget _buildGuestCard(ContractDetail c) {
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
          Text(
            '임차인 정보',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.green100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person, color: AppColors.green600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '이름',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral600),
                        ),
                        Text(
                          _formatName(c.guestName, c.guestNickname),
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '연락처',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral600),
                    ),
                    Text(
                      ContractUtils.shouldShowPhoneNumber(c.status)
                          ? c.guestPhone
                          : '결제 완료 후 확인 가능',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                  ],
                ),
              ),
              if (c.guestMessage != null && c.guestMessage!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: AppRadius.radiusSm,
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.message_outlined, size: 16, color: AppColors.neutral600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '임차인 메시지',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.neutral700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c.guestMessage!,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.gray900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
