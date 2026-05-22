import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/move_in/move_in.dart';
import '../../../../models/room.dart' show UnavailablePeriod;
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

  /// 알림 딥링크에서 전달된 강조 대상 방 id — 자동 스크롤 + 펄스 보더 + (APPROVED일 때) 자동 선택
  final int? highlightRoomId;

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
    this.highlightRoomId,
  });

  @override
  State<MoveInCreateExistingTab> createState() => _MoveInCreateExistingTabState();
}

class _MoveInCreateExistingTabState extends State<MoveInCreateExistingTab> {
  final MoveInContractFormController _contractFormController = MoveInContractFormController();
  final MoveInService _service = MoveInService();

  MoveInRoom? _selectedRoom;
  bool _isSaving = false;

  /// 선택된 방의 점유 구간 → 캘린더 비활성화 입력.
  /// 점유 판정은 반열림 `[checkInDate, checkOutDate)` 이므로 endDate 는
  /// `checkOutDate - 1일` 로 보정 (당일 체크아웃·다음 손님 체크인 허용).
  List<UnavailablePeriod> _unavailablePeriods = const [];

  /// 현재 fetch 중인 방 id — 다른 방으로 빠르게 전환 시 오래된 응답 무시
  int? _rangesFetchRoomId;

  /// 방 id 별 GlobalKey — 하이라이트 자동 스크롤에 사용
  final Map<int, GlobalKey> _roomKeys = {};

  /// 자동 스크롤은 한 번만 — 이후 화면 갱신 때 다시 튀지 않게
  bool _didScrollToHighlight = false;

  @override
  void initState() {
    super.initState();
    _applyInitialSelection();
    _maybeScheduleHighlight();
    if (_selectedRoom != null) _fetchOccupiedRanges(_selectedRoom!.id);
  }

  /// 방 선택 시 호출 — 점유 구간 fetch + 캘린더 반영.
  Future<void> _fetchOccupiedRanges(int roomId) async {
    _rangesFetchRoomId = roomId;
    try {
      final today = DateTime.now();
      final from = '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';
      final resp = await _service.getRoomOccupiedRanges(roomId, from: from);
      if (!mounted || _rangesFetchRoomId != roomId) return;
      setState(() {
        _unavailablePeriods = _toUnavailablePeriods(resp.ranges);
      });
    } on MoveInException {
      // ranges 조회 실패는 사용자 흐름 막지 않음 — 빈 배열 폴백 (서버 409 가 최종 안전망)
      if (!mounted || _rangesFetchRoomId != roomId) return;
      setState(() => _unavailablePeriods = const []);
    }
  }

  /// 백엔드 ranges → 캘린더 위젯 입력 변환.
  /// 점유 판정 [checkIn, checkOut) — checkOut 당일은 비점유이므로
  /// UnavailablePeriod.endDate 를 (checkOutDate - 1일) 로 보정.
  List<UnavailablePeriod> _toUnavailablePeriods(List<RoomOccupiedRange> ranges) {
    final result = <UnavailablePeriod>[];
    for (final r in ranges) {
      final start = DateTime.tryParse(r.checkInDate);
      final out = DateTime.tryParse(r.checkOutDate);
      if (start == null || out == null) continue;
      final end = out.subtract(const Duration(days: 1));
      // 같은 날 체크인·체크아웃(end < start) 케이스는 비점유 — 스킵.
      if (end.isBefore(start)) continue;
      result.add(UnavailablePeriod(
        startDate: start,
        endDate: end,
        type: 'contract',
      ));
    }
    return result;
  }

  @override
  void didUpdateWidget(MoveInCreateExistingTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelectedRoomId != widget.initialSelectedRoomId ||
        oldWidget.rooms.length != widget.rooms.length) {
      _applyInitialSelection();
    }
    if (oldWidget.highlightRoomId != widget.highlightRoomId) {
      _didScrollToHighlight = false;
    }
    _maybeScheduleHighlight();
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

  /// 하이라이트 대상 방이 로드된 첫 프레임에 자동 스크롤 + (APPROVED) 자동 선택
  void _maybeScheduleHighlight() {
    final targetId = widget.highlightRoomId;
    if (targetId == null || _didScrollToHighlight) return;
    MoveInRoom? target;
    for (final r in widget.rooms) {
      if (r.id == targetId) {
        target = r;
        break;
      }
    }
    if (target == null) return;
    _didScrollToHighlight = true;

    final approvedRoom = target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // APPROVED 인 경우에만 자동 선택 (가드: PENDING/REJECTED 는 라디오 disabled 와 동일 정책)
      if (approvedRoom.isSelectable && _selectedRoom?.id != approvedRoom.id) {
        setState(() => _selectedRoom = approvedRoom);
      }
      final key = _roomKeys[approvedRoom.id];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          alignment: 0.1,
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Key _ensureRoomKey(int roomId) =>
      _roomKeys.putIfAbsent(roomId, () => GlobalKey(debugLabel: 'move-in-room-$roomId'));

  Future<void> _onEditRoom(MoveInRoom room) async {
    final updated = await showMoveInRoomEditDialog(context, room: room);
    if (updated == null) return;
    setState(() {
      if (_selectedRoom?.id == updated.id) _selectedRoom = updated;
    });
    widget.onRoomsChanged();
  }

  Future<void> _onDeleteRoom(MoveInRoom room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('방을 삭제하시겠어요?'),
        content: Text(
          '"${room.displayName}" 방을 삭제합니다.\n'
          '연결된 입주 준비 케이스가 있으면 삭제되지 않습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteMoveInRoom(room.id);
      if (!mounted) return;
      if (_selectedRoom?.id == room.id) {
        setState(() => _selectedRoom = null);
      }
      CustomToast.success(context, '방을 삭제했습니다.');
      widget.onRoomsChanged();
    } on MoveInException catch (e) {
      if (!mounted) return;
      CustomToast.error(context, e.message);
    }
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
          cleaningDate: result.cleaningDate,
          cleaningTime: result.cleaningTime,
        ),
      );
      if (!mounted) return;

      // 1단계 성공 → 자동발송 결과 토스트
      _showAutoSendToast(response.autoSend);

      // 2단계 — 청소 신청 (Q5-D: 실패해도 케이스는 살아있다는 솔직 안내)
      // 일자/시간은 1단계에서 이미 저장됨. 본 호출은 상태 전환만.
      String? cleaningWarn;
      if (result.cleaningRequested) {
        try {
          await _service.requestCleaning(response.moveInCase.id);
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
        // 다른 디바이스/탭 동시 등록으로 ranges 가 stale 일 수 있음 → 재조회.
        if (_selectedRoom != null) {
          _fetchOccupiedRanges(_selectedRoom!.id);
        }
        final caseId = parseConflictCaseId(message: e.message, details: e.details);
        final goExisting = await showMoveInConflictDialog(
          context,
          message: e.message,
          existingCaseId: caseId,
        );
        if (goExisting == true && caseId != null && mounted) {
          context.go('/host/move-in/$caseId');
        }
      } else if (e.errorCode == MoveInErrorCode.moveInRoomNotApproved) {
        // 가이드 §1.4 — details.reviewStatus 로 PENDING/REJECTED 분기
        final reviewStatus = (e.details is Map ? e.details['reviewStatus'] : null)?.toString();
        final message = reviewStatus == 'REJECTED'
            ? '방이 심사 반려되었습니다. 사유를 확인하고 수정 후 다시 시도해주세요.'
            : '방이 아직 심사 대기 중입니다. 승인 후 다시 시도해주세요.';
        CustomToast.error(context, message);
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
                  onSelected: (room) {
                    setState(() {
                      _selectedRoom = room;
                      // 새 방으로 전환 시 이전 점유 구간 초기화 (응답 도착 전 stale 안내 방지)
                      _unavailablePeriods = const [];
                    });
                    _fetchOccupiedRanges(room.id);
                  },
                  onEditTap: _onEditRoom,
                  onDeleteTap: _onDeleteRoom,
                  isLoading: widget.isLoadingRooms,
                  highlightRoomId: widget.highlightRoomId,
                  highlightKeyBuilder: _ensureRoomKey,
                ),
                if (_selectedRoom != null) ...[
                  SizedBox(height: AppSpacing.lg),
                  MoveInContractForm(
                    cleaningSuppliesAvailable: _selectedRoom!.cleaningSuppliesAvailable,
                    controller: _contractFormController,
                    unavailablePeriods: _unavailablePeriods,
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
