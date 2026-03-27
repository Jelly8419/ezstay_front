import 'package:flutter/material.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';

/// 방 상태 배지 위젯
///
/// 상태별로 색상과 라벨을 자동 매핑하여 표시
class RoomStatusBadge extends StatelessWidget {
  final String status;
  final bool isActive;

  const RoomStatusBadge({
    super.key,
    required this.status,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final badgeInfo = _getBadgeInfo();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: badgeInfo.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        badgeInfo.label,
        style: AppTextStyles.labelSmall.copyWith(
          color: badgeInfo.textColor,
        ),
      ),
    );
  }

  /// 상태별 배지 정보 반환
  _BadgeInfo _getBadgeInfo() {
    // published 상태에서는 isActive 여부로 게시중/게시중단 구분
    if (status == 'published') {
      if (isActive) {
        return const _BadgeInfo(
          label: '게시중',
          backgroundColor: Color(0xFFE7F5FF),
          textColor: Color(0xFF1971C2),
        );
      } else {
        return const _BadgeInfo(
          label: '게시중단',
          backgroundColor: Color(0xFFF3F4F6),
          textColor: Color(0xFF6B7280),
        );
      }
    }

    switch (status) {
      case 'draft':
        return const _BadgeInfo(
          label: '등록중',
          backgroundColor: Color(0xFFFFF4E6),
          textColor: Color(0xFFE67700),
        );
      case 'pending_review':
        return const _BadgeInfo(
          label: '심사중',
          backgroundColor: Color(0xFFFFE6F0),
          textColor: Color(0xFFC2255C),
        );
      case 'approved':
        return const _BadgeInfo(
          label: '승인됨',
          backgroundColor: Color(0xFFE6FCF5),
          textColor: Color(0xFF0CA678),
        );
      case 'rejected':
        return const _BadgeInfo(
          label: '등록 반려',
          backgroundColor: Color(0xFFFEE2E2),
          textColor: Color(0xFFDC2626),
        );
      case 'hidden_by_admin':
        return const _BadgeInfo(
          label: '관리자 숨김',
          backgroundColor: Color(0xFFF3F4F6),
          textColor: Color(0xFF374151),
        );
      default:
        return const _BadgeInfo(
          label: '등록중',
          backgroundColor: Color(0xFFF3F4F6),
          textColor: Color(0xFF6B7280),
        );
    }
  }
}

/// 배지 정보 데이터 클래스
class _BadgeInfo {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _BadgeInfo({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });
}
