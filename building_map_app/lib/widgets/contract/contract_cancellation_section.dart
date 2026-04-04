import 'package:flutter/material.dart';
import '../../constants/notice_texts.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/refund_policy.dart';

/// 계약 해지 조항 + 안내사항 섹션
class ContractCancellationSection extends StatelessWidget {
  final String refundPolicy;
  final RefundPolicy? refundPolicyData;
  final bool isLoadingPolicy;

  const ContractCancellationSection({
    super.key,
    required this.refundPolicy,
    required this.refundPolicyData,
    required this.isLoadingPolicy,
  });

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
          Text('환불 규정', style: AppTextStyles.headingSmall),
          const SizedBox(height: 16),

          // 로딩 중
          if (isLoadingPolicy)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          // API에서 로드한 환불 정책 표시
          else if (refundPolicyData != null) ...[
            ...refundPolicyData!.rules.map((rule) {
              return _buildBulletText(
                NoticeTexts.cancellationText(rule.period, rule.description, rule.refundRate),
              );
            }),
          ]
          // Fallback: 기본값 (API 실패 시)
          else ...[
            _buildBulletText('환불 정책을 불러오는데 실패했습니다.'),
            _buildBulletText('자세한 환불 규정은 호스트에게 문의해주세요.'),
          ],

          const SizedBox(height: 20),

          // 안내사항
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // blue-50
              border: Border.all(color: const Color(0xFFDBEAFE)), // blue-100
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '안내사항',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: const Color(0xFF1E40AF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildNoticeBulletText(NoticeTexts.sameDayCancelPenalty),
                _buildNoticeBulletText(NoticeTexts.alwaysRefundDefault),
                _buildNoticeBulletText(NoticeTexts.rentRefundByHost),
                _buildNoticeBulletText(NoticeTexts.hostCancelPenalty),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 불릿 텍스트 (회색)
  Widget _buildBulletText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[500],
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 불릿 텍스트 (파란색 - 안내사항용)
  Widget _buildNoticeBulletText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13,
                color: const Color(0xFF1E40AF),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
