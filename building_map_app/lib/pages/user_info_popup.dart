import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'host_home_page.dart';
import 'guest_home_page.dart';

class UserInfoPopup extends StatefulWidget {
  final bool isFromSignup;

  const UserInfoPopup({
    super.key,
    this.isFromSignup = false,
  });

  @override
  State<UserInfoPopup> createState() => _UserInfoPopupState();
}

class _UserInfoPopupState extends State<UserInfoPopup> {
  // 회원정보 폼 컨트롤러
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  // 정산정보 폼 컨트롤러 (호스트용)
  final _bankController = TextEditingController();
  final _accountController = TextEditingController();
  final _accountHolderController = TextEditingController();

  // 상태 변수들
  bool _phoneVerified = false;
  bool _accountVerified = false;

  // 약관 동의 상태
  bool _serviceTermsAgreed = false;
  bool _privacyPolicyAgreed = false;
  bool _marketingAgreed = false;
  bool _ageConfirmed = false;
  bool _allAgreed = false;

  String? _selectedBank;
  final List<String> _banks = [
    '국민은행', '신한은행', '우리은행', '하나은행',
    'KB국민은행', '기업은행', '농협은행', '카카오뱅크',
    '토스뱅크', '새마을금고', '신협', '우체국예금보험',
    '경남은행', '광주은행', '대구은행', '부산은행',
    '수협은행', '전북은행', '제주은행', '산업은행',
    '수출입은행', 'SC제일은행', '씨티은행'
  ];

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  void _initializeUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user != null) {
      _nameController.text = user.name;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWideScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Center(
        child: Container(
          width: isWideScreen ? 800 : screenWidth * 0.95,
          height: isWideScreen ? screenHeight * 0.85 : screenHeight * 0.9,
          constraints: BoxConstraints(
            maxWidth: 900,
            maxHeight: screenHeight * 0.9,
            minHeight: 600,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // 팝업 헤더
              _buildPopupHeader(),

              // 메인 컨텐츠 - 가로 레이아웃
              Expanded(
                child: Consumer<AuthService>(
                  builder: (context, authService, child) {
                    final user = authService.currentUser;
                    final isHost = user?.mode == UserMode.host;

                    // 모든 환경에서 세로 배치로 통일
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 회원정보
                          _buildUserInfoSection(user),

                          // 정산정보 (호스트만)
                          if (isHost) ...[
                            const SizedBox(height: 32),
                            _buildSettlementSection(),
                          ],

                          // 약관 동의
                          const SizedBox(height: 32),
                          const Text(
                            '약관 동의',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTermsSection(),

                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // 하단 버튼들
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '회원정보',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.grey),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '회원정보',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 20),

        // 이메일 필드
        _buildReadOnlyField(
          label: '이메일',
          value: user?.email ?? '',
        ),

        const SizedBox(height: 16),

        // 휴대폰번호 필드
        _buildPhoneField(),

        const SizedBox(height: 16),

        // 이름 필드
        _buildNameField(user),
      ],
    );
  }

  Widget _buildSettlementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '정산 정보',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '수익 정산을 위한 계좌 정보를 입력해주세요',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 20),

        // 은행 선택
        _buildDropdownField(
          label: '은행',
          value: _selectedBank,
          items: _banks,
          onChanged: (value) {
            setState(() {
              _selectedBank = value;
            });
          },
        ),

        const SizedBox(height: 16),

        // 계좌번호
        _buildTextFieldWithButton(
          label: '계좌번호',
          controller: _accountController,
          buttonText: '확인하기',
          onButtonPressed: _verifyAccount,
          isVerified: _accountVerified,
        ),

        const SizedBox(height: 16),

        // 예금주
        _buildSimpleTextField(
          label: '예금주',
          controller: _accountHolderController,
        ),
      ],
    );
  }

  Widget _buildTermsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 전체 동의
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF87CEEB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF87CEEB).withOpacity(0.3)),
          ),
          child: _buildTermCheckbox(
            title: '전체동의',
            value: _allAgreed,
            onChanged: (value) {
              setState(() {
                _allAgreed = value ?? false;
                _serviceTermsAgreed = _allAgreed;
                _privacyPolicyAgreed = _allAgreed;
                _marketingAgreed = _allAgreed;
                _ageConfirmed = _allAgreed;
              });
            },
            isBold: true,
          ),
        ),

        const SizedBox(height: 16),

        // 개별 약관들
        _buildTermCheckbox(
          title: '[필수] 서비스 이용약관',
          value: _serviceTermsAgreed,
          onChanged: (value) {
            setState(() {
              _serviceTermsAgreed = value ?? false;
              _updateAllAgreed();
            });
          },
        ),

        _buildTermCheckbox(
          title: '[필수] 개인정보 취급방침',
          value: _privacyPolicyAgreed,
          onChanged: (value) {
            setState(() {
              _privacyPolicyAgreed = value ?? false;
              _updateAllAgreed();
            });
          },
        ),

        _buildTermCheckbox(
          title: '[선택] 마케팅 정보 수신 동의',
          value: _marketingAgreed,
          onChanged: (value) {
            setState(() {
              _marketingAgreed = value ?? false;
              _updateAllAgreed();
            });
          },
        ),

        _buildTermCheckbox(
          title: '[필수] 만 19세 이상입니다.',
          value: _ageConfirmed,
          onChanged: (value) {
            setState(() {
              _ageConfirmed = value ?? false;
              _updateAllAgreed();
            });
          },
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
  }) {
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
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '휴대폰번호',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                enabled: !_phoneVerified,
                decoration: InputDecoration(
                  hintText: '휴대폰 번호를 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF87CEEB), width: 2),
                  ),
                  filled: true,
                  fillColor: _phoneVerified ? Colors.grey[100] : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _phoneVerified ? Colors.green : const Color(0xFF6366f1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: _phoneVerified ? null : _verifyPhone,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  _phoneVerified ? '인증완료' : '인증하기',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNameField(User? user) {
    final isReadOnly = user?.provider != AuthProvider.email || _phoneVerified;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이름',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          enabled: !isReadOnly,
          decoration: InputDecoration(
            hintText: '이름을 입력하세요',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF87CEEB), width: 2),
            ),
            filled: true,
            fillColor: isReadOnly ? Colors.grey[100] : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
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
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            hintText: '선택하세요',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF87CEEB), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextFieldWithButton({
    required String label,
    required TextEditingController controller,
    required String buttonText,
    required VoidCallback onButtonPressed,
    required bool isVerified,
  }) {
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
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: '입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF87CEEB), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isVerified ? Colors.green : const Color(0xFF6366f1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: isVerified ? null : onButtonPressed,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  isVerified ? '확인완료' : buttonText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSimpleTextField({
    required String label,
    required TextEditingController controller,
  }) {
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
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '입력하세요',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF87CEEB), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildTermCheckbox({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6366f1),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: const Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 다음에 할게요 버튼
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _handleSkip,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '다음에 할게요',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 완료 버튼
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _handleComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                '완료',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateAllAgreed() {
    setState(() {
      _allAgreed = _serviceTermsAgreed && _privacyPolicyAgreed && _marketingAgreed && _ageConfirmed;
    });
  }

  void _verifyPhone() {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('휴대폰번호를 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: 실제 본인인증 API 연동 (SMS 인증 등)
    // 현재는 단순히 인증 완료 처리
    setState(() {
      _phoneVerified = true;
      // 로컬 유저의 경우 본인인증 시 이름 자동 채우기
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser?.provider == AuthProvider.email && _nameController.text.isEmpty) {
        _nameController.text = '홍길동'; // 실제로는 본인인증 API에서 받아온 이름
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('휴대폰 인증이 완료되었습니다'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _verifyAccount() async {
    if (_accountController.text.isEmpty || _selectedBank == null || _accountHolderController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 정보를 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/account/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await Provider.of<AuthService>(context, listen: false).getAccessToken()}',
        },
        body: json.encode({
          'bank_code': _getBankCode(_selectedBank!),
          'account_num': _accountController.text,
          'account_holder_name': _accountHolderController.text,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final data = responseData['data'];
          final actualName = data['accountHolderName']; // 실제 예금주명
          final inputName = data['inputName']; // 입력한 예금주명
          final verified = responseData['verified'] == true;

          if (verified) {
            // 이름이 정확히 일치하는 경우
            setState(() {
              _accountVerified = true;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('계좌 확인이 완료되었습니다'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // 이름이 다른 경우 확인 팝업 표시
            final shouldUse = await _showAccountMismatchDialog(actualName, inputName);

            if (shouldUse) {
              // 사용하겠다고 한 경우
              setState(() {
                _accountVerified = true;
                // 실제 예금주명으로 업데이트
                _accountHolderController.text = actualName;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('계좌 확인이 완료되었습니다'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              // 사용하지 않겠다고 한 경우 - 계좌정보 초기화
              _clearAccountInfo();
            }
          }
        } else {
          // API 호출은 성공했지만 계좌 확인 실패
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? '계좌 확인에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('계좌 확인 에러: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('계좌 확인 중 오류가 발생했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 예금주명 불일치 확인 팝업
  Future<bool> _showAccountMismatchDialog(String actualName, String inputName) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text(
                '예금주명 불일치',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '입력하신 예금주명과 실제 계좌의 예금주명이 다릅니다.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('입력한 예금주: ', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(inputName, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('실제 예금주: ', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(actualName, style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '그래도 이 계좌를 사용하시겠습니까?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                '아니요, 다시 입력하겠습니다',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF87CEEB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('네, 사용하겠습니다'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // 계좌정보 초기화
  void _clearAccountInfo() {
    setState(() {
      _selectedBank = null;
      _accountController.clear();
      _accountHolderController.clear();
      _accountVerified = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('계좌 정보가 초기화되었습니다. 다시 입력해주세요.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // 은행명을 은행코드로 변환
  String _getBankCode(String bankName) {
    const bankCodes = {
      '국민은행': '004',
      '신한은행': '088',
      '우리은행': '020',
      '하나은행': '081',
      'KB국민은행': '004',
      '기업은행': '003',
      '농협은행': '011',
      '카카오뱅크': '090',
      '토스뱅크': '092',
      '새마을금고': '045',
      '신협': '048',
      '우체국예금보험': '071',
      '경남은행': '039',
      '광주은행': '034',
      '대구은행': '031',
      '부산은행': '032',
      '수협은행': '007',
      '전북은행': '037',
      '제주은행': '035',
      '산업은행': '002',
      '수출입은행': '008',
      'SC제일은행': '023',
      '씨티은행': '027',
    };
    return bankCodes[bankName] ?? '004';
  }

  void _handleSkip() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    Navigator.of(context).pop(); // 팝업 닫기

    if (user?.mode == UserMode.guest) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const GuestHomePage(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HostHomePage(),
        ),
      );
    }
  }

  Future<void> _handleComplete() async {
    // 필수 약관 체크
    if (!_serviceTermsAgreed || !_privacyPolicyAgreed || !_ageConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('필수 약관에 동의해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final isHost = user?.mode == UserMode.host;

    // 본인인증 완료 여부 확인
    if (!_phoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('휴대폰 인증을 완료해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 호스트의 경우 계좌 인증도 확인
    if (isHost && !_accountVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('계좌 확인을 완료해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // 백엔드에 사용자 정보 저장
      await _saveUserVerification();

      Navigator.of(context).pop(); // 팝업 닫기

      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('회원 정보 등록이 완료되었습니다'),
          backgroundColor: Colors.green,
        ),
      );

      // 페이지 이동
      if (user?.mode == UserMode.guest) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const GuestHomePage(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HostHomePage(),
          ),
        );
      }
    } catch (e) {
      debugPrint('완료 처리 에러: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('처리 중 오류가 발생했습니다'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 사용자 정보 백엔드 저장 (약관 정보 포함)
  Future<void> _saveUserVerification() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final isHost = user?.mode == UserMode.host;

    String apiUrl;
    Map<String, dynamic> requestBody;

    // 약관 정보
    final termsData = {
      'service_terms': _serviceTermsAgreed,
      'privacy_policy': _privacyPolicyAgreed,
      'marketing_consent': _marketingAgreed,
      'age_confirmed': _ageConfirmed,
    };

    if (isHost) {
      // 호스트: 본인인증 + 계좌정보 + 약관 저장
      apiUrl = 'http://localhost:8080/api/user/host/verification';
      requestBody = {
        'name': _nameController.text,
        'phone_number': _phoneController.text,
        'bank_code': _selectedBank!,
        'account_num': _accountController.text,
        'account_holder_name': _accountHolderController.text,
        'terms': termsData,
      };
    } else {
      // 게스트: 본인인증 + 약관 저장
      apiUrl = 'http://localhost:8080/api/user/guest/verification';
      requestBody = {
        'name': _nameController.text,
        'phone_number': _phoneController.text,
        'terms': termsData,
      };
    }

    debugPrint('🚀 사용자 정보 및 약관 저장 시작 - ${isHost ? "호스트" : "게스트"}');
    debugPrint('🌐 API URL: $apiUrl');
    debugPrint('📦 요청 데이터: ${json.encode(requestBody)}');

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await authService.getAccessToken()}',
      },
      body: json.encode(requestBody),
    );

    debugPrint('📡 응답 - Status: ${response.statusCode}');
    debugPrint('📄 응답 - Body: ${response.body}');

    if (response.statusCode != 200) {
      debugPrint('❌ 저장 실패 - Status: ${response.statusCode}');
      final responseData = json.decode(response.body);
      throw Exception(responseData['message'] ?? '사용자 정보 저장에 실패했습니다');
    } else {
      debugPrint('✅ 사용자 정보 및 약관 저장 성공');
    }
  }

}