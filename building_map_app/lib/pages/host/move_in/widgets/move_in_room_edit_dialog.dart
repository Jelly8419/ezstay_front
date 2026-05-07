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

  Future<void> _onSave() async {
    final request = _formController.buildRequest();
    if (request == null) {
      CustomToast.error(context, '입력값을 확인해주세요.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = await _service.updateMoveInRoom(widget.room.id, request);
      if (!mounted) return;
      CustomToast.success(context, '방 정보를 수정했습니다.');
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
