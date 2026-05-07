import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/move_in/move_in.dart';

/// 상세 페이지 상단 헤더 카드 (이미지 ③ 상단)
///
/// 방 정보 + 입주/퇴실 + 임차인 정보 + 정보 수정 버튼
class MoveInDetailHeader extends StatelessWidget {
  final MoveInCase moveInCase;
  final VoidCallback onEdit;

  const MoveInDetailHeader({
    super.key,
    required this.moveInCase,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final c = moveInCase;
    final room = c.roomSnapshot;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.displayName,
                      style: AppTextStyles.headingMedium,
                    ),
                    SizedBox(height: 2),
                    Text(
                      room.fullAddress,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('정보 수정'),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          _row('입주일', _formatDate(c.checkInDate)),
          SizedBox(height: AppSpacing.xs),
          _row('퇴실일', _formatDate(c.checkOutDate)),
          SizedBox(height: AppSpacing.xs),
          _row('임차인', '${c.guestName} · ${_formatPhone(c.guestPhone)}'),
          if (c.requestMemo?.isNotEmpty == true) ...[
            SizedBox(height: AppSpacing.xs),
            _row('메모', c.requestMemo!),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: AppTextStyles.bodyMedium),
        ),
      ],
    );
  }

  String _formatDate(String yyyymmdd) {
    try {
      return DateFormat('yyyy.MM.dd').format(DateTime.parse(yyyymmdd));
    } catch (_) {
      return yyyymmdd;
    }
  }

  String _formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }
    return phone;
  }
}

/// 청소·임차인 결제 요청이 독립 이벤트라는 PRD 안내 박스 (이미지 ③ 중앙)
class MoveInIndependenceNotice extends StatelessWidget {
  const MoveInIndependenceNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: AppColors.primary500.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.primary700),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              '청소 서비스 신청/결제와 임차인 결제 요청은 서로 종속되지 않습니다.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
