import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../config/api_config.dart';
import '../../../constants/bank_constants.dart';
import '../../../services/token_service.dart';

/// 호스트 정산계좌 입력 + 약관동의 단계
///
/// 두 가지 모드 지원:
/// 1. 회원가입 플로우 (isStandaloneMode: false)
///    - email, password, phoneNumber, realName 필수
///    - /api/auth/register → /api/user/host/verification 호출
///
/// 2. 게스트→호스트 전환 (isStandaloneMode: true)
///    - 이미 로그인된 게스트 사용자
///    - 계좌 정보만 입력 후 /api/user/upgrade-to-host 호출
class HostAccountStep extends StatefulWidget {
  final String? email;
  final String? password;
  final String? phoneNumber;
  final String? realName;
  final String? di;
  final String? birth;
  final String? gender;
  final Function() onNext;
  final bool isStandaloneMode; // true: 게스트→호스트 전환, false: 회원가입
  final bool isSocialLogin; // true: 소셜 로그인 (카카오 등)

  const HostAccountStep({
    super.key,
    this.email,
    this.password,
    this.phoneNumber,
    this.realName,
    this.di,
    this.birth,
    this.gender,
    required this.onNext,
    this.isStandaloneMode = false,
    this.isSocialLogin = false,
  });

  @override
  State<HostAccountStep> createState() => _HostAccountStepState();
}

class _HostAccountStepState extends State<HostAccountStep> {
  final _formKey = GlobalKey<FormState>();

  // 약관 동의
  bool _agreeTerms = false;
  bool _agreeMarketing = false;

  // 호스트 계좌 정보
  String? _selectedBank;
  final _accountController = TextEditingController();
  final _accountHolderController = TextEditingController();
  bool _accountVerified = false;
  bool _isVerifying = false;
  bool _isRegistering = false;

  // 은행 목록 (BankConstants에서 가져옴)
  static List<String> get _banks => BankConstants.banks;

  // 색상 정의
  static const primaryBlack = Color(0xFF000000);
  static const secondaryGray = Color(0xFF666666);
  static const borderGray = Color(0xFFE0E0E0);
  static const backgroundColor = Color(0xFFF5F5F5);
  static const successGreen = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();

    // 회원가입 모드: 본인인증 실명으로 초기화
    if (!widget.isStandaloneMode && widget.realName != null) {
      _accountHolderController.text = widget.realName!;
    }
    // Standalone 모드에서는 사용자가 직접 입력
  }

  @override
  void dispose() {
    _accountController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  /// 계좌 인증
  Future<void> _verifyAccount() async {
    if (_selectedBank == null ||
        _accountController.text.isEmpty ||
        _accountHolderController.text.isEmpty) {
      _showErrorDialog('모든 계좌 정보를 입력해주세요.');
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final token = await TokenService.getAccessToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/account/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'bank_code': _getBankCode(_selectedBank!),
          'account_num': _accountController.text,
          'account_holder_name': _accountHolderController.text,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));

        if (responseData['success'] == true) {
          final data = responseData['data'];
          final actualName = data['accountHolderName']; // 실제 예금주명
          final verified = responseData['verified'] == true;

          setState(() {
            _accountVerified = true;
            _isVerifying = false;
            if (!verified && actualName != null) {
              // 이름이 다른 경우 - 실제 예금주명으로 업데이트
              _accountHolderController.text = actualName;
            }
          });

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                verified ? '계좌 확인이 완료되었습니다' : '예금주명이 "$actualName"으로 확인되었습니다',
              ),
              backgroundColor: successGreen,
            ),
          );
        } else {
          // API 호출은 성공했지만 계좌 확인 실패
          throw Exception(responseData['message'] ?? '계좌 확인에 실패했습니다');
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });

      if (!mounted) return;

      _showErrorDialog('계좌 확인 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.');
    }
  }

  /// 은행명을 은행코드로 변환
  String _getBankCode(String bankName) {
    return BankConstants.getBankCode(bankName);
  }

  /// 회원가입 완료 (호스트) 또는 게스트→호스트 전환
  Future<void> _completeRegistration() async {
    // Standalone 모드에서는 약관 동의 불필요 (이미 회원가입 완료)
    if (!widget.isStandaloneMode && !_agreeTerms) {
      _showErrorDialog('필수 약관에 동의해주세요.');
      return;
    }

    if (!_accountVerified) {
      _showErrorDialog('계좌 인증을 완료해주세요.');
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      if (widget.isStandaloneMode) {
        // === Standalone 모드: 게스트→호스트 전환 ===
        await _upgradeToHost();
      } else if (widget.isSocialLogin) {
        // === 소셜 로그인 호스트: 본인인증+계좌 저장 ===
        await _verifySocialHost();
      } else {
        // === 이메일 회원가입 모드: 전체 플로우 ===
        await _registerAsHost();
      }
    } catch (e) {
      setState(() {
        _isRegistering = false;
      });

      if (!mounted) return;

      debugPrint('❌ [REGISTER] 에러: $e');
      _showErrorDialog(
        widget.isStandaloneMode
            ? '호스트 전환에 실패했습니다.\n${e.toString()}'
            : '회원가입에 실패했습니다.\n${e.toString()}',
      );
    }
  }

  /// 게스트→호스트 전환 (Standalone 모드)
  /// POST /api/account - 계좌 정보만 추가/수정
  Future<void> _upgradeToHost() async {
    debugPrint('🔄 [UPGRADE] 게스트→호스트 전환 시작');

    final token = await TokenService.getAccessToken();
    if (token == null) {
      throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
    }

    final accountUrl = '${ApiConfig.baseUrl}/api/account';
    final accountBody = {
      'bank_code': _selectedBank!, // 은행명 그대로 전송 (예: "국민은행")
      'account_num': _accountController.text,
      'account_holder_name': _accountHolderController.text,
    };

    final response = await http
        .post(
          Uri.parse(accountUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(accountBody),
        )
        .timeout(ApiConfig.timeout);

    debugPrint('📡 [UPGRADE] 응답 상태: ${response.statusCode}');
    debugPrint('📄 [UPGRADE] 응답 내용: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body);
      final message = data['message'] ?? '계좌 등록에 실패했습니다';
      throw Exception(message);
    }

    final responseData = jsonDecode(response.body);
    if (responseData['success'] != true) {
      final message = responseData['message'] ?? '계좌 등록에 실패했습니다';
      throw Exception(message);
    }

    // 성공 시 다음 단계로 이동 (AuthService는 /host 페이지 진입 시 자동으로 프로필 새로고침)
    debugPrint('✅ [UPGRADE] 게스트→호스트 전환 완료 (계좌 등록)');
    debugPrint('📋 [UPGRADE] 계좌 정보: ${responseData['data']?['account']}');
    widget.onNext();
  }

  /// 소셜 로그인 호스트: 본인인증+계좌+약관 저장
  /// POST /api/user/host/verification (로그인 토큰 필요)
  Future<void> _verifySocialHost() async {
    debugPrint('📝 [VERIFY] 소셜 로그인 호스트: 본인인증+계좌 저장 API 호출');

    final token = await TokenService.getAccessToken(skipExpiryCheck: true);
    if (token == null) {
      throw Exception('저장된 JWT 토큰을 찾을 수 없습니다. 다시 로그인해주세요.');
    }

    final verifyBody = {
      'name': widget.realName,
      'phoneNumber': widget.phoneNumber,
      if (widget.birth != null) 'birth': widget.birth,
      if (widget.gender != null) 'gender': widget.gender,
      if (widget.di != null) 'di': widget.di,
      'bank_code': _getBankCode(_selectedBank!),
      'account_num': _accountController.text,
      'account_holder_name': _accountHolderController.text,
      'terms': {
        'service_terms': _agreeTerms,
        'privacy_policy': _agreeTerms,
        'marketing_consent': _agreeMarketing,
        'age_confirmed': true,
      },
    };
    debugPrint('📦 [VERIFY] 요청 데이터: $verifyBody');

    final response = await http
        .post(
          Uri.parse(ApiConfig.hostVerificationUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(verifyBody),
        )
        .timeout(ApiConfig.timeout);

    debugPrint('📡 [VERIFY] 응답 상태: ${response.statusCode}');
    debugPrint('📄 [VERIFY] 응답 내용: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body);
      final message = data['message'] ?? '본인인증 정보 저장에 실패했습니다';
      throw Exception(message);
    }

    final responseData = jsonDecode(response.body);
    if (responseData['success'] != true) {
      final message = responseData['message'] ?? '본인인증 정보 저장에 실패했습니다';
      throw Exception(message);
    }

    // 응답에 새 토큰이 있으면 갱신
    if (responseData['data'] != null &&
        responseData['data']['accessToken'] != null) {
      await TokenService.saveTokens(
        responseData['data']['accessToken'],
        responseData['data']['refreshToken'],
      );
      debugPrint('✅ [VERIFY] 토큰 갱신 완료');
    }

    debugPrint('✅ [VERIFY] 소셜 로그인 호스트 본인인증+계좌 저장 완료');
    widget.onNext();
  }

  /// 이메일 호스트 회원가입 (기존 플로우)
  Future<void> _registerAsHost() async {
    // 필수 파라미터 검증
    if (widget.email == null ||
        widget.password == null ||
        widget.phoneNumber == null ||
        widget.realName == null) {
      throw Exception('회원가입에 필요한 정보가 부족합니다');
    }

    // Step 1: 회원가입 API 호출 (이메일, 비밀번호, user_mode + KMC 본인인증 데이터)
    debugPrint('📝 [REGISTER] Step 1: 회원가입 API 호출');
    final registerBody = {
      'email': widget.email,
      'password': widget.password,
      'user_mode': 'host',
      'name': widget.realName,
      'phoneNumber': widget.phoneNumber,
      if (widget.birth != null) 'birth': widget.birth,
      if (widget.gender != null) 'gender': widget.gender,
      if (widget.di != null) 'di': widget.di,
      'bank_code': _getBankCode(_selectedBank!),
      'account_num': _accountController.text,
      'account_holder_name': _accountHolderController.text,
      'terms': {
        'service_terms': _agreeTerms,
        'privacy_policy': _agreeTerms,
        'marketing_consent': _agreeMarketing,
        'age_confirmed': true,
      },
    };
    debugPrint('📦 [REGISTER] 회원가입 요청 데이터: $registerBody');
    final registerResponse = await http
        .post(
          Uri.parse(ApiConfig.authRegisterUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(registerBody),
        )
        .timeout(ApiConfig.timeout);

    debugPrint('📡 [REGISTER] 회원가입 응답 상태: ${registerResponse.statusCode}');
    debugPrint('📄 [REGISTER] 회원가입 응답 내용: ${registerResponse.body}');

    if (registerResponse.statusCode != 200 &&
        registerResponse.statusCode != 201) {
      final data = jsonDecode(registerResponse.body);
      final message = data['message'] ?? '회원가입에 실패했습니다';
      throw Exception(message);
    }

    final registerData = jsonDecode(registerResponse.body);
    if (registerData['success'] != true) {
      final message = registerData['message'] ?? '회원가입에 실패했습니다';
      throw Exception(message);
    }

    // Step 2: JWT 토큰 추출 및 저장
    debugPrint('🔑 [REGISTER] Step 2: JWT 토큰 저장');
    String? accessToken;
    String? refreshToken;

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

    // Step 3: 성공 - register API에서 본인인증+계좌+약관 모두 처리 완료
    debugPrint('✅ [REGISTER] 회원가입 완료 (본인인증+계좌+약관동의 포함)');
    debugPrint('✅ [REGISTER] 호스트 회원가입 완료');
    widget.onNext();
  }

  /// 에러 다이얼로그
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 제목
          Text(
            '정산 계좌 정보 입력',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isStandaloneMode
                ? '호스트로 활동하시려면 정산 계좌 정보를 등록해주세요.'
                : '호스트로 활동하시려면 정산 계좌 정보가 필요합니다.',
            style: AppTextStyles.bodySmall.copyWith(color: secondaryGray),
          ),
          const SizedBox(height: 32),

          // 은행 선택
          const Text(
            '은행',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryBlack,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedBank,
            decoration: InputDecoration(
              hintText: '은행을 선택하세요',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: borderGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: borderGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary600, width: 2),
              ),
            ),
            items: _banks.map((bank) {
              return DropdownMenuItem(value: bank, child: Text(bank));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBank = value;
                _accountVerified = false; // 은행 변경 시 인증 초기화
              });
            },
          ),
          const SizedBox(height: 16),

          // 계좌번호
          const Text(
            '계좌번호',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryBlack,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _accountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '계좌번호를 입력하세요 (- 제외)',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: borderGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: borderGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary600, width: 2),
              ),
            ),
            onChanged: (_) {
              setState(() {
                _accountVerified = false; // 계좌번호 변경 시 인증 초기화
              });
            },
          ),
          const SizedBox(height: 16),

          // 예금주명
          const Text(
            '예금주명',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryBlack,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _accountHolderController,
            decoration: InputDecoration(
              hintText: '예금주명을 입력하세요',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: borderGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: borderGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary600, width: 2),
              ),
            ),
            onChanged: (_) {
              setState(() {
                _accountVerified = false; // 예금주명 변경 시 인증 초기화
              });
            },
          ),
          const SizedBox(height: 16),

          // 계좌 인증 버튼
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _accountVerified || _isVerifying
                  ? null
                  : _verifyAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accountVerified
                    ? successGreen
                    : AppColors.primary600,
                foregroundColor: Colors.white,
                disabledBackgroundColor: backgroundColor,
                disabledForegroundColor: secondaryGray,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isVerifying
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _accountVerified ? '계좌 인증 완료 ✓' : '계좌 인증',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),

          // 약관 동의 (회원가입 모드에서만 표시)
          if (!widget.isStandaloneMode) ...[
            const Text(
              '약관 동의',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryBlack,
              ),
            ),
            const SizedBox(height: 16),

            // 필수 약관
            CheckboxListTile(
              value: _agreeTerms,
              onChanged: (value) {
                setState(() {
                  _agreeTerms = value ?? false;
                });
              },
              title: Text(
                '이용약관 및 개인정보 처리방침 동의 (필수)',
                style: AppTextStyles.bodySmall,
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary600,
            ),

            // 선택 약관
            CheckboxListTile(
              value: _agreeMarketing,
              onChanged: (value) {
                setState(() {
                  _agreeMarketing = value ?? false;
                });
              },
              title: Text(
                '마케팅 정보 수신 동의 (선택)',
                style: AppTextStyles.bodySmall,
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary600,
            ),
            const SizedBox(height: 32),
          ],

          // 완료 버튼
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: (widget.isStandaloneMode
                      ? (!_accountVerified || _isRegistering)
                      : (!_agreeTerms || !_accountVerified || _isRegistering))
                  ? null
                  : _completeRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary600,
                foregroundColor: Colors.white,
                disabledBackgroundColor: backgroundColor,
                disabledForegroundColor: secondaryGray,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isRegistering
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.isStandaloneMode ? '호스트 전환 완료' : '회원가입 완료',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          // "나중에 입력" 버튼 (등록 플로우에서만 표시, standalone 모드에서는 미표시)
          if (!widget.isStandaloneMode) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _isRegistering ? null : _showSkipAccountDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: secondaryGray,
                  side: const BorderSide(color: borderGray, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '나중에 입력 (게스트로 활동)',
                  style: TextStyle(
                    fontSize: 14,
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

  /// "나중에 입력" 확인 다이얼로그
  void _showSkipAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게스트로 활동하시겠습니까?'),
        content: const Text(
          '계좌 정보를 나중에 입력하시면 게스트 모드로 활동하게 됩니다.\n'
          '호스트 기능을 사용하시려면 계좌 정보를 등록해야 합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 게스트 모드로 홈 이동 (계좌 미등록 상태 유지)
              context.go('/guest');
            },
            child: Text(
              '게스트로 활동',
              style: TextStyle(color: AppColors.primary600),
            ),
          ),
        ],
      ),
    );
  }
}
