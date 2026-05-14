import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/move_in/move_in_deadline_policy.dart';
import '../../../../widgets/common/custom_text_field.dart';
import '../../../../widgets/common/date_range_picker.dart' show DateRangePicker, SingleDatePicker;

/// 계약 정보 + 자동발송 + 청소 서비스 폼 (탭 1 Step 2~4)
///
/// PRD 5.3 / 가이드 4.1 Step2~4 / 이미지 ② 좌측 탭의 "2. 계약 정보 입력" + "3. 청소 서비스" 영역.
class MoveInContractForm extends StatefulWidget {
  /// 청소용품 구비 여부 — 청소 서비스 토글의 활성/비활성 결정
  final bool cleaningSuppliesAvailable;
  final MoveInContractFormController controller;

  const MoveInContractForm({
    super.key,
    required this.cleaningSuppliesAvailable,
    required this.controller,
  });

  @override
  State<MoveInContractForm> createState() => _MoveInContractFormState();
}

class _MoveInContractFormState extends State<MoveInContractForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _guestNameCtrl;
  late TextEditingController _guestPhoneCtrl;
  late TextEditingController _memoCtrl;

  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  DateTime? _cleaningRequestedDate;
  /// 청소 희망 시간 — 'HH:mm' (30분 단위 드롭다운 값)
  String? _cleaningRequestedTime;

  /// 자동발송 체크박스 — Q3-A 결정대로 기본 ON
  bool _sendGuestPaymentRequest = true;

  /// 청소 서비스 신청 토글
  bool _cleaningRequested = false;

  @override
  void initState() {
    super.initState();
    _guestNameCtrl = TextEditingController();
    _guestPhoneCtrl = TextEditingController();
    _memoCtrl = TextEditingController();
    widget.controller._attach(this);
  }

  @override
  void didUpdateWidget(MoveInContractForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 청소용품 구비 여부가 미구비로 바뀌면 청소 신청 강제 해제
    if (oldWidget.cleaningSuppliesAvailable && !widget.cleaningSuppliesAvailable) {
      _cleaningRequested = false;
    }
  }

  @override
  void dispose() {
    _guestNameCtrl.dispose();
    _guestPhoneCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? d) =>
      d == null ? '' : DateFormat('yyyy-MM-dd').format(d);

  bool _validate() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return false;
    if (_checkInDate == null || _checkOutDate == null) return false;
    if (_checkOutDate!.isBefore(_checkInDate!)) return false;
    if (_cleaningRequested && _cleaningRequestedDate == null) return false;
    if (_cleaningRequested && _cleaningRequestedTime == null) return false;
    return true;
  }

  String? _validationMessage() {
    if (_checkInDate == null || _checkOutDate == null) {
      return '입주일과 퇴실일을 선택해주세요.';
    }
    if (_checkOutDate!.isBefore(_checkInDate!)) {
      return '퇴실일은 입주일 이후여야 합니다.';
    }
    if (_cleaningRequested && _cleaningRequestedDate == null) {
      return '청소 희망일을 선택해주세요.';
    }
    if (_cleaningRequested && _cleaningRequestedTime == null) {
      return '청소 희망 시간을 선택해주세요.';
    }
    return null;
  }

  MoveInContractFormResult _buildResult() {
    final cleaningOn = _cleaningRequested && _cleaningRequestedDate != null;
    return MoveInContractFormResult(
      checkInDate: _formatDate(_checkInDate),
      checkOutDate: _formatDate(_checkOutDate),
      guestName: _guestNameCtrl.text.trim(),
      guestPhone: _guestPhoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
      requestMemo: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
      sendGuestPaymentRequest: _sendGuestPaymentRequest,
      cleaningRequested: _cleaningRequested,
      cleaningDate: cleaningOn ? _formatDate(_cleaningRequestedDate) : null,
      cleaningTime: cleaningOn ? _cleaningRequestedTime : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('2. 계약 정보 입력', [
            DateRangePicker(
              checkInDate: _checkInDate,
              checkOutDate: _checkOutDate,
              minContractDays: 1,
              placeholderText: '입주일 - 퇴실일 선택',
              customHelperText: '외부 플랫폼 계약의 입주일과 퇴실일을 선택해주세요.',
              onDateSelected: (checkIn, checkOut) {
                setState(() {
                  _checkInDate = checkIn;
                  _checkOutDate = checkOut;
                });
              },
              onDateCleared: () => setState(() {
                _checkInDate = null;
                _checkOutDate = null;
              }),
            ),
            SizedBox(height: AppSpacing.sm),
            CustomTextField(
              label: '임차인 이름',
              controller: _guestNameCtrl,
              validator: (v) => (v == null || v.trim().isEmpty) ? '임차인 이름을 입력해주세요.' : null,
            ),
            SizedBox(height: AppSpacing.sm),
            CustomTextField(
              label: '임차인 연락처',
              hint: '01012345678',
              controller: _guestPhoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '임차인 연락처를 입력해주세요.';
                if (v.length < 10 || v.length > 11) return '올바른 휴대폰 번호를 입력해주세요.';
                return null;
              },
            ),
            SizedBox(height: AppSpacing.sm),
            CustomTextField(
              label: '요청 메모 (선택)',
              hint: '임차인 또는 운영팀에 전달할 메모',
              controller: _memoCtrl,
              maxLines: 2,
            ),
            // 결제 마감 기한 안내 — 입주일/퇴실일 둘 다 선택 시 노출
            if (_checkInDate != null && _checkOutDate != null) ...[
              SizedBox(height: AppSpacing.md),
              _PaymentDeadlineNotice(checkInDate: _checkInDate!),
            ],
          ]),
          // 자동발송 체크박스 (Q3-A) — 계약 정보 영역 하단에 배치
          _AutoSendCheckbox(
            value: _sendGuestPaymentRequest,
            onChanged: (v) => setState(() => _sendGuestPaymentRequest = v),
          ),
          SizedBox(height: AppSpacing.lg),
          _section('3. 청소 서비스 (선택)', [
            _CleaningToggle(
              available: widget.cleaningSuppliesAvailable,
              requested: _cleaningRequested,
              onChanged: (v) => setState(() => _cleaningRequested = v),
            ),
            if (_cleaningRequested) ...[
              SizedBox(height: AppSpacing.md),
              SingleDatePicker(
                selectedDate: _cleaningRequestedDate,
                placeholderText: '청소 희망일 선택',
                onDateSelected: (d) =>
                    setState(() => _cleaningRequestedDate = d),
                onDateCleared: () =>
                    setState(() => _cleaningRequestedDate = null),
              ),
              SizedBox(height: AppSpacing.xs),
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '청소비는 방 평수 기준으로 서버에서 자동 산정됩니다.\n결제는 저장 후 상세 페이지에서 진행할 수 있습니다.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary700),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              _CleaningTimeDropdown(
                value: _cleaningRequestedTime,
                onChanged: (v) => setState(() => _cleaningRequestedTime = v),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                '해당 시간 부터 최대 4시간 동안 청소 진행으로 입실이 어려울 수 있으니, '
                '다른 임차인의 예약과 겹치지 않게 주의해주세요.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _AutoSendCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AutoSendCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '저장 후 임차인에게 입주용품/침구류 결제 요청을 자동 발송합니다.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  SizedBox(height: 2),
                  Text(
                    '체크 해제 시 케이스만 생성되며, 상세 페이지에서 직접 발송할 수 있습니다.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
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

/// 청소 희망 시간 드롭다운 — 30분 단위 (09:00 ~ 18:00)
class _CleaningTimeDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _CleaningTimeDropdown({required this.value, required this.onChanged});

  /// 09:00 ~ 18:00 (30분 단위, 18:00 포함 → 19개)
  static final List<String> _slots = List.generate(19, (i) {
    final minutes = 9 * 60 + i * 30;
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: '청소 희망 시간',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        isDense: true,
      ),
      items: _slots
          .map((slot) => DropdownMenuItem(value: slot, child: Text(slot)))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? '청소 희망 시간을 선택해주세요.' : null,
    );
  }
}

class _CleaningToggle extends StatelessWidget {
  final bool available;
  final bool requested;
  final ValueChanged<bool> onChanged;

  const _CleaningToggle({
    required this.available,
    required this.requested,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('청소 서비스 신청', style: AppTextStyles.bodyMedium),
            ),
            Switch(
              value: requested,
              onChanged: available ? onChanged : null,
            ),
          ],
        ),
        if (!available) ...[
          SizedBox(height: AppSpacing.xs),
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.warning50,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '청소용품이 미구비된 방은 청소 서비스를 신청할 수 없습니다.\n방 정보 편집에서 청소용품 구비 여부를 변경한 후 다시 시도해주세요.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning700),
            ),
          ),
        ],
      ],
    );
  }
}

/// 결제 마감 기한 안내 카드 (청소 D-2, 입주용품/침구류 D-5)
///
/// 마감 정의: 입주일의 D-N **23:59:59** 까지.
/// 마감 시각이 현재보다 과거이면 회색 칩 + "사용 불가" 표시로 안내.
class _PaymentDeadlineNotice extends StatelessWidget {
  final DateTime checkInDate;

  const _PaymentDeadlineNotice({required this.checkInDate});

  @override
  Widget build(BuildContext context) {
    final cleaningDeadline = MoveInDeadlinePolicy.cleaningDeadline(checkInDate);
    final optionDeadline = MoveInDeadlinePolicy.optionDeadline(checkInDate);

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: AppColors.primary500, size: 20),
              SizedBox(width: AppSpacing.xs),
              Text(
                '결제 마감기한 안내',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DeadlineItem(
                  icon: Icons.cleaning_services_outlined,
                  iconColor: AppColors.primary500,
                  title: '청소 서비스',
                  deadline: cleaningDeadline,
                  chipBg: AppColors.primary50,
                  chipFg: AppColors.primary700,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DeadlineItem(
                  icon: Icons.shopping_bag_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                  title: '입주용품/침구류',
                  subtitle: '(임차인 결제)',
                  deadline: optionDeadline,
                  chipBg: const Color(0xFFF3E8FF),
                  chipFg: const Color(0xFF6D28D9),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline,
                  size: 14, color: AppColors.textSecondary),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '결제 마감 기한은 청소 서비스 - 입주일 2일 전, '
                  '입주 용품/침구류 - 입주일 5일 전까지 입니다. '
                  '마감 기한 이후에는 결제 요청 또는 결제가 제한될 수 있습니다.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeadlineItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final DateTime deadline;
  final Color chipBg;
  final Color chipFg;

  const _DeadlineItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.deadline,
    required this.chipBg,
    required this.chipFg,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = deadline.isBefore(DateTime.now());
    final dateText = DateFormat('yyyy.MM.dd (E) HH:mm', 'ko_KR').format(deadline);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text.rich(
                TextSpan(
                  text: title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  children: subtitle == null
                      ? null
                      : [
                          TextSpan(
                            text: ' $subtitle',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: isExpired ? AppColors.neutral100 : chipBg,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            isExpired ? '$dateText · 사용 불가' : '$dateText 까지',
            style: AppTextStyles.bodySmall.copyWith(
              color: isExpired ? AppColors.textSecondary : chipFg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// 외부 노출 결과 객체
class MoveInContractFormResult {
  final String checkInDate;
  final String checkOutDate;
  final String guestName;
  final String guestPhone;
  final String? requestMemo;
  final bool sendGuestPaymentRequest;
  final bool cleaningRequested;

  /// 청소 희망 일자 'YYYY-MM-DD' (cleaningRequested == false 면 null)
  final String? cleaningDate;

  /// 청소 희망 시작 시각 'HH:mm' (30분 단위, 09:00~18:00)
  final String? cleaningTime;

  const MoveInContractFormResult({
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestName,
    required this.guestPhone,
    this.requestMemo,
    required this.sendGuestPaymentRequest,
    required this.cleaningRequested,
    this.cleaningDate,
    this.cleaningTime,
  });
}

class MoveInContractFormController {
  _MoveInContractFormState? _state;

  void _attach(_MoveInContractFormState state) {
    _state = state;
  }

  bool validate() => _state?._validate() ?? false;

  /// 검증 실패 시 사용자에게 보여줄 한글 메시지 (form 자체 메시지 외 추가 검증)
  String? validationMessage() => _state?._validationMessage();

  MoveInContractFormResult? buildResult() {
    if (!validate()) return null;
    return _state?._buildResult();
  }
}
