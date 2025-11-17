import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// 유효성 검증 에러 박스 (리액트 에러 UI 복제)
class ValidationErrorBox extends StatelessWidget {
  final List<String> errors;

  const ValidationErrorBox({
    super.key,
    required this.errors,
  });

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error50,
        border: Border.all(color: AppColors.error500),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error icon
          Icon(
            Icons.error_outline,
            size: 20,
            color: AppColors.error500,
          ),
          const SizedBox(width: 12),
          // Error messages
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '다음 항목을 확인해주세요:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error700,
                  ),
                ),
                const SizedBox(height: 8),
                ...errors.map(
                  (error) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $error',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.error700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
