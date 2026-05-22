import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/move_in/move_in.dart';
import 'move_in_review_status_badge.dart';

/// 등록된 간편 방 카드 리스트 (탭 1 - Step 1 방 선택)
///
/// 카드 좌측에 라디오 선택 아이콘, 우측 상단에 심사 상태 뱃지와 편집/삭제 버튼을 배치한다.
/// - [MoveInRoom.isSelectable] 이 false 면 라디오와 카드 탭이 비활성화 (PENDING/REJECTED)
/// - [MoveInRoom.isEditable] 이 false 면 편집 버튼은 비노출 (가이드 §1.1)
/// - REJECTED 방은 카드 하단에 반려 사유를 표시
/// - 카드 하이라이트가 필요하면 [highlightRoomId] 와 [highlightKeyBuilder] 를 전달
class MoveInRoomPicker extends StatelessWidget {
  final List<MoveInRoom> rooms;
  final int? selectedRoomId;
  final ValueChanged<MoveInRoom> onSelected;
  final void Function(MoveInRoom room) onEditTap;
  final void Function(MoveInRoom room) onDeleteTap;
  final bool isLoading;

  /// 펄스 강조 표시 대상 방 id (알림 딥링크 등에서 사용)
  final int? highlightRoomId;

  /// 자동 스크롤용 GlobalKey 빌더 — 부모가 방 id별 GlobalKey 를 관리할 때 전달
  final Key Function(int roomId)? highlightKeyBuilder;

  const MoveInRoomPicker({
    super.key,
    required this.rooms,
    required this.selectedRoomId,
    required this.onSelected,
    required this.onEditTap,
    required this.onDeleteTap,
    this.isLoading = false,
    this.highlightRoomId,
    this.highlightKeyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (rooms.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.neutral50,
          borderRadius: AppRadius.radiusMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(Icons.bed_outlined, size: 40, color: AppColors.textDisabled),
            SizedBox(height: AppSpacing.sm),
            Text(
              '아직 등록된 방이 없습니다.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              '"새 주소로 간편 등록" 탭에서 방을 먼저 등록해주세요.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < rooms.length; i++) ...[
          if (i > 0) SizedBox(height: AppSpacing.sm),
          _RoomCard(
            key: highlightKeyBuilder?.call(rooms[i].id),
            room: rooms[i],
            isSelected: rooms[i].id == selectedRoomId,
            isHighlighted: rooms[i].id == highlightRoomId,
            onTap: () => onSelected(rooms[i]),
            onEditTap: () => onEditTap(rooms[i]),
            onDeleteTap: () => onDeleteTap(rooms[i]),
          ),
        ],
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  final MoveInRoom room;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback onTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  const _RoomCard({
    super.key,
    required this.room,
    required this.isSelected,
    required this.isHighlighted,
    required this.onTap,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final canSelect = room.isSelectable;
    final isRejected = room.reviewStatus == MoveInRoomReviewStatus.rejected;

    final borderColor = isHighlighted
        ? AppColors.warning500
        : isSelected
            ? AppColors.primary500
            : AppColors.border;
    final borderWidth = (isHighlighted || isSelected) ? 2.0 : 1.0;

    return Opacity(
      opacity: canSelect ? 1.0 : 0.6,
      child: InkWell(
        onTap: canSelect ? onTap : null,
        borderRadius: AppRadius.radiusMd,
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.radiusMd,
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 좌측 라디오 — isSelectable === false 시 disabled
                  Padding(
                    padding: EdgeInsets.only(top: 2, right: AppSpacing.sm),
                    child: _radioIcon(isSelected: isSelected, enabled: canSelect),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.displayName,
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 2),
                        Text(
                          room.fullAddress,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 4),
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: [
                            _meta('${room.areaPyeong}평'),
                            _meta('방 ${room.roomCount}'),
                            _meta('침대 ${room.bedCount}'),
                            if (!room.cleaningSuppliesAvailable)
                              Text(
                                '청소용품 미구비',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.warning700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      MoveInReviewStatusBadge(status: room.reviewStatus),
                      SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (room.isEditable)
                            TextButton.icon(
                              onPressed: onEditTap,
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('편집'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 0),
                                minimumSize: const Size(0, 28),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          IconButton(
                            onPressed: onDeleteTap,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            tooltip: '방 삭제',
                            color: AppColors.error600,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 28),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (isRejected && (room.rejectionReason?.isNotEmpty ?? false)) ...[
                SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error50,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 16, color: AppColors.error700),
                      SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '반려 사유: ${room.rejectionReason}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.error700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _radioIcon({required bool isSelected, required bool enabled}) {
    if (!enabled) {
      return Icon(Icons.radio_button_unchecked,
          color: AppColors.textDisabled, size: 22);
    }
    if (isSelected) {
      return Icon(Icons.check_circle, color: AppColors.primary500, size: 22);
    }
    return Icon(Icons.radio_button_unchecked,
        color: AppColors.neutral500, size: 22);
  }

  Widget _meta(String text) => Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
      );
}
