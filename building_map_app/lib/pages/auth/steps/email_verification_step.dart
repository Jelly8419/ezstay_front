import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/verification_service.dart';

/// Step 2: 이메일 인증 단계
class EmailVerificationStep extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;
  final VoidCallback onPrevious;

  const EmailVerificationStep({
    super.key,
    required this.email,
    required this.onVerified,
    required this.onPrevious,
  });

  @override
  State<EmailVerificationStep> createState() => _EmailVerificationStepState();
}

class _EmailVerificationStepState extends State<EmailVerificationStep> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isVerifying = false;
  bool _isSending = false;
  int _resendCountdown = 180; // 3분 (180초)
  Timer? _timer;
  bool _codeSent = false;

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
    // 페이지 진입 시 자동으로 인증 코드 발송
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendVerificationCode();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  /// 타이머 시작
  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _resendCountdown = 180;
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

  /// 인증 코드 발송
  Future<void> _sendVerificationCode() async {
    setState(() {
      _isSending = true;
    });

    try {
      await VerificationService.sendEmailVerification(widget.email);

      if (mounted) {
        setState(() {
          _codeSent = true;
          _isSending = false;
        });
        _startCountdown();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.email}로 인증 코드를 발송했습니다'),
            backgroundColor: AppColors.success500,
          ),
        );
      }
    } on VerificationException catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _showErrorDialog(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _showErrorDialog('인증 코드 발송 중 오류가 발생했습니다');
      }
    }
  }

  /// 인증 코드 재발송
  Future<void> _resendVerificationCode() async {
    if (_resendCountdown > 0) {
      _showErrorDialog('잠시 후 다시 시도해주세요');
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await VerificationService.resendEmailVerification(widget.email);

      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _startCountdown();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('인증 코드를 재발송했습니다'),
            backgroundColor: AppColors.success500,
          ),
        );
      }
    } on VerificationException catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _showErrorDialog(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _showErrorDialog('인증 코드 재발송 중 오류가 발생했습니다');
      }
    }
  }

  /// 인증 코드 확인
  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final success = await VerificationService.verifyEmailCode(
        widget.email,
        _codeController.text,
      );

      if (mounted) {
        setState(() {
          _isVerifying = false;
        });

        if (success) {
          _timer?.cancel();
          widget.onVerified();
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          '인증 실패',
          style: AppTextStyles.headingSmall,
        ),
        content: Text(
          message,
          style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
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

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
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
            '이메일 인증',
            style: AppTextStyles.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.email}로 발송된\n인증 코드를 입력해주세요',
            style: AppTextStyles.labelLarge,
          ),
          const SizedBox(height: 40),

          // 이메일 표시 (읽기 전용)
          const Text(
            '이메일 주소',
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: TextFormField(
              controller: TextEditingController(text: widget.email),
              enabled: false,
              style: AppTextStyles.labelLarge.copyWith(color: primaryBlack),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
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
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: borderGray,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 인증 코드 입력
          const Text(
            '인증 코드',
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: AppTextStyles.labelLarge.copyWith(color: primaryBlack),
                    decoration: InputDecoration(
                      hintText: '6자리 인증 코드',
                      hintStyle: AppTextStyles.labelLarge.copyWith(color: hintGray),
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '인증 코드를 입력해주세요';
                      }
                      if (value.length != 6) {
                        return '6자리 코드를 입력해주세요';
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
                  onPressed: _resendCountdown == 0 && !_isSending
                      ? _resendVerificationCode
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    foregroundColor: backgroundWhite,
                    disabledBackgroundColor: borderGray,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSending
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
                          _resendCountdown > 0
                              ? _formatTime(_resendCountdown)
                              : '재발송',
                          style: AppTextStyles.labelMedium,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // 버튼 영역
          Row(
            children: [
              // 이전 버튼
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: widget.onPrevious,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary600,
                      side: BorderSide(color: AppColors.primary600),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '이전',
                      style: AppTextStyles.labelLarge,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 인증하기 버튼
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      foregroundColor: backgroundWhite,
                      disabledBackgroundColor: borderGray,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  backgroundWhite),
                            ),
                          )
                        : const Text(
                            '인증하기',
                            style: AppTextStyles.labelLarge,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
