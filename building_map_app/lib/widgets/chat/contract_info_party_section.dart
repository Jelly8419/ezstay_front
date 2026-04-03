import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/contract_detail.dart';
import '../../utils/contract_utils.dart';

/// 계약 정보 모달 — 호스트/게스트 당사자 정보 섹션
class ContractInfoPartySection extends StatelessWidget {
  final ContractDetail contract;
  final String userMode;

  const ContractInfoPartySection({
    super.key,
    required this.contract,
    required this.userMode,
  });

  bool get _isPaymentConfirmed =>
      ['PAYMENT_COMPLETED', 'IN_PROGRESS', 'COMPLETED'].contains(contract.status);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PartyCard(
            title: '호스트',
            name: contract.hostDisplayName,
            phone: _isPaymentConfirmed ? contract.hostPhoneNumber : null,
            profileImage: contract.hostProfileImage,
            iconColor: AppColors.blue600,
            iconBgColor: const Color(0xFFDBEAFE),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _GuestCard(
            contract: contract,
            userMode: userMode,
            isPaymentConfirmed: _isPaymentConfirmed,
          ),
        ),
      ],
    );
  }
}

class _PartyCard extends StatelessWidget {
  final String title;
  final String name;
  final String? phone;
  final String? profileImage;
  final Color iconColor;
  final Color iconBgColor;

  const _PartyCard({
    required this.title,
    required this.name,
    this.phone,
    this.profileImage,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.gray900)),
          const SizedBox(height: 12),
          Row(
            children: [
              if (profileImage != null && profileImage!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: CachedNetworkImage(
                    imageUrl: ContractUtils.getFullImageUrl(profileImage!),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) =>
                        _avatarPlaceholder(iconColor, iconBgColor),
                    errorWidget: (ctx, url, error) =>
                        _avatarPlaceholder(iconColor, iconBgColor),
                  ),
                )
              else
                _avatarPlaceholder(iconColor, iconBgColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gray900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (phone != null && phone!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(phone!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.gray600)),
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
}

class _GuestCard extends StatelessWidget {
  final ContractDetail contract;
  final String userMode;
  final bool isPaymentConfirmed;

  const _GuestCard({
    required this.contract,
    required this.userMode,
    required this.isPaymentConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    final showPhone = userMode == 'host'
        ? (isPaymentConfirmed ? contract.guestPhone : '결제 완료 후 확인 가능')
        : contract.guestPhone;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('게스트',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.gray900)),
          const SizedBox(height: 12),
          Row(
            children: [
              _avatarPlaceholder(AppColors.green600, const Color(0xFFD1FAE5)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contract.guestDisplayName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gray900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(showPhone,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.gray600)),
                  ],
                ),
              ),
            ],
          ),

          if (userMode == 'host' &&
              contract.guestMessage != null &&
              contract.guestMessage!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neutral0,
                border: Border.all(color: AppColors.gray200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.message, size: 16, color: AppColors.gray600),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '게스트 메시지',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.neutral700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contract.guestMessage!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.neutral800),
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
    );
  }
}

Widget _avatarPlaceholder(Color iconColor, Color bgColor) {
  return Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(9999),
    ),
    child: Icon(Icons.person, size: 24, color: iconColor),
  );
}
