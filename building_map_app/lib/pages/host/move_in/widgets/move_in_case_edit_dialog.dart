import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/move_in/move_in.dart';
import '../../../../widgets/common/custom_text_field.dart';
import '../../../../widgets/common/date_range_picker.dart';

/// 케이스 정보 수정 다이얼로그
///
/// 결과: 변경 사항이 있으면 [MoveInCaseUpdateRequest] 반환, 없으면 null.
/// 호출 측에서 PATCH `/cases/:id` 호출 + 결과로 케이스 갱신.
///
/// 주의 (PRD 9.2 / 가이드 6.3): `guestPhone` 변경 시 백엔드가 토큰 자동 재발급 +
/// `paymentRequest.status`를 NOT_SENT로 초기화함. UI에 별도 표시 X — 다음 조회 시 자동 반영.
Future<MoveInCaseUpdateRequest?> showMoveInCaseEditDialog(
  BuildContext context, {
  required MoveInCase moveInCase,
}) {
  return showDialog<MoveInCaseUpdateRequest>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _MoveInCaseEditDialog(moveInCase: moveInCase),
  );
}

class _MoveInCaseEditDialog extends StatefulWidget {
  final MoveInCase moveInCase;
  const _MoveInCaseEditDialog({required this.moveInCase});

  @override
  State<_MoveInCaseEditDialog> createState() => _MoveInCaseEditDialogState();
}

class _MoveInCaseEditDialogState extends State<_MoveInCaseEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _memoCtrl;
  late DateTime _checkInDate;
  late DateTime _checkOutDate;

  @override
  void initState() {
    super.initState();
    final c = widget.moveInCase;
    _nameCtrl = TextEditingController(text: c.guestName);
    _phoneCtrl = TextEditingController(text: c.guestPhone);
    _memoCtrl = TextEditingController(text: c.requestMemo ?? '');
    _checkInDate = DateTime.tryParse(c.checkInDate) ?? DateTime.now();
    _checkOutDate = DateTime.tryParse(c.checkOutDate) ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_checkOutDate.isBefore(_checkInDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('퇴실일은 입주일 이후여야 합니다.')),
      );
      return;
    }

    // 변경된 필드만 포함한 PATCH 요청 생성
    final original = widget.moveInCase;
    final newName = _nameCtrl.text.trim();
    final newPhone = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    final newMemo = _memoCtrl.text.trim();
    final newCheckIn = DateFormat('yyyy-MM-dd').format(_checkInDate);
    final newCheckOut = DateFormat('yyyy-MM-dd').format(_checkOutDate);

    final request = MoveInCaseUpdateRequest(
      checkInDate: newCheckIn != original.checkInDate ? newCheckIn : null,
      checkOutDate: newCheckOut != original.checkOutDate ? newCheckOut : null,
      guestName: newName != original.guestName ? newName : null,
      guestPhone: newPhone != original.guestPhone ? newPhone : null,
      requestMemo: newMemo != (original.requestMemo ?? '') ? newMemo : null,
    );

    if (request.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop(request);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width < 720 ? size.width - 32 : 520.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('계약 정보 수정', style: AppTextStyles.headingSmall)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                DateRangePicker(
                  checkInDate: _checkInDate,
                  checkOutDate: _checkOutDate,
                  minContractDays: 1,
                  placeholderText: '입주일 - 퇴실일 선택',
                  showHelperText: false,
                  onDateSelected: (checkIn, checkOut) {
                    setState(() {
                      _checkInDate = checkIn;
                      _checkOutDate = checkOut;
                    });
                  },
                ),
                SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  label: '임차인 이름',
                  controller: _nameCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty) ? '이름을 입력해주세요.' : null,
                ),
                SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  label: '임차인 연락처',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '연락처를 입력해주세요.';
                    final digits = v.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 10 || digits.length > 11) return '올바른 휴대폰 번호를 입력해주세요.';
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  '※ 연락처를 변경하면 임차인 결제 요청이 다시 발송 가능 상태로 초기화됩니다.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  label: '요청 메모',
                  controller: _memoCtrl,
                  maxLines: 2,
                ),
                SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      onPressed: _onSave,
                      child: const Text('저장'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

