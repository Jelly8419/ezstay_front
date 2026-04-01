import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../utils/format_utils.dart';

/// 계약 요청 페이지에서 사용하는 다이얼로그 모음
class ContractStartDialogs {
  /// 계약 요청 확인 다이얼로그
  static Future<void> showRequestDialog(
    BuildContext context, {
    required int finalTotalAmount,
    required VoidCallback onConfirm,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('계약 승인 요청'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('계약 승인을 요청하시겠습니까?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '최종 결제 금액',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${FormatUtils.formatCurrency(finalTotalAmount)}원',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.primary600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '호스트가 승인하면 결제가 진행됩니다.',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('취소', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('확인', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 계약 요청 성공 안내 다이얼로그
  static Future<void> showSuccessMessage(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('요청 완료'),
          ],
        ),
        content: const Text('계약 요청이 완료되었습니다.\n호스트가 승인하면 결제를 진행할 수 있습니다.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go('/guest');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('확인', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 계약 요청 실패 안내 다이얼로그
  static Future<void> showErrorMessage(
    BuildContext context,
    String errorMessage,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('요청 실패'),
          ],
        ),
        content: Text(errorMessage),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('확인', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 옵션 선택 기한 만료 안내 다이얼로그 (세션 방어)
  /// 반환값: true면 옵션 제외 후 계속 진행, false면 취소
  static Future<bool> showOptionDeadlineExpiredDialog(
    BuildContext context, {
    required DateTime? checkInDate,
  }) async {
    final checkInDay = checkInDate != null
        ? DateTime(checkInDate.year, checkInDate.month, checkInDate.day)
        : null;
    final deadline = checkInDay?.subtract(const Duration(days: 6));
    final deadlineStr = deadline != null
        ? '${deadline.month}/${deadline.day}'
        : '';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.schedule, color: AppColors.warning500, size: 24),
            const SizedBox(width: 8),
            const Text('옵션 선택 기한 만료'),
          ],
        ),
        content: Text(
          '옵션 상품 선택 가능 기한이 지났습니다.\n'
          '($deadlineStr 23:59까지 선택 가능)\n\n'
          '선택하신 옵션 상품을 제외하고 계약 요청을 진행할까요?\n'
          '옵션 상품은 계약 승인 후에도 기한 내 추가할 수 있습니다.',
          style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '옵션 제외 후 진행',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
