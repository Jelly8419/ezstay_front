import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/contract_detail.dart';
import '../../utils/contract_utils.dart';
import '../../utils/responsive_util.dart';
import '../contract/contract_common_widgets.dart';

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
}

Widget _buildHostCard(ContractDetail c) {
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
        const Text(
          '호스트 정보',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
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
                  decoration: const BoxDecoration(
                    color: Color(0xFFDBEAFE),
                    shape: BoxShape.circle,
                  ),
                  child: c.hostProfileImage != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl:
                                ContractUtils.getFullImageUrl(c.hostProfileImage!),
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Icon(
                                Icons.person,
                                color: Color(0xFF2563EB)),
                          ),
                        )
                      : const Icon(Icons.person, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '이름',
                        style: TextStyle(
                            fontSize: 14, color: Color(0xFF4B5563)),
                      ),
                      Text(
                        c.hostName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
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
                  const Text(
                    '연락처',
                    style: TextStyle(
                        fontSize: 14, color: Color(0xFF4B5563)),
                  ),
                  if (c.hostPhoneNumber != null)
                    Text(
                      c.hostPhoneNumber!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
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
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: ContractDetailCard.cardShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '게스트 정보',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
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
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Color(0xFF16A34A)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '이름',
                        style: TextStyle(
                            fontSize: 14, color: Color(0xFF4B5563)),
                      ),
                      Text(
                        c.guestName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
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
                  const Text(
                    '연락처',
                    style: TextStyle(
                        fontSize: 14, color: Color(0xFF4B5563)),
                  ),
                  Text(
                    ContractUtils.shouldShowPhoneNumber(c.status)
                        ? c.guestPhone
                        : '결제 완료 후 확인 가능',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
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
                  color: const Color(0xFFF9FAFB),
                  borderRadius: AppRadius.radiusSm,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.message_outlined,
                        size: 16, color: Color(0xFF4B5563)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '게스트 메시지',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.guestMessage!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1F2937),
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
