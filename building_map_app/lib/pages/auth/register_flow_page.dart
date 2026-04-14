import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../models/login_result.dart';
import '../../models/register_state.dart';
import '../../services/auth_service.dart';
import '../../services/token_service.dart';
import '../../config/api_config.dart';
import '../../core/theme/app_colors.dart';
import 'steps/email_password_step.dart';
import 'steps/phone_verification_step.dart';
import 'steps/host_account_step.dart';

/// 회원가입 플로우 메인 페이지
///
/// 4가지 가입 케이스의 API 호출을 모두 이 파일에서 담당한다.
///
/// [이메일 게스트]  EmailPassword → PhoneVerification(약관O) → _registerEmailGuest()
/// [이메일 호스트]  EmailPassword → PhoneVerification(약관X) → HostAccount → _registerEmailHost()
/// [소셜 게스트]   PhoneVerification(약관O, skipButton) → _registerSocialGuest()
/// [소셜 호스트]   PhoneVerification(약관X) → HostAccount → _registerSocialHost()
class RegisterFlowPage extends StatefulWidget {
  final UserMode mode;
  final bool isSocialLogin;
  final String? initialEmail;
  final String? initialName;
  final String? profileImageUrl;

  const RegisterFlowPage({
    super.key,
    required this.mode,
    this.isSocialLogin = false,
    this.initialEmail,
    this.initialName,
    this.profileImageUrl,
  });

  @override
  State<RegisterFlowPage> createState() => _RegisterFlowPageState();
}

class _RegisterFlowPageState extends State<RegisterFlowPage> {
  late RegisterState _state;

  static const primaryBlack = Color(0xFF000000);
  static const backgroundWhite = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    if (widget.isSocialLogin) {
      _state = RegisterState.fromKakao(
        email: widget.initialEmail!,
        name: widget.initialName!,
        mode: widget.mode,
        profileImageUrl: widget.profileImageUrl,
      );
    } else {
      _state = RegisterState(mode: widget.mode);
    }
  }

  // ──────────────────────────────────────────────
  // 카카오 로그인 전환 (EmailPasswordStep에서 호출)
  // ──────────────────────────────────────────────

  Future<void> _switchToKakaoLogin() async {
    try {
      final authService = context.read<AuthService>();
      final result = await authService.loginWithKakao(widget.mode);

      if (!mounted) return;

      if (result == LoginResult.success) {
        // 카카오 인증 완료 → 소셜 가입 플로우로 전환 (홈 이동 금지)
        final currentUser = authService.currentUser;
        context.pushReplacement(
          '/register',
          extra: {
            'mode': widget.mode,
            'isSocialLogin': true,
            'email': currentUser?.email,
            'name': currentUser?.name,
          },
        );
      } else if (result == LoginResult.unknownError) {
        // 웹 환경: 카카오 OAuth 리다이렉트 중 — 페이지가 이동되므로 무시
        return;
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('로그인 실패'),
            content: Text(result.message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('오류'),
          content: Text('카카오 로그인 중 오류가 발생했습니다.\n$e'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
          ],
        ),
      );
    }
  }

  // ──────────────────────────────────────────────
  // API 호출 — 4가지 케이스
  // ──────────────────────────────────────────────

  /// [이메일 게스트] POST /api/auth/register (user_mode: guest)
  Future<void> _registerEmailGuest({
    required String realName,
    required String phoneNumber,
    String? certNum,
    String? birth,
    String? gender,
    required bool agreeTerms,
    required bool agreeMarketing,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.authRegisterUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': _state.email,
              'password': _state.password,
              'user_mode': 'guest',
              'name': realName,
              'phone_number': phoneNumber,
              if (certNum != null) 'certNum': certNum,
              if (birth != null) 'birth': birth,
              if (gender != null) 'gender': gender,
              'terms': {
                'service_terms': agreeTerms,
                'privacy_policy': agreeTerms,
                'marketing_consent': agreeMarketing,
                'age_confirmed': true,
              },
            }),
          )
          .timeout(ApiConfig.timeout);

      await _handleRegisterResponse(response);
      if (!mounted) return;
      await _autoLoginAndNavigate(UserMode.guest);
    } catch (e) {
      _showError('회원가입에 실패했습니다.\n${e.toString()}');
    }
  }

  /// [이메일 호스트] POST /api/auth/register (user_mode: host, 계좌 포함)
  Future<void> _registerEmailHost({
    required String bankCode,
    required String accountNum,
    required String accountHolderName,
    required bool agreeTerms,
    required bool agreeMarketing,
  }) async {
    // bankCode가 비어 있으면 계좌 없이 게스트로 가입 (나중에 입력 선택)
    if (bankCode.isEmpty) {
      await _registerEmailGuest(
        realName: _state.realName!,
        phoneNumber: _state.phoneNumber!,
        certNum: _state.certNum,
        birth: _state.birth,
        gender: _state.gender,
        agreeTerms: agreeTerms,
        agreeMarketing: agreeMarketing,
      );
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.authRegisterUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': _state.email,
              'password': _state.password,
              'user_mode': 'host',
              'name': _state.realName,
              'phone_number': _state.phoneNumber,
              if (_state.certNum != null) 'certNum': _state.certNum,
              if (_state.birth != null) 'birth': _state.birth,
              if (_state.gender != null) 'gender': _state.gender,
              'bank_code': bankCode,
              'account_num': accountNum,
              'account_holder_name': accountHolderName,
              'terms': {
                'service_terms': agreeTerms,
                'privacy_policy': agreeTerms,
                'marketing_consent': agreeMarketing,
                'age_confirmed': true,
              },
            }),
          )
          .timeout(ApiConfig.timeout);

      await _handleRegisterResponse(response);
      if (!mounted) return;
      await _autoLoginAndNavigate(UserMode.host);
    } catch (e) {
      _showError('회원가입에 실패했습니다.\n${e.toString()}');
    }
  }

  /// [소셜 게스트] POST /api/user/guest/verification
  Future<void> _registerSocialGuest({
    required String realName,
    required String phoneNumber,
    String? certNum,
    String? birth,
    String? gender,
    required bool agreeTerms,
    required bool agreeMarketing,
  }) async {
    try {
      final token = await TokenService.getAccessToken(skipExpiryCheck: true);
      if (token == null) throw Exception('저장된 JWT 토큰을 찾을 수 없습니다. 다시 로그인해주세요.');

      final response = await http
          .post(
            Uri.parse(ApiConfig.guestVerificationUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'name': realName,
              'phone_number': phoneNumber,
              if (certNum != null) 'certNum': certNum,
              if (birth != null) 'birth': birth,
              if (gender != null) 'gender': gender,
              'terms': {
                'service_terms': agreeTerms,
                'privacy_policy': agreeTerms,
                'marketing_consent': agreeMarketing,
                'age_confirmed': true,
              },
            }),
          )
          .timeout(ApiConfig.timeout);

      await _handleVerificationResponse(response);
      if (!mounted) return;
      await _autoLoginAndNavigate(UserMode.guest);
    } catch (e) {
      _showError('회원가입에 실패했습니다.\n${e.toString()}');
    }
  }

  /// [소셜 호스트] POST /api/user/host/verification (계좌 포함)
  Future<void> _registerSocialHost({
    required String bankCode,
    required String accountNum,
    required String accountHolderName,
    required bool agreeTerms,
    required bool agreeMarketing,
  }) async {
    // 나중에 입력 선택 → 소셜 게스트로 가입
    if (bankCode.isEmpty) {
      await _registerSocialGuest(
        realName: _state.realName!,
        phoneNumber: _state.phoneNumber!,
        certNum: _state.certNum,
        birth: _state.birth,
        gender: _state.gender,
        agreeTerms: agreeTerms,
        agreeMarketing: agreeMarketing,
      );
      return;
    }

    try {
      final token = await TokenService.getAccessToken(skipExpiryCheck: true);
      if (token == null) throw Exception('저장된 JWT 토큰을 찾을 수 없습니다. 다시 로그인해주세요.');

      final response = await http
          .post(
            Uri.parse(ApiConfig.hostVerificationUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'name': _state.realName,
              'phone_number': _state.phoneNumber,
              if (_state.certNum != null) 'certNum': _state.certNum,
              if (_state.birth != null) 'birth': _state.birth,
              if (_state.gender != null) 'gender': _state.gender,
              'bank_code': bankCode,
              'account_num': accountNum,
              'account_holder_name': accountHolderName,
              'terms': {
                'service_terms': agreeTerms,
                'privacy_policy': agreeTerms,
                'marketing_consent': agreeMarketing,
                'age_confirmed': true,
              },
            }),
          )
          .timeout(ApiConfig.timeout);

      await _handleVerificationResponse(response);
      if (!mounted) return;
      await _autoLoginAndNavigate(UserMode.host);
    } catch (e) {
      _showError('회원가입에 실패했습니다.\n${e.toString()}');
    }
  }

  // ──────────────────────────────────────────────
  // 공통 응답 처리 헬퍼
  // ──────────────────────────────────────────────

  /// register API 응답 처리 + 토큰 저장
  Future<void> _handleRegisterResponse(http.Response response) async {
    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? '회원가입에 실패했습니다');
    }
    final data = jsonDecode(response.body);
    if (data['success'] != true) throw Exception(data['message'] ?? '회원가입에 실패했습니다');

    final accessToken = data['data']?['accessToken'] ?? data['accessToken'];
    final refreshToken = data['data']?['refreshToken'] ?? data['refreshToken'];
    if (accessToken == null) throw Exception('JWT 토큰을 받지 못했습니다');
    await TokenService.saveTokens(accessToken as String, refreshToken as String?);
  }

  /// verification API 응답 처리 + 토큰 갱신
  Future<void> _handleVerificationResponse(http.Response response) async {
    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? '본인인증 정보 저장에 실패했습니다');
    }
    final data = jsonDecode(response.body);
    if (data['success'] != true) throw Exception(data['message'] ?? '본인인증 정보 저장에 실패했습니다');

    // 응답에 새 토큰이 있으면 갱신
    final accessToken = data['data']?['accessToken'];
    final refreshToken = data['data']?['refreshToken'];
    if (accessToken != null) {
      await TokenService.saveTokens(accessToken as String, refreshToken as String?);
    }
  }

  /// 자동 로그인 후 홈 이동
  Future<void> _autoLoginAndNavigate(UserMode targetMode) async {
    final authService = context.read<AuthService>();
    await authService.tryAutoLogin();
    if (!mounted) return;
    if (authService.isLoggedIn && authService.currentUser != null) {
      context.go(targetMode == UserMode.host ? '/host' : '/guest');
    } else {
      context.go('/login');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // 단계별 위젯 구성
  // ──────────────────────────────────────────────

  List<Widget> _getSteps() {
    if (widget.isSocialLogin) {
      if (_state.mode == UserMode.host) {
        // ── 소셜 호스트: 2단계 ──
        // Step 0: 본인인증 (약관 없음, 다음 버튼)
        // Step 1: 계좌 + 약관
        return [
          PhoneVerificationStep(
            initialPhoneNumber: _state.phoneNumber,
            showTerms: false,
            nextButtonLabel: '다음',
            onNext: ({
              required String realName,
              required String phoneNumber,
              String? certNum,
              String? birth,
              String? gender,
              required bool agreeTerms,
              required bool agreeMarketing,
            }) {
              if (!mounted) return;
              setState(() {
                _state.markPhoneVerified(phoneNumber, realName, certNum: certNum, birth: birth, gender: gender);
                _state.nextStep();
              });
            },
          ),
          HostAccountStep(
            realName: _state.realName,
            onNext: ({
              required String bankCode,
              required String accountNum,
              required String accountHolderName,
              required bool agreeTerms,
              required bool agreeMarketing,
            }) {
              _registerSocialHost(
                bankCode: bankCode,
                accountNum: accountNum,
                accountHolderName: accountHolderName,
                agreeTerms: agreeTerms,
                agreeMarketing: agreeMarketing,
              );
            },
          ),
        ];
      } else {
        // ── 소셜 게스트: 1단계 ──
        // Step 0: 본인인증 + 약관 + 비회원 버튼
        return [
          PhoneVerificationStep(
            initialPhoneNumber: _state.phoneNumber,
            showTerms: true,
            showSkipButton: true,
            nextButtonLabel: '회원가입 완료',
            onNext: ({
              required String realName,
              required String phoneNumber,
              String? certNum,
              String? birth,
              String? gender,
              required bool agreeTerms,
              required bool agreeMarketing,
            }) {
              _registerSocialGuest(
                realName: realName,
                phoneNumber: phoneNumber,
                certNum: certNum,
                birth: birth,
                gender: gender,
                agreeTerms: agreeTerms,
                agreeMarketing: agreeMarketing,
              );
            },
          ),
        ];
      }
    } else {
      if (_state.mode == UserMode.host) {
        // ── 이메일 호스트: 3단계 ──
        // Step 0: 이메일/PW
        // Step 1: 본인인증 (약관 없음)
        // Step 2: 계좌 + 약관
        return [
          EmailPasswordStep(
            initialEmail: _state.email,
            initialPassword: _state.password,
            mode: _state.mode,
            onNext: (email, password) {
              setState(() {
                _state.setEmailPassword(email, password);
                _state.markEmailVerified();
                _state.nextStep();
              });
            },
            onKakaoLogin: _switchToKakaoLogin,
          ),
          PhoneVerificationStep(
            initialPhoneNumber: _state.phoneNumber,
            showTerms: false,
            nextButtonLabel: '다음',
            onNext: ({
              required String realName,
              required String phoneNumber,
              String? certNum,
              String? birth,
              String? gender,
              required bool agreeTerms,
              required bool agreeMarketing,
            }) {
              if (!mounted) return;
              setState(() {
                _state.markPhoneVerified(phoneNumber, realName, certNum: certNum, birth: birth, gender: gender);
                _state.nextStep();
              });
            },
          ),
          HostAccountStep(
            realName: _state.realName,
            onNext: ({
              required String bankCode,
              required String accountNum,
              required String accountHolderName,
              required bool agreeTerms,
              required bool agreeMarketing,
            }) {
              _registerEmailHost(
                bankCode: bankCode,
                accountNum: accountNum,
                accountHolderName: accountHolderName,
                agreeTerms: agreeTerms,
                agreeMarketing: agreeMarketing,
              );
            },
          ),
        ];
      } else {
        // ── 이메일 게스트: 2단계 ──
        // Step 0: 이메일/PW
        // Step 1: 본인인증 + 약관
        return [
          EmailPasswordStep(
            initialEmail: _state.email,
            initialPassword: _state.password,
            mode: _state.mode,
            onNext: (email, password) {
              setState(() {
                _state.setEmailPassword(email, password);
                _state.markEmailVerified();
                _state.nextStep();
              });
            },
            onKakaoLogin: _switchToKakaoLogin,
          ),
          PhoneVerificationStep(
            initialPhoneNumber: _state.phoneNumber,
            showTerms: true,
            nextButtonLabel: '회원가입 완료',
            onNext: ({
              required String realName,
              required String phoneNumber,
              String? certNum,
              String? birth,
              String? gender,
              required bool agreeTerms,
              required bool agreeMarketing,
            }) {
              _registerEmailGuest(
                realName: realName,
                phoneNumber: phoneNumber,
                certNum: certNum,
                birth: birth,
                gender: gender,
                agreeTerms: agreeTerms,
                agreeMarketing: agreeMarketing,
              );
            },
          ),
        ];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _getSteps();
    final currentStepIndex = _state.currentStep >= steps.length ? steps.length - 1 : _state.currentStep;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_state.currentStep > 0) {
          setState(() => _state.prevStep());
        } else {
          _showExitConfirmDialog();
        }
      },
      child: Scaffold(
        backgroundColor: backgroundWhite,
        appBar: AppBar(
          backgroundColor: backgroundWhite,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: primaryBlack),
            onPressed: () {
              if (_state.currentStep > 0) {
                setState(() => _state.prevStep());
              } else {
                _showExitConfirmDialog();
              }
            },
          ),
          title: Text(
            widget.mode == UserMode.guest ? '임차인 가입' : '임대인 가입',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: primaryBlack),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProgressIndicator(),
                  const SizedBox(height: 40),
                  steps[currentStepIndex],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showExitConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원가입 중단'),
        content: const Text('인증이 진행 중입니다. 나가시겠습니까?\n입력한 정보는 저장되지 않습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('계속 진행')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // 소셜 로그인으로 토큰이 발급된 상태일 수 있으므로 로그아웃 처리
              // (토큰이 남아있으면 redirect 로직이 다시 /register로 튕김)
              await context.read<AuthService>().logout();
              if (context.mounted) context.go('/login');
            },
            child: Text('나가기', style: TextStyle(color: AppColors.error500)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final totalSteps = _state.totalSteps;
    final currentStep = _state.currentStep;

    return Column(
      children: [
        Row(
          children: List.generate(totalSteps, (index) {
            final isCompleted = index < currentStep;
            final isCurrent = index == currentStep;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < totalSteps - 1 ? 4 : 0),
                decoration: BoxDecoration(
                  color: isCompleted || isCurrent ? AppColors.primary600 : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text(
          'Step ${currentStep + 1} / $totalSteps',
          style: TextStyle(fontSize: 14, color: AppColors.primary600, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
