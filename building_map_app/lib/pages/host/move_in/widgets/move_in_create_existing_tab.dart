import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/move_in/move_in.dart';
import '../../../../providers/move_in/move_in_list_provider.dart';
import '../../../../services/move_in_service.dart';
import '../../../../widgets/common/custom_toast.dart';
import 'move_in_conflict_dialog.dart';
import 'move_in_contract_form.dart';
import 'move_in_room_edit_dialog.dart';
import 'move_in_room_picker.dart';

/// "등록된 방에서 선택" 탭 본문 (탭 1)
///
/// Step 1. 방 선택  ─┐
/// Step 2. 계약 정보 ┼ MoveInContractForm
/// Step 3. 자동발송  │   (체크박스 + 청소 서비스 토글 포함)
/// Step 4. 청소 서비스 ┘
/// Step 5. 저장 → POST /cases → (청소 신청 ON이면) POST cleaning/request
class MoveInCreateExistingTab extends StatefulWidget {
  /// 외부에서 전달된 초기 선택 방 (탭 2에서 등록 후 자동 전환된 경우)
  final int? initialSelectedRoomId;

  /// 부모 위젯이 보유한 방 목록 — 탭 2에서 등록한 방을 즉시 반영하기 위해 외부 주입
  final List<MoveInRoom> rooms;
  final bool isLoadingRooms;

  /// 방 정보 편집 후 부모가 [rooms] 리프레시할 수 있도록 알림
  final VoidCallback onRoomsChanged;

  const MoveInCreateExistingTab({
    super.key,
    required this.rooms,
    required this.isLoadingRooms,
    required this.onRoomsChanged,
    this.initialSelectedRoomId,
  });

  @override
  State<MoveInCreateExistingTab> createState() => _MoveInCreateExistingTabState();
}

class _MoveInCreateExistingTabState extends State<MoveInCreateExistingTab> {
  final MoveInContractFormController _contractFormController = MoveInContractFormController();
  final MoveInService _service = MoveInService();

  MoveInRoom? _selectedRoom;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _applyInitialSelection();
  }

  @override
  void didUpdateWidget(MoveInCreateExistingTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelectedRoomId != widget.initialSelectedRoomId ||
        oldWidget.rooms.length != widget.rooms.length) {
      _applyInitialSelection();
    }
  }

  void _applyInitialSelection() {
    if (widget.initialSelectedRoomId == null) return;
    for (final room in widget.rooms) {
      if (room.id == widget.initialSelectedRoomId) {
        _selectedRoom = room;
        return;
      }
    }
  }

  Future<void> _onEditRoom(MoveInRoom room) async {
    final updated = await showMoveInRoomEditDialog(context, room: room);
    if (updated == null) return;
    setState(() {
      if (_selectedRoom?.id == updated.id) _selectedRoom = updated;
    });
    widget.onRoomsChanged();
  }

  Future<void> _onSave() async {
    if (_selectedRoom == null) {
      CustomToast.error(context, '방을 먼저 선택해주세요.');
      return;
    }

    final result = _contractFormController.buildResult();
    if (result == null) {
      final extra = _contractFormController.validationMessage();
      CustomToast.error(context, extra ?? '입력값을 확인해주세요.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final response = await _service.createMoveInCase(
        MoveInCaseCreateRequest(
          moveInRoomId: _selectedRoom!.id,
          checkInDate: result.checkInDate,
          checkOutDate: result.checkOutDate,
          guestName: result.guestName,
          guestPhone: result.guestPhone,
          requestMemo: result.requestMemo,
          sendGuestPaymentRequest: result.sendGuestPaymentRequest,
        ),
      );
      if (!mounted) return;

      // 1단계 성공 → 자동발송 결과 토스트
      _showAutoSendToast(response.autoSend);

      // 2단계 — 청소 신청 (Q5-D: 실패해도 케이스는 살아있다는 솔직 안내)
      String? cleaningWarn;
      if (result.cleaningRequested) {
        try {
          await _service.requestCleaning(
            response.moveInCase.id,
            body: CleaningRequestBody(cleaningRequestedDate: result.cleaningRequestedDate),
          );
        } on MoveInException catch (e) {
          cleaningWarn = e.message;
        }
      }

      if (!mounted) return;

      // 목록 새로고침 (다음 진입 시 즉시 반영)
      context.read<MoveInListProvider>().load();

      // 상세로 이동 — 청소 신청 실패 시 추가 토스트 안내
      if (cleaningWarn != null) {
        CustomToast.warning(
          context,
          '케이스는 생성되었지만 청소 신청에 실패했습니다. 상세 페이지에서 다시 시도해주세요.\n($cleaningWarn)',
        );
      } else {
        CustomToast.success(context, '입주 준비 등록을 저장했습니다.');
      }
      context.go('/host/move-in/${response.moveInCase.id}');
    } on MoveInException catch (e) {
      if (!mounted) return;
      if (e.isConflict) {
        final caseId = parseConflictCaseId(message: e.message, details: e.details);
        final goExisting = await showMoveInConflictDialog(
          context,
          message: e.message,
          existingCaseId: caseId,
        );
        if (goExisting == true && caseId != null && mounted) {
          context.go('/host/move-in/$caseId');
        }
      } else {
        CustomToast.error(context, e.message);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAutoSendToast(AutoSendResult? autoSend) {
    if (autoSend == null) return;
    if (autoSend.sent) {
      CustomToast.success(context, '임차인에게 결제 요청을 발송했습니다.');
    } else {
      CustomToast.warning(
        context,
        '케이스는 생성되었으나 알림톡 발송에 실패했습니다. 상세 페이지에서 재발송할 수 있습니다.',
      );
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
                _stepTitle('1. 방 선택'),
                MoveInRoomPicker(
                  rooms: widget.rooms,
                  selectedRoomId: _selectedRoom?.id,
                  onSelected: (room) => setState(() => _selectedRoom = room),
                  onEditTap: _onEditRoom,
                  isLoading: widget.isLoadingRooms,
                ),
                if (_selectedRoom != null) ...[
                  SizedBox(height: AppSpacing.lg),
                  MoveInContractForm(
                    cleaningSuppliesAvailable: _selectedRoom!.cleaningSuppliesAvailable,
                    controller: _contractFormController,
                  ),
                ],
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
                onPressed: (_isSaving || _selectedRoom == null) ? null : _onSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isSaving ? '저장 중...' : '저장하고 다음 단계'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepTitle(String text) => Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(text, style: AppTextStyles.headingSmall),
      );
}
