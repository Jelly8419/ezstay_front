import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 날짜 겹침 (4300 CONFLICT_WITH_CONTRACT) 안내 다이얼로그
///
/// 결과:
/// - `null` / `false` → 닫기 (날짜 수정 후 재시도)
/// - `true` → "기존 등록 보기" 클릭 → 호출자가 해당 caseId 상세로 이동
Future<bool?> showMoveInConflictDialog(
  BuildContext context, {
  required String message,
  required int? existingCaseId,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      icon: Icon(Icons.event_busy_outlined, color: AppColors.warning700, size: 32),
      title: const Text('날짜가 겹치는 등록이 있습니다'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: AppTextStyles.bodyMedium,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            '입주일/퇴실일을 수정한 뒤 다시 시도하거나, 기존 등록을 확인해주세요.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        TextButton(
          // dialogCtx 를 써야 GoRouter 하위 Navigator 에서도 정확히
          // 다이얼로그 라우트만 pop. 외부 context 는 root navigator 를 가리켜
          // 닫기가 동작하지 않을 수 있음.
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: const Text('닫기'),
        ),
        if (existingCaseId != null)
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('기존 등록 보기'),
          ),
      ],
    ),
  );
}

/// 응답 메시지에서 caseId 추출 — "(case #N)" 또는 details.caseId
int? parseConflictCaseId({String? message, dynamic details}) {
  if (details is Map && details['caseId'] is num) {
    return (details['caseId'] as num).toInt();
  }
  if (message != null) {
    final match = RegExp(r'#(\d+)').firstMatch(message);
    if (match != null) return int.tryParse(match.group(1) ?? '');
  }
  return null;
}
