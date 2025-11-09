import 'package:flutter/material.dart';
import '../models/user.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

/// 게스트/호스트 모드 선택 다이얼로그
/// 회원가입 시 사용자 모드를 선택하는 팝업
class ModeSelectionDialog extends StatelessWidget {
  const ModeSelectionDialog({super.key});

  /// 다이얼로그 표시
  static Future<UserMode?> show(BuildContext context) {
    return showDialog<UserMode>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ModeSelectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLg,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Row(
              children: [
                // 로고
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary100,
                    borderRadius: AppRadius.radiusSm,
                  ),
                  child: Icon(
                    Icons.home,
                    color: AppColors.primary600,
                    size: AppSizes.iconMd,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'EZStay',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.primary600,
                  ),
                ),
                const Spacer(),
                // 닫기 버튼
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  color: AppColors.neutral600,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xl),

            // 제목
            Text(
              '사용자 선택',
              style: AppTextStyles.headingLarge,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              '어떤 목적으로 서비스를 이용하시나요?',
              style: AppTextStyles.bodyMediumSecondary,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xxl),

            // 게스트/호스트 선택 카드
            Flexible(
              child: SingleChildScrollView(
                child: Row(
                  children: [
                    // 게스트 모드
                    Expanded(
                      child: _buildModeCard(
                        context: context,
                        mode: UserMode.guest,
                        title: '집을 찾고 있어요',
                        icon: Icons.search,
                        features: [
                          _Feature(
                            title: '빠른 계약',
                            description: '계약요청 > 승인 > 결제\n3단계로 간편하게',
                          ),
                          _Feature(
                            title: '안전한 거래',
                            description: 'EZStay가 모든 계약의\n안전성을 보장합니다',
                          ),
                        ],
                        buttonText: '집 둘러보기',
                      ),
                    ),
                    SizedBox(width: AppSpacing.lg),

                    // 호스트 모드
                    Expanded(
                      child: _buildModeCard(
                        context: context,
                        mode: UserMode.host,
                        title: '집을 내놓고 싶어요',
                        icon: Icons.home_work,
                        features: [
                          _Feature(
                            title: '빠른 공실 해소',
                            description: '등록 즉시 계약 가능\n공실 걱정 끝',
                          ),
                          _Feature(
                            title: '쉬운 임대관리',
                            description: '복잡한 절차 없이\n바로 계약',
                          ),
                        ],
                        buttonText: '집 내놓기',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required UserMode mode,
    required String title,
    required IconData icon,
    required List<_Feature> features,
    required String buttonText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.cardDefault,
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(mode),
        borderRadius: AppRadius.radiusMd,
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이콘
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary100,
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: AppColors.primary600,
                ),
              ),
              SizedBox(height: AppSpacing.lg),

              // 제목
              Text(
                title,
                style: AppTextStyles.headingSmall,
              ),
              SizedBox(height: AppSpacing.lg),

              // 특징 리스트
              ...features.map((feature) => Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: AppColors.primary600,
                            ),
                            SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                feature.title,
                                style: AppTextStyles.labelMedium,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Padding(
                          padding: EdgeInsets.only(left: AppSpacing.md),
                          child: Text(
                            feature.description,
                            style: AppTextStyles.bodySmallSecondary,
                          ),
                        ),
                      ],
                    ),
                  )),

              SizedBox(height: AppSpacing.lg),

              // 선택 버튼
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(mode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    foregroundColor: AppColors.neutral0,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusSm,
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.neutral0,
                    ),
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

/// 특징 데이터 클래스
class _Feature {
  final String title;
  final String description;

  _Feature({required this.title, required this.description});
}
