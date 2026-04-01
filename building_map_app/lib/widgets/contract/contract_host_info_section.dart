import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';

/// 계약 요청 페이지용 호스트 정보 섹션
class ContractHostInfoSection extends StatelessWidget {
  final String? hostName;

  const ContractHostInfoSection({super.key, required this.hostName});

  @override
  Widget build(BuildContext context) {
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
          Text('호스트', style: AppTextStyles.headingSmall),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 호스트 아바타 (React: w-12 h-12 = 48px)
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFDBEAFE), // blue-100
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 24,
                  color: Color(0xFF2563EB), // blue-600
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hostName ?? '호스트',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: const Color(0xFF111827),
                      ),
                    ),
                    // TODO: Room 모델에 hostIntroduction 추가 후 소개문 표시
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 호스트 연락처 안내
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // blue-50
              border: Border.all(color: const Color(0xFFDBEAFE)), // blue-100
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '호스트의 연락처는 계약이 확정된 후 공개됩니다.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFF1E40AF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
