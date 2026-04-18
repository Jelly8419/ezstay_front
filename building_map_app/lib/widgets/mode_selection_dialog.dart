import 'package:flutter/material.dart';
import '../models/user.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

/// 게스트/호스트 모드 선택
/// - 모바일(width < 600): 바텀시트
/// - 웹/태블릿: 기존 다이얼로그
class ModeSelectionBottomSheet extends StatelessWidget {
  const ModeSelectionBottomSheet({super.key});

  /// 환경에 따라 바텀시트(모바일) 또는 다이얼로그(웹/태블릿) 표시
  static Future<UserMode?> show(BuildContext context) {
    if (AppBreakpoints.isMobile(context)) {
      return showModalBottomSheet<UserMode>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black54,
        builder: (context) => const ModeSelectionBottomSheet(),
      );
    } else {
      return showDialog<UserMode>(
        context: context,
        barrierDismissible: true,
        builder: (context) => const _ModeSelectionDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 드래그 핸들
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 28),

              // 제목
              Text(
                '어떤 목적으로\n서비스를 이용하시나요?',
                style: AppTextStyles.headingLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // 임차인 버튼
              _ModeButton(
                label: '집을 빌리고 싶어요',
                mode: UserMode.guest,
              ),
              const SizedBox(height: 16),

              // 임대인 버튼
              _ModeButton(
                label: '집을 내놓고 싶어요',
                mode: UserMode.host,
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

/// 웹/태블릿용 기존 다이얼로그 (변경 없음)
class _ModeSelectionDialog extends StatelessWidget {
  const _ModeSelectionDialog();

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
                Image.asset(
                  'assets/logos/ezstay_logo_gnb_v2.png',
                  width: 36,
                  height: 36,
                  filterQuality: FilterQuality.high,
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'EZStay',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.primary600,
                  ),
                ),
                const Spacer(),
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
                    Expanded(
                      child: _buildModeCard(
                        context: context,
                        mode: UserMode.guest,
                        title: '임차인',
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
                    Expanded(
                      child: _buildModeCard(
                        context: context,
                        mode: UserMode.host,
                        title: '임대인',
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary100,
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Icon(icon, size: 28, color: AppColors.primary600),
              ),
              SizedBox(height: AppSpacing.lg),
              Text(title, style: AppTextStyles.headingSmall),
              SizedBox(height: AppSpacing.lg),
              ...features.map((feature) => Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 16, color: AppColors.primary600),
                            SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(feature.title,
                                  style: AppTextStyles.labelMedium),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Padding(
                          padding: EdgeInsets.only(left: AppSpacing.md),
                          child: Text(feature.description,
                              style: AppTextStyles.bodySmallSecondary),
                        ),
                      ],
                    ),
                  )),
              SizedBox(height: AppSpacing.lg),
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

class _Feature {
  final String title;
  final String description;

  _Feature({required this.title, required this.description});
}

class _ModeButton extends StatelessWidget {
  final String label;
  final UserMode mode;

  const _ModeButton({required this.label, required this.mode});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).pop(mode),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.neutral300, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.radiusMd,
          ),
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.neutral0,
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
