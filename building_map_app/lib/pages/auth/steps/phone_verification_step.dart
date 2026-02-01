import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../config/api_config.dart';
import '../../../models/user.dart';
import '../../../services/token_service.dart';
import '../../../services/auth_service.dart';

/// Step 1 (이메일/소셜 가입): 휴대폰 본인인증 + 약관동의 단계
class PhoneVerificationStep extends StatefulWidget {
  final String? initialPhoneNumber;
  final String email;
  final String password;
  final UserMode mode;
  final Function({String? realName, String? phoneNumber}) onNext;
  final bool isSocialLogin; // 소셜 로그인 여부 (카카오 등)
  final bool isPhoneVerificationOnly; // 본인인증만 하는 단계인지 (호스트 소셜 로그인 첫 단계)

  const PhoneVerificationStep({
    super.key,
    this.initialPhoneNumber,
    required this.email,
    required this.password,
    required this.mode,
    required this.onNext,
    this.isSocialLogin = false, // 기본값: 일반 회원가입
    this.isPhoneVerificationOnly = false, // 기본값: 전체 단계
  });

  @override
  State<PhoneVerificationStep> createState() => _PhoneVerificationStepState();
}

class _PhoneVerificationStepState extends State<PhoneVerificationStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;
  final _nameController = TextEditingController();

  bool _isVerifying = false;
  bool _isVerified = false;
  bool _isRegistering = false;

  // 약관 동의
  bool _agreeTerms = false;
  bool _agreeMarketing = false;

  // 호스트 계좌 정보
  String? _selectedBank;
  final _accountController = TextEditingController();
  final _accountHolderController = TextEditingController();
  bool _accountVerified = false;

  // 은행 목록
  static const List<String> _banks = [
    '국민은행',
    '신한은행',
    '우리은행',
    '하나은행',
    'KB국민은행',
    '기업은행',
    '농협은행',
    '카카오뱅크',
    '토스뱅크',
    '새마을금고',
    '신협',
    '우체국예금보험',
    '경남은행',
    '광주은행',
    '대구은행',
    '부산은행',
    '수협은행',
    '전북은행',
    '제주은행',
    '산업은행',
    '수출입은행',
    'SC제일은행',
    '씨티은행',
  ];

  // 색상 정의
  static const primaryBlack = Color(0xFF000000);
  static const secondaryGray = Color(0xFF808080);
  static const borderGray = Color(0xFFE0E0E0);
  static const backgroundWhite = Color(0xFFFFFFFF);
  static const hintGray = Color(0xFFCCCCCC);
  static const textGray = Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhoneNumber);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _accountController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  /// 은행 코드 변환 헬퍼
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

  /// 계좌 확인
  Future<void> _verifyAccount() async {
    if (_accountController.text.isEmpty ||
        _selectedBank == null ||
        _accountHolderController.text.isEmpty) {
      _showErrorDialog('모든 계좌 정보를 입력해주세요');
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // 등록 중에는 JWT 토큰이 아직 없으므로, 계좌 확인은 등록 후에 가능
      // 임시로 입력값만 검증
      debugPrint('🏦 [ACCOUNT] 계좌 정보 검증 시작');
      debugPrint('은행: $_selectedBank');
      debugPrint('계좌번호: ${_accountController.text}');
      debugPrint('예금주: ${_accountHolderController.text}');

      // TODO: 실제 계좌 확인 API 호출은 JWT 토큰 발급 후 가능
      // 현재는 입력값 형식만 검증
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _isVerifying = false;
          _accountVerified = true;
        });

        _showSuccessDialog('계좌 정보가 확인되었습니다');
      }
    } on SocketException {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
        _showErrorDialog('네트워크 연결을 확인해주세요');
      }
    } catch (e) {
      debugPrint('❌ [ACCOUNT] 계좌 확인 에러: $e');
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
        _showErrorDialog('계좌 확인 중 오류가 발생했습니다');
      }
    }
  }

  /// 본인인증 요청 (임시 - API 없음)
  Future<void> _requestVerification() async {
    if (_phoneController.text.isEmpty) {
      _showErrorDialog('휴대폰 번호를 입력해주세요');
      return;
    }

    if (!RegExp(
      r'^01[016789][-]?\d{3,4}[-]?\d{4}$',
    ).hasMatch(_phoneController.text)) {
      _showErrorDialog('올바른 휴대폰 번호 형식이 아닙니다');
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    // TODO: 실제 본인인증 API 연동
    // 현재는 임시로 2초 후 성공 처리
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isVerifying = false;
        _isVerified = true;
        // 테스트용 실명 (실제로는 본인인증 결과에서 받음)
        _nameController.text = '홍길동';
      });

      _showSuccessDialog('본인인증이 완료되었습니다\n실명: 홍길동');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          '오류',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: primaryBlack,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textGray,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '확인',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          '성공',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.success600,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textGray,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '확인',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNext() async {
    if (!_isVerified) {
      _showErrorDialog('본인인증을 먼저 완료해주세요');
      return;
    }

    // 본인인증만 하는 단계일 때는 API 호출 없이 바로 다음 단계로 이동
    if (widget.isPhoneVerificationOnly) {
      debugPrint('📞 [REGISTER] 본인인증만 완료 - 다음 단계로 이동 (API 호출 없음)');
      debugPrint('실명: ${_nameController.text}');
      debugPrint('휴대폰: ${_phoneController.text}');

      // 실명과 전화번호를 onNext 콜백으로 전달
      widget.onNext(
        realName: _nameController.text,
        phoneNumber: _phoneController.text,
      );
      return;
    }

    // 전체 단계인 경우 - 약관 동의 및 계좌 정보 검증
    if (!_agreeTerms) {
      _showErrorDialog('이용약관 및 개인정보처리방침에 동의해주세요');
      return;
    }

    // 호스트의 경우 계좌 정보 필수
    if (widget.mode == UserMode.host) {
      if (!_accountVerified) {
        _showErrorDialog('계좌 정보를 먼저 확인해주세요');
        return;
      }
      if (_selectedBank == null ||
          _accountController.text.isEmpty ||
          _accountHolderController.text.isEmpty) {
        _showErrorDialog('모든 계좌 정보를 입력해주세요');
        return;
      }
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      String? accessToken;
      String? refreshToken;

      if (widget.isSocialLogin) {
        // 소셜 로그인 (카카오) - 이미 토큰이 저장되어 있음
        debugPrint('🔑 [REGISTER] 카카오 사용자: 저장된 JWT 토큰 확인');
        accessToken = await TokenService.getAccessToken(skipExpiryCheck: true);

        if (accessToken == null) {
          throw Exception('저장된 JWT 토큰을 찾을 수 없습니다. 다시 로그인해주세요.');
        }

        debugPrint('✅ [REGISTER] 저장된 JWT 토큰 확인 완료');
      } else {
        // 일반 회원가입: Step 1, 2 진행
        // Step 1: 회원가입 API 호출 (이메일, 비밀번호, user_mode만)
        debugPrint('📝 [REGISTER] Step 1: 회원가입 API 호출');
        final registerResponse = await http
            .post(
              Uri.parse(ApiConfig.authRegisterUrl),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'email': widget.email,
                'password': widget.password,
                'user_mode': widget.mode == UserMode.guest ? 'guest' : 'host',
              }),
            )
            .timeout(ApiConfig.timeout);

        debugPrint('📡 [REGISTER] 회원가입 응답 상태: ${registerResponse.statusCode}');
        debugPrint('📄 [REGISTER] 회원가입 응답 내용: ${registerResponse.body}');

        if (registerResponse.statusCode != 200 &&
            registerResponse.statusCode != 201) {
          final data = json.decode(registerResponse.body);
          final message = data['message'] ?? '회원가입에 실패했습니다';
          throw Exception(message);
        }

        final registerData = json.decode(registerResponse.body);
        if (registerData['success'] != true) {
          final message = registerData['message'] ?? '회원가입에 실패했습니다';
          throw Exception(message);
        }

        // Step 2: JWT 토큰 추출 및 저장
        debugPrint('🔑 [REGISTER] Step 2: JWT 토큰 저장');

        if (registerData['data'] != null &&
            registerData['data']['accessToken'] != null) {
          accessToken = registerData['data']['accessToken'];
          refreshToken = registerData['data']['refreshToken'];
        } else if (registerData['accessToken'] != null) {
          accessToken = registerData['accessToken'];
          refreshToken = registerData['refreshToken'];
        }

        if (accessToken == null) {
          throw Exception('JWT 토큰을 받지 못했습니다');
        }

        await TokenService.saveTokens(accessToken, refreshToken);
        debugPrint('✅ [REGISTER] JWT 토큰 저장 완료');
      }

      // Step 3: 본인인증 API 호출 (또는 본인인증만 호출)
      if (widget.isPhoneVerificationOnly) {
        // 본인인증만 하는 단계 (호스트 소셜 로그인 첫 단계)
        debugPrint('📞 [REGISTER] 본인인증만 API 호출');
        final verificationUrl =
            '${ApiConfig.baseUrl}/api/user/host/phone-verification';

        final verificationBody = {
          'name': _nameController.text,
          'phone_number': _phoneController.text,
        };

        final verificationResponse = await http
            .post(
              Uri.parse(verificationUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $accessToken',
              },
              body: json.encode(verificationBody),
            )
            .timeout(ApiConfig.timeout);

        debugPrint(
          '📡 [REGISTER] 본인인증 응답 상태: ${verificationResponse.statusCode}',
        );
        debugPrint('📄 [REGISTER] 본인인증 응답 내용: ${verificationResponse.body}');

        if (verificationResponse.statusCode != 200 &&
            verificationResponse.statusCode != 201) {
          final data = json.decode(verificationResponse.body);
          final message = data['message'] ?? '본인인증에 실패했습니다';
          throw Exception(message);
        }

        final verificationData = json.decode(verificationResponse.body);
        if (verificationData['success'] != true) {
          final message = verificationData['message'] ?? '본인인증에 실패했습니다';
          throw Exception(message);
        }

        // 본인인증 완료 - 다음 단계로 이동
        debugPrint('✅ [REGISTER] 본인인증 완료 - 다음 단계로 이동');
        if (mounted) {
          setState(() {
            _isRegistering = false;
          });
          widget.onNext();
        }
        return; // 여기서 종료
      }

      // 전체 단계인 경우: 본인인증 + 약관동의 + (호스트의 경우) 계좌 정보
      debugPrint('📞 [REGISTER] Step 3: 본인인증 API 호출');
      final verificationUrl = widget.mode == UserMode.guest
          ? '${ApiConfig.baseUrl}/api/user/guest/verification'
          : '${ApiConfig.baseUrl}/api/user/host/verification';

      final verificationBody = {
        'name': _nameController.text,
        'phone_number': _phoneController.text,
        'terms': {
          'service_terms': _agreeTerms,
          'privacy_policy': _agreeTerms,
          'marketing_consent': _agreeMarketing,
          'age_confirmed': true,
        },
      };

      // 호스트의 경우 계좌 정보 추가
      if (widget.mode == UserMode.host) {
        verificationBody['bank_code'] = _getBankCode(_selectedBank!);
        verificationBody['account_num'] = _accountController.text;
        verificationBody['account_holder_name'] = _accountHolderController.text;
        debugPrint('🏦 [REGISTER] 호스트 계좌 정보 포함');
        debugPrint('은행 코드: ${verificationBody['bank_code']}');
        debugPrint('계좌번호: ${verificationBody['account_num']}');
        debugPrint('예금주: ${verificationBody['account_holder_name']}');
      }

      final verificationResponse = await http
          .post(
            Uri.parse(verificationUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: json.encode(verificationBody),
          )
          .timeout(ApiConfig.timeout);

      debugPrint(
        '📡 [REGISTER] 본인인증 응답 상태: ${verificationResponse.statusCode}',
      );
      debugPrint('📄 [REGISTER] 본인인증 응답 내용: ${verificationResponse.body}');

      if (verificationResponse.statusCode != 200 &&
          verificationResponse.statusCode != 201) {
        final data = json.decode(verificationResponse.body);
        final message = data['message'] ?? '본인인증에 실패했습니다';
        throw Exception(message);
      }

      final verificationData = json.decode(verificationResponse.body);
      if (verificationData['success'] != true) {
        final message = verificationData['message'] ?? '본인인증에 실패했습니다';
        throw Exception(message);
      }

      // Step 4: 성공 (JWT 토큰 이미 저장됨)
      debugPrint('✅ [REGISTER] 회원가입 및 본인인증 완료');

      if (mounted) {
        setState(() {
          _isRegistering = false;
        });

        // 성공 다이얼로그 표시
        _showSuccessDialog('회원가입이 완료되었습니다!');

        // 다이얼로그 닫힌 후 자동 로그인 및 홈 화면 이동 (onNext 콜백에서 처리)
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            widget.onNext();
          }
        });
      }
    } on SocketException {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
        _showErrorDialog('네트워크 연결을 확인해주세요');
      }
    } on http.ClientException {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
        _showErrorDialog('서버에 연결할 수 없습니다');
      }
    } catch (e) {
      debugPrint('❌ [REGISTER] 에러: $e');
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        _showErrorDialog(errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 제목
          const Text(
            '본인인증',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: primaryBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '안전한 서비스 이용을 위해 본인인증이 필요합니다',
            style: AppTextStyles.bodyLarge.copyWith(color: textGray),
          ),
          const SizedBox(height: 40),

          // 휴대폰 번호 라벨
          const Text(
            '휴대폰 번호',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: textGray,
            ),
          ),
          const SizedBox(height: 8),

          // 휴대폰 번호 입력 + 본인인증 버튼
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: TextFormField(
                    controller: _phoneController,
                    enabled: !_isVerified,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: primaryBlack,
                    ),
                    decoration: InputDecoration(
                      hintText: '01012345678',
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: hintGray,
                      ),
                      filled: true,
                      fillColor: _isVerified
                          ? const Color(0xFFF5F5F5)
                          : backgroundWhite,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: borderGray,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _isVerified
                              ? AppColors.success500
                              : borderGray,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.primary600,
                          width: 1.5,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.success500,
                          width: 1,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '휴대폰 번호를 입력해주세요';
                      }
                      if (!RegExp(r'^01[016789]\d{7,8}$').hasMatch(value)) {
                        return '올바른 휴대폰 번호 형식이 아닙니다';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isVerified
                      ? null
                      : (_isVerifying ? null : _requestVerification),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isVerified
                        ? AppColors.success500
                        : AppColors.primary600,
                    foregroundColor: backgroundWhite,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: _isVerified
                        ? AppColors.success500
                        : const Color(0xFFE0E0E0),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              backgroundWhite,
                            ),
                          ),
                        )
                      : Text(
                          _isVerified ? '인증완료' : '본인인증',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 실명 표시 (본인인증 후)
          if (_isVerified) ...[
            const Text(
              '실명',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: textGray,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: TextFormField(
                controller: _nameController,
                enabled: false,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: primaryBlack,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: borderGray, width: 1),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.success500,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 호스트 계좌 정보 입력 (호스트 모드 + 본인인증 완료 후 + 전체 단계인 경우에만)
          if (widget.mode == UserMode.host &&
              _isVerified &&
              !widget.isPhoneVerificationOnly) ...[
            const Text(
              '정산 계좌 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: primaryBlack,
              ),
            ),
            const SizedBox(height: 16),

            // 은행 선택
            const Text(
              '은행',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: textGray,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedBank,
                hint: const Text(
                  '은행을 선택하세요',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: hintGray,
                  ),
                ),
                items: _banks.map((bank) {
                  return DropdownMenuItem(
                    value: bank,
                    child: Text(
                      bank,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: primaryBlack,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: _accountVerified
                    ? null
                    : (value) {
                        setState(() {
                          _selectedBank = value;
                        });
                      },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _accountVerified
                      ? const Color(0xFFF5F5F5)
                      : backgroundWhite,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: borderGray, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _accountVerified
                          ? AppColors.success500
                          : borderGray,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.primary600,
                      width: 1.5,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.success500,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 계좌번호
            const Text(
              '계좌번호',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: textGray,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: TextFormField(
                controller: _accountController,
                enabled: !_accountVerified,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: primaryBlack,
                ),
                decoration: InputDecoration(
                  hintText: '계좌번호 (- 없이 입력)',
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: hintGray,
                  ),
                  filled: true,
                  fillColor: _accountVerified
                      ? const Color(0xFFF5F5F5)
                      : backgroundWhite,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: borderGray, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _accountVerified
                          ? AppColors.success500
                          : borderGray,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.primary600,
                      width: 1.5,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.success500,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 예금주
            const Text(
              '예금주',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: textGray,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: TextFormField(
                      controller: _accountHolderController,
                      enabled: !_accountVerified,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: primaryBlack,
                      ),
                      decoration: InputDecoration(
                        hintText: '예금주명',
                        hintStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: hintGray,
                        ),
                        filled: true,
                        fillColor: _accountVerified
                            ? const Color(0xFFF5F5F5)
                            : backgroundWhite,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: borderGray,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: _accountVerified
                                ? AppColors.success500
                                : borderGray,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.primary600,
                            width: 1.5,
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.success500,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _accountVerified
                        ? null
                        : (_isVerifying ? null : _verifyAccount),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accountVerified
                          ? AppColors.success500
                          : AppColors.primary600,
                      foregroundColor: backgroundWhite,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: _accountVerified
                          ? AppColors.success500
                          : const Color(0xFFE0E0E0),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                backgroundWhite,
                              ),
                            ),
                          )
                        : Text(
                            _accountVerified ? '확인완료' : '확인하기',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 계좌 안내
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance,
                        size: 16,
                        color: AppColors.primary600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '정산 계좌 안내',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• 입력한 계좌로 숙박 수익이 정산됩니다\n'
                    '• 예금주는 본인 명의여야 합니다\n'
                    '• 계좌 정보는 마이페이지에서 변경 가능합니다',
                    style: TextStyle(
                      fontSize: 12,
                      color: textGray,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // 안내 문구
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.primary600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '본인인증 안내',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• 본인인증을 통해 실명이 자동으로 입력됩니다\n'
                  '• 입력하신 정보는 안전하게 보호됩니다\n'
                  '• 만 14세 이상만 가입 가능합니다',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: textGray,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 약관 동의 섹션 (본인인증만 하는 단계가 아닌 경우에만 표시)
          if (!widget.isPhoneVerificationOnly) ...[
            const Text(
              '약관 동의',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: primaryBlack,
              ),
            ),
            const SizedBox(height: 16),

            // 전체 동의
            InkWell(
              onTap: () {
                setState(() {
                  final allAgreed = _agreeTerms && _agreeMarketing;
                  _agreeTerms = !allAgreed;
                  _agreeMarketing = !allAgreed;
                });
              },
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreeTerms && _agreeMarketing,
                      onChanged: (value) {
                        setState(() {
                          _agreeTerms = value ?? false;
                          _agreeMarketing = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '전체 동의',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryBlack,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: borderGray, thickness: 1),
            const SizedBox(height: 12),

            // 필수 약관 동의
            InkWell(
              onTap: () {
                setState(() {
                  _agreeTerms = !_agreeTerms;
                });
              },
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreeTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeTerms = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '[필수] 이용약관 및 개인정보처리방침 동의',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: primaryBlack,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: secondaryGray),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 선택 약관 동의
            InkWell(
              onTap: () {
                setState(() {
                  _agreeMarketing = !_agreeMarketing;
                });
              },
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreeMarketing,
                      onChanged: (value) {
                        setState(() {
                          _agreeMarketing = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '[선택] 마케팅 정보 수신 동의',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: primaryBlack,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: secondaryGray),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ], // 약관 동의 섹션 종료
          // 회원가입 완료 버튼 (또는 다음 버튼)
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isVerified && !_isRegistering ? _handleNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary600,
                foregroundColor: backgroundWhite,
                elevation: 0,
                disabledBackgroundColor: const Color(0xFFE0E0E0),
                disabledForegroundColor: secondaryGray,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isRegistering
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          backgroundWhite,
                        ),
                      ),
                    )
                  : Text(
                      widget.isPhoneVerificationOnly ? '다음' : '회원가입 완료',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),

          // 소셜 로그인 사용자만 "비회원으로 이용하기" 버튼 표시
          if (widget.isSocialLogin) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: TextButton(
                onPressed: _isRegistering
                    ? null
                    : () async {
                        // 로그아웃 처리
                        final authService = context.read<AuthService>();
                        await authService.logout();

                        if (!mounted) return;

                        // 게스트 홈으로 이동
                        context.go('/guest');
                      },
                style: TextButton.styleFrom(
                  foregroundColor: secondaryGray,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: borderGray, width: 1),
                  ),
                ),
                child: Text(
                  '비회원으로 이용하기',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
