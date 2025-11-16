import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// 등록 진행 단계를 표시하는 인디케이터 (리액트 StepIndicator 복제)
class StepIndicator extends StatelessWidget {
  final List<String> steps;
  final int currentStepIndex;
  final String title;

  const StepIndicator({
    super.key,
    required this.steps,
    required this.currentStepIndex,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bars
              Row(
                children: List.generate(steps.length, (index) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index < steps.length - 1 ? 8 : 0,
                      ),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= currentStepIndex
                            ? AppColors.primary600
                            : AppColors.gray200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
