import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/daum_postcode_widget.dart';
import '../components/form_section.dart';

/// Step 1: 기본 정보 (리액트 BasicInfoStep 복제)
class BasicInfoStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final ValueChanged<Map<String, dynamic>> onFormDataChange;
  final List<String> validationErrors;

  const BasicInfoStep({
    super.key,
    required this.formData,
    required this.onFormDataChange,
    this.validationErrors = const [],
  });

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  late TextEditingController _roomNameController;
  late TextEditingController _addressController;
  late TextEditingController _addressDetailController;
  late TextEditingController _floorController;
  late TextEditingController _areaController;
  late TextEditingController _parkingInfoController;

  bool _showEntrancePasswordKeypad = false;

  @override
  void initState() {
    super.initState();
    _roomNameController = TextEditingController(
      text: widget.formData['roomName'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.formData['address'] ?? '',
    );
    _addressDetailController = TextEditingController(
      text: widget.formData['detailAddress'] ?? '',
    );
    _floorController = TextEditingController(
      text: widget.formData['floor'] ?? '',
    );
    _areaController = TextEditingController(
      text: widget.formData['area'] ?? '',
    );
    _parkingInfoController = TextEditingController(
      text: widget.formData['parkingInfo'] ?? '',
    );
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _addressController.dispose();
    _addressDetailController.dispose();
    _floorController.dispose();
    _areaController.dispose();
    _parkingInfoController.dispose();
    super.dispose();
  }

  void _updateFormData(String key, dynamic value) {
    final newData = Map<String, dynamic>.from(widget.formData);
    newData[key] = value;
    widget.onFormDataChange(newData);
  }

  bool _hasError(String keyword) {
    // "상세 주소" 에러 체크 시 "주소"만 있는 에러와 구분
    if (keyword == '주소') {
      return widget.validationErrors.any(
        (error) => error.contains('주소') && !error.contains('상세'),
      );
    }
    return widget.validationErrors.any((error) => error.contains(keyword));
  }

  String _getParkingDisplayValue() {
    final parkingAvailable = widget.formData['parkingAvailable'];
    if (parkingAvailable == null) return '선택';
    return parkingAvailable == true ? '가능' : '불가능';
  }

  String _getElevatorDisplayValue() {
    final elevatorAvailable = widget.formData['elevatorAvailable'];
    if (elevatorAvailable == null) return '선택';
    return elevatorAvailable == true ? '있음' : '없음';
  }

  void _openAddressSearch() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => DaumPostcodeWidget(
          onAddressSelected: (addressData) {
            Navigator.pop(context, addressData);
          },
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      // 서울 지역 제한 검증 (Daum API sido 필드는 축약형: "서울")
      final sido = result['sido'] ?? '';
      if (sido.isNotEmpty && sido != '서울') {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('서비스 지역 안내'),
              content: const Text('현재 서울 지역만 방 등록이 가능합니다.\n서비스 지역은 추후 확대될 예정입니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
        return;
      }

      String fullAddress = '';
      if (result.containsKey('roadAddress') &&
          result['roadAddress']!.isNotEmpty) {
        fullAddress = result['roadAddress']!;
      } else if (result.containsKey('jibunAddress') &&
          result['jibunAddress']!.isNotEmpty) {
        fullAddress = result['jibunAddress']!;
      } else if (result.containsKey('address') &&
          result['address']!.isNotEmpty) {
        fullAddress = result['address']!;
      }

      if (result.containsKey('buildingName') &&
          result['buildingName']!.isNotEmpty) {
        fullAddress += ' (${result['buildingName']!})';
      }

      setState(() {
        _addressController.text = fullAddress;
      });
      _updateFormData('address', fullAddress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 방 이름
          FormSection(
            title: '방 이름',
            child: TextField(
              controller: _roomNameController,
              onChanged: (value) => _updateFormData('roomName', value),
              decoration: InputDecoration(
                hintText: '예: 강남역 도보 5분 깨끗한 원룸',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _hasError('방 이름')
                        ? AppColors.error500
                        : AppColors.gray300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _hasError('방 이름')
                        ? AppColors.error500
                        : AppColors.gray300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _hasError('방 이름')
                        ? AppColors.error500
                        : AppColors.primary600,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: _hasError('방 이름') ? AppColors.error50 : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 주소
          FormSection(
            title: '주소',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addressController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: '주소 찾기를 통해 입력해주세요',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _hasError('주소')
                                  ? AppColors.error500
                                  : AppColors.gray300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _hasError('주소')
                                  ? AppColors.error500
                                  : AppColors.gray300,
                            ),
                          ),
                          filled: true,
                          fillColor: _hasError('주소')
                              ? AppColors.error50
                              : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _openAddressSearch,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.gray300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '주소 찾기',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressDetailController,
                  onChanged: (value) => _updateFormData('detailAddress', value),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: '상세주소를 입력해주세요. (예: 3층, 2호, 2동 3호 등)',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError('상세 주소')
                            ? AppColors.error500
                            : AppColors.gray300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError('상세 주소')
                            ? AppColors.error500
                            : AppColors.gray300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError('상세 주소')
                            ? AppColors.error500
                            : AppColors.primary600,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: _hasError('상세 주소')
                        ? AppColors.error50
                        : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _floorController,
                  onChanged: (value) => _updateFormData('floor', value),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '층 수',
                    hintText: '예: 3',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError('층 수')
                            ? AppColors.error500
                            : AppColors.gray300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError('층 수')
                            ? AppColors.error500
                            : AppColors.gray300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError('층 수')
                            ? AppColors.error500
                            : AppColors.primary600,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: _hasError('층 수')
                        ? AppColors.error50
                        : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ⓘ 상세주소는 입주 당일 임차인에게 공개됩니다.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.primary600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 방 정보
          FormSection(
            title: '방 정보',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: '건물 유형',
                        value: widget.formData['buildingType'] ?? '선택',
                        items: ['선택', '오피스텔', '원룸', '빌라', '주택', '아파트', '고시원'],
                        onChanged: (value) =>
                            _updateFormData('buildingType', value),
                        hasError: _hasError('건물 유형'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildAreaField()),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: '방 개수',
                        value: (widget.formData['roomCount'] ?? 1).toString(),
                        items: List.generate(10, (i) => (i + 1).toString()),
                        onChanged: (value) =>
                            _updateFormData('roomCount', int.parse(value)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        label: '화장실 개수',
                        value: (widget.formData['bathroomCount'] ?? 1)
                            .toString(),
                        items: List.generate(5, (i) => (i + 1).toString()),
                        onChanged: (value) =>
                            _updateFormData('bathroomCount', int.parse(value)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 복층 구조
                Row(
                  children: [
                    Checkbox(
                      value: widget.formData['isDuplex'] ?? false,
                      onChanged: (value) =>
                          _updateFormData('isDuplex', value ?? false),
                    ),
                    const Text(
                      '복층 구조',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '*방이 2개 층으로 나뉘어져 있는 경우 체크해주세요',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: '주차 여부',
                        value: _getParkingDisplayValue(),
                        items: ['선택', '가능', '불가능'],
                        onChanged: (value) {
                          _updateFormData('parkingAvailable', value == '가능');
                          if (value != '가능') {
                            _updateFormData('parkingInfo', '');
                            _parkingInfoController.clear();
                          }
                        },
                        hasError: _hasError('주차 여부'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        label: '엘리베이터',
                        value: _getElevatorDisplayValue(),
                        items: ['선택', '있음', '없음'],
                        onChanged: (value) =>
                            _updateFormData('elevatorAvailable', value == '있음'),
                        hasError: _hasError('엘리베이터'),
                      ),
                    ),
                  ],
                ),
                if (_getParkingDisplayValue() == '가능') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _parkingInfoController,
                    decoration: InputDecoration(
                      labelText: '주차 상세 정보 (선택사항)',
                      hintText: '예: 건물 지하 1층, 주차 가능 대수 등',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                    onChanged: (value) => _updateFormData('parkingInfo', value),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 공동현관 비밀번호
          FormSection(
            title: '공동현관 비밀번호',
            child: _buildEntrancePasswordSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    bool hasError = false,
  }) {
    // ✅ value가 items에 없으면 첫 번째 항목으로 설정
    final safeValue = items.contains(value) ? value : items.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: safeValue,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? AppColors.error500 : AppColors.gray300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? AppColors.error500 : AppColors.gray300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? AppColors.error500 : AppColors.primary600,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: hasError ? AppColors.error50 : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
      ],
    );
  }

  Widget _buildAreaField() {
    // formData['area']는 평수로 저장
    final areaValue = widget.formData['area'] ?? '';

    // 초기값 설정
    if (areaValue.isNotEmpty && _areaController.text.isEmpty) {
      _areaController.text = areaValue;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '전용 면적 (평)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _areaController,
          onChanged: (value) {
            // 평수 그대로 저장
            _updateFormData('area', value);
          },
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '예: 10',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _hasError('전용 면적')
                    ? AppColors.error500
                    : AppColors.gray300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _hasError('전용 면적')
                    ? AppColors.error500
                    : AppColors.gray300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _hasError('전용 면적')
                    ? AppColors.error500
                    : AppColors.primary600,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: _hasError('전용 면적') ? AppColors.error50 : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEntrancePasswordSection() {
    final password = widget.formData['entrancePassword'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '공동현관 비밀번호 유무',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                label: '없음',
                selected: password.isEmpty,
                onTap: () {
                  _updateFormData('entrancePassword', '');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildToggleButton(
                label: '있음',
                selected: password.isNotEmpty,
                onTap: () {
                  // 비밀번호가 비어있으면 공백 문자를 저장해서 UI를 표시
                  _updateFormData(
                    'entrancePassword',
                    password.isEmpty ? ' ' : password,
                  );
                },
              ),
            ),
          ],
        ),
        if (password.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildPasswordInput(password),
        ],
      ],
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary50 : Colors.white,
          border: Border.all(
            color: selected ? AppColors.primary600 : AppColors.gray200,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary900 : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordInput(String password) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showEntrancePasswordKeypad = !_showEntrancePasswordKeypad;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _hasError('공동현관 비밀번호') ? AppColors.error50 : Colors.white,
              border: Border.all(
                color: _hasError('공동현관 비밀번호')
                    ? AppColors.error500
                    : AppColors.gray300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              password.isEmpty ? '비밀번호를 입력하세요' : password,
              style: TextStyle(
                fontSize: 14,
                color: password.isEmpty
                    ? (_hasError('공동현관 비밀번호')
                          ? AppColors.error500
                          : Colors.grey[400])
                    : Colors.black,
              ),
            ),
          ),
        ),
        if (_showEntrancePasswordKeypad) ...[
          const SizedBox(height: 16),
          _buildKeypad(password),
        ],
      ],
    );
  }

  Widget _buildKeypad(String password) {
    const double buttonHeight = 48.0; // 모든 버튼의 통일된 높이

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Icon buttons
          Row(
            children: [
              Expanded(
                child: _buildKeypadButton(
                  '🔑',
                  onTap: () {
                    _updateFormData('entrancePassword', '$password🔑');
                  },
                  fontSize: 32,
                  height: buttonHeight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKeypadButton(
                  '🔔',
                  onTap: () {
                    _updateFormData('entrancePassword', '$password🔔');
                  },
                  fontSize: 32,
                  height: buttonHeight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKeypadButton(
                  '🛡',
                  onTap: () {
                    _updateFormData('entrancePassword', '$password🛡');
                  },
                  fontSize: 32,
                  height: buttonHeight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Number buttons
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
                      (num) => _buildKeypadButton(
                        num,
                        onTap: () {
                          _updateFormData('entrancePassword', password + num);
                        },
                        height: buttonHeight,
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 12),
          // Control buttons (높이를 아이콘/숫자 버튼과 동일하게)
          SizedBox(
            height: buttonHeight,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _updateFormData('entrancePassword', '');
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
                          'entrancePassword',
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
                        _showEntrancePasswordKeypad = false;
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
}
