import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// 방 등록 진행 상태 표시 컴포넌트
///
/// 현재 단계와 전체 단계를 시각적으로 표시
class RegistrationFlowIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepTitles;

  const RegistrationFlowIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitles,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 진행률 바
        Row(
          children: List.generate(totalSteps, (index) {
            final stepNumber = index + 1;
            final isActive = stepNumber <= currentStep;

            return Expanded(
              child: Row(
                children: [
                  // Step 구분선 (첫 번째 제외)
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: stepNumber <= currentStep
                            ? AppColors.primary600
                            : AppColors.gray200,
                      ),
                    ),

                  // Step 번호 원
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppColors.primary600 : Colors.white,
                      border: Border.all(
                        color: isActive ? AppColors.primary600 : AppColors.gray300,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$stepNumber',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  // 마지막 Step 이후 구분선 제거
                  if (index < totalSteps - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: stepNumber < currentStep
                            ? AppColors.primary600
                            : AppColors.gray200,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),

        const SizedBox(height: 12),

        // Step 제목 표시
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(totalSteps, (index) {
            final stepNumber = index + 1;
            final isCurrent = stepNumber == currentStep;
            final title = stepTitles[index];

            return Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrent ? AppColors.primary600 : AppColors.textSecondary,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
