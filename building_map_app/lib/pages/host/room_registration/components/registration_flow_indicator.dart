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
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        return Stack(
          children: [
            // 배경 연결선 (전체)
            Positioned(
              top: 17,  // 원의 중앙 (36 / 2 - 1)
              left: 18,  // 첫 원의 중심
              right: 18,  // 마지막 원의 중심
              child: Container(
                height: 2,
                color: AppColors.gray200,
              ),
            ),

            // 진행된 연결선
            if (currentStep > 1)
              Positioned(
                top: 17,
                left: 18,
                width: (totalWidth - 36) * ((currentStep - 1) / (totalSteps - 1)),
                child: Container(
                  height: 2,
                  color: AppColors.primary600,
                ),
              ),

            // 원들과 텍스트
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(totalSteps, (index) {
                final stepNumber = index + 1;
                final isActive = stepNumber <= currentStep;
                final isCurrent = stepNumber == currentStep;
                final title = stepTitles[index];

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Step 번호 원
                    Container(
                      width: 36,
                      height: 36,
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

                    const SizedBox(height: 12),

                    // Step 제목
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                        color: isCurrent ? AppColors.primary600 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
