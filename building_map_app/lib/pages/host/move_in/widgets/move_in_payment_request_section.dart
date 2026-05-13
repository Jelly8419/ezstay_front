import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/move_in/move_in.dart';
import 'move_in_status_chips.dart';

/// 상세 페이지 — B. 임차인 결제 요청 (입주용품/침구류 대여) 섹션 (이미지 ③ 본문 우)
///
/// 액션:
/// - NOT_SENT → "결제 요청 보내기"
/// - SENT     → "다시 보내기" + "링크 복사"
class MoveInPaymentRequestSection extends StatelessWidget {
  final MoveInCase moveInCase;
  final bool isMutating;
  final VoidCallback onSend;
  final VoidCallback onResend;
  final VoidCallback onCopyLink;

  /// 알림톡 미연동 운영 단계 — send/resend 응답에 `_note`가 포함됐을 때만 표시되는 배너 텍스트
  final String? devNote;

  const MoveInPaymentRequestSection({
    super.key,
    required this.moveInCase,
    required this.isMutating,
    required this.onSend,
    required this.onResend,
    required this.onCopyLink,
    this.devNote,
  });

  @override
  Widget build(BuildContext context) {
    final c = moveInCase;
    final paymentRequest = c.paymentRequest;
    final status = paymentRequest?.status ?? PaymentRequestStatus.notSent;
    final isSent = status == PaymentRequestStatus.sent;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '임차인 입주 서비스 요청',
                  style: AppTextStyles.headingSmall,
                ),
              ),
              PaymentRequestStatusChip(status: status),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _row('요청 상태', isSent ? '발송 완료' : '발송 전'),
          if (paymentRequest != null) ...[
            if (paymentRequest.lastResentAt != null)
              _row('마지막 재발송', _formatDateTime(paymentRequest.lastResentAt!))
            else if (paymentRequest.sentAt != null)
              _row('마지막 발송', _formatDateTime(paymentRequest.sentAt!)),
            if (paymentRequest.resendCount > 0)
              _row('재발송 횟수', '${paymentRequest.resendCount}회'),
          ],
          _row('요청 항목', '입주용품 세트 / 침구류 세트'),
          SizedBox(height: AppSpacing.sm),
          Text(
            '* 임차인이 결제를 완료하면, 배송 준비를 진행합니다.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (devNote != null && devNote!.isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),
            _DevNoteBanner(note: devNote!),
          ],
          SizedBox(height: AppSpacing.md),
          _buildActions(isSent),
        ],
      ),
    );
  }

  Widget _buildActions(bool isSent) {
    if (!isSent) {
      return Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          onPressed: isMutating ? null : onSend,
          child: const Text('결제 요청 보내기'),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: isMutating ? null : onCopyLink,
          child: const Text('결제 링크 복사'),
        ),
        SizedBox(width: AppSpacing.sm),
        FilledButton(
          onPressed: isMutating ? null : onResend,
          child: const Text('알림톡 보내기'),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  String _formatDateTime(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return DateFormat('yyyy.MM.dd HH:mm').format(d);
    } catch (_) {
      return iso;
    }
  }
}

/// 알림톡 미연동 운영 단계 — `_note` 응답이 있을 때 노출되는 배너
class _DevNoteBanner extends StatelessWidget {
  final String note;
  const _DevNoteBanner({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warning50,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.warning500.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_outlined, size: 18, color: AppColors.warning700),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '개발 모드 안내',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.warning700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  note,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
