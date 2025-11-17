import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../components/form_section.dart';
import '../components/option_toggle.dart';

/// Step 3: 요금 설정 (리액트 PricingStep 복제)
class PricingStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final ValueChanged<Map<String, dynamic>> onFormDataChange;
  final List<String>? validationErrors;

  const PricingStep({
    super.key,
    required this.formData,
    required this.onFormDataChange,
    this.validationErrors,
  });

  @override
  State<PricingStep> createState() => _PricingStepState();
}

class _PricingStepState extends State<PricingStep> {
  final NumberFormat _numberFormat = NumberFormat('#,###', 'ko_KR');

  // TextEditingController 선언
  late final TextEditingController _dailyRentController;
  late final TextEditingController _dailyMaintenanceController;
  late final TextEditingController _maintenanceDescriptionController;
  late final TextEditingController _cleaningFeeController;
  late final TextEditingController _longTermDiscountPercentController;
  late final TextEditingController _earlyCheckInDiscountAmountController;

  // FocusNode 선언
  late final FocusNode _dailyRentFocus;
  late final FocusNode _dailyMaintenanceFocus;
  late final FocusNode _cleaningFeeFocus;
  late final FocusNode _longTermDiscountPercentFocus;
  late final FocusNode _earlyCheckInDiscountAmountFocus;

  // 관리비 포함 항목
  static const List<String> _maintenanceOptions = ['수도세', '전기세', '가스비', '인터넷'];

  // 환불 규정 옵션
  static const List<Map<String, String>> _refundPolicies = [
    {'value': '', 'label': '선택'},
    {'value': '약하게', 'label': '약하게'},
    {'value': '보통', 'label': '보통'},
    {'value': '엄격하게', 'label': '엄격하게'},
  ];

  // 환불 규정 상세 내용
  static const Map<String, List<String>> _refundPolicyDetails = {
    '약하게': [
      '• 입주일 15일 이전 : 임대료의 100% 환불',
      '• 입주일 14일 ~ 8일 이전 : 임대료의 80% 환불',
      '• 입주일 7일 ~ 1일 이전 : 임대료의 60% 환불',
      '• 입주일 당일 : 환불 불가',
      '',
      '계약 당일 취소는 환불 규정에 상관없이 임대료의 90%가 환불됩니다.',
      '청소비와 관리비는 100% 환불됩니다.',
    ],
    '보통': [
      '• 입주일 20일 이전 : 임대료의 100% 환불',
      '• 입주일 19일 ~ 10일 이전 : 임대료의 70% 환불',
      '• 입주일 9일 ~ 1일 이전 : 임대료의 50% 환불',
      '• 입주일 당일 : 환불 불가',
      '',
      '계약 당일 취소는 환불 규정에 상관없이 임대료의 90%가 환불됩니다.',
      '청소비와 관리비는 100% 환불됩니다.',
    ],
    '엄격하게': [
      '• 입주일 30일 이전 : 임대료의 100% 환불',
      '• 입주일 29일 ~ 15일 이전 : 임대료의 50% 환불',
      '• 입주일 14일 이내 : 환불 불가',
      '',
      '계약 당일 취소는 환불 규정에 상관없이 임대료의 90%가 환불됩니다.',
      '청소비와 관리비는 100% 환불됩니다.',
    ],
  };

  String get _dailyRent => (widget.formData['dailyRent'] as String?) ?? '';

  // 주간 임대료는 일일 임대료 * 7로 자동 계산
  String get _weeklyRent {
    if (_dailyRent.isEmpty) return '0';
    final dailyValue = int.tryParse(_dailyRent) ?? 0;
    return (dailyValue * 7).toString();
  }

  String get _deposit => '300000'; // 고정값

  String get _dailyMaintenanceFee =>
      (widget.formData['dailyMaintenanceFee'] as String?) ?? '';

  // 주간 관리비는 일일 관리비 * 7로 자동 계산
  String get _weeklyMaintenanceFee {
    if (_dailyMaintenanceFee.isEmpty) return '0';
    final dailyValue = int.tryParse(_dailyMaintenanceFee) ?? 0;
    return (dailyValue * 7).toString();
  }

  String get _maintenanceDescription =>
      (widget.formData['maintenanceDescription'] as String?) ?? '';
  String get _cleaningFee => (widget.formData['cleaningFee'] as String?) ?? '';
  String get _minContractPeriod =>
      (widget.formData['minContractPeriod'] as String?) ?? '1주';
  String get _refundPolicy =>
      (widget.formData['refundPolicy'] as String?) ?? '';
  String get _longTermDiscountWeeks =>
      (widget.formData['longTermDiscountWeeks'] as String?) ?? '0';
  String get _longTermDiscountPercent =>
      (widget.formData['longTermDiscountPercent'] as String?) ?? '';
  String get _earlyCheckInDiscountDays =>
      (widget.formData['earlyCheckInDiscountDays'] as String?) ?? '0';
  String get _earlyCheckInDiscountAmount =>
      (widget.formData['earlyCheckInDiscountAmount'] as String?) ?? '';

  List<String> get _maintenanceInclusions =>
      (widget.formData['maintenanceInclusions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
      [];

  @override
  void initState() {
    super.initState();

    // TextEditingController 초기화
    _dailyRentController = TextEditingController(
      text: _formatNumberWithCommas(_dailyRent),
    );
    _dailyMaintenanceController = TextEditingController(
      text: _formatNumberWithCommas(_dailyMaintenanceFee),
    );
    _maintenanceDescriptionController = TextEditingController(
      text: _maintenanceDescription,
    );
    _cleaningFeeController = TextEditingController(
      text: _formatNumberWithCommas(_cleaningFee),
    );
    _longTermDiscountPercentController = TextEditingController(
      text: _longTermDiscountPercent,
    );
    _earlyCheckInDiscountAmountController = TextEditingController(
      text: _formatNumberWithCommas(_earlyCheckInDiscountAmount),
    );

    // FocusNode 초기화
    _dailyRentFocus = FocusNode();
    _dailyMaintenanceFocus = FocusNode();
    _cleaningFeeFocus = FocusNode();
    _longTermDiscountPercentFocus = FocusNode();
    _earlyCheckInDiscountAmountFocus = FocusNode();

    // FocusNode listener 추가 (포커스 벗어날 때 천원 단위 반올림)
    _dailyRentFocus.addListener(() {
      if (!_dailyRentFocus.hasFocus) {
        _handleDailyRentBlur();
      }
    });

    _dailyMaintenanceFocus.addListener(() {
      if (!_dailyMaintenanceFocus.hasFocus) {
        _handleDailyMaintenanceBlur();
      }
    });

    _cleaningFeeFocus.addListener(() {
      if (!_cleaningFeeFocus.hasFocus) {
        _handleCleaningFeeBlur();
      }
    });
  }

  @override
  void didUpdateWidget(PricingStep oldWidget) {
    super.didUpdateWidget(oldWidget);

    // formData가 변경되었을 때만 컨트롤러 업데이트 (포커스 없을 때만)
    if (!_dailyRentFocus.hasFocus) {
      final newText = _formatNumberWithCommas(_dailyRent);
      if (_dailyRentController.text != newText) {
        _dailyRentController.text = newText;
      }
    }
    if (!_dailyMaintenanceFocus.hasFocus) {
      final newText = _formatNumberWithCommas(_dailyMaintenanceFee);
      if (_dailyMaintenanceController.text != newText) {
        _dailyMaintenanceController.text = newText;
      }
    }
    if (_maintenanceDescriptionController.text != _maintenanceDescription) {
      _maintenanceDescriptionController.text = _maintenanceDescription;
    }
    if (!_cleaningFeeFocus.hasFocus) {
      final newText = _formatNumberWithCommas(_cleaningFee);
      if (_cleaningFeeController.text != newText) {
        _cleaningFeeController.text = newText;
      }
    }
    if (!_longTermDiscountPercentFocus.hasFocus) {
      if (_longTermDiscountPercentController.text != _longTermDiscountPercent) {
        _longTermDiscountPercentController.text = _longTermDiscountPercent;
      }
    }
    if (!_earlyCheckInDiscountAmountFocus.hasFocus) {
      final newText = _formatNumberWithCommas(_earlyCheckInDiscountAmount);
      if (_earlyCheckInDiscountAmountController.text != newText) {
        _earlyCheckInDiscountAmountController.text = newText;
      }
    }
  }

  @override
  void dispose() {
    // TextEditingController 해제
    _dailyRentController.dispose();
    _dailyMaintenanceController.dispose();
    _maintenanceDescriptionController.dispose();
    _cleaningFeeController.dispose();
    _longTermDiscountPercentController.dispose();
    _earlyCheckInDiscountAmountController.dispose();

    // FocusNode 해제
    _dailyRentFocus.dispose();
    _dailyMaintenanceFocus.dispose();
    _cleaningFeeFocus.dispose();
    _longTermDiscountPercentFocus.dispose();
    _earlyCheckInDiscountAmountFocus.dispose();

    super.dispose();
  }

  void _updateFormData(String key, dynamic value) {
    final updated = Map<String, dynamic>.from(widget.formData);
    updated[key] = value;
    widget.onFormDataChange(updated);
  }

  String _formatNumberWithCommas(String value) {
    if (value.isEmpty) return '';
    final number = int.tryParse(value.replaceAll(',', ''));
    if (number == null) return '';
    return _numberFormat.format(number);
  }

  void _handleDailyRentChange(String value) {
    final number = value.replaceAll(RegExp(r'[^0-9]'), '');
    _updateFormData('dailyRent', number);

    // 실시간 콤마 포맷팅 적용
    if (number.isNotEmpty) {
      final formatted = _formatNumberWithCommas(number);
      _dailyRentController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _handleDailyRentBlur() {
    if (_dailyRent.isNotEmpty) {
      final value = int.tryParse(_dailyRent) ?? 0;
      final rounded = (value / 1000).round() * 1000;

      _updateFormData('dailyRent', rounded.toString());
    }
  }

  void _handleDailyMaintenanceChange(String value) {
    final number = value.replaceAll(RegExp(r'[^0-9]'), '');
    _updateFormData('dailyMaintenanceFee', number);

    // 실시간 콤마 포맷팅 적용
    if (number.isNotEmpty) {
      final formatted = _formatNumberWithCommas(number);
      _dailyMaintenanceController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _handleDailyMaintenanceBlur() {
    if (_dailyMaintenanceFee.isNotEmpty) {
      final value = int.tryParse(_dailyMaintenanceFee) ?? 0;
      final rounded = (value / 1000).round() * 1000;

      _updateFormData('dailyMaintenanceFee', rounded.toString());
    }
  }

  void _handleCleaningFeeChange(String value) {
    final number = value.replaceAll(RegExp(r'[^0-9]'), '');
    _updateFormData('cleaningFee', number);

    // 실시간 콤마 포맷팅 적용
    if (number.isNotEmpty) {
      final formatted = _formatNumberWithCommas(number);
      _cleaningFeeController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _handleCleaningFeeBlur() {
    if (_cleaningFee.isNotEmpty) {
      final value = int.tryParse(_cleaningFee) ?? 0;
      final rounded = (value / 1000).round() * 1000;
      _updateFormData('cleaningFee', rounded.toString());
    }
  }

  void _toggleMaintenanceInclusion(String item) {
    final updated = List<String>.from(_maintenanceInclusions);
    if (updated.contains(item)) {
      updated.remove(item);
    } else {
      updated.add(item);
    }
    _updateFormData('maintenanceInclusions', updated);
  }

  bool _hasError(String field) {
    if (widget.validationErrors == null) return false;
    const errorMessages = {
      'dailyRent': '임대료를 입력해주세요',
      'dailyMaintenanceFee': '관리비를 입력해주세요',
      'cleaningFee': '청소비를 입력해주세요',
      'refundPolicy': '환불 규정을 선택해주세요',
    };
    return widget.validationErrors!.contains(errorMessages[field]);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 임대료
          FormSection(
            title: '임대료',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1일 임대료',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _dailyRentController,
                  focusNode: _dailyRentFocus,
                  onChanged: _handleDailyRentChange,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '예: 40,000',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    suffixText:
                        _dailyRent.isNotEmpty &&
                            int.tryParse(_dailyRent) != null &&
                            int.parse(_dailyRent) > 0
                        ? '원/일'
                        : null,
                    suffixStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: _hasError('dailyRent')
                        ? AppColors.error50
                        : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError('dailyRent')
                            ? AppColors.error500
                            : AppColors.gray300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError('dailyRent')
                            ? AppColors.error500
                            : AppColors.gray300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError('dailyRent')
                            ? AppColors.error500
                            : AppColors.primary600,
                        width: 2,
                      ),
                    ),
                  ),
                  onEditingComplete: _handleDailyRentBlur,
                ),
                if (_dailyRent.isNotEmpty &&
                    int.tryParse(_dailyRent) != null &&
                    int.parse(_dailyRent) > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '1주 임대료: ${_formatNumberWithCommas(_weeklyRent)}원',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                const Text(
                  '* 최소 천원 단위로 입력할 수 있습니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_hasError('dailyRent'))
                  const Text(
                    '임대료를 입력해주세요',
                    style: TextStyle(fontSize: 12, color: AppColors.error600),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 관리비
          FormSection(
            title: '관리비',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1일 관리비
                const Text(
                  '1일 관리비 (선택)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _dailyMaintenanceController,
                  focusNode: _dailyMaintenanceFocus,
                  onChanged: _handleDailyMaintenanceChange,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '예: 7,000',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    suffixText:
                        _dailyMaintenanceFee.isNotEmpty &&
                            int.tryParse(_dailyMaintenanceFee) != null &&
                            int.parse(_dailyMaintenanceFee) > 0
                        ? '원/일'
                        : null,
                    suffixStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: _hasError('dailyMaintenanceFee')
                        ? AppColors.error50
                        : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError('dailyMaintenanceFee')
                            ? AppColors.error500
                            : AppColors.gray300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError('dailyMaintenanceFee')
                            ? AppColors.error500
                            : AppColors.gray300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError('dailyMaintenanceFee')
                            ? AppColors.error500
                            : AppColors.primary600,
                        width: 2,
                      ),
                    ),
                  ),
                  onEditingComplete: _handleDailyMaintenanceBlur,
                ),
                if (_dailyMaintenanceFee.isNotEmpty &&
                    int.tryParse(_dailyMaintenanceFee) != null &&
                    int.parse(_dailyMaintenanceFee) > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '1주 관리비: ${_formatNumberWithCommas(_weeklyMaintenanceFee)}원',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                const Text(
                  '* 최소 천원 단위로 입력할 수 있습니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_hasError('dailyMaintenanceFee'))
                  const Text(
                    '관리비를 입력해주세요',
                    style: TextStyle(fontSize: 12, color: AppColors.error600),
                  ),
                const SizedBox(height: 16),

                // 관리비 포함 항목
                const Text(
                  '관리비 포함 항목(해당되는 항목 선택)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _maintenanceOptions.map((item) {
                    return OptionToggle(
                      label: item,
                      selected: _maintenanceInclusions.contains(item),
                      onToggle: () => _toggleMaintenanceInclusion(item),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 관리비 설명
                const Text(
                  '관리비 설명 (선택)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _maintenanceDescriptionController,
                  onChanged: (value) =>
                      _updateFormData('maintenanceDescription', value),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '관리비에 대한 추가 설명을 입력해주세요',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.gray300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.gray300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary600,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 청소비
          FormSection(
            title: '청소비 (선택)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _cleaningFeeController,
                  focusNode: _cleaningFeeFocus,
                  onChanged: _handleCleaningFeeChange,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '예: 50,000',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    suffixText: '원',
                    suffixStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: _hasError('cleaningFee')
                        ? AppColors.error50
                        : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError('cleaningFee')
                            ? AppColors.error500
                            : AppColors.gray300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError('cleaningFee')
                            ? AppColors.error500
                            : AppColors.gray300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError('cleaningFee')
                            ? AppColors.error500
                            : AppColors.primary600,
                        width: 2,
                      ),
                    ),
                  ),
                  onEditingComplete: _handleCleaningFeeBlur,
                ),
                const SizedBox(height: 8),
                const Text(
                  '* 최소 천원 단위로 입력할 수 있습니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // 보증금 (고정)
          FormSection(
            title: '보증금',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    border: Border.all(color: AppColors.gray200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // 왼쪽 아이콘
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary600,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: AppColors.primary600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 금액 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_formatNumberWithCommas(_deposit)}원',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '보증금은 30만원으로 고정되어 있습니다',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '* 보증금은 퇴실 후 시설 훼손 완료 시 영업일 기준 7일 이내에 자동 환불됩니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // 최소 계약 기간
          FormSection(
            title: '최소 계약 기간',
            child: DropdownButtonFormField<String>(
              initialValue:
                  ['1주', '2주', '3주', '4주'].contains(_minContractPeriod)
                  ? _minContractPeriod
                  : '1주',
              items: ['1주', '2주', '3주', '4주']
                  .map(
                    (period) =>
                        DropdownMenuItem(value: period, child: Text(period)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _updateFormData('minContractPeriod', value);
                }
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.gray300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.gray300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.primary600,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // 환불 규정
          FormSection(
            title: '환불 규정',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue:
                      _refundPolicies.any((p) => p['value'] == _refundPolicy)
                      ? _refundPolicy
                      : '',
                  items: _refundPolicies
                      .map(
                        (policy) => DropdownMenuItem(
                          value: policy['value'],
                          child: Text(policy['label']!),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _updateFormData('refundPolicy', value);
                    }
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.gray300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.gray300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary600,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                if (_refundPolicy.isNotEmpty &&
                    _refundPolicyDetails.containsKey(_refundPolicy)) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      border: Border.all(color: AppColors.gray200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _refundPolicyDetails[_refundPolicy]!
                          .map(
                            (line) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                line,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                if (_hasError('refundPolicy'))
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '환불 규정을 선택해주세요',
                      style: TextStyle(fontSize: 12, color: AppColors.error600),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 장기계약할인
          FormSection(
            title: '장기계약할인 (선택)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DropdownButton<String>(
                      value:
                          [
                            '0',
                            '2',
                            '3',
                            '4',
                            '5',
                            '6',
                            '7',
                            '8',
                            '9',
                            '10',
                            '11',
                            '12',
                          ].contains(_longTermDiscountWeeks)
                          ? _longTermDiscountWeeks
                          : '0',
                      items:
                          [
                                '0',
                                '2',
                                '3',
                                '4',
                                '5',
                                '6',
                                '7',
                                '8',
                                '9',
                                '10',
                                '11',
                                '12',
                              ]
                              .map(
                                (week) => DropdownMenuItem(
                                  value: week,
                                  child: Text('$week주'),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _updateFormData('longTermDiscountWeeks', value);
                        }
                      },
                      underline: Container(),
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                    const Text('이상 계약 시'),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _longTermDiscountPercentController,
                        focusNode: _longTermDiscountPercentFocus,
                        onChanged: (value) {
                          final number = value.replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          );
                          final numValue = int.tryParse(number) ?? 0;
                          if (numValue >= 0 && numValue <= 100) {
                            _updateFormData('longTermDiscountPercent', number);
                          }
                        },
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '0',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.gray300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.gray300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.primary600,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Text('% 할인'),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '* 장기 계약 시 임대료 할인을 제공할 수 있습니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 빠른입주할인
          FormSection(
            title: '빠른입주할인 (선택)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DropdownButton<String>(
                      value:
                          [
                            '0',
                            'today',
                            '1',
                            '2',
                            '3',
                            '4',
                            '5',
                            '6',
                            '7',
                          ].contains(_earlyCheckInDiscountDays)
                          ? _earlyCheckInDiscountDays
                          : '0',
                      items:
                          [
                                {'value': '0', 'label': '0일'},
                                {'value': 'today', 'label': '오늘입주'},
                                {'value': '1', 'label': '1일'},
                                {'value': '2', 'label': '2일'},
                                {'value': '3', 'label': '3일'},
                                {'value': '4', 'label': '4일'},
                                {'value': '5', 'label': '5일'},
                                {'value': '6', 'label': '6일'},
                                {'value': '7', 'label': '7일'},
                              ]
                              .map(
                                (day) => DropdownMenuItem(
                                  value: day['value'],
                                  child: Text(day['label']!),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _updateFormData('earlyCheckInDiscountDays', value);
                        }
                      },
                      underline: Container(),
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                    const Text('이내 입주 시'),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _earlyCheckInDiscountAmountController,
                        focusNode: _earlyCheckInDiscountAmountFocus,
                        onChanged: (value) {
                          final number = value.replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          );
                          _updateFormData('earlyCheckInDiscountAmount', number);

                          // 실시간 콤마 포맷팅 적용
                          if (number.isNotEmpty) {
                            final formatted = _formatNumberWithCommas(number);
                            _earlyCheckInDiscountAmountController.value =
                                TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(
                                    offset: formatted.length,
                                  ),
                                );
                          }
                        },
                        onEditingComplete: () {
                          if (_earlyCheckInDiscountAmount.isNotEmpty) {
                            final value =
                                int.tryParse(_earlyCheckInDiscountAmount) ?? 0;
                            final rounded = (value / 10000).round() * 10000;
                            _updateFormData(
                              'earlyCheckInDiscountAmount',
                              rounded.toString(),
                            );
                          }
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.gray300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.gray300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.primary600,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Text('원 할인'),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '* 빠른 입주 시 고정 금액 할인을 제공할 수 있습니다 (만원 단위로 자동 조정됩니다)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
