import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import '../../../../constants/fee_constants.dart';
import '../../../../utils/format_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/refund_policy.dart';
import '../../../../services/refund_policy_service.dart';
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
  final RefundPolicyService _refundPolicyService = RefundPolicyService();

  // TextEditingController 선언
  late final TextEditingController _dailyRentController;
  late final TextEditingController _dailyMaintenanceController;
  late final TextEditingController _maintenanceDescriptionController;
  late final TextEditingController _cleaningFeeController;
  late final TextEditingController _longTermDiscountPercentController;
  late final TextEditingController _earlyCheckInDiscountAmountController;
  late final TextEditingController _minContractDaysController;

  // FocusNode 선언
  late final FocusNode _dailyRentFocus;
  late final FocusNode _dailyMaintenanceFocus;
  late final FocusNode _cleaningFeeFocus;
  late final FocusNode _longTermDiscountPercentFocus;
  late final FocusNode _earlyCheckInDiscountAmountFocus;

  // 청소 서비스 비밀번호 키패드 표시 여부
  bool _showServicePasswordKeypad = false;

  // 관리비 포함 항목
  static const List<String> _maintenanceOptions = ['수도세', '전기세', '가스비', '인터넷'];

  // 환불 정책 상태
  List<RefundPolicy> _refundPolicies = [];
  bool _isLoadingPolicies = false;
  String? _policyLoadError;

  String get _dailyRent => widget.formData['dailyRent']?.toString() ?? '';

  // 주간 임대료는 일일 임대료 * 7로 자동 계산
  String get _weeklyRent {
    if (_dailyRent.isEmpty) return '0';
    final dailyValue = int.tryParse(_dailyRent) ?? 0;
    return (dailyValue * 7).toString();
  }

  String get _deposit => FeeConstants.depositAmount.toString();

  String get _dailyMaintenanceFee =>
      widget.formData['dailyMaintenanceFee']?.toString() ?? '';

  // 주간 관리비는 일일 관리비 * 7로 자동 계산
  String get _weeklyMaintenanceFee {
    if (_dailyMaintenanceFee.isEmpty) return '0';
    final dailyValue = int.tryParse(_dailyMaintenanceFee) ?? 0;
    return (dailyValue * 7).toString();
  }

  String get _maintenanceDescription =>
      widget.formData['maintenanceDescription']?.toString() ?? '';
  String get _cleaningFee => widget.formData['cleaningFee']?.toString() ?? '';
  String get _minContractDays =>
      widget.formData['minContractDays']?.toString() ?? '7';
  String get _refundPolicy =>
      widget.formData['refundPolicy']?.toString() ?? '';
  String get _longTermDiscountWeeks =>
      widget.formData['longTermDiscountWeeks']?.toString() ?? '0';
  String get _longTermDiscountPercent =>
      widget.formData['longTermDiscountPercent']?.toString() ?? '';
  String get _earlyCheckInDiscountDays =>
      widget.formData['earlyCheckInDiscountDays']?.toString() ?? '0';
  String get _earlyCheckInDiscountAmount =>
      widget.formData['earlyCheckInDiscountAmount']?.toString() ?? '';

  List<String> get _maintenanceInclusions =>
      (widget.formData['maintenanceInclusions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
      [];

  // 청소 서비스 관련 getter
  bool get _cleaningService =>
      (widget.formData['cleaningService'] as bool?) ?? false;
  String get _servicePassword =>
      (widget.formData['servicePassword'] as String?) ?? '';
  String get _area => (widget.formData['area'] as String?) ?? '';

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
    _minContractDaysController = TextEditingController(
      text: _minContractDays,
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

    // 환불 정책 로드
    _loadRefundPolicies();
  }

  /// 환불 정책 목록을 API에서 로드
  Future<void> _loadRefundPolicies() async {
    setState(() {
      _isLoadingPolicies = true;
      _policyLoadError = null;
    });

    try {
      final policies = await _refundPolicyService.getRefundPolicies();
      setState(() {
        _refundPolicies = policies;
        _isLoadingPolicies = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPolicies = false;
        _policyLoadError = '환불 정책을 불러오는데 실패했습니다: $e';
      });
      AppLogger.e('❌ [PRICING_STEP] Failed to load refund policies: $e');
    }
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
    _minContractDaysController.dispose();

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
    return FormatUtils.formatCurrency(number);
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

  // 청소 서비스 자동 청소비 계산 (면적 기반)
  int _calculateCleaningFee() {
    if (!_cleaningService || _area.isEmpty) return 0;
    final areaValue = double.tryParse(_area) ?? 0;
    final pyeong = areaValue * 0.3025;
    if (pyeong <= 10) return 50000;
    return 50000 + ((pyeong - 10) / 10).ceil() * 20000;
  }

  void _handleCleaningServiceChange(bool enabled) {
    if (enabled) {
      final fee = _calculateCleaningFee();
      _updateFormData('cleaningService', true);
      _updateFormData('cleaningFee', fee.toString());
      _cleaningFeeController.text = _formatNumberWithCommas(fee.toString());
    } else {
      _updateFormData('cleaningService', false);
    }
  }

  void _showCleaningServiceConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary600, size: 24),
            const SizedBox(width: 8),
            const Text('청소 서비스 안내'),
          ],
        ),
        titleTextStyle: AppTextStyles.headingSmall.copyWith(
          fontSize: 18,
          color: AppColors.textPrimary,
        ),
        content: const Text(
          '청소 서비스 선택 시, 호스트님은 청소비를 설정 및 정산받을 수 없습니다.',
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '취소',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleCleaningServiceChange(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('확인', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 비밀번호 입력 섹션
  Widget _buildServicePasswordSection() {
    final password = _servicePassword;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showServicePasswordKeypad = !_showServicePasswordKeypad;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.gray300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              password.isEmpty ? '비밀번호를 입력하세요' : password,
              style: TextStyle(
                fontSize: 14,
                color: password.isEmpty ? Colors.grey[400] : Colors.black,
              ),
            ),
          ),
        ),
        if (_showServicePasswordKeypad) ...[
          const SizedBox(height: 16),
          _buildKeypad(password),
        ],
      ],
    );
  }

  Widget _buildKeypad(String password) {
    const double buttonHeight = 48.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.5,
            physics: const NeverScrollableScrollPhysics(),
            children:
                ['1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#']
                    .map(
                      (digit) => _buildKeypadButton(
                        digit,
                        onTap: () {
                          _updateFormData(
                              'servicePassword', password + digit);
                        },
                        height: buttonHeight,
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: buttonHeight,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _updateFormData('servicePassword', '');
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.error50,
                      side: const BorderSide(color: AppColors.error500),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      '전체 삭제',
                      style: TextStyle(
                        color: AppColors.error600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (password.isNotEmpty) {
                        _updateFormData(
                          'servicePassword',
                          password.substring(0, password.length - 1),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.gray300),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      '삭제',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showServicePasswordKeypad = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      '완료',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(
    String label, {
    required VoidCallback onTap,
    double fontSize = 16,
    double? height,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.gray300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
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
                  Text(
                    '임대료를 입력해주세요',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.error600),
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
                  Text(
                    '관리비를 입력해주세요',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.error600),
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
            title: '청소비',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _cleaningFeeController,
                  focusNode: _cleaningFeeFocus,
                  onChanged: _handleCleaningFeeChange,
                  keyboardType: TextInputType.number,
                  enabled: !_cleaningService,
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
                    fillColor: _cleaningService
                        ? AppColors.gray50
                        : _hasError('cleaningFee')
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
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.gray300),
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
                const SizedBox(height: 16),

                // 이지스테이 청소 서비스 체크박스
                InkWell(
                  onTap: () {
                    if (!_cleaningService) {
                      _showCleaningServiceConfirmDialog();
                    } else {
                      _handleCleaningServiceChange(false);
                    }
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: _cleaningService
                              ? AppColors.primary600
                              : Colors.white,
                          border: Border.all(
                            color: _cleaningService
                                ? AppColors.primary600
                                : AppColors.gray300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: _cleaningService
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '이지스테이 청소 서비스 사용',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _cleaningService
                                  ? '* 이지스테이에서 게스트 퇴실 이후 부터 다음날 오전까지(부득이한 사정으로 인해 지연 시 사전 안내 예정) 청소를 진행합니다.\n  기본요금은 5만원이며, 10평마다 2만원이 추가되어 게스트에게 청구됩니다. (예 : 7평 5만원, 15평 7만원, 기존에 설정한 청소비는 게스트에게 이중 부과되지 않습니다.)'
                                  : '* 이지스테이에서 게스트 퇴실 이후 부터 다음날 오전까지(부득이한 사정으로 인해 지연 시 사전 안내 예정) 청소를 진행합니다.\n  기본요금은 5만원, 등록된 방 평수 기준으로 10평마다 2만원이 추가되어 게스트에게 청구되며 해당 요금은 정산받을 수 없습니다. (예 : 7평 5만원, 15평 7만원)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 청소 서비스 선택 시 방 비밀번호(도어락) 입력
                if (_cleaningService) ...[
                  const SizedBox(height: 24),
                  const Text(
                    '방 비밀번호(도어락)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildServicePasswordSection(),
                  const SizedBox(height: 8),
                  Text(
                    '* 청소 서비스 진행을 위해 도어락 비밀번호를 입력해주세요. 비밀번호가 불일치할 경우 청소 일정에 불이익이 발생할 수 있습니다.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
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
                            Text(
                              '보증금은 ${_formatNumberWithCommas(_deposit)}원으로 고정되어 있습니다',
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
            child: TextField(
              controller: _minContractDaysController,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final number = value.replaceAll(RegExp(r'[^0-9]'), '');
                _updateFormData('minContractDays', number);
              },
              decoration: InputDecoration(
                hintText: '7 ~ 90',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                suffixText: '일',
                suffixStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                helperText: '최소 7일, 최대 90일까지 설정 가능합니다',
                helperStyle: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
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
                // 로딩 중
                if (_isLoadingPolicies)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                // 에러 발생
                else if (_policyLoadError != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error50,
                      border: Border.all(color: AppColors.error500),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _policyLoadError!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.error600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadRefundPolicies,
                          child: const Text('재시도'),
                        ),
                      ],
                    ),
                  )
                // 정상 로드됨
                else ...[
                  DropdownButtonFormField<String>(
                    initialValue:
                        _refundPolicies.any(
                          (p) => p.policyType == _refundPolicy,
                        )
                        ? _refundPolicy
                        : null,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('선택')),
                      ..._refundPolicies.map(
                        (policy) => DropdownMenuItem(
                          value: policy.policyType,
                          child: Text(policy.displayName),
                        ),
                      ),
                    ],
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
                  // 선택된 정책의 상세 내용 표시
                  if (_refundPolicy.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final selectedPolicy = _refundPolicies.firstWhere(
                          (p) => p.policyType == _refundPolicy,
                          orElse: () => _refundPolicies.first,
                        );

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.gray50,
                            border: Border.all(color: AppColors.gray200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 정책 설명
                              if (selectedPolicy.description.isNotEmpty) ...[
                                Text(
                                  selectedPolicy.description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              // 환불 규칙
                              ...selectedPolicy.rules.map(
                                (rule) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '• ${rule.period} : 임대료의 ${rule.refundRate}% 환불',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              // 특별 규칙
                              if (selectedPolicy.specialRules?.alwaysRefund !=
                                  null) ...[
                                const SizedBox(height: 8),
                                const Divider(color: AppColors.gray300),
                                const SizedBox(height: 8),
                                Text(
                                  selectedPolicy.specialRules!.alwaysRefund!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
                if (_hasError('refundPolicy'))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '환불 규정을 선택해주세요',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.error600),
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
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.black),
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
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.black),
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
