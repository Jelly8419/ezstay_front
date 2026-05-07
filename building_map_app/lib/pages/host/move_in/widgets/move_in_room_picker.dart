import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/move_in/move_in.dart';

/// 등록된 간편 방 카드 리스트 (탭 1 - Step 1 방 선택)
///
/// 선택된 방은 우측 상단에 체크 아이콘 표시.
class MoveInRoomPicker extends StatelessWidget {
  final List<MoveInRoom> rooms;
  final int? selectedRoomId;
  final ValueChanged<MoveInRoom> onSelected;
  final void Function(MoveInRoom room) onEditTap;
  final bool isLoading;

  const MoveInRoomPicker({
    super.key,
    required this.rooms,
    required this.selectedRoomId,
    required this.onSelected,
    required this.onEditTap,
    this.isLoading = false,
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
            room: rooms[i],
            isSelected: rooms[i].id == selectedRoomId,
            onTap: () => onSelected(rooms[i]),
            onEditTap: () => onEditTap(rooms[i]),
          ),
        ],
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  final MoveInRoom room;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEditTap;

  const _RoomCard({
    required this.room,
    required this.isSelected,
    required this.onTap,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusMd,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.radiusMd,
          border: Border.all(
            color: isSelected ? AppColors.primary500 : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                if (isSelected)
                  Icon(Icons.check_circle, color: AppColors.primary500, size: 22)
                else
                  Icon(Icons.radio_button_unchecked, color: AppColors.textDisabled, size: 22),
                SizedBox(height: AppSpacing.sm),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(String text) => Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
      );
}
