import 'package:flutter/material.dart';

/// 방 등록 플로우 표시 위젯
class RegistrationFlowIndicator extends StatelessWidget {
  final int currentStep;

  const RegistrationFlowIndicator({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      '기본정보',
      '요금설정',
      '사진 및 편의시설',
      '무료 부가 서비스',
      '방소개',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      color: Colors.grey[50],
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isEven) {
                // 단계 표시
                final stepIndex = index ~/ 2;
                final isActive = stepIndex == currentStep;
                final isCompleted = stepIndex < currentStep;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      steps[stepIndex],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? const Color(0xFF4A90E2)
                            : isCompleted
                                ? const Color(0xFF2C3E50)
                                : Colors.grey[400],
                      ),
                    ),
                  ],
                );
              } else {
                // 화살표 표시
                final stepIndex = index ~/ 2;
                final isCompleted = stepIndex < currentStep;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: isCompleted ? const Color(0xFF2C3E50) : Colors.grey[400],
                  ),
                );
              }
            }),
          ),
        ),
      ),
    );
  }
}
