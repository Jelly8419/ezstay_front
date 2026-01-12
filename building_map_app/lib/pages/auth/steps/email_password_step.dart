import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/verification_service.dart';
import '../../../models/user.dart';

/// Step 1: 이메일/비밀번호 입력 및 이메일 인증 단계
class EmailPasswordStep extends StatefulWidget {
  final String? initialEmail;
  final String? initialPassword;
  final UserMode mode;
  final Function(String email, String password) onNext;
  final VoidCallback? onKakaoLogin; // 카카오 로그인 콜백

  const EmailPasswordStep({
    super.key,
    this.initialEmail,
    this.initialPassword,
    required this.mode,
    required this.onNext,
    this.onKakaoLogin,
  });

  @override
  State<EmailPasswordStep> createState() => _EmailPasswordStepState();
}

class _EmailPasswordStepState extends State<EmailPasswordStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  final _verificationCodeController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // 이메일 인증 관련 상태
  bool _isEmailSending = false;
  bool _isCodeSent = false;
  bool _isVerifying = false;
  bool _isEmailVerified = false;
  int _resendCountdown = 300; // 5분 (300초)
  Timer? _timer;

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
    _emailController = TextEditingController(text: widget.initialEmail);
    _passwordController = TextEditingController(text: widget.initialPassword);
    _confirmPasswordController = TextEditingController();

    // 첫 번째 입력 필드에 자동 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_emailController.text.isEmpty) {
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _verificationCodeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  /// 타이머 시작
  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _resendCountdown = 300;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  /// 이메일 인증 코드 발송
  Future<void> _sendVerificationCode() async {
    // 이메일 유효성 검사
    if (_emailController.text.isEmpty) {
      _showErrorDialog('이메일을 입력해주세요');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailController.text)) {
      _showErrorDialog('올바른 이메일 형식이 아닙니다');
      return;
    }

    setState(() {
      _isEmailSending = true;
    });

    try {
      await VerificationService.sendEmailVerification(_emailController.text);

      if (mounted) {
        setState(() {
          _isCodeSent = true;
          _isEmailSending = false;
        });
        _startCountdown();

        _showSuccessDialog('${_emailController.text}로\n인증 코드를 발송했습니다');
      }
    } on VerificationException catch (e) {
      if (mounted) {
        setState(() {
          _isEmailSending = false;
        });
        _showErrorDialog(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEmailSending = false;
        });
        _showErrorDialog('인증 코드 발송 중 오류가 발생했습니다');
      }
    }
  }

  /// 이메일 인증 코드 재발송
  Future<void> _resendVerificationCode() async {
    if (_resendCountdown > 0) {
      _showErrorDialog('잠시 후 다시 시도해주세요');
      return;
    }

    setState(() {
      _isEmailSending = true;
    });

    try {
      await VerificationService.resendEmailVerification(_emailController.text);

      if (mounted) {
        setState(() {
          _isEmailSending = false;
        });
        _startCountdown();

        _showSuccessDialog('인증 코드를 재발송했습니다');
      }
    } on VerificationException catch (e) {
      if (mounted) {
        setState(() {
          _isEmailSending = false;
        });
        _showErrorDialog(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEmailSending = false;
        });
        _showErrorDialog('인증 코드 재발송 중 오류가 발생했습니다');
      }
    }
  }

  /// 인증 코드 확인
  Future<void> _verifyCode() async {
    if (_verificationCodeController.text.isEmpty) {
      _showErrorDialog('인증 코드를 입력해주세요');
      return;
    }

    if (_verificationCodeController.text.length != 6) {
      _showErrorDialog('6자리 코드를 입력해주세요');
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final success = await VerificationService.verifyEmailCode(
        _emailController.text,
        _verificationCodeController.text,
      );

      if (mounted) {
        setState(() {
          _isVerifying = false;
        });

        if (success) {
          _timer?.cancel();
          setState(() {
            _isEmailVerified = true;
          });

          _showSuccessDialog('이메일 인증이 완료되었습니다');
        }
      }
    } on VerificationException catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
        _showErrorDialog(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
        _showErrorDialog('인증 코드 확인 중 오류가 발생했습니다');
      }
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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

  void _handleNext() {
    if (!_isEmailVerified) {
      _showErrorDialog('이메일 인증을 먼저 완료해주세요');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 다음 단계(본인인증)로 이동
    widget.onNext(_emailController.text, _passwordController.text);
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
            '이메일로 가입하기',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: primaryBlack,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '이메일 인증 후 비밀번호를 설정해주세요',
            style: TextStyle(
              fontSize: 16,
              color: textGray,
            ),
          ),
          const SizedBox(height: 40),

          // 이메일 라벨
          const Text(
            '이메일 주소',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: textGray,
            ),
          ),
          const SizedBox(height: 8),

          // 이메일 입력 + 인증하기 버튼
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    enabled: !_isEmailVerified, // 인증 완료 후 비활성화
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: primaryBlack,
                    ),
                    decoration: InputDecoration(
                      hintText: 'email@example.com',
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: hintGray,
                      ),
                      filled: true,
                      fillColor: _isEmailVerified
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
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: borderGray,
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
              ),
              const SizedBox(width: 8),

              // 인증하기 버튼
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isEmailVerified
                      ? null
                      : (_isEmailSending ? null : _sendVerificationCode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEmailVerified
                        ? AppColors.success500
                        : AppColors.primary600,
                    foregroundColor: backgroundWhite,
                    disabledBackgroundColor: borderGray,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isEmailSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(backgroundWhite),
                          ),
                        )
                      : Text(
                          _isEmailVerified ? '인증완료' : '인증하기',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ],
          ),

          // 인증 코드 입력란 (인증 코드 발송 후에만 표시)
          if (_isCodeSent && !_isEmailVerified) ...[
            const SizedBox(height: 20),

            // 인증 코드 라벨
            const Text(
              '인증 코드',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: textGray,
              ),
            ),
            const SizedBox(height: 8),

            // 인증 코드 입력 + 재발송/인증 버튼
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: TextFormField(
                      controller: _verificationCodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: primaryBlack,
                      ),
                      decoration: InputDecoration(
                        hintText: '6자리 인증 코드',
                        hintStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: hintGray,
                        ),
                        filled: true,
                        fillColor: backgroundWhite,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        counterText: '',
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
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 재발송 버튼
                SizedBox(
                  height: 52,
                  width: 80,
                  child: ElevatedButton(
                    onPressed: _resendCountdown == 0 && !_isEmailSending
                        ? _resendVerificationCode
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      foregroundColor: backgroundWhite,
                      disabledBackgroundColor: borderGray,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isEmailSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  backgroundWhite),
                            ),
                          )
                        : Text(
                            _resendCountdown > 0
                                ? _formatTime(_resendCountdown)
                                : '재발송',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),

                // 인증 버튼
                SizedBox(
                  height: 52,
                  width: 80,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      foregroundColor: backgroundWhite,
                      disabledBackgroundColor: borderGray,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  backgroundWhite),
                            ),
                          )
                        : const Text(
                            '인증',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // 비밀번호 라벨
          const Text(
            '비밀번호',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: textGray,
            ),
          ),
          const SizedBox(height: 8),

          // 비밀번호 입력
          SizedBox(
            height: 52,
            child: TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: primaryBlack,
              ),
              decoration: InputDecoration(
                hintText: '8자 이상, 영문과 숫자 포함',
                hintStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
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
                if (value.length < 8) {
                  return '비밀번호는 8자 이상이어야 합니다';
                }
                if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d).+$').hasMatch(value)) {
                  return '영문과 숫자를 포함해야 합니다';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),

          // 비밀번호 확인 라벨
          const Text(
            '비밀번호 확인',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: textGray,
            ),
          ),
          const SizedBox(height: 8),

          // 비밀번호 확인 입력
          SizedBox(
            height: 52,
            child: TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: primaryBlack,
              ),
              decoration: InputDecoration(
                hintText: '비밀번호를 다시 입력해 주세요.',
                hintStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
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
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: secondaryGray,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호 확인을 입력해주세요';
                }
                if (value != _passwordController.text) {
                  return '비밀번호가 일치하지 않습니다';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 40),

          // 다음 버튼
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary600,
                foregroundColor: backgroundWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '다음',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // 카카오 로그인 옵션 (onKakaoLogin 콜백이 있을 때만 표시)
          if (widget.onKakaoLogin != null) ...[
            const SizedBox(height: 40),

            // 구분선
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: secondaryGray,
                    ),
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

            // 카카오로 시작하기 버튼
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: widget.onKakaoLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFE812), // 카카오 노란색
                  foregroundColor: const Color(0xFF3C1E1E), // 어두운 갈색 텍스트
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.chat_bubble,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '카카오로 시작하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
