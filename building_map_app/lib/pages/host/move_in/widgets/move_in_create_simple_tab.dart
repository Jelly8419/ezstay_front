import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/move_in/move_in.dart';
import '../../../../services/move_in_service.dart';
import '../../../../widgets/common/custom_toast.dart';
import 'move_in_room_form.dart';

/// "새 주소로 간편 등록" 탭 본문 (탭 2)
///
/// 방 정보만 등록 — 계약 정보/청소 영역 노출 X.
/// 저장 성공 시 [onCreated]로 신규 방을 부모(`MoveInCreatePage`)에 전달 →
/// 부모가 탭 1로 자동 전환 + 해당 방 선택.
class MoveInCreateSimpleTab extends StatefulWidget {
  final ValueChanged<MoveInRoom> onCreated;

  const MoveInCreateSimpleTab({super.key, required this.onCreated});

  @override
  State<MoveInCreateSimpleTab> createState() => _MoveInCreateSimpleTabState();
}

class _MoveInCreateSimpleTabState extends State<MoveInCreateSimpleTab> {
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
      final created = await _service.createMoveInRoom(request);
      if (!mounted) return;
      CustomToast.success(context, '방 정보를 등록했습니다.');
      widget.onCreated(created);
    } on MoveInException catch (e) {
      if (!mounted) return;
      CustomToast.error(context, e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '방 정보만 먼저 등록한 뒤, "등록된 방에서 선택" 탭에서 계약 정보와 함께 등록을 완료할 수 있습니다.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary700),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                MoveInRoomForm(controller: _formController),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.icon(
                onPressed: _isSaving ? null : _onSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? '저장 중...' : '방 정보 저장'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
