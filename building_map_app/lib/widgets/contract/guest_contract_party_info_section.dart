import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/contract_detail.dart';
import '../../utils/contract_utils.dart';
import '../../utils/responsive_util.dart';

/// 게스트 계약 상세 — 호스트/게스트 정보 섹션
class GuestContractPartyInfoSection extends StatelessWidget {
  final ContractDetail contract;

  const GuestContractPartyInfoSection({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          _buildHostCard(contract),
          const SizedBox(height: 24),
          _buildGuestCard(contract),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildHostCard(contract)),
          const SizedBox(width: 24),
          Expanded(child: _buildGuestCard(contract)),
        ],
      );
    }
  }

  Widget _buildHostCard(ContractDetail contract) {
    final showPhone = ContractUtils.shouldShowPhoneNumber(contract.status);

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
          Text(
            '호스트',
            style: AppTextStyles.headingMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gray50,
                ),
                clipBehavior: Clip.antiAlias,
                child: contract.hostProfileImage != null
                    ? CachedNetworkImage(
                        imageUrl: ContractUtils.getFullImageUrl(
                            contract.hostProfileImage),
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.person, size: 28),
                      )
                    : Icon(Icons.person, size: 28, color: AppColors.gray600),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contract.hostDisplayName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                    if (showPhone && contract.hostPhoneNumber != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        contract.hostPhoneNumber!,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 14,
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCard(ContractDetail contract) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '게스트',
                style: AppTextStyles.headingMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
              ),
              if (contract.isEzCleaning)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cleaning_services,
                        size: 14,
                        color: AppColors.green600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'EZ청소',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.green600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    contract.guestDisplayName.isNotEmpty
                        ? contract.guestDisplayName.substring(0, 1)
                        : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contract.guestDisplayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contract.guestPhone,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
