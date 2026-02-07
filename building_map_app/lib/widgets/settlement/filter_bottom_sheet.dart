import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/settlement.dart';

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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
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

/// 바텀시트를 표시하는 헬퍼 함수
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
