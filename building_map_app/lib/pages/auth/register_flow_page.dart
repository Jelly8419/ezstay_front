import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../models/login_result.dart';
import '../../models/register_state.dart';
import '../../services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import 'steps/email_password_step.dart';
import 'steps/phone_verification_step.dart';
import 'steps/host_account_step.dart';

/// 회원가입 플로우 메인 페이지
class RegisterFlowPage extends StatefulWidget {
  final UserMode mode; // guest or host
  final bool isSocialLogin; // 카카오 가입 여부
  final String? initialEmail; // 카카오 이메일
  final String? initialName; // 카카오 이름
  final String? profileImageUrl; // 카카오 프로필

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

  // 색상 정의
  static const primaryBlack = Color(0xFF000000);
  static const backgroundWhite = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();

    // 초기 상태 설정
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

  /// 카카오 로그인으로 전환
  Future<void> _switchToKakaoLogin() async {
    try {
      final authService = context.read<AuthService>();

      // 카카오 로그인 시작
      final result = await authService.loginWithKakao(widget.mode);

      if (!mounted) return;

      if (result == LoginResult.success) {
        // 카카오 로그인 완료 - 홈 화면으로 이동
        final currentUser = authService.currentUser;

        if (!mounted) return;

        if (currentUser != null) {
          final userMode = currentUser.mode;
          if (userMode == UserMode.guest) {
            context.go('/guest');
          } else {
            context.go('/host');
          }
        }
      } else {
        // 카카오 로그인 실패
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('로그인 실패'),
            content: Text(result.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  /// 단계별 위젯 리스트
  List<Widget> _getSteps() {
    if (widget.isSocialLogin) {
      // 카카오 가입
      if (_state.mode == UserMode.host) {
        // 호스트: 2단계 (본인인증 → 정산계좌+약관)
        return [
          // Step 0: 본인인증만
          PhoneVerificationStep(
            initialPhoneNumber: _state.phoneNumber,
            email: _state.email ?? widget.initialEmail ?? '',
            password: '', // 소셜 로그인은 비밀번호 없음
            mode: _state.mode,
            isSocialLogin: true, // 소셜 로그인 (카카오)
            isPhoneVerificationOnly: true, // 본인인증만 하는 단계
            onNext: ({
              String? realName,
              String? phoneNumber,
              String? di,
              String? birth,
              String? gender,
            }) {
              // 본인인증 완료 - 다음 단계로
              if (!mounted) return;
              setState(() {
                if (realName != null && phoneNumber != null) {
                  _state.markPhoneVerified(phoneNumber, realName,
                      di: di, birth: birth, gender: gender);
                }
                _state.nextStep();
              });
            },
          ),

          // Step 1: 정산계좌 + 약관동의
          HostAccountStep(
            email: _state.email ?? widget.initialEmail ?? '',
            password: '', // 소셜 로그인은 비밀번호 없음
            phoneNumber: _state.phoneNumber ?? '',
            realName: _state.realName ?? '',
            di: _state.di,
            birth: _state.birth,
            gender: _state.gender,
            onNext: () async {
              // 회원가입 성공 - 자동 로그인 후 홈 화면으로 이동
              if (!mounted) return;

              final authService = context.read<AuthService>();

              // JWT 토큰으로 자동 로그인
              await authService.tryAutoLogin();

              // async 작업 후 mounted 체크
              if (!mounted) return;

              // 호스트 홈으로 이동
              if (authService.isLoggedIn && authService.currentUser != null) {
                context.go('/host');
              } else {
                // 자동 로그인 실패 시 로그인 페이지로
                context.go('/login');
              }
            },
          ),
        ];
      } else {
        // 게스트: 1단계 (본인인증 + 약관동의)
        return [
          PhoneVerificationStep(
            initialPhoneNumber: _state.phoneNumber,
            email: _state.email ?? widget.initialEmail ?? '',
            password: '', // 소셜 로그인은 비밀번호 없음
            mode: _state.mode,
            isSocialLogin: true, // 소셜 로그인 (카카오)
            isPhoneVerificationOnly: false, // 전체 단계
            onNext: ({
              String? realName,
              String? phoneNumber,
              String? di,
              String? birth,
              String? gender,
            }) async {
              // 회원가입 성공 - 자동 로그인 후 홈 화면으로 이동
              if (!mounted) return;

              final authService = context.read<AuthService>();

              // JWT 토큰으로 자동 로그인
              await authService.tryAutoLogin();

              // async 작업 후 mounted 체크
              if (!mounted) return;

              // 게스트 홈으로 이동
              if (authService.isLoggedIn && authService.currentUser != null) {
                context.go('/guest');
              } else {
                // 자동 로그인 실패 시 로그인 페이지로
                context.go('/login');
              }
            },
          ),
        ];
      }
    } else {
      // 이메일 가입
      if (_state.mode == UserMode.host) {
        // 호스트 이메일 가입: 3단계 (이메일/PW → 본인인증 → 정산계좌+약관)
        return [
          // Step 0: 이메일/비밀번호 + 이메일 인증
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

          // Step 1: 본인인증만
          PhoneVerificationStep(
            initialPhoneNumber: _state.phoneNumber,
            email: _state.email ?? '',
            password: _state.password ?? '',
            mode: _state.mode,
            isSocialLogin: false,
            isPhoneVerificationOnly: true, // 본인인증만
            onNext: ({
              String? realName,
              String? phoneNumber,
              String? di,
              String? birth,
              String? gender,
            }) {
              if (!mounted) return;
              // 본인인증 정보를 RegisterState에 저장
              setState(() {
                if (realName != null && phoneNumber != null) {
                  _state.markPhoneVerified(phoneNumber, realName,
                      di: di, birth: birth, gender: gender);
                }
                _state.nextStep();
              });
            },
          ),

          // Step 2: 정산계좌 + 약관동의
          HostAccountStep(
            email: _state.email ?? '',
            password: _state.password ?? '',
            phoneNumber: _state.phoneNumber ?? '',
            realName: _state.realName ?? '',
            di: _state.di,
            birth: _state.birth,
            gender: _state.gender,
            onNext: () async {
              if (!mounted) return;
              final authService = context.read<AuthService>();
              await authService.tryAutoLogin();
              if (!mounted) return;
              if (authService.isLoggedIn && authService.currentUser != null) {
                context.go('/host');
              } else {
                context.go('/login');
              }
            },
          ),
        ];
      } else {
        // 게스트 이메일 가입: 2단계 (이메일/PW → 본인인증+약관)
        return [
          // Step 0: 이메일/비밀번호 + 이메일 인증
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

          // Step 1: 본인인증 + 약관동의
          PhoneVerificationStep(
            initialPhoneNumber: _state.phoneNumber,
            email: _state.email ?? '',
            password: _state.password ?? '',
            mode: _state.mode,
            isSocialLogin: false,
            isPhoneVerificationOnly: false, // 전체 단계
            onNext: ({
              String? realName,
              String? phoneNumber,
              String? di,
              String? birth,
              String? gender,
            }) async {
              if (!mounted) return;
              final authService = context.read<AuthService>();
              await authService.tryAutoLogin();
              if (!mounted) return;
              if (authService.isLoggedIn && authService.currentUser != null) {
                context.go('/guest');
              } else {
                context.go('/login');
              }
            },
          ),
        ];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _getSteps();
    final currentStepIndex = _state.currentStep >= steps.length
        ? steps.length - 1
        : _state.currentStep;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_state.currentStep > 0) {
          setState(() {
            _state.prevStep();
          });
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
              setState(() {
                _state.prevStep();
              });
            } else {
              _showExitConfirmDialog();
            }
          },
        ),
        title: Text(
          widget.mode == UserMode.guest ? '게스트 가입' : '호스트 가입',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: primaryBlack,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.only(
              top: 20,
              left: 24,
              right: 24,
              bottom: 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 진행 상태 표시
                _buildProgressIndicator(),
                const SizedBox(height: 40),

                // 현재 단계 위젯
                steps[currentStepIndex],
              ],
            ),
          ),
        ),
      ),
    ), // PopScope
    );
  }

  /// 회원가입 이탈 확인 다이얼로그
  void _showExitConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원가입 중단'),
        content: const Text(
          '인증이 진행 중입니다. 나가시겠습니까?\n입력한 정보는 저장되지 않습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('계속 진행'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            child: Text(
              '나가기',
              style: TextStyle(color: AppColors.error500),
            ),
          ),
        ],
      ),
    );
  }

  /// 진행 상태 표시 인디케이터
  Widget _buildProgressIndicator() {
    final totalSteps = _state.totalSteps;
    final currentStep = _state.currentStep;

    return Column(
      children: [
        // 진행바
        Row(
          children: List.generate(totalSteps, (index) {
            final isCompleted = index < currentStep;
            final isCurrent = index == currentStep;

            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < totalSteps - 1 ? 4 : 0),
                decoration: BoxDecoration(
                  color: isCompleted || isCurrent
                      ? AppColors.primary600
                      : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),

        // 진행 텍스트
        Text(
          'Step ${currentStep + 1} / $totalSteps',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.primary600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
