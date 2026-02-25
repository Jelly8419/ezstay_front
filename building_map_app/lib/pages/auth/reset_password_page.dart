import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../services/verification_service.dart';
import '../../utils/password_validator.dart';

/// 비밀번호 재설정 페이지
///
/// 플로우: 이메일 입력 → 인증 코드 발송 → 인증 확인 → 새 비밀번호 입력 → 재설정 완료
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // 단계: 0=이메일 입력, 1=인증 코드 입력, 2=새 비밀번호 입력
  int _step = 0;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // 인증 코드 타이머
  int _resendCountdown = 300; // 5분
  Timer? _timer;

  // 색상 정의
  static const primaryBlack = Color(0xFF000000);
  static const secondaryGray = Color(0xFF808080);
  static const borderGray = Color(0xFFE0E0E0);
  static const backgroundWhite = Color(0xFFFFFFFF);
  static const hintGray = Color(0xFFCCCCCC);
  static const textGray = Color(0xFF666666);

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendCountdown = 300);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Step 0: 인증 코드 발송
  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErrorDialog('이메일을 입력해주세요');
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showErrorDialog('올바른 이메일 형식이 아닙니다');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await VerificationService.sendPasswordResetVerification(email);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _step = 1;
        });
        _startCountdown();
        _showSuccessDialog('$email로\n인증 코드를 발송했습니다');
      }
    } on VerificationException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('인증 코드 발송 중 오류가 발생했습니다');
      }
    }
  }

  /// Step 0→1에서 재발송
  Future<void> _resendVerificationCode() async {
    if (_resendCountdown > 0) return;

    setState(() => _isLoading = true);

    try {
      await VerificationService.sendPasswordResetVerification(
          _emailController.text.trim());
      if (mounted) {
        setState(() => _isLoading = false);
        _startCountdown();
        _showSuccessDialog('인증 코드를 재발송했습니다');
      }
    } on VerificationException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('인증 코드 재발송 중 오류가 발생했습니다');
      }
    }
  }

  /// Step 1: 인증 코드 확인
  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showErrorDialog('인증 코드를 입력해주세요');
      return;
    }
    if (code.length != 6) {
      _showErrorDialog('6자리 코드를 입력해주세요');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await VerificationService.verifyEmailCode(
        _emailController.text.trim(),
        code,
      );
      if (mounted && success) {
        _timer?.cancel();
        setState(() {
          _isLoading = false;
          _step = 2;
        });
      }
    } on VerificationException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('인증 코드 확인 중 오류가 발생했습니다');
      }
    }
  }

  /// Step 2: 비밀번호 재설정
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await VerificationService.resetPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        _showCompletionDialog();
      }
    } on VerificationException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('비밀번호 재설정 중 오류가 발생했습니다');
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: backgroundWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          '비밀번호 변경 완료',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.success600,
          ),
        ),
        content: const Text(
          '비밀번호가 성공적으로 변경되었습니다.\n새 비밀번호로 로그인해주세요.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textGray,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go('/login');
            },
            child: Text(
              '로그인하기',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      appBar: AppBar(
        backgroundColor: backgroundWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryBlack),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              context.pop();
            }
          },
        ),
        title: const Text(
          '비밀번호 찾기',
          style: TextStyle(
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: _buildCurrentStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildEmailStep();
      case 1:
        return _buildCodeStep();
      case 2:
        return _buildPasswordStep();
      default:
        return const SizedBox.shrink();
    }
  }

  /// Step 0: 이메일 입력
  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '가입한 이메일을\n입력해주세요',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: primaryBlack,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '이메일로 인증 코드를 보내드립니다',
          style: TextStyle(fontSize: 16, color: textGray),
        ),
        const SizedBox(height: 40),

        const Text(
          '이메일 주소',
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
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: primaryBlack,
            ),
            decoration: _inputDecoration('email@example.com'),
          ),
        ),
        const SizedBox(height: 32),

        _buildPrimaryButton(
          text: '인증 코드 발송',
          onPressed: _isLoading ? null : _sendVerificationCode,
        ),
      ],
    );
  }

  /// Step 1: 인증 코드 입력
  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '인증 코드를\n입력해주세요',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: primaryBlack,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_emailController.text}로 발송된\n6자리 코드를 입력해주세요',
          style: const TextStyle(fontSize: 16, color: textGray),
        ),
        const SizedBox(height: 40),

        const Text(
          '인증 코드',
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
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: primaryBlack,
                  ),
                  decoration: _inputDecoration('6자리 인증 코드').copyWith(
                    counterText: '',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _resendCountdown == 0 && !_isLoading
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
                child: Text(
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
          ],
        ),
        const SizedBox(height: 32),

        _buildPrimaryButton(
          text: '인증 확인',
          onPressed: _isLoading ? null : _verifyCode,
        ),
      ],
    );
  }

  /// Step 2: 새 비밀번호 입력
  Widget _buildPasswordStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '새 비밀번호를\n입력해주세요',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: primaryBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            PasswordValidator.policyDescription,
            style: const TextStyle(fontSize: 16, color: textGray),
          ),
          const SizedBox(height: 40),

          // 새 비밀번호
          const Text(
            '새 비밀번호',
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
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofocus: true,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: primaryBlack,
              ),
              decoration: _inputDecoration(PasswordValidator.hintText).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: secondaryGray,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: PasswordValidator.validate,
            ),
          ),
          const SizedBox(height: 20),

          // 비밀번호 확인
          const Text(
            '새 비밀번호 확인',
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
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: primaryBlack,
              ),
              decoration:
                  _inputDecoration('비밀번호를 다시 입력해 주세요.').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: secondaryGray,
                    size: 20,
                  ),
                  onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (value) => PasswordValidator.validateConfirm(
                  value, _passwordController.text),
            ),
          ),
          const SizedBox(height: 32),

          _buildPrimaryButton(
            text: '비밀번호 변경',
            onPressed: _isLoading ? null : _resetPassword,
          ),
        ],
      ),
    );
  }

  /// 공통 입력 필드 데코레이션
  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: hintGray,
      ),
      filled: true,
      fillColor: backgroundWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderGray, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderGray, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary600, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.error500, width: 1),
      ),
    );
  }

  /// 공통 메인 버튼
  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary600,
          foregroundColor: backgroundWhite,
          disabledBackgroundColor: borderGray,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(backgroundWhite),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}
