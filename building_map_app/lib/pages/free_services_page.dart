import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../widgets/registration_flow_indicator.dart';
import 'dart:io';

/// 무료 부가 서비스 페이지
class FreeServicesPage extends StatefulWidget {
  const FreeServicesPage({super.key});

  @override
  State<FreeServicesPage> createState() => _FreeServicesPageState();
}

class _FreeServicesPageState extends State<FreeServicesPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _passwordController = TextEditingController();

  // 섹션1: 확인 동의
  bool _agreeTerms = false;

  // 섹션2: 안심 청소
  bool _cleaningService = false;
  XFile? _cleaningToolImage;

  // 섹션3: 헤어 드라이기 대여
  bool _hairDryerRental = false;

  // 섹션4: 침구류 대여 서비스
  bool _beddingService = false;
  final Map<String, int> _bedSizes = {
    '슈퍼싱글': 0,
    '퀸': 0,
    '킹': 0,
  };

  // 섹션5: 비밀번호 자동 변경
  bool _autoPasswordChange = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickCleaningToolImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _cleaningToolImage = image;
      });
    }
  }

  void _removeCleaningToolImage() {
    setState(() {
      _cleaningToolImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('무료 부가 서비스'),
        backgroundColor: const Color(0xFF4DB5BD),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const RegistrationFlowIndicator(currentStep: 3),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // 섹션1: 확인 동의
                  _buildConfirmationSection(),
                  const SizedBox(height: 24),

                  // 섹션2: 안심 청소
                  _buildSectionTitle('안심 청소'),
                  _buildCleaningCard(),
                  const SizedBox(height: 24),

                  // 섹션3: 헤어 드라이기 대여
                  _buildSectionTitle('헤어 드라이기 대여 (게스트가 입주 시 필요하면 결제)'),
                  _buildHairDryerCard(),
                  const SizedBox(height: 24),

                  // 섹션4: 침구류 대여 서비스
                  _buildSectionTitle('침구류 대여 서비스 (게스트가 입주 시 필요하면 결제)'),
                  _buildBeddingCard(),
                  const SizedBox(height: 24),

                  // 섹션5: 어메니티 키트
                  _buildSectionTitle('어메니티 키트 (게스트가 입주 시 필요하면 결제)'),
                  _buildAmenityKitCard(),
                  const SizedBox(height: 24),

                  // 섹션6: 비밀번호 자동 변경
                  _buildSectionTitle('비밀번호 자동 변경'),
                  _buildPasswordCard(),
                  const SizedBox(height: 24),

                  // 섹션7: 방 비밀번호 (비밀번호 자동 변경 사용 시 노출)
                  if (_autoPasswordChange) ...[
                    _buildSectionTitle('방 비밀번호'),
                    _buildRoomPasswordCard(),
                    const SizedBox(height: 24),
                  ],

                        // 하단 버튼
                        _buildBottomButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _agreeTerms,
              onChanged: (value) {
                setState(() => _agreeTerms = value!);
              },
              activeColor: const Color(0xFF4DB5BD),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2C3E50),
                      height: 1.6,
                    ),
                    children: [
                      const TextSpan(
                        text: '무료 부가 서비스는 방문이 필요한 서비스이므로 이지스테이에서만 예약을 받는 방일 경우 이용하실 수 있습니다.\n',
                      ),
                      TextSpan(
                        text: '해당 방을 타 플랫폼에서도 예약받고 계실 경우, 혼선이 발생할 수 있어 무료 부가 서비스 제공을 할 수 없습니다.',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleaningCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _buildCleaningSection(),
      ),
    );
  }

  Widget _buildCleaningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _cleaningService,
              onChanged: (value) {
                setState(() => _cleaningService = value!);
              },
              activeColor: const Color(0xFF4DB5BD),
            ),
            const Text(
              '사용',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(width: 24),
            Checkbox(
              value: !_cleaningService,
              onChanged: (value) {
                setState(() => _cleaningService = !value!);
              },
              activeColor: const Color(0xFF4DB5BD),
            ),
            const Text(
              '미사용',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 청소 도구 위치 사진
        if (_cleaningToolImage != null)
          Stack(
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb
                      ? Image.network(
                          _cleaningToolImage!.path,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(_cleaningToolImage!.path),
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: _removeCleaningToolImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: _pickCleaningToolImage,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, width: 2),
                color: Colors.grey[50],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+ 사진첨부',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '청소 도구를 놓아둔 장소를 알려주세요',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        _buildBlueInfoBox([
          '• 청소 도구는 방에 계속 구비해두셔야 청소가 가능합니다.',
          '  필수 항목 : \'청소기\',\'막대걸레\',\'청소포\' ,\'고무장갑\',\'걸레\',\'세제\',\'종량제 봉투 10L\'',
          '• 계약 체결 시 50,000원이 포함되어 게스트에게 청구됩니다.',
          '• 사용 시, 요금 설정의 퇴실 청소비는 자동으로 설정 해제됩니다.',
          '• 퇴실 후 당일~다음 날 오전 내에 자동으로 청소를 진행하고, 등록된 매물에 청결 뱃지가 부여됩니다.',
        ]),
      ],
    );
  }

  Widget _buildHairDryerCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _buildHairDryerSection(),
      ),
    );
  }

  Widget _buildHairDryerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _hairDryerRental,
              onChanged: (value) {
                setState(() => _hairDryerRental = value!);
              },
              activeColor: const Color(0xFF4DB5BD),
            ),
            const Text(
              '사용',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(width: 24),
            Checkbox(
              value: !_hairDryerRental,
              onChanged: (value) {
                setState(() => _hairDryerRental = !value!);
              },
              activeColor: const Color(0xFF4DB5BD),
            ),
            const Text(
              '미사용',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBeddingCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _buildBeddingSection(),
      ),
    );
  }

  Widget _buildBeddingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _beddingService,
              onChanged: (value) {
                setState(() => _beddingService = value!);
              },
              activeColor: const Color(0xFF4DB5BD),
            ),
            const Text(
              '사용',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(width: 24),
            Checkbox(
              value: !_beddingService,
              onChanged: (value) {
                setState(() => _beddingService = !value!);
              },
              activeColor: const Color(0xFF4DB5BD),
            ),
            const Text(
              '미사용',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 방 침대 사이즈
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '방 침대 사이즈',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              ..._bedSizes.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (entry.value > 0) {
                            setState(() {
                              _bedSizes[entry.key] = entry.value - 1;
                            });
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFF4A90E2),
                      ),
                      Container(
                        width: 50,
                        alignment: Alignment.center,
                        child: Text(
                          '${entry.value}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _bedSizes[entry.key] = entry.value + 1;
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFF4A90E2),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildBlueInfoBox([
          '• 게스트는 계약 시 호스트님의 방 침대 사이즈에 적절한 침구류(매트리스 커버, 베개, 이불 1set)를 대여할 수 있습니다.',
          '• 게스트 입주 전에 침구류를 세팅해드리며, 퇴실 후 세탁을 위해 직접 수거해갑니다.',
          '• 호스트님의 침구류는 수거가 불가능합니다.',
        ]),
      ],
    );
  }

  Widget _buildAmenityKitCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _buildAmenityKitSection(),
      ),
    );
  }

  Widget _buildAmenityKitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: false,
              onChanged: (value) {},
              activeColor: const Color(0xFF4DB5BD),
            ),
            const Text(
              '사용',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(width: 24),
            Checkbox(
              value: true,
              onChanged: (value) {},
              activeColor: const Color(0xFF4DB5BD),
            ),
            const Text(
              '미사용',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildBlueInfoBox([
          '• 게스트는 계약 시 생활에 필요한 물품들이 포함된 어메니티 키트를 함께 구매할 수 있습니다.',
          '• 이지스테이의 어메니티 키트는 폼클렌징, 샴푸, 바디워시, 비누, 빗 으로 구성되어 있습니다.',
        ]),
      ],
    );
  }

  Widget _buildPasswordCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _buildPasswordSection(),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _autoPasswordChange,
              onChanged: (value) {
                setState(() => _autoPasswordChange = value!);
              },
              activeColor: const Color(0xFF4DB5BD),
            ),
            const Text(
              '사용',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(width: 24),
            Checkbox(
              value: !_autoPasswordChange,
              onChanged: (value) {
                setState(() => _autoPasswordChange = !value!);
              },
              activeColor: const Color(0xFF4DB5BD),
            ),
            const Text(
              '미사용',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildBlueInfoBox([
          '• 안전한 비밀번호 관리를 위해 게스트 퇴실 후 집 비밀번호를 임의의 조합으로 변경 및 설정하여 호스트님께 전달드립니다.',
        ]),
      ],
    );
  }

  Widget _buildRoomPasswordCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _buildRoomPasswordSection(),
      ),
    );
  }

  Widget _buildRoomPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: '방 비밀번호를 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                // 저장 로직
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('비밀번호가 저장되었습니다')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '저장하기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildBlueInfoBox([
          '• 안심 청소, 침구류 대여, 키트, 비밀번호 변경 서비스를 위해서만 사용되며, 이외의 목적으로 사용하거나 공개되지 않습니다.',
          '• 추가로 호스트님은 게스트에게 보낼 자동 안내 메시지 기능에서 활용할 수도 있습니다.',
        ]),
      ],
    );
  }

  Widget _buildBlueInfoBox(List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[900],
                height: 1.6,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 250,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              context.go('/host/amenities');
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF4A90E2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '이전으로',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A90E2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 250,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              if (!_agreeTerms) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('이용 약관에 동의해주세요')),
                );
                return;
              }

              if (_formKey.currentState!.validate()) {
                // TODO: 저장 로직
                context.go('/host/room-description');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              '저장 후 다음',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
