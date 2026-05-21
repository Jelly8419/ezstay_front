import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/move_in/move_in.dart';
import 'move_in_status_chips.dart';

/// 상세 페이지 — A. 청소 서비스 섹션 (이미지 ③ 본문 좌)
///
/// 상태별 액션 분기:
/// - NOT_REQUESTED → "청소 신청하기"
/// - PAYMENT_PENDING → "PG 결제하기" + "청소 신청 취소"
/// - PAID → 결제 정보 표시 (액션 없음)
/// - CANCELLED → "청소 신청하기" 재활성화
class MoveInCleaningSection extends StatelessWidget {
  final MoveInCase moveInCase;
  final bool isMutating;
  final VoidCallback onRequest;
  final VoidCallback onPay;
  final VoidCallback onCancel;
  final VoidCallback onRefund;

  const MoveInCleaningSection({
    super.key,
    required this.moveInCase,
    required this.isMutating,
    required this.onRequest,
    required this.onPay,
    required this.onCancel,
    required this.onRefund,
  });

  @override
  Widget build(BuildContext context) {
    final c = moveInCase;
    final cleaningSuppliesAvailable = c.roomSnapshot.cleaningSuppliesAvailable;

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
                child: Text('청소 서비스', style: AppTextStyles.headingSmall),
              ),
              CleaningStatusChip(status: c.cleaningStatus),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          if (!cleaningSuppliesAvailable)
            _suppliesUnavailableNotice()
          else
            _buildContent(c),
          if (cleaningSuppliesAvailable) ...[
            SizedBox(height: AppSpacing.md),
            _buildActions(c),
          ],
        ],
      ),
    );
  }

  Widget _suppliesUnavailableNotice() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warning50,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        '이 방은 청소용품이 미구비되어 있어 청소 서비스를 신청할 수 없습니다.\n'
        '"정보 수정"에서 방 정보의 청소용품 구비 여부를 변경한 뒤 다시 시도해주세요.',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning700),
      ),
    );
  }

  Widget _buildContent(MoveInCase c) {
    switch (c.cleaningStatus) {
      case CleaningStatus.notRequested:
        return Text(
          '청소 서비스를 신청하지 않은 상태입니다.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        );
      case CleaningStatus.cancelled:
        return Text(
          '청소 신청이 취소되었습니다. 필요 시 다시 신청할 수 있습니다.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        );
      case CleaningStatus.paymentPending:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('신청 상태', '신청 완료'),
            if (c.cleaningDate != null)
              _row('청소 희망 일시', _formatCleaningDateTime(c)),
            _row('청소용품 구비', _suppliesText(c.roomSnapshot)),
            _row('청소 금액', _money(c.cleaningFee)),
            SizedBox(height: AppSpacing.sm),
            Text(
              '결제를 진행하면 청소 일정이 예약됩니다.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            _refundPolicyNotice(),
          ],
        );
      case CleaningStatus.paid:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('신청 상태', '결제 완료'),
            if (c.cleaningDate != null)
              _row('청소 희망 일시', _formatCleaningDateTime(c)),
            _row('청소용품 구비', _suppliesText(c.roomSnapshot)),
            _row('결제 일시', _formatDateTime(c.cleaningPaidAt)),
            _row('결제 금액', _money(c.cleaningFee)),
          ],
        );
    }
  }

  Widget _buildActions(MoveInCase c) {
    if (!c.roomSnapshot.cleaningSuppliesAvailable) return const SizedBox.shrink();

    switch (c.cleaningStatus) {
      case CleaningStatus.notRequested:
      case CleaningStatus.cancelled:
        return Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: isMutating ? null : onRequest,
            child: const Text('청소 신청하기'),
          ),
        );
      case CleaningStatus.paymentPending:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: isMutating ? null : onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error600,
                side: BorderSide(color: AppColors.error500.withValues(alpha: 0.5)),
              ),
              child: const Text('신청 취소'),
            ),
            SizedBox(width: AppSpacing.sm),
            FilledButton(
              onPressed: isMutating ? null : onPay,
              child: const Text('결제하기'),
            ),
          ],
        );
      case CleaningStatus.paid:
        return _buildRefundAction(c);
    }
  }

  /// PAID 상태 — 청소 결제 환불 (서버 산정 견적 + 버튼)
  ///
  /// 정책 수치(차감액·D-2·1시간)는 서버가 단일 진실 원천(`evaluateCleaningRefund`)이며
  /// 프론트는 `c.cleaningRefund` 값만 표시. 클라이언트 산정 없음.
  Widget _buildRefundAction(MoveInCase c) {
    final quote = c.cleaningRefund;
    final notAllowed = !quote.canRefund;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _refundPolicyNotice(
          highlighted: !notAllowed,
          trailing: !notAllowed
              ? Text(
                  quote.deduction > 0
                      ? '현재 환불 시 ${_money(quote.deduction)} 차감 후 ${_money(quote.refundAmount)} 환불됩니다.'
                      : '현재 환불 시 전액 ${_money(quote.refundAmount)} 환불됩니다.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary700,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Text(
                  quote.reason ?? '현재 환불할 수 없습니다.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            onPressed: (isMutating || notAllowed) ? null : onRefund,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error600,
              side: BorderSide(
                color: AppColors.error500.withValues(alpha: 0.5),
              ),
            ),
            child: const Text('청소 결제 환불'),
          ),
        ),
      ],
    );
  }

  /// 청소 환불 정책 안내 박스 — 결제 대기/완료 양쪽에서 공용.
  ///
  /// [highlighted] true 면 primary 배경(환불 가능), false 면 회색 배경.
  /// [trailing] 정책 문구 아래에 붙는 현재 시점 산정 안내(선택).
  Widget _refundPolicyNotice({bool highlighted = false, Widget? trailing}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primary50 : AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '환불 정책',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 2),
          Text(
            '· 청소 희망일 2일 전까지: 전액 환불\n'
            '· 희망일 1일 전 ~ 당일: 10,000원 차감 후 환불\n'
            '· 희망 시간 1시간 전부터: 환불 불가',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (trailing != null) ...[
            SizedBox(height: AppSpacing.xs),
            trailing,
          ],
        ],
      ),
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
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }

  String _suppliesText(MoveInRoom room) {
    if (!room.cleaningSuppliesAvailable) return '구비 안 함';
    final loc = room.cleaningSuppliesLocation;
    return loc == null || loc.isEmpty ? '구비함' : '구비함 ($loc)';
  }

  String _money(int? amount) {
    if (amount == null) return '-';
    final formatted = NumberFormat.decimalPattern('ko_KR').format(amount);
    return '$formatted원';
  }

  /// 청소 희망 일시를 'yyyy.MM.dd HH:mm' 한 줄로 포맷.
  /// cleaningDate('YYYY-MM-DD') + cleaningTime('HH:mm[:ss]') 결합.
  /// 날짜만 있으면 'yyyy.MM.dd', 둘 다 비면 '-'.
  String _formatCleaningDateTime(MoveInCase c) {
    final d = c.cleaningDate;
    if (d == null || d.isEmpty) return '-';
    String datePart;
    try {
      datePart = DateFormat('yyyy.MM.dd').format(DateTime.parse(d));
    } catch (_) {
      datePart = d;
    }
    final t = c.cleaningTime;
    if (t == null || t.isEmpty) return datePart;
    final hhmm = t.length >= 5 ? t.substring(0, 5) : t;
    return '$datePart $hhmm';
  }

  String _formatDateTime(String? iso) {
    if (iso == null) return '-';
    try {
      final d = DateTime.parse(iso).toLocal();
      return DateFormat('yyyy.MM.dd HH:mm').format(d);
    } catch (_) {
      return iso;
    }
  }
}
