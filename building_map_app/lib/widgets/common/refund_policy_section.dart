import 'package:flutter/material.dart';
import '../../constants/notice_texts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 환불 규정 공통 섹션 위젯
///
/// 방 상세, 계약 시작, 게스트 계약 상세, 채팅 계약정보 모달에서 공통으로 사용.
///
/// [rules]는 각 규칙의 최소 필드만 담은 [RefundRuleItem] 리스트로 전달.
/// 호출부에서 RefundRule / RefundPolicyRule 등 모델에 무관하게 변환해서 넘긴다.
class RefundPolicySection extends StatelessWidget {
  final List<RefundRuleItem> rules;
  final bool isLoading;

  const RefundPolicySection({
    super.key,
    required this.rules,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('환불 규정', style: AppTextStyles.headingSmall),
        const SizedBox(height: 16),

        // 고정 안내 문구 (강조)
        Text(
          NoticeTexts.refundPolicyHeader,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 13,
            color: AppColors.blue600,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),

        // 로딩
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        // 규칙 목록 (isSameDayCancellation == true 제외)
        else if (rules.isNotEmpty) ...[
          ...rules
              .where((r) => !r.isSameDayCancellation)
              .map((r) => _buildBulletText(
                    NoticeTexts.cancellationRuleText(
                      daysBeforeMin: r.daysBeforeMin,
                      daysBeforeMax: r.daysBeforeMax,
                      description: r.description,
                    ),
                  )),
        ] else ...[
          _buildBulletText('환불 정책 정보를 불러올 수 없습니다.'),
        ],

        const SizedBox(height: 20),

        // 안내사항
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.blue50,
            border: Border.all(color: AppColors.blue100),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 18, color: AppColors.blue600),
                  const SizedBox(width: 8),
                  Text(
                    '안내사항',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.blue700,
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
    );
  }

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
              decoration: const BoxDecoration(
                color: AppColors.neutral500,
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
                color: AppColors.neutral600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                color: AppColors.blue600,
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
                color: AppColors.blue700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 환불 규칙 공통 데이터 클래스
/// RefundRule / RefundPolicyRule 모델에 무관하게 변환해서 사용
class RefundRuleItem {
  final int? daysBeforeMin;
  final int? daysBeforeMax;
  final int refundRate;
  final bool isSameDayCancellation;
  final String description;

  const RefundRuleItem({
    this.daysBeforeMin,
    this.daysBeforeMax,
    required this.refundRate,
    required this.isSameDayCancellation,
    required this.description,
  });
}
