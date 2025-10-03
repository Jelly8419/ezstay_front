import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../widgets/registration_flow_indicator.dart';

/// 요금 설정 페이지
class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  final _formKey = GlobalKey<FormState>();

  // 섹션1
  final _weeklyRentController = TextEditingController();
  int _longTermWeeks = 0;
  int _longTermDiscount = 0;
  String _quickMoveIn = '0일';
  int _quickMoveInDiscount = 0;

  // 섹션2
  final _maintenanceFeeController = TextEditingController();
  final _maintenanceDetailController = TextEditingController();
  bool _includeElectricity = false;
  bool _includeWater = false;
  bool _includeGas = false;
  bool _includeInternet = false;
  final _cleaningFeeController = TextEditingController();

  // 섹션3
  int _minContractWeeks = 1;

  // 섹션4
  String _refundPolicy = '환불 규정 선택';

  @override
  void dispose() {
    _weeklyRentController.dispose();
    _maintenanceFeeController.dispose();
    _maintenanceDetailController.dispose();
    _cleaningFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('요금설정'),
        backgroundColor: const Color(0xFF4DB5BD),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const RegistrationFlowIndicator(currentStep: 1),
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
                  // 섹션1: 보증금 및 임대료
                  _buildSection1(),
                  const SizedBox(height: 24),

                  // 섹션2: 관리비
                  _buildSection2(),
                  const SizedBox(height: 24),

                  // 섹션3: 최소 계약 기간
                  _buildSection3(),
                  const SizedBox(height: 24),

                  // 섹션4: 환불 규정
                  _buildSection4(),
                  const SizedBox(height: 32),

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

  Widget _buildSection1() {
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
            const Text(
              '보증금',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '300,000 원',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '계약 보증금은 1주 임대료에 따라 자동으로 책정되며, 최소 30만원 ~ 최대 100만원 까지 정해집니다.\n'
                    '보증금은 이지스테이에 안전하게 보관되며 호스트(임대인)와의 최상 상태를 확인한 후 게스트에게 반환됩니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 임대료
            const Text(
              '임대료',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 400,
              child: TextFormField(
                controller: _weeklyRentController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  hintText: '250,000',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  suffixText: '원 / 1주',
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
                    borderSide: const BorderSide(color: Color(0xFF4DB5BD), width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '1주당에 책정 하는 임대료를 입력해 주세요.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '임대료는 계약 기간에 따라 자동으로 게산되어 산출로 요청됩니다.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // 임대료 할인
            const Text(
              '임대료 할인',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '장기간 거주자를 대상으로 임주자의 계약조건에 할인을 적용해 보세요.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // 장기계약할인
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    '장기계약할인',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _longTermWeeks,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                              borderSide: const BorderSide(color: Color(0xFF4DB5BD), width: 1.5),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: List.generate(13, (index) => index).map((weeks) {
                            return DropdownMenuItem(
                              value: weeks,
                              child: Text('$weeks주'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _longTermWeeks = value ?? 0;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('이상 계약 시'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _longTermDiscount,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                              borderSide: const BorderSide(color: Color(0xFF4DB5BD), width: 1.5),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: List.generate(19, (index) => index * 5).map((percent) {
                            return DropdownMenuItem(
                              value: percent,
                              child: Text('$percent%'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _longTermDiscount = value ?? 0;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('할인'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 빠른입주할인
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    '빠른입주할인',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _quickMoveIn,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                              borderSide: const BorderSide(color: Color(0xFF4DB5BD), width: 1.5),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: [
                            '0일',
                            '오늘입주',
                            ...List.generate(7, (index) => '${index + 1}일')
                          ].map((day) {
                            return DropdownMenuItem(
                              value: day,
                              child: Text(day),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _quickMoveIn = value ?? '0일';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('이내 입주 시'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _quickMoveInDiscount,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                              borderSide: const BorderSide(color: Color(0xFF4DB5BD), width: 1.5),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: List.generate(31, (index) => index).map((amount) {
                            return DropdownMenuItem(
                              value: amount,
                              child: Text('$amount만원'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _quickMoveInDiscount = value ?? 0;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('할인'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection2() {
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
            // 관리비
            const Text(
              '관리비',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 400,
              child: TextFormField(
                controller: _maintenanceFeeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  hintText: '50,000',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  suffixText: '원 / 1주',
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
                    borderSide: const BorderSide(color: Color(0xFF4DB5BD), width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '이지스테이는 관리비 정산을 대행하지 않습니다.\n'
              '관리비는 가격으로 고려하여 관리비에 포함시킬 것을 추천드립니다.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // 포함사항
            const Text(
              '포함사항',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '관리비에 포함되는 항목을 선택해주세요.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInclusionItem('전기', _includeElectricity, (value) {
                    setState(() {
                      _includeElectricity = value;
                    });
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInclusionItem('수도', _includeWater, (value) {
                    setState(() {
                      _includeWater = value;
                    });
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInclusionItem('가스', _includeGas, (value) {
                    setState(() {
                      _includeGas = value;
                    });
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInclusionItem('인터넷', _includeInternet, (value) {
                    setState(() {
                      _includeInternet = value;
                    });
                  }),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 관리비 상세설명
            const Text(
              '관리비 상세설명',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _maintenanceDetailController,
              maxLength: 255,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '모든 공과금은 관리비에 포함되어 있습니다.',
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
                  borderSide: const BorderSide(color: Color(0xFF4DB5BD), width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                counterText: '${_maintenanceDetailController.text.length}/200',
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 24),

            // 퇴실 청소
            const Text(
              '퇴실 청소',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 400,
                  child: TextFormField(
                    controller: _cleaningFeeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      hintText: '50,000',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      suffixText: '원',
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
                        borderSide: const BorderSide(color: Color(0xFF4DB5BD), width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    // TODO: 예시 기능
                  },
                  child: const Text(
                    '예시',
                    style: TextStyle(
                      color: Color(0xFF4DB5BD),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '청소비가 설정된 경우, 청소가 완료된 상태로 임차인에게 방을 제공해야 합니다',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[900],
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '계약 체결시 게스트에게 청구됩니다(1회))',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection3() {
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
            const Text(
              '최소 계약 기간',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 300,
              child: DropdownButtonFormField<int>(
                value: _minContractWeeks,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    borderSide: const BorderSide(color: Color(0xFF4DB5BD), width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: List.generate(12, (index) => index + 1).map((weeks) {
                  return DropdownMenuItem(
                    value: weeks,
                    child: Text('$weeks주'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _minContractWeeks = value ?? 1;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '최소 계약 기간 미만으로는 계약 신청이 불가능 합니다.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection4() {
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
            const Text(
              '환불 규정',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 400,
              child: DropdownButtonFormField<String>(
                value: _refundPolicy,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    borderSide: const BorderSide(color: Color(0xFF4DB5BD), width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(
                    value: '환불 규정 선택',
                    child: Text('환불 규정 선택'),
                  ),
                  DropdownMenuItem(
                    value: '환불 규정1',
                    child: Text('환불 규정1'),
                  ),
                  DropdownMenuItem(
                    value: '환불 규정2',
                    child: Text('환불 규정2'),
                  ),
                  DropdownMenuItem(
                    value: '환불 규정3',
                    child: Text('환불 규정3'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _refundPolicy = value ?? '환불 규정 선택';
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // 환불 규정 설명
            if (_refundPolicy == '환불 규정1') ...[
              Text(
                '- 입주일 15일 이전 - 입대금의 100% 환불\n'
                '- 입주일 14일 ~ 8일 이전 - 입대금의 80% 환불\n'
                '- 입주일 7일 ~ 1일 이전 · 입대금의 60% 환불\n'
                '- 입주일 당일·환불 불가',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                  height: 1.6,
                ),
              ),
            ] else if (_refundPolicy == '환불 규정2') ...[
              Text(
                '규정2 내용 (샘플)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                  height: 1.6,
                ),
              ),
            ] else if (_refundPolicy == '환불 규정3') ...[
              Text(
                '규정3 내용 (샘플)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                  height: 1.6,
                ),
              ),
            ],

            if (_refundPolicy != '환불 규정 선택') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.red[700],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '호스트 사유로 계약을 취소하는 경우, 같은 규정을 적용하여 위약금을 게스트에게 지급해야 합니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              '계약 신청 후 입주의 90%가 경과됩니다.\n'
              '청소비와 관리비는 100%환불됩니다.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInclusionItem(String label, bool isSelected, Function(bool) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? const Color(0xFF4DB5BD) : Colors.grey[300]!,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(true),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4DB5BD) : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        bottomLeft: Radius.circular(6),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '포함',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 1.5,
                height: 44,
                color: isSelected ? const Color(0xFF4DB5BD) : Colors.grey[300],
              ),
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(false),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !isSelected ? Colors.grey[300] : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(6),
                        bottomRight: Radius.circular(6),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '불포함',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: !isSelected ? const Color(0xFF2C3E50) : Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
              context.go('/host/room-registration');
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
              if (_formKey.currentState!.validate()) {
                // TODO: 저장 로직
                context.push('/host/amenities');
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
