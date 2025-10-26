import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';

/// 앱 초기화 중 표시되는 스플래시 화면
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Icon(
                Icons.home_rounded,
                size: 64,
                color: AppColors.primary500,
              ),
            ),
            SizedBox(height: AppSpacing.xl),

            // 앱 이름
            Text(
              'EZStay',
              style: AppTextStyles.displayLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary500,
              ),
            ),
            SizedBox(height: AppSpacing.md),

            // 로딩 인디케이터
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
            ),
            SizedBox(height: AppSpacing.md),

            // 로딩 텍스트
            Text(
              '앱을 시작하는 중...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
