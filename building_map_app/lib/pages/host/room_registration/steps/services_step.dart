import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../components/form_section.dart';

/// Step 4: 무료 부가 서비스 (리액트 ServicesStep 복제)
class ServicesStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final ValueChanged<Map<String, dynamic>> onFormDataChange;
  final List<String>? validationErrors;

  const ServicesStep({
    super.key,
    required this.formData,
    required this.onFormDataChange,
    this.validationErrors,
  });

  @override
  State<ServicesStep> createState() => _ServicesStepState();
}

class _ServicesStepState extends State<ServicesStep> {
  bool _showServicePasswordKeypad = false;

  // 게스트용 대여/구매 서비스
  static const List<Map<String, String>> _guestServices = [
    {
      'id': 'beddingRentalService',
      'title': '침구류 대여',
      'description': '침대 1set당 (이불+베개+커버)',
    },
    {'id': 'hairDryerRental', 'title': '헤어드라이기 대여', 'description': ''},
    {
      'id': 'amenityKitPurchase',
      'title': '어메니티 키트',
      'description': '샴푸·바디워시(30ml), 폼클렌징(50ml)·비누, 빗, 두루마리 휴지, 티슈',
    },
  ];

  // 호스트 방 관리 서비스
  static const List<Map<String, String>> _hostServices = [
    {
      'id': 'cleaningService',
      'title': '청소 서비스',
      'description':
          '이지스테이에서 게스트 퇴실 이후 부터 다음날 오전내로 청소를 진행합니다.\n기본요금은 5만원이며, 10평마다 2만원이 추가되어 게스트에게 청구됩니다. (예 : 7평 5만원, 15평 7만원, 기존에 설정한 청소비는 게스트에게 이중 부과되지 않습니다.)',
    },
    {
      'id': 'exitInspectionService',
      'title': '도어락 비밀번호 변경 및 퇴실 점검',
      'description':
          '이지스테이에서 게스트 퇴실 여부 및 방 상태(가스, 수도, 소등)를 점검하고 도어락 비밀번호를 임의의 조합으로 변경하여 호스트님께 알려드립니다.',
    },
  ];

  bool get _cleaningService =>
      (widget.formData['cleaningService'] as bool?) ?? false;
  bool get _exitInspectionService =>
      (widget.formData['exitInspectionService'] as bool?) ?? false;
  String get _servicePassword =>
      (widget.formData['servicePassword'] as String?) ?? '';
  String get _area => (widget.formData['area'] as String?) ?? '';
  String get _cleaningFee => (widget.formData['cleaningFee'] as String?) ?? '';

  bool get _needsPasswordInput =>
      _cleaningService || _exitInspectionService;

  void _updateFormData(String key, dynamic value) {
    final updated = Map<String, dynamic>.from(widget.formData);
    updated[key] = value;
    widget.onFormDataChange(updated);
  }

  int _calculateCleaningFee() {
    if (!_cleaningService || _area.isEmpty) return 0;
    final areaValue = double.tryParse(_area) ?? 0;
    final pyeong = areaValue * 0.3025;
    if (pyeong <= 10) return 50000;
    return 50000 + ((pyeong - 10) / 10).ceil() * 20000;
  }

  void _handleCleaningServiceChange(bool enabled) {
    final fee = enabled
        ? _calculateCleaningFee()
        : int.tryParse(_cleaningFee) ?? 0;
    _updateFormData('cleaningService', enabled);
    _updateFormData('cleaningFee', fee.toString());
  }

  void _toggleService(String serviceId) {
    if (serviceId == 'cleaningService') {
      _handleCleaningServiceChange(!_cleaningService);
    } else {
      final currentValue = widget.formData[serviceId] as bool? ?? false;
      _updateFormData(serviceId, !currentValue);
    }
  }

  Widget _buildServiceCard({
    required String serviceId,
    required String title,
    required String description,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _toggleService(serviceId),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary50 : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary600 : AppColors.gray200,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 체크박스
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary600 : Colors.white,
                border: Border.all(
                  color: isSelected ? AppColors.primary600 : AppColors.gray300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            // 제목 및 설명
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 비밀번호 입력 섹션 (토글 없이 바로 표시)
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
                      (digit) => _buildKeypadButton(
                        digit,
                        onTap: () {
                          _updateFormData('servicePassword', password + digit);
                        },
                        height: buttonHeight,
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 12),
          // Control buttons (높이를 숫자 버튼과 동일하게)
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 정보 박스
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              border: Border.all(color: AppColors.primary100),
              borderRadius: AppRadius.radiusLg,
            ),
            child: const Text(
              '💡무료 부가 서비스를 사용하면 방에 직접 가지 않고 관리할 수 있으며, 사용하지 않을 때보다 게스트 예약율이 훨씬 높아져요!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary900,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // 호스트 방 관리 서비스
          FormSection(
            title: '호스트 방 관리 서비스',
            child: Column(
              children: _hostServices.map((service) {
                final serviceId = service['id']!;
                final isSelected =
                    (widget.formData[serviceId] as bool?) ?? false;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildServiceCard(
                    serviceId: serviceId,
                    title: service['title']!,
                    description: service['description']!,
                    isSelected: isSelected,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),

          // 게스트용 대여/구매 서비스
          FormSection(
            title: '게스트용 대여/구매 서비스',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '옵션 선택 시, 게스트는 입주에 필요한 상품을 직접 구매할 수 있어요. 호스트님은 물품을 별도로 제공하지 않아도 됩니다.',
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                ...(_guestServices.map((service) {
                  final serviceId = service['id']!;
                  final isSelected =
                      (widget.formData[serviceId] as bool?) ?? false;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildServiceCard(
                      serviceId: serviceId,
                      title: service['title']!,
                      description: service['description']!,
                      isSelected: isSelected,
                    ),
                  );
                }).toList()),
              ],
            ),
          ),

          // 비밀번호 입력 (호스트 관리 서비스 선택 시에만 표시)
          if (_needsPasswordInput) ...[
            const SizedBox(height: 32),
            FormSection(
              title: '방 비밀번호(도어락)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServicePasswordSection(),
                  const SizedBox(height: 12),
                  const Text(
                    'ⓘ 호스트 방 관리 서비스를 위해 도어락 비밀번호를 입력해주세요.',
                    style: TextStyle(fontSize: 12, color: AppColors.primary600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
