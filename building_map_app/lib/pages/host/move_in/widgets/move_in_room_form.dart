import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/move_in/move_in.dart';
import '../../../../widgets/common/custom_text_field.dart';
import '../../../../widgets/daum_postcode_widget.dart';

/// 간편 방 정보 폼 — PRD 5.4 / 가이드 4.1 / 이미지 ② 우측 탭
///
/// 사용처:
/// 1. **새 주소로 간편 등록 탭** — `initialRoom: null`, `roomName` 옵션 외 13필드 입력
/// 2. **방 정보 편집 모달 (탭 1)** — `initialRoom` 전달 시 기존 값으로 채워짐
///
/// 외부에서 [MoveInRoomFormController] 로 검증 + request 빌드를 트리거.
class MoveInRoomForm extends StatefulWidget {
  final MoveInRoom? initialRoom;
  final MoveInRoomFormController controller;

  const MoveInRoomForm({
    super.key,
    required this.controller,
    this.initialRoom,
  });

  @override
  State<MoveInRoomForm> createState() => _MoveInRoomFormState();
}

class _MoveInRoomFormState extends State<MoveInRoomForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _addressCtrl;
  late TextEditingController _detailAddressCtrl;
  late TextEditingController _areaCtrl;
  late TextEditingController _livingRoomCtrl;
  late TextEditingController _roomCountCtrl;
  late TextEditingController _bathroomCtrl;
  late TextEditingController _commonPwCtrl;
  late TextEditingController _doorPwCtrl;
  late TextEditingController _suppliesLocationCtrl;
  late TextEditingController _memoCtrl;

  int _bedCount = 0;
  List<BedSize> _bedSizes = [];
  bool _cleaningSuppliesAvailable = true;

  static const _digitsOnly = TextInputType.number;

  @override
  void initState() {
    super.initState();
    final r = widget.initialRoom;
    _addressCtrl = TextEditingController(text: r?.address ?? '');
    _detailAddressCtrl = TextEditingController(text: r?.detailAddress ?? '');
    _areaCtrl = TextEditingController(text: r?.areaPyeong.toString() ?? '');
    _livingRoomCtrl = TextEditingController(text: r?.livingRoomCount.toString() ?? '');
    _roomCountCtrl = TextEditingController(text: r?.roomCount.toString() ?? '');
    _bathroomCtrl = TextEditingController(text: r?.bathroomCount.toString() ?? '');
    _commonPwCtrl = TextEditingController(text: r?.commonEntrancePassword ?? '');
    _doorPwCtrl = TextEditingController(text: r?.doorLockPassword ?? '');
    _suppliesLocationCtrl = TextEditingController(text: r?.cleaningSuppliesLocation ?? '');
    _memoCtrl = TextEditingController(text: r?.memo ?? '');

    _bedCount = r?.bedCount ?? 0;
    _bedSizes = r?.beds.map((b) => b.size).toList() ?? <BedSize>[];
    _cleaningSuppliesAvailable = r?.cleaningSuppliesAvailable ?? true;

    widget.controller._attach(this);
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _detailAddressCtrl.dispose();
    _areaCtrl.dispose();
    _livingRoomCtrl.dispose();
    _roomCountCtrl.dispose();
    _bathroomCtrl.dispose();
    _commonPwCtrl.dispose();
    _doorPwCtrl.dispose();
    _suppliesLocationCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  /// Daum 우편번호 위젯 호출.
  ///
  /// 웹 버전은 oncomplete 직후 자동으로 onclose도 호출 → 위젯이 자체적으로 1번 pop.
  /// 따라서 콜백에서 추가로 pop을 호출하면 입주준비 등록 페이지까지 닫혀
  /// 메인 탭(`/host/move-in`)으로 빠져버린다.
  /// → pop은 Daum 위젯에 위임하고, 결과는 외부 변수에 저장.
  ///
  /// 호스트 방 등록과 동일 정책 — 서울 지역만 등록 가능.
  /// Daum API sido 필드는 축약형 '서울'.
  Future<void> _openAddressSearch() async {
    Map<String, String>? captured;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DaumPostcodeWidget(
          onAddressSelected: (data) {
            captured = data;
            // pop은 호출하지 않음 — Daum 위젯의 onclose가 처리
          },
        ),
      ),
    );
    if (!mounted || captured == null || captured!.isEmpty) return;

    final result = captured!;

    // 서울 지역 제한 — 비서울이면 즉시 안내 + 주소 미반영
    final sido = result['sido'] ?? '';
    if (sido.isNotEmpty && sido != '서울') {
      await showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('서비스 지역 안내'),
          content: const Text(
            '현재 서울 지역만 방 등록이 가능합니다.\n서비스 지역은 추후 확대될 예정입니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }

    final road = result['roadAddress'] ?? '';
    final jibun = result['jibunAddress'] ?? '';
    final raw = result['address'] ?? '';
    var fullAddress = road.isNotEmpty ? road : (jibun.isNotEmpty ? jibun : raw);

    final building = result['buildingName'] ?? '';
    if (building.isNotEmpty) fullAddress = '$fullAddress ($building)';

    setState(() => _addressCtrl.text = fullAddress);
  }

  void _onBedCountChanged(String value) {
    final count = int.tryParse(value) ?? 0;
    setState(() {
      _bedCount = count;
      // 기존 사이즈 보존 + 부족분 SINGLE로 채움
      if (count > _bedSizes.length) {
        _bedSizes = [..._bedSizes, ...List.filled(count - _bedSizes.length, BedSize.single)];
      } else if (count < _bedSizes.length) {
        _bedSizes = _bedSizes.sublist(0, count);
      }
    });
  }

  bool _validate() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return false;
    if (_bedCount > 0 && _bedSizes.length != _bedCount) return false;
    if (_cleaningSuppliesAvailable && _suppliesLocationCtrl.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  MoveInRoomRequest _buildRequest() {
    return MoveInRoomRequest(
      address: _addressCtrl.text.trim(),
      detailAddress: _detailAddressCtrl.text.trim(),
      areaPyeong: num.tryParse(_areaCtrl.text) ?? 0,
      livingRoomCount: int.tryParse(_livingRoomCtrl.text) ?? 0,
      roomCount: int.tryParse(_roomCountCtrl.text) ?? 0,
      bathroomCount: int.tryParse(_bathroomCtrl.text) ?? 0,
      bedCount: _bedCount,
      beds: List.generate(
        _bedCount,
        (i) => BedInfo(index: i + 1, size: _bedSizes[i]),
      ),
      commonEntrancePassword:
          _commonPwCtrl.text.trim().isEmpty ? null : _commonPwCtrl.text.trim(),
      doorLockPassword:
          _doorPwCtrl.text.trim().isEmpty ? null : _doorPwCtrl.text.trim(),
      cleaningSuppliesAvailable: _cleaningSuppliesAvailable,
      cleaningSuppliesLocation: _cleaningSuppliesAvailable
          ? _suppliesLocationCtrl.text.trim()
          : null,
      memo: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('주소', [
            _AddressSearchField(
              controller: _addressCtrl,
              onSearchTap: _openAddressSearch,
              validator: _addressValidator,
            ),
            SizedBox(height: AppSpacing.sm),
            CustomTextField(
              label: '상세 주소',
              hint: '동/호수 등',
              controller: _detailAddressCtrl,
              validator: _required('상세 주소'),
            ),
          ]),
          _section('구조 정보', [
            Row(
              children: [
                Expanded(child: CustomTextField(
                  label: '평수',
                  controller: _areaCtrl,
                  keyboardType: _digitsOnly,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _positiveNumber('평수'),
                )),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: CustomTextField(
                  label: '거실 수',
                  controller: _livingRoomCtrl,
                  keyboardType: _digitsOnly,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _nonNegativeInt('거실 수'),
                )),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: CustomTextField(
                  label: '방 수',
                  controller: _roomCountCtrl,
                  keyboardType: _digitsOnly,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _positiveInt('방 수'),
                )),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: CustomTextField(
                  label: '화장실 수',
                  controller: _bathroomCtrl,
                  keyboardType: _digitsOnly,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _positiveInt('화장실 수'),
                )),
              ],
            ),
          ]),
          _section('침대 정보', [
            CustomTextField(
              label: '침대 수',
              hint: '침대 개수를 입력하면 사이즈 입력 필드가 자동 생성됩니다.',
              initialValue: _bedCount > 0 ? '$_bedCount' : '',
              keyboardType: _digitsOnly,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: _onBedCountChanged,
              validator: _nonNegativeInt('침대 수'),
            ),
            if (_bedCount > 0) ...[
              SizedBox(height: AppSpacing.sm),
              for (var i = 0; i < _bedCount; i++) ...[
                if (i > 0) SizedBox(height: AppSpacing.xs),
                _BedSizeRow(
                  index: i + 1,
                  selected: _bedSizes[i],
                  onChanged: (size) => setState(() => _bedSizes[i] = size),
                ),
              ],
            ],
          ]),
          _section('보안 / 출입 정보', [
            CustomTextField(
              label: '공동현관 비밀번호 (선택)',
              controller: _commonPwCtrl,
            ),
            SizedBox(height: AppSpacing.sm),
            CustomTextField(
              label: '도어락 비밀번호',
              controller: _doorPwCtrl,
              validator: _required('도어락 비밀번호'),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              '도어락 비밀번호는 필수입니다. 열쇠로만 출입하는 집은 청소 서비스를 제공할 수 없습니다.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ]),
          _section('청소용품 구비 여부', [
            DropdownButtonFormField<bool>(
              initialValue: _cleaningSuppliesAvailable,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: true, child: Text('구비함')),
                DropdownMenuItem(value: false, child: Text('구비 안 함')),
              ],
              onChanged: (v) => setState(() => _cleaningSuppliesAvailable = v ?? true),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              '청소 서비스 이용을 위한 구비 항목: 청소기, 고무장갑, 걸레 및 청소 도구, 쓰레기봉투',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            if (_cleaningSuppliesAvailable) ...[
              SizedBox(height: AppSpacing.sm),
              CustomTextField(
                label: '청소용품 위치',
                hint: '예: 현관 수납장 하단',
                controller: _suppliesLocationCtrl,
                validator: (v) {
                  if (!_cleaningSuppliesAvailable) return null;
                  if (v == null || v.trim().isEmpty) {
                    return '청소용품 위치를 입력해주세요.';
                  }
                  return null;
                },
              ),
            ],
          ]),
          _section('비고 (선택)', [
            CustomTextField(
              label: '메모',
              controller: _memoCtrl,
              maxLines: 3,
            ),
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

  String? Function(String?) _required(String label) {
    return (v) => (v == null || v.trim().isEmpty) ? '$label을(를) 입력해주세요.' : null;
  }

  /// 주소 검증 — 필수 + 서울 지역만 허용 (기존 호스트 방 등록 정책과 동일)
  String? _addressValidator(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return '주소을(를) 입력해주세요.';
    if (!value.startsWith('서울')) return '현재 서울 지역만 방 등록이 가능합니다.';
    return null;
  }

  String? Function(String?) _positiveNumber(String label) {
    return (v) {
      if (v == null || v.trim().isEmpty) return '$label을(를) 입력해주세요.';
      final n = num.tryParse(v);
      if (n == null || n <= 0) return '$label은 0보다 커야 합니다.';
      return null;
    };
  }

  String? Function(String?) _positiveInt(String label) {
    return (v) {
      if (v == null || v.trim().isEmpty) return '$label을(를) 입력해주세요.';
      final n = int.tryParse(v);
      if (n == null || n <= 0) return '$label은 0보다 커야 합니다.';
      return null;
    };
  }

  String? Function(String?) _nonNegativeInt(String label) {
    return (v) {
      if (v == null || v.trim().isEmpty) return '$label을(를) 입력해주세요.';
      final n = int.tryParse(v);
      if (n == null || n < 0) return '$label은 0 이상이어야 합니다.';
      return null;
    };
  }
}

class _BedSizeRow extends StatelessWidget {
  final int index;
  final BedSize selected;
  final ValueChanged<BedSize> onChanged;

  const _BedSizeRow({
    required this.index,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text('침대 $index', style: AppTextStyles.bodySmall),
        ),
        Expanded(
          child: DropdownButtonFormField<BedSize>(
            initialValue: selected,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
              isDense: true,
            ),
            items: BedSize.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}

/// 주소 검색 필드 — read-only TextFormField + 우측 "주소 검색" 버튼
///
/// 호스트 방 등록의 BasicInfoStep과 동일한 UX. 직접 타이핑은 막고
/// 반드시 Daum 우편번호 검색을 거치도록 강제 (오타 방지).
class _AddressSearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearchTap;
  final String? Function(String?) validator;

  const _AddressSearchField({
    required this.controller,
    required this.onSearchTap,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            readOnly: true,
            onTap: onSearchTap,
            validator: validator,
            decoration: InputDecoration(
              labelText: '주소',
              hintText: '주소 검색 버튼을 눌러 입력',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
              prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
            ),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: onSearchTap,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('주소 검색'),
          ),
        ),
      ],
    );
  }
}

/// 외부 컨트롤러 — 부모 위젯에서 [validate], [buildRequest] 호출용
class MoveInRoomFormController {
  _MoveInRoomFormState? _state;

  void _attach(_MoveInRoomFormState state) {
    _state = state;
  }

  bool validate() => _state?._validate() ?? false;

  MoveInRoomRequest? buildRequest() {
    if (!validate()) return null;
    return _state?._buildRequest();
  }
}
