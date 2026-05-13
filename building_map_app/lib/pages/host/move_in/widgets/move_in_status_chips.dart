import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/move_in/move_in.dart';

/// 청소 상태 칩 — 이미지의 결제 대기/완료/신청 안 함 칩
class CleaningStatusChip extends StatelessWidget {
  final CleaningStatus status;
  const CleaningStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(status);
    return _Chip(label: status.label, background: bg, foreground: fg);
  }

  static (Color, Color) _colors(CleaningStatus status) {
    switch (status) {
      case CleaningStatus.notRequested:
        return (AppColors.neutral100, AppColors.textSecondary);
      case CleaningStatus.paymentPending:
        return (AppColors.warning50, AppColors.warning700);
      case CleaningStatus.paid:
        return (AppColors.success50, AppColors.success700);
      case CleaningStatus.cancelled:
        return (AppColors.neutral100, AppColors.textSecondary);
    }
  }
}

/// 임차인 결제 요청 상태 칩
class PaymentRequestStatusChip extends StatelessWidget {
  final PaymentRequestStatus status;
  const PaymentRequestStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(status);
    final label = status == PaymentRequestStatus.notSent ? '요청 대기' : '알림톡 발송 완료';
    return _Chip(label: label, background: bg, foreground: fg);
  }

  static (Color, Color) _colors(PaymentRequestStatus status) {
    switch (status) {
      case PaymentRequestStatus.notSent:
        return (AppColors.warning50, AppColors.warning700);
      case PaymentRequestStatus.sent:
        return (AppColors.success50, AppColors.success700);
    }
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
