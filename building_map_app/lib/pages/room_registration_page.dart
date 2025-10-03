import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/daum_postcode_widget.dart';
import '../widgets/registration_flow_indicator.dart';

/// 호스트 전용 방 등록 페이지
class RoomRegistrationPage extends StatefulWidget {
  const RoomRegistrationPage({super.key});

  @override
  State<RoomRegistrationPage> createState() => _RoomRegistrationPageState();
}

class _RoomRegistrationPageState extends State<RoomRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // 폼 컨트롤러들
  final _roomNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _detailAddressController = TextEditingController();
  final _areaController = TextEditingController();
  final _parkingInfoController = TextEditingController();
  final _roomCountController = TextEditingController();
  final _bathroomCountController = TextEditingController();
  final _livingRoomCountController = TextEditingController();
  final _kitchenCountController = TextEditingController();

  // 셀렉트 박스 값들
  String _SelectDefault = '선택';
  String _buildingType = '오피스텔';
  String _parkingAvailable = '가능';
  String _elevatorAvailable = '있음';
  String _floor = '1층';
  int _roomCount = 1;
  int _bathroomCount = 1;
  int _livingRoomCount = 0;
  int _kitchenCount = 0;

  // 체크박스 값
  bool _isDuplex = false;

  // 공통 현관 비밀번호
  String _entrancePassword = '';
  bool _useEntrancePassword = false;

  @override
  void dispose() {
    _roomNameController.dispose();
    _addressController.dispose();
    _detailAddressController.dispose();
    _areaController.dispose();
    _parkingInfoController.dispose();
    _roomCountController.dispose();
    _bathroomCountController.dispose();
    _livingRoomCountController.dispose();
    _kitchenCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('방 등록하기'),
        backgroundColor: const Color(0xFF4DB5BD),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          const RegistrationFlowIndicator(currentStep: 0),
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
              // 기본 정보 섹션
              _buildSectionTitle('기본 정보'),
              _buildBasicInfoSection(),

              const SizedBox(height: 24),

              // 건물 정보 섹션
              _buildSectionTitle('건물 정보'),
              _buildBuildingInfoSection(),

              const SizedBox(height: 24),

              // 구조 정보 섹션
              _buildSectionTitle('구조 정보'),
              _buildStructureInfoSection(),

              const SizedBox(height: 32),

              // 공통 현관 비밀번호 섹션
              _buildSectionTitle('공통 현관 비밀번호'),
              _buildEntrancePasswordSection(),

              const SizedBox(height: 32),

              // 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 이전으로 버튼
                  SizedBox(
                    width: 250,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
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
                  // 저장 후 다음으로 버튼
                  SizedBox(
                    width: 250,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '저장 후 다음으로',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
      padding: const EdgeInsets.only(bottom: 16.0),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 방이름
            _buildFieldLabel('방이름'),
            const SizedBox(height: 8),
            SizedBox(
              width: 400,
              child: TextFormField(
              controller: _roomNameController,
              decoration: InputDecoration(
                hintText: '방 이름을 입력해 주세요. (최대 12자)',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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
                  borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '방 이름을 입력해주세요';
                }
                return null;
              },
              ),
            ),

            const SizedBox(height: 20),

            // 주소
            _buildFieldLabel('주소'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _addressController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: '도로명 주소를 입력해 주세요.',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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
                        borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '주소를 입력해주세요';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _openAddressSearch,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(
                      '주소 찾기',
                      style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 지번주소 입력
            TextFormField(
              controller: _detailAddressController,
              decoration: InputDecoration(
                hintText: '지번주소 입력해 주세요.',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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
                  borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 12),

            // 상세주소 입력
            TextFormField(
              decoration: InputDecoration(
                hintText: '상세주소 입력해 주세요. 예) 302호, 2층 전체 사용',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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
                  borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 20),

            // 면적
            _buildFieldLabel('면적 (㎡)'),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: TextFormField(
                controller: _areaController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '예) 84.5',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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
                    borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '면적을 입력해주세요';
                  }
                  if (double.tryParse(value) == null) {
                    return '올바른 숫자를 입력해주세요';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 20),

            // 층
            _buildFieldLabel('층'),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                value: _floor,
                decoration: InputDecoration(
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
                  borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: [
                const DropdownMenuItem(value: '지하', child: Text('지하')),
                const DropdownMenuItem(value: '반지하', child: Text('반지하')),
                ...List.generate(100, (index) => index + 1)
                    .map((floor) => DropdownMenuItem(
                          value: '${floor}층',
                          child: Text('${floor}층'),
                        ))
                    .toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _floor = value!;
                });
              },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF2C3E50),
      ),
    );
  }

  Widget _buildBuildingInfoSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 건물유형
            _buildFieldLabel('건물유형'),
            const SizedBox(height: 8),
            SizedBox(
              width: 300,
              child: DropdownButtonFormField<String>(
                value: _SelectDefault,
                decoration: InputDecoration(
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
                  borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: ['선택','오피스텔', '아파트', '단독주택', '기타']
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _buildingType = value!;
                });
              },
              ),
            ),

            const SizedBox(height: 20),

            // 주차여부
            _buildFieldLabel('주차 가능 여부'),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
              value: _SelectDefault,
              decoration: InputDecoration(
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
                  borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: ['선택','가능', '불가능']
                  .map((option) => DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _parkingAvailable = value!;
                });
              },
              ),
            ),

            const SizedBox(height: 20),

            // 주차 정보 (선택사항)
            _buildFieldLabel('주차 정보 (선택)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _parkingInfoController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '주차와 관련된 안내를 입력해 주세요. (예: 최대 2대, 선착순)',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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
                  borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 20),

            // 엘리베이터
            _buildFieldLabel('엘리베이터'),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                value: _SelectDefault,
                decoration: InputDecoration(
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
                  borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: ['선택','있음', '없음']
                  .map((option) => DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _elevatorAvailable = value!;
                });
              },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStructureInfoSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 구조 정보 안내
            Text(
              '게스트가 이용하는 공간 내에서 입력해주세요.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            // 방 수 & 화장실 수
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('방 수'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _roomCount,
                        decoration: InputDecoration(
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
                            borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: List.generate(10, (index) => index)
                            .map((count) => DropdownMenuItem(
                                  value: count,
                                  child: Text(count.toString()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _roomCount = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('화장실 수'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _bathroomCount,
                        decoration: InputDecoration(
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
                            borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: List.generate(10, (index) => index)
                            .map((count) => DropdownMenuItem(
                                  value: count,
                                  child: Text(count.toString()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _bathroomCount = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 거실 수 & 주방 수
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('거실 수'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _livingRoomCount,
                        decoration: InputDecoration(
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
                            borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: List.generate(10, (index) => index)
                            .map((count) => DropdownMenuItem(
                                  value: count,
                                  child: Text(count.toString()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _livingRoomCount = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('주방 수'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _kitchenCount,
                        decoration: InputDecoration(
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
                            borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: List.generate(10, (index) => index)
                            .map((count) => DropdownMenuItem(
                                  value: count,
                                  child: Text(count.toString()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _kitchenCount = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 복층 구조
            Row(
              children: [
                Checkbox(
                  value: _isDuplex,
                  onChanged: (value) {
                    setState(() {
                      _isDuplex = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF4A90E2),
                ),
                const Text(
                  '복층 구조',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openAddressSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DaumPostcodeWidget(
          onAddressSelected: (addressData) {
            if (addressData.containsKey('action') && addressData['action'] == 'close') {
              // 사용자가 주소 선택 없이 창을 닫은 경우
              return;
            }

            // 선택된 주소 정보를 텍스트 필드에 설정
            String fullAddress = '';
            if (addressData.containsKey('roadAddress') && addressData['roadAddress']!.isNotEmpty) {
              // 도로명 주소가 있는 경우 우선 사용
              fullAddress = addressData['roadAddress']!;
            } else if (addressData.containsKey('jibunAddress') && addressData['jibunAddress']!.isNotEmpty) {
              // 지번 주소 사용
              fullAddress = addressData['jibunAddress']!;
            } else if (addressData.containsKey('address') && addressData['address']!.isNotEmpty) {
              // 기본 주소 사용
              fullAddress = addressData['address']!;
            }

            // 건물명이 있는 경우 추가
            if (addressData.containsKey('buildingName') && addressData['buildingName']!.isNotEmpty) {
              fullAddress += ' (${addressData['buildingName']!})';
            }

            setState(() {
              _addressController.text = fullAddress;
            });



            // 디버그용 - 선택된 주소 데이터 출력
            debugPrint('선택된 주소 데이터: $addressData');
          },
        ),
      ),
    );
  }

  // 공통 현관 비밀번호 섹션
  Widget _buildEntrancePasswordSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildFieldLabel('건물 공통현관 비밀번호'),
                const SizedBox(width: 8),
                Checkbox(
                  value: !_useEntrancePassword,
                  onChanged: (value) {
                    setState(() {
                      _useEntrancePassword = !value!;
                      if (!_useEntrancePassword) {
                        _entrancePassword = '';
                      }
                    });
                  },
                ),
                Text(
                  '없어요',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_useEntrancePassword)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 입력된 비밀번호 표시
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        _entrancePassword.isEmpty ? '비밀번호를 입력하세요' : _entrancePassword,
                        style: TextStyle(
                          fontSize: 16,
                          color: _entrancePassword.isEmpty ? Colors.grey[400] : Colors.black,
                          letterSpacing: _entrancePassword.isEmpty ? 0 : 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 숫자 패드
                    _buildPasswordKeypad(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 공통 현관 비밀번호 입력 키패드 위젯
  Widget _buildPasswordKeypad() {
    return Column(
      children: [
        // 첫 번째 줄: 🔑, 🔔, 👮, *, #, 1, 2, 3
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildKeypadButton('🔑', isSpecial: true),
            _buildKeypadButton('🔔', isSpecial: true),
            _buildKeypadButton('👮', isSpecial: true),
            _buildKeypadButton('*'),
            _buildKeypadButton('#'),
            _buildKeypadButton('1'),
            _buildKeypadButton('2'),
            _buildKeypadButton('3'),
          ],
        ),
        const SizedBox(height: 8),
        // 두 번째 줄: 4, 5, 6, 7, 8, 9, 0, X
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildKeypadButton('4'),
            _buildKeypadButton('5'),
            _buildKeypadButton('6'),
            _buildKeypadButton('7'),
            _buildKeypadButton('8'),
            _buildKeypadButton('9'),
            _buildKeypadButton('0'),
            _buildKeypadButton('X', isDelete: true),
          ],
        ),
      ],
    );
  }

  // 키패드 버튼 위젯
  Widget _buildKeypadButton(String value, {bool isSpecial = false, bool isDelete = false}) {
    Color backgroundColor;
    Color textColor = Colors.black;

    if (isDelete) {
      backgroundColor = Colors.grey[400]!;
      textColor = Colors.white;
    } else if (isSpecial) {
      backgroundColor = const Color(0xFFB3E5FC); // 연한 파란색
    } else {
      backgroundColor = const Color(0xFFB3E5FC); // 연한 파란색
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          onTap: () {
            setState(() {
              if (isDelete) {
                if (_entrancePassword.isNotEmpty) {
                  _entrancePassword = _entrancePassword.substring(0, _entrancePassword.length - 1);
                }
              } else {
                _entrancePassword += value;
              }
            });
          },
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isSpecial ? 20 : 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // 폼 데이터 수집
      final roomData = {
        'roomName': _roomNameController.text,
        'address': _addressController.text,
        'detailAddress': _detailAddressController.text,
        'area': double.parse(_areaController.text),
        'floor': _floor,
        'buildingType': _buildingType,
        'parkingAvailable': _parkingAvailable == '가능',
        'parkingInfo': _parkingInfoController.text,
        'elevatorAvailable': _elevatorAvailable == '있음',
        'roomCount': _roomCount,
        'bathroomCount': _bathroomCount,
        'livingRoomCount': _livingRoomCount,
        'kitchenCount': _kitchenCount,
        'isDuplex': _isDuplex, //복층 여부
        'entrancePassword': _useEntrancePassword ? _entrancePassword : null, // 공통 현관 비밀번호
      };

      // TODO: 서버로 데이터 전송
      print('방 등록 데이터: $roomData');

      // 요금설정 페이지로 이동
      if (context.mounted) {
        context.go('/host/pricing');
      }
    }
  }
}