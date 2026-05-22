import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/move_in/move_in.dart';
import '../../../../services/move_in_service.dart';
import '../../../../widgets/common/custom_toast.dart';
import 'move_in_room_form.dart';

/// 간편 방 정보 편집 다이얼로그
///
/// 호출 결과:
/// - `null` → 취소
/// - `MoveInRoom` → PATCH 성공 → 호출자가 selectedRoom 갱신 + 목록 갱신
Future<MoveInRoom?> showMoveInRoomEditDialog(
  BuildContext context, {
  required MoveInRoom room,
}) {
  return showDialog<MoveInRoom>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _MoveInRoomEditDialog(room: room),
  );
}

class _MoveInRoomEditDialog extends StatefulWidget {
  final MoveInRoom room;
  const _MoveInRoomEditDialog({required this.room});

  @override
  State<_MoveInRoomEditDialog> createState() => _MoveInRoomEditDialogState();
}

class _MoveInRoomEditDialogState extends State<_MoveInRoomEditDialog> {
  final MoveInRoomFormController _formController = MoveInRoomFormController();
  final MoveInService _service = MoveInService();
  bool _isSaving = false;

  /// 재심사 트리거 필드 — 가이드 §1.3
  ///
  /// 이 필드 중 하나라도 변경되면 APPROVED/REJECTED 방이 자동 PENDING 으로 복귀.
  /// `beds` 배열 자체는 비트리거지만 `bedCount` 는 트리거.
  List<String> _changedTriggerFields(MoveInRoomRequest next) {
    final prev = widget.room;
    final changed = <String>[];
    if (next.address != prev.address) changed.add('주소');
    if (next.detailAddress != prev.detailAddress) changed.add('상세 주소');
    if (next.areaPyeong != prev.areaPyeong) changed.add('평수');
    if (next.livingRoomCount != prev.livingRoomCount) changed.add('거실 수');
    if (next.roomCount != prev.roomCount) changed.add('방 수');
    if (next.bathroomCount != prev.bathroomCount) changed.add('욕실 수');
    if (next.bedCount != prev.bedCount) changed.add('침대 수');
    return changed;
  }

  Future<bool> _confirmReReview(List<String> changedFields) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('재심사가 진행됩니다'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '변경된 항목이 있어 방이 다시 심사 대기 상태로 전환됩니다.\n'
              '관리자 승인 후 다시 사용할 수 있습니다.',
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              '변경 항목: ${changedFields.join(', ')}',
              style: AppTextStyles.labelSmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('계속'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _onSave() async {
    final request = _formController.buildRequest();
    if (request == null) {
      CustomToast.error(context, '입력값을 확인해주세요.');
      return;
    }

    // 트리거 필드 변경 + 현재 APPROVED/REJECTED 방인 경우에만 확인 모달
    final isApprovedOrRejected = widget.room.reviewStatus != MoveInRoomReviewStatus.pending;
    if (isApprovedOrRejected) {
      final triggered = _changedTriggerFields(request);
      if (triggered.isNotEmpty) {
        final proceed = await _confirmReReview(triggered);
        if (!proceed) return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final updated = await _service.updateMoveInRoom(widget.room.id, request);
      if (!mounted) return;
      // 응답 status로 안내 메시지 분기 (가이드 §1.3)
      final wentToReview = updated.reviewStatus == MoveInRoomReviewStatus.pending &&
          widget.room.reviewStatus != MoveInRoomReviewStatus.pending;
      CustomToast.success(
        context,
        wentToReview
            ? '방 정보가 수정되었습니다. 변경 항목이 있어 재심사가 진행됩니다.'
            : '방 정보를 수정했습니다.',
      );
      Navigator.of(context).pop(updated);
    } on MoveInException catch (e) {
      if (!mounted) return;
      CustomToast.error(context, e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width < 720 ? size.width - 32 : 640.0;
    final maxHeight = size.height * 0.85;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '방 정보 편집',
                      style: AppTextStyles.headingSmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.md),
                child: MoveInRoomForm(
                  controller: _formController,
                  initialRoom: widget.room,
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: _isSaving ? null : _onSave,
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('저장'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
