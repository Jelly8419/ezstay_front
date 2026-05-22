import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/move_in/move_in.dart';
import '../../../../utils/responsive_util.dart';
import 'move_in_status_chips.dart';

typedef MoveInCaseAction = void Function(MoveInCase moveInCase);

/// 입주 준비 등록 목록 (이미지 ① 하단)
///
/// 데스크탑/태블릿: 테이블 형태 / 모바일: 카드 리스트
class MoveInCaseList extends StatelessWidget {
  final List<MoveInCase> cases;
  final MoveInCaseAction onTapDetail;
  final MoveInCaseAction onTapPay;

  const MoveInCaseList({
    super.key,
    required this.cases,
    required this.onTapDetail,
    required this.onTapPay,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);
    if (isMobile) {
      return Column(
        children: [
          for (var i = 0; i < cases.length; i++) ...[
            if (i > 0) SizedBox(height: AppSpacing.sm),
            MoveInCaseCard(
              moveInCase: cases[i],
              onTapDetail: onTapDetail,
              onTapPay: onTapPay,
            ),
          ],
        ],
      );
    }
    return _DesktopTable(
      cases: cases,
      onTapDetail: onTapDetail,
      onTapPay: onTapPay,
    );
  }
}

// ============================================================
// 데스크탑/태블릿 — 테이블
// ============================================================

class _DesktopTable extends StatelessWidget {
  final List<MoveInCase> cases;
  final MoveInCaseAction onTapDetail;
  final MoveInCaseAction onTapPay;

  const _DesktopTable({
    required this.cases,
    required this.onTapDetail,
    required this.onTapPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildHeader(),
          for (final c in cases) _DesktopRow(
            moveInCase: c,
            onTapDetail: onTapDetail,
            onTapPay: onTapPay,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final cellStyle = AppTextStyles.labelMedium.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w600,
    );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        border: Border(bottom: BorderSide(color: AppColors.border)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('방 정보', style: cellStyle)),
          Expanded(flex: 3, child: Text('입주일 - 퇴실일', style: cellStyle)),
          Expanded(flex: 2, child: Text('청소 서비스', style: cellStyle)),
          Expanded(flex: 2, child: Text('임차인 입주 서비스 요청', style: cellStyle)),
          SizedBox(width: 180, child: Text('관리', style: cellStyle)),
        ],
      ),
    );
  }
}

class _DesktopRow extends StatelessWidget {
  final MoveInCase moveInCase;
  final MoveInCaseAction onTapDetail;
  final MoveInCaseAction onTapPay;

  const _DesktopRow({
    required this.moveInCase,
    required this.onTapDetail,
    required this.onTapPay,
  });

  @override
  Widget build(BuildContext context) {
    final c = moveInCase;
    return InkWell(
      onTap: () => onTapDetail(c),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 4, child: _RoomInfoCell(moveInCase: c)),
            Expanded(flex: 3, child: _DateRangeCell(moveInCase: c)),
            // 칩은 텍스트 너비에 맞춤 — Align 으로 셀 내 좌측 정렬,
            // 셀 자체 폭(flex)은 유지해 헤더 컬럼과 정렬을 맞춘다.
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: CleaningStatusChip(status: c.cleaningStatus),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: PaymentRequestStatusChip(
                  status: c.paymentRequest?.status ??
                      PaymentRequestStatus.notSent,
                ),
              ),
            ),
            SizedBox(width: 180, child: _ActionCell(
              moveInCase: c,
              onTapDetail: onTapDetail,
              onTapPay: onTapPay,
            )),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 모바일 — 카드
// ============================================================

class MoveInCaseCard extends StatelessWidget {
  final MoveInCase moveInCase;
  final MoveInCaseAction onTapDetail;
  final MoveInCaseAction onTapPay;

  const MoveInCaseCard({
    super.key,
    required this.moveInCase,
    required this.onTapDetail,
    required this.onTapPay,
  });

  @override
  Widget build(BuildContext context) {
    final c = moveInCase;
    return InkWell(
      onTap: () => onTapDetail(c),
      borderRadius: AppRadius.radiusMd,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.radiusMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RoomInfoCell(moveInCase: c),
            SizedBox(height: AppSpacing.sm),
            _DateRangeCell(moveInCase: c),
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                CleaningStatusChip(status: c.cleaningStatus),
                SizedBox(width: AppSpacing.xs),
                PaymentRequestStatusChip(
                  status: c.paymentRequest?.status ?? PaymentRequestStatus.notSent,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            _ActionCell(
              moveInCase: c,
              onTapDetail: onTapDetail,
              onTapPay: onTapPay,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 셀 위젯 (데스크탑/모바일 공용)
// ============================================================

class _RoomInfoCell extends StatelessWidget {
  final MoveInCase moveInCase;
  const _RoomInfoCell({required this.moveInCase});

  @override
  Widget build(BuildContext context) {
    final room = moveInCase.roomSnapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          room.displayName,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 2),
        Text(
          room.fullAddress,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 2),
        Text(
          '${moveInCase.guestName} · ${_formatPhone(moveInCase.guestPhone)}',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }
    return phone;
  }
}

class _DateRangeCell extends StatelessWidget {
  final MoveInCase moveInCase;
  const _DateRangeCell({required this.moveInCase});

  @override
  Widget build(BuildContext context) {
    final inDate = _format(moveInCase.checkInDate);
    final outDate = _format(moveInCase.checkOutDate);
    return Text(
      '$inDate ~ $outDate',
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _format(String yyyymmdd) {
    try {
      final date = DateTime.parse(yyyymmdd);
      return DateFormat('yyyy.MM.dd').format(date);
    } catch (_) {
      return yyyymmdd;
    }
  }
}

class _ActionCell extends StatelessWidget {
  final MoveInCase moveInCase;
  final MoveInCaseAction onTapDetail;
  final MoveInCaseAction onTapPay;

  const _ActionCell({
    required this.moveInCase,
    required this.onTapDetail,
    required this.onTapPay,
  });

  @override
  Widget build(BuildContext context) {
    final canPay = moveInCase.canPayCleaning;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: () => onTapDetail(moveInCase),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            side: BorderSide(color: AppColors.border),
            foregroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
          child: const Text('상세'),
        ),
        if (canPay) ...[
          SizedBox(width: AppSpacing.xs),
          FilledButton(
            onPressed: () => onTapPay(moveInCase),
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              backgroundColor: AppColors.primary500,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
            child: const Text('결제'),
          ),
        ],
      ],
    );
  }
}
