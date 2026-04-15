import 'package:building_map_app/core/utils/app_logger.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/kmc_service.dart';
import '../../services/verification_service.dart';
import '../../utils/password_validator.dart';
import '../../widgets/kmc_webview.dart';

/// 비밀번호 찾기 페이지
///
/// 플로우:
/// Step 0 — 이메일 입력 → POST /find-password/check-email (소셜 계정 차단)
/// Step 1 — KMC 본인인증 → DI 수신
/// Step 2 — 새 비밀번호 입력 → POST /find-password/reset (email + di + newPassword)
/// 완료   — 변경 완료 메시지 → 로그인 이동
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _step = 0; // 0=이메일, 1=KMC, 2=비밀번호
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // KMC 인증 완료 후 저장
  String? _verifiedCi;

  static const _primaryBlack = Color(0xFF000000);
  static const _textGray = Color(0xFF666666);
  static const _borderGray = Color(0xFFE0E0E0);
  static const _backgroundWhite = Color(0xFFFFFFFF);
  static const _hintGray = Color(0xFFCCCCCC);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ===================== Step 0: 이메일 확인 =====================

  Future<void> _checkEmail() async {
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
      await VerificationService.checkEmailForPasswordReset(email: email);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _step = 1;
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
        _showErrorDialog('이메일 확인 중 오류가 발생했습니다');
      }
    }
  }

  // ===================== Step 1: KMC 본인인증 =====================

  Future<void> _handleKmcVerification() async {
    setState(() => _isLoading = true);

    try {
      final requestResult = await KmcService.requestVerification();

      if (!mounted) return;

      final popupResult = await KmcWebViewHelper.openKmcVerification(
        context: context,
        requestResult: requestResult,
      );

      if (!mounted) return;

      if (popupResult == null) return;

      final verifyResult = await KmcService.verifyResult(
        apiToken: popupResult['apiToken']!,
        certNum: popupResult['certNum']!,
        purpose: 'find_password',
      );

      if (!mounted) return;

      setState(() {
        _verifiedCi = verifyResult.certNum;
        _step = 2;
      });
    } on KmcException catch (e) {
      if (mounted) _showErrorDialog(KmcService.getErrorMessage(e.code));
    } catch (e) {
      AppLogger.e('❌ [RESET_PW] KMC 오류: $e');
      if (mounted) _showErrorDialog('본인인증 중 오류가 발생했습니다');
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 로컬 dev-verify (개발 환경 전용)
  Future<void> _handleDevVerification() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.kmcDevVerifyUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': '이재욱',
          'phoneNumber': '01065218419',
          'birth': '19930408',
          'gender': '0',
        }),
      ).timeout(ApiConfig.timeout);

      final data = json.decode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        final result = data['data'] ?? data;
        final certNum = result['certNum']?.toString() ?? '';
        if (mounted) {
          setState(() {
            _verifiedCi = certNum;
            _step = 2;
          });
        }
      } else {
        final message = data['message']?.toString() ?? 'dev-verify 호출 실패';
        if (mounted) _showErrorDialog(message);
      }
    } catch (e) {
      AppLogger.e('❌ [RESET_PW] dev-verify 에러: $e');
      if (mounted) _showErrorDialog('테스트 인증 중 오류가 발생했습니다');
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ===================== Step 2: 비밀번호 재설정 =====================

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_verifiedCi == null) {
      _showErrorDialog('본인인증 정보가 없습니다. 다시 시도해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await VerificationService.resetPasswordWithKmc(
        email: _emailController.text.trim(),
        certNum: _verifiedCi!,
        newPassword: _passwordController.text,
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

  // ===================== 다이얼로그 =====================

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          '비밀번호 변경 완료',
          style: AppTextStyles.headingSmall.copyWith(color: AppColors.success600),
        ),
        content: Text(
          '비밀번호가 성공적으로 변경되었습니다.\n새 비밀번호로 로그인해주세요.',
          style: AppTextStyles.bodyMedium.copyWith(color: _textGray),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/login');
            },
            child: Text(
              '로그인하기',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary600),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          '오류',
          style: AppTextStyles.headingSmall,
        ),
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: _textGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '확인',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary600),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== Build =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundWhite,
      appBar: AppBar(
        backgroundColor: _backgroundWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primaryBlack),
          onPressed: () {
            if (_step > 0) {
              setState(() {
                _step--;
                // Step 1로 돌아올 때 KMC DI 초기화
                if (_step == 1) _verifiedCi = null;
              });
            } else {
              context.pop();
            }
          },
        ),
        title: const Text(
          '비밀번호 찾기',
          style: AppTextStyles.headingSmall,
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
        return _buildKmcStep();
      case 2:
        return _buildPasswordStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ===================== Step 위젯들 =====================

  /// Step 0: 이메일 입력
  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '가입한 이메일을\n입력해주세요',
          style: AppTextStyles.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          '소셜 계정(카카오)으로 가입한 경우 이용할 수 없습니다',
          style: AppTextStyles.bodyLarge.copyWith(color: _textGray),
        ),
        const SizedBox(height: 40),

        Text(
          '이메일 주소',
          style: AppTextStyles.bodyMedium.copyWith(color: _textGray),
        ),
        const SizedBox(height: 8),

        SizedBox(
          height: 52,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            style: AppTextStyles.labelLarge.copyWith(color: _primaryBlack),
            decoration: _inputDecoration('email@example.com'),
          ),
        ),
        const SizedBox(height: 32),

        _buildPrimaryButton(
          text: '다음',
          onPressed: _isLoading ? null : _checkEmail,
        ),
      ],
    );
  }

  /// Step 1: KMC 본인인증
  Widget _buildKmcStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '본인인증을\n진행해주세요',
          style: AppTextStyles.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          '가입 시 등록한 휴대폰으로 본인인증을 완료해주세요',
          style: AppTextStyles.bodyLarge.copyWith(color: _textGray),
        ),
        const SizedBox(height: 48),

        // 입력한 이메일 표시
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _borderGray),
          ),
          child: Row(
            children: [
              const Icon(Icons.email_outlined, size: 18, color: Color(0xFF888888)),
              const SizedBox(width: 8),
              Text(
                _emailController.text.trim(),
                style: AppTextStyles.bodyLarge.copyWith(color: _primaryBlack),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // 본인인증 안내 박스
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderGray),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFF666666)),
                  const SizedBox(width: 6),
                  Text(
                    '본인인증 안내',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF444444),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• 휴대폰 본인인증이 진행됩니다\n• 이메일과 본인인증 정보가 일치해야 합니다',
                style: AppTextStyles.bodySmall.copyWith(color: _textGray, height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        _buildPrimaryButton(
          text: '본인인증 시작',
          onPressed: _isLoading ? null : _handleKmcVerification,
        ),
        if (!ApiConfig.isProduction) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _isLoading ? null : _handleDevVerification,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF888888),
                side: const BorderSide(color: Color(0xFFCCCCCC)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('[Dev] 테스트 인증', style: AppTextStyles.bodyMedium),
            ),
          ),
        ],
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
            style: AppTextStyles.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            PasswordValidator.policyDescription,
            style: AppTextStyles.bodyLarge.copyWith(color: _textGray),
          ),
          const SizedBox(height: 40),

          Text(
            '새 비밀번호',
            style: AppTextStyles.bodyMedium.copyWith(color: _textGray),
          ),
          const SizedBox(height: 8),

          SizedBox(
            height: 52,
            child: TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofocus: true,
              style: AppTextStyles.labelLarge.copyWith(color: _primaryBlack),
              decoration: _inputDecoration(PasswordValidator.hintText).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF808080),
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

          Text(
            '새 비밀번호 확인',
            style: AppTextStyles.bodyMedium.copyWith(color: _textGray),
          ),
          const SizedBox(height: 8),

          SizedBox(
            height: 52,
            child: TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              style: AppTextStyles.labelLarge.copyWith(color: _primaryBlack),
              decoration:
                  _inputDecoration('비밀번호를 다시 입력해 주세요.').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF808080),
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

  // ===================== 공통 위젯 =====================

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.labelLarge.copyWith(color: _hintGray),
      filled: true,
      fillColor: _backgroundWhite,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _borderGray, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _borderGray, width: 1),
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
          foregroundColor: _backgroundWhite,
          disabledBackgroundColor: _borderGray,
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
                      AlwaysStoppedAnimation<Color>(_backgroundWhite),
                ),
              )
            : Text(
                text,
                style: AppTextStyles.labelLarge,
              ),
      ),
    );
  }
}
