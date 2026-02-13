import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/common/responsive_page_layout.dart';

/// 계정 정지 안내 페이지 (Phase 4)
///
/// 정책: 정지 상태 사용자는 주요 기능 차단, 정지 사유 표시
class AccountSuspendedPage extends StatelessWidget {
  final String? reason;

  const AccountSuspendedPage({super.key, this.reason});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: '계정 안내',
      body: Center(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 아이콘
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.error500.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.block,
                  size: 40,
                  color: AppColors.error500,
                ),
              ),
              const SizedBox(height: 24),

              // 제목
              Text(
                '계정이 일시 정지되었습니다',
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.gray900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // 사유
              if (reason != null && reason!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '정지 사유',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF991B1B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reason!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 안내 텍스트
              Text(
                '이용 약관 위반으로 계정이 정지되었습니다.\n문의사항이 있으시면 고객센터로 연락해주세요.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // 고객센터 문의 버튼
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // 고객센터 문의 (향후 연동)
                  },
                  icon: const Icon(Icons.headset_mic),
                  label: const Text('고객센터 문의'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusMd,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 로그아웃 버튼
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  },
                  child: Text(
                    '로그아웃',
                    style: TextStyle(color: AppColors.gray600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
