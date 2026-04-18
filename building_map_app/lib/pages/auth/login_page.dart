import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../../models/login_result.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/mode_selection_dialog.dart';
import '../../widgets/common/ezstay_logo.dart';

/// 로그인 페이지 - 미니멀 디자인
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoggingIn = false;
  bool _autoLogin = false;
  bool _obscurePassword = true;

  // PRD 5.2: 로그인 실패 횟수 제한 (5회/10분)
  int _failureCount = 0;
  DateTime? _lockoutEndTime;
  static const int _maxFailures = 5;
  static const Duration _lockoutDuration = Duration(minutes: 10);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============= 색상 정의 =============
  static const primaryBlack = Color(0xFF000000);
  static const secondaryGray = Color(0xFF808080);
  static const borderGray = Color(0xFFE0E0E0);
  static const backgroundWhite = Color(0xFFFFFFFF);
  static const hintGray = Color(0xFFCCCCCC);
  static const textGray = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundWhite,
      child: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.only(
              top: 80,
              left: 24,
              right: 24,
              bottom: 40,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 제목
                  // ub85cuace0
                  const Center(
                    child: EZStayLogo(
                      width: 150,
                      height: 150,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    '로그인하기',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: primaryBlack,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),

                  // 이메일 라벨
                  const Text(
                    '이메일 주소',
                    style: AppTextStyles.labelMedium,
                  ),
                  const SizedBox(height: 8),

                  // 이메일 입력
                  SizedBox(
                    height: 52,
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: primaryBlack,
                      ),
                      decoration: InputDecoration(
                        hintText: '이메일 주소를 입력해 주세요.',
                        hintStyle: AppTextStyles.labelLarge.copyWith(
                          color: hintGray,
                        ),
                        filled: true,
                        fillColor: backgroundWhite,
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
                          borderSide: const BorderSide(
                            color: borderGray,
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
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.error500,
                            width: 1,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '이메일을 입력해주세요';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return '올바른 이메일 형식이 아닙니다';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 비밀번호 라벨
                  const Text(
                    '비밀번호',
                    style: AppTextStyles.labelMedium,
                  ),
                  const SizedBox(height: 8),

                  // 비밀번호 입력
                  SizedBox(
                    height: 52,
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: primaryBlack,
                      ),
                      decoration: InputDecoration(
                        hintText: '비밀번호를 입력해 주세요.',
                        hintStyle: AppTextStyles.labelLarge.copyWith(
                          color: hintGray,
                        ),
                        filled: true,
                        fillColor: backgroundWhite,
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
                          borderSide: const BorderSide(
                            color: borderGray,
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
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.error500,
                            width: 1,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: secondaryGray,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 자동 로그인 & 아이디/비밀번호 찾기
                  Row(
                    children: [
                      // 자동 로그인
                      InkWell(
                        onTap: () {
                          setState(() {
                            _autoLogin = !_autoLogin;
                          });
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _autoLogin,
                                onChanged: (value) {
                                  setState(() {
                                    _autoLogin = value ?? false;
                                  });
                                },
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                activeColor: AppColors.primary600,
                                side: const BorderSide(
                                  color: borderGray,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '자동 로그인',
                              style: AppTextStyles.labelMedium,
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // 아이디 찾기
                      TextButton(
                        onPressed: () => context.push('/find-id'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '아이디 찾기',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: secondaryGray,
                          ),
                        ),
                      ),

                      Text(
                        ' | ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: borderGray,
                        ),
                      ),

                      // 비밀번호 찾기
                      TextButton(
                        onPressed: () {
                          context.push('/reset-password');
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '비밀번호 찾기',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: secondaryGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 로그인 버튼
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoggingIn ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary600,
                        foregroundColor: backgroundWhite,
                        disabledBackgroundColor: borderGray,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoggingIn
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(backgroundWhite),
                              ),
                            )
                          : const Text(
                              '로그인',
                              style: AppTextStyles.labelLarge,
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 회원가입 버튼
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _handleSignup,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryBlack,
                        side: const BorderSide(
                          color: borderGray,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '회원가입',
                        style: AppTextStyles.labelLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 소셜 로그인 구분선
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(
                          color: borderGray,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '또는',
                          style: AppTextStyles.labelMedium.copyWith(color: secondaryGray),
                        ),
                      ),
                      const Expanded(
                        child: Divider(
                          color: borderGray,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 카카오 로그인
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handleKakaoLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE812),
                        foregroundColor: const Color(0xFF3C1E1E),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '카카오로 계속하기',
                            style: AppTextStyles.labelLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// PRD 5.2: 잠금 상태 확인
  bool _isLockedOut() {
    if (_lockoutEndTime == null) return false;
    if (DateTime.now().isAfter(_lockoutEndTime!)) {
      _lockoutEndTime = null;
      _failureCount = 0;
      return false;
    }
    return true;
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // PRD 5.2: 잠금 상태 확인
    if (_isLockedOut()) {
      final remaining = _lockoutEndTime!.difference(DateTime.now());
      _showErrorDialog(
        '로그인 시도가 여러 번 실패하여\n${remaining.inMinutes}분간 로그인할 수 없습니다.',
      );
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      final authService = context.read<AuthService>();
      final result = await authService.loginWithEmail(
        _emailController.text,
        _passwordController.text,
        null,
      );

      if (mounted) {
        setState(() => _isLoggingIn = false);

        if (result == LoginResult.success) {
          _failureCount = 0;
          _lockoutEndTime = null;
          context.go('/');
        } else if (result == LoginResult.accountWithdrawn) {
          // PRD 5.3.2: 탈퇴 계정 재가입 다이얼로그
          _showWithdrawnAccountDialog();
        } else if (result == LoginResult.accountSuspended) {
          // PRD 5.3.1: 정지 계정은 라우터가 처리하지만, 로그인 단계에서도 안내
          _showErrorDialog(result.message);
        } else {
          // PRD 5.2: 실패 횟수 증가
          _failureCount++;
          if (_failureCount >= _maxFailures) {
            _lockoutEndTime = DateTime.now().add(_lockoutDuration);
            _showErrorDialog(
              '로그인 시도가 여러 번 실패하여\n10분간 로그인할 수 없습니다.',
            );
          } else {
            _showErrorDialog(result.message);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoggingIn = false);
        _showErrorDialog(LoginResult.unknownError.message);
      }
    }
  }

  Future<void> _handleKakaoLogin() async {
    try {
      final authService = context.read<AuthService>();

      // 웹 환경에서는 전체 페이지 리다이렉트
      if (kIsWeb) {
        await authService.loginWithKakao(UserMode.guest);
        // 페이지가 리다이렉트되므로 이후 코드는 실행되지 않음
        return;
      }

      // 모바일 환경: 일반 카카오 로그인 플로우
      final result = await authService.loginWithKakao(UserMode.guest);

      if (!mounted) return;

      if (result == LoginResult.success) {
        final currentUser = authService.currentUser;
        context.push(
          '/register',
          extra: {
            'mode': UserMode.guest,
            'email': currentUser?.email,
            'name': currentUser?.name,
            'isSocialLogin': true,
          },
        );
      } else if (result == LoginResult.kakaoEmailDuplicate) {
        // PRD 8: 이메일 중복 안내
        _showErrorDialog(result.message);
      } else if (result == LoginResult.accountWithdrawn) {
        _showWithdrawnAccountDialog();
      } else if (result.isFailure) {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(LoginResult.kakaoOAuthFailed.message);
      }
    }
  }

  /// PRD 5.3.2: 탈퇴 계정 재가입 안내 다이얼로그
  void _showWithdrawnAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: backgroundWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          '탈퇴한 계정',
          style: AppTextStyles.headingSmall,
        ),
        content: const Text(
          '탈퇴한 계정입니다.\n재가입 하시겠습니까?',
          style: AppTextStyles.labelMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              '취소',
              style: AppTextStyles.labelMedium.copyWith(color: secondaryGray),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // 모드 선택 후 회원가입 페이지로 이동
              final selectedMode = await ModeSelectionBottomSheet.show(context);
              if (selectedMode != null && mounted) {
                final modeStr = selectedMode == UserMode.host ? 'host' : 'guest';
                context.push('/register?mode=$modeStr');
              }
            },
            child: Text(
              '재가입하기',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary600),
            ),
          ),
        ],
      ),
    );
  }

  /// 회원가입 처리 - 모드 선택 다이얼로그 후 회원가입 페이지로 이동
  Future<void> _handleSignup() async {
    final selectedMode = await ModeSelectionBottomSheet.show(context);

    if (selectedMode != null && mounted) {
      final modeStr = selectedMode == UserMode.host ? 'host' : 'guest';
      context.go('/register?mode=$modeStr');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          '로그인 실패',
          style: AppTextStyles.headingSmall,
        ),
        content: Text(
          message,
          style: AppTextStyles.labelMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '확인',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary600),
            ),
          ),
        ],
      ),
    );
  }

}
