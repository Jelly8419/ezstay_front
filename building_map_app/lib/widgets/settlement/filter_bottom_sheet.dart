import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/settlement.dart';

/// 데스크탑 환경에서 버튼 아래에 표시되는 드롭다운 팝업 (방 선택)
class SettlementRoomDropdown extends StatefulWidget {
  final List<SettlementRoom> rooms;
  final String selectedRoomId;
  final ValueChanged<String> onSelectRoom;

  const SettlementRoomDropdown({
    super.key,
    required this.rooms,
    required this.selectedRoomId,
    required this.onSelectRoom,
  });

  @override
  State<SettlementRoomDropdown> createState() => _SettlementRoomDropdownState();
}

class _SettlementRoomDropdownState extends State<SettlementRoomDropdown> {
  late String _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = widget.selectedRoomId;
  }

  void _handleConfirm() {
    widget.onSelectRoom(_tempSelected);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '방 선택',
                    style: AppTextStyles.labelLarge.copyWith(fontSize: 15),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(4),
                    child: Icon(Icons.close, size: 18, color: AppColors.neutral400),
                  ),
                ],
              ),
            ),
            // 방 목록
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [
                    _buildOption(id: 'all', name: '전체 보기'),
                    ...widget.rooms.map(
                      (room) => _buildOption(
                        id: room.roomId.toString(),
                        name: room.roomTitle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 적용 버튼
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue500,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '적용하기',
                    style: AppTextStyles.labelMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({required String id, required String name}) {
    final isSelected = _tempSelected == id;

    return InkWell(
      onTap: () => setState(() => _tempSelected = id),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary50 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.blue500 : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? AppColors.blue600 : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, size: 16, color: AppColors.blue500),
          ],
        ),
      ),
    );
  }
}

/// 정산 필터 바텀시트 (방 선택)
/// React FilterBottomSheet.tsx와 동일한 UI
class SettlementFilterBottomSheet extends StatefulWidget {
  final List<SettlementRoom> rooms;
  final String selectedRoomId;
  final ValueChanged<String> onSelectRoom;

  const SettlementFilterBottomSheet({
    super.key,
    required this.rooms,
    required this.selectedRoomId,
    required this.onSelectRoom,
  });

  @override
  State<SettlementFilterBottomSheet> createState() =>
      _SettlementFilterBottomSheetState();
}

class _SettlementFilterBottomSheetState
    extends State<SettlementFilterBottomSheet> {
  late String _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = widget.selectedRoomId;
  }

  void _handleConfirm() {
    widget.onSelectRoom(_tempSelected);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '방 선택',
                  style: AppTextStyles.headingSmall,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, size: 20),
                  padding: EdgeInsets.all(8),
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),
          // 스크롤 영역
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // 전체 보기 옵션
                  _buildRoomOption(
                    id: 'all',
                    name: '전체 보기',
                  ),
                  SizedBox(height: 8),
                  // 방 목록
                  ...widget.rooms.map((room) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: _buildRoomOption(
                          id: room.roomId.toString(),
                          name: room.roomTitle,
                        ),
                      )),
                ],
              ),
            ),
          ),
          // 확인 버튼
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue500,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '적용하기',
                  style: AppTextStyles.labelLarge,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomOption({
    required String id,
    required String name,
  }) {
    final isSelected = _tempSelected == id;

    return InkWell(
      onTap: () => setState(() => _tempSelected = id),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary50 : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.blue500 : AppColors.gray200,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: AppTextStyles.labelMedium,
                textAlign: TextAlign.left,
              ),
            ),
            if (isSelected)
              Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.check,
                  size: 20,
                  color: AppColors.blue500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 모바일: 바텀시트를 표시하는 헬퍼 함수
void showSettlementFilterBottomSheet({
  required BuildContext context,
  required List<SettlementRoom> rooms,
  required String selectedRoomId,
  required ValueChanged<String> onSelectRoom,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SettlementFilterBottomSheet(
      rooms: rooms,
      selectedRoomId: selectedRoomId,
      onSelectRoom: onSelectRoom,
    ),
  );
}

/// 데스크탑: 버튼 아래에 드롭다운 팝업을 표시하는 헬퍼 함수
void showSettlementRoomDropdown({
  required BuildContext context,
  required RenderBox buttonBox,
  required List<SettlementRoom> rooms,
  required String selectedRoomId,
  required ValueChanged<String> onSelectRoom,
}) {
  final buttonOffset = buttonBox.localToGlobal(Offset.zero);
  final buttonSize = buttonBox.size;

  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) {
      return Stack(
        children: [
          // 배경 탭하면 닫힘
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
          Positioned(
            left: buttonOffset.dx,
            top: buttonOffset.dy + buttonSize.height + 4,
            child: SettlementRoomDropdown(
              rooms: rooms,
              selectedRoomId: selectedRoomId,
              onSelectRoom: (roomId) {
                Navigator.pop(context);
                onSelectRoom(roomId);
              },
            ),
          ),
        ],
      );
    },
  );
}
