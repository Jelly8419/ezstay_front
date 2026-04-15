import 'package:building_map_app/core/utils/app_logger.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../config/api_config.dart';
import '../../../services/auth_service.dart';
import '../../../services/kmc_service.dart';
import '../../../widgets/kmc_webview.dart';

/// 본인인증 + 약관동의 단계 (순수 UI/데이터 수집)
///
/// API 호출 없음 — 수집한 데이터를 onNext 콜백으로 상위에 전달.
/// 상위(RegisterFlowPage)가 가입 타입에 맞는 API를 호출한다.
///
/// [showTerms]: false면 약관 UI 숨김 (호스트 가입 중간 단계 등)
/// [showSkipButton]: true면 "비회원으로 이용하기" 버튼 표시 (소셜 가입 흐름)
class PhoneVerificationStep extends StatefulWidget {
  final String? initialPhoneNumber;
  final bool showTerms;       // 약관 동의 UI 표시 여부
  final bool showSkipButton;  // 비회원으로 이용하기 버튼 표시 여부
  final String nextButtonLabel; // 완료/다음 버튼 텍스트
  final Function({
    required String realName,
    required String phoneNumber,
    String? certNum,
    String? birth,
    String? gender,
    required bool agreeTerms,
    required bool agreeMarketing,
  }) onNext;

  const PhoneVerificationStep({
    super.key,
    this.initialPhoneNumber,
    this.showTerms = true,
    this.showSkipButton = false,
    this.nextButtonLabel = '다음',
    required this.onNext,
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

  // KMC 본인인증 결과
  String? _verifiedCi;
  String? _verifiedBirth;
  String? _verifiedGender;

  // 약관 동의
  bool _agreeServiceTerms = false;    // [필수] 서비스 이용약관
  bool _agreePrivacy = false;         // [필수] 개인정보 수집·이용
  bool _agreeMarketing = false;       // [선택] 마케팅 수신
  bool _agreeAgeConfirm = false;      // [필수] 만 19세 이상

  // 하위 호환: agreeTerms = 필수 2개 모두 동의
  bool get _agreeTerms => _agreeServiceTerms && _agreePrivacy && _agreeAgeConfirm;

  // 색상
  static const primaryBlack = Color(0xFF000000);
  static const secondaryGray = Color(0xFF808080);
  static const borderGray = Color(0xFFE0E0E0);
  static const backgroundWhite = Color(0xFFFFFFFF);
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
    super.dispose();
  }

  /// 만 나이 계산
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// dev-verify 본인인증 (개발 환경 전용)
  ///
  /// POST /api/auth/kmc/dev-verify → certNum 수신 → 회원가입 body에 전달
  Future<void> _handleDevVerification() async {
    setState(() => _isVerifying = true);
    try {
      await _runDevVerify();
    } finally {
      if (mounted && _isVerifying) setState(() => _isVerifying = false);
    }
  }

  Future<void> _runDevVerify() async {
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
        final name = result['name']?.toString() ?? '이재욱';
        final phoneNumber = result['phoneNumber']?.toString() ?? '01065218419';
        final certNum = result['certNum']?.toString() ?? '';
        final birth = result['birth']?.toString() ?? '19930408';
        final gender = result['gender']?.toString() ?? '0';

        if (mounted) {
          setState(() {
            _nameController.text = name;
            _phoneController.text = phoneNumber;
            _verifiedCi = certNum;
            _verifiedBirth = birth;
            _verifiedGender = gender;
            _isVerified = true;
          });
        }
      } else {
        final message = data['message']?.toString() ?? 'dev-verify 호출 실패';
        AppLogger.e('❌ [KMC DevVerify] $message');
        if (mounted) _showErrorDialog(message);
      }
    } catch (e) {
      AppLogger.e('❌ [KMC DevVerify] 에러: $e');
      if (mounted) _showErrorDialog('본인인증 처리 중 오류가 발생했습니다');
    }
  }

  /// 실서버 KMC 본인인증
  Future<void> _handleKmcVerification() async {
    setState(() => _isVerifying = true);
    try {
      final requestResult = await KmcService.requestVerification();
      if (!mounted) return;

      final popupResult = await KmcWebViewHelper.openKmcVerification(
        context: context,
        requestResult: requestResult,
      );
      if (!mounted) return;

      if (popupResult == null) {
        setState(() => _isVerifying = false);
        return;
      }

      final verifyResult = await KmcService.verifyResult(
        apiToken: popupResult['apiToken']!,
        certNum: popupResult['certNum']!,
      );
      if (!mounted) return;

      if (!verifyResult.verified) {
        setState(() => _isVerifying = false);
        _showErrorDialog('본인인증에 실패했습니다. 다시 시도해주세요.');
        return;
      }

      final birthDate = verifyResult.birthDate;
      if (birthDate != null && _calculateAge(birthDate) < 19) {
        setState(() => _isVerifying = false);
        _showAgeRestrictionDialog();
        return;
      }

      setState(() {
        _nameController.text = verifyResult.name;
        _phoneController.text = verifyResult.phoneNumber;
        _verifiedCi = verifyResult.certNum;
        _verifiedBirth = verifyResult.birth;
        _verifiedGender = verifyResult.gender;
        _isVerified = true;
      });
    } on KmcException catch (e) {
      AppLogger.e('❌ [KMC] [${e.code}] ${e.message}');
      if (mounted) _showErrorDialog(KmcService.getErrorMessage(e.code));
    } catch (e) {
      AppLogger.e('❌ [KMC] 예기치 않은 에러: $e');
      if (mounted) _showErrorDialog('본인인증 중 오류가 발생했습니다. 다시 시도해주세요.');
    } finally {
      if (mounted && _isVerifying) setState(() => _isVerifying = false);
    }
  }

  /// 다음 버튼 핸들러 — API 호출 없이 데이터만 상위로 전달
  void _handleNext() {
    if (!_isVerified) {
      _showErrorDialog('본인인증을 먼저 완료해주세요');
      return;
    }
    if (widget.showTerms && !_agreeTerms) {
      _showErrorDialog('이용약관 및 개인정보처리방침에 동의해주세요');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    widget.onNext(
      realName: _nameController.text,
      phoneNumber: _phoneController.text,
      certNum: _verifiedCi,
      birth: _verifiedBirth,
      gender: _verifiedGender,
      agreeTerms: _agreeTerms,
      agreeMarketing: _agreeMarketing,
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          '오류',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: primaryBlack),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primary600)),
          ),
        ],
      ),
    );
  }

  void _showAgeRestrictionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          '가입 불가',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: primaryBlack),
        ),
        content: const Text(
          '만 19세 미만은 가입할 수 없습니다.',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textGray),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            child: Text('확인', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primary600)),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsRow({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required VoidCallback onViewTap,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: primaryBlack)),
        ),
        _ViewButton(onTap: onViewTap),
      ],
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
          const Text(
            '본인인증',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: primaryBlack),
          ),
          const SizedBox(height: 8),
          Text(
            '안전한 서비스 이용을 위해 본인인증이 필요합니다',
            style: AppTextStyles.bodyLarge.copyWith(color: textGray),
          ),
          const SizedBox(height: 40),

          // 본인인증 섹션
          if (!_isVerified) ...[
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isVerifying ? null : _handleKmcVerification,
                icon: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(backgroundWhite),
                        ),
                      )
                    : const Icon(Icons.verified_user_outlined, size: 20),
                label: Text(
                  _isVerifying ? '인증 진행 중...' : '본인인증하기',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: backgroundWhite,
                  elevation: 0,
                  disabledBackgroundColor: const Color(0xFFE0E0E0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            if (!ApiConfig.isProduction) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isVerifying ? null : _handleDevVerification,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF888888),
                    side: const BorderSide(color: Color(0xFFCCCCCC)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('[Dev] 테스트 인증', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ] else ...[
            // 인증 완료 후 실명 표시
            const Text('실명', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textGray)),
            const SizedBox(height: 8),
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success500),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _nameController.text,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: primaryBlack),
                    ),
                  ),
                  Icon(Icons.check_circle, color: AppColors.success500, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 휴대폰 번호 표시
            const Text('휴대폰 번호', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textGray)),
            const SizedBox(height: 8),
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success500),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _phoneController.text,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: primaryBlack),
                    ),
                  ),
                  Icon(Icons.check_circle, color: AppColors.success500, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 인증 완료 뱃지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: AppColors.success600, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '본인인증 완료',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success600),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // 본인인증 안내
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.primary600),
                    const SizedBox(width: 8),
                    Text('본인인증 안내', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• 본인인증을 통해 실명이 자동으로 입력됩니다\n'
                  '• 입력하신 정보는 안전하게 보호됩니다\n'
                  '• 만 19세 이상만 가입 가능합니다',
                  style: AppTextStyles.bodySmall.copyWith(color: textGray, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 약관 동의 (showTerms == true일 때만)
          if (widget.showTerms) ...[
            const Text(
              '약관 동의',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: primaryBlack),
            ),
            const SizedBox(height: 16),

            // 전체 동의
            InkWell(
              onTap: () {
                setState(() {
                  final allAgreed = _agreeServiceTerms && _agreePrivacy && _agreeMarketing && _agreeAgeConfirm;
                  _agreeServiceTerms = !allAgreed;
                  _agreePrivacy = !allAgreed;
                  _agreeMarketing = !allAgreed;
                  _agreeAgeConfirm = !allAgreed;
                });
              },
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreeServiceTerms && _agreePrivacy && _agreeMarketing && _agreeAgeConfirm,
                      onChanged: (value) {
                        setState(() {
                          _agreeServiceTerms = value ?? false;
                          _agreePrivacy = value ?? false;
                          _agreeMarketing = value ?? false;
                          _agreeAgeConfirm = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('전체 동의', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primaryBlack)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: borderGray, thickness: 1),
            const SizedBox(height: 12),

            // [필수] 만 19세 이상
            InkWell(
              onTap: () => setState(() => _agreeAgeConfirm = !_agreeAgeConfirm),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreeAgeConfirm,
                      onChanged: (v) => setState(() => _agreeAgeConfirm = v ?? false),
                      activeColor: AppColors.primary600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('[필수] 만 19세 이상입니다.',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: primaryBlack)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // [필수] 서비스 이용약관
            _buildTermsRow(
              label: '[필수] 서비스 이용약관 동의',
              value: _agreeServiceTerms,
              onChanged: (v) => setState(() => _agreeServiceTerms = v ?? false),
              onViewTap: () => launchUrl(Uri.parse('/terms.html'), webOnlyWindowName: '_blank'),
            ),
            const SizedBox(height: 12),

            // [필수] 개인정보 수집·이용
            _buildTermsRow(
              label: '[필수] 개인정보 수집 및 이용 동의',
              value: _agreePrivacy,
              onChanged: (v) => setState(() => _agreePrivacy = v ?? false),
              onViewTap: () => launchUrl(Uri.parse('/privacy-collection-consent.html'), webOnlyWindowName: '_blank'),
            ),
            const SizedBox(height: 12),

            // [선택] 마케팅
            _buildTermsRow(
              label: '[선택] 마케팅 정보 수신 동의',
              value: _agreeMarketing,
              onChanged: (v) => setState(() => _agreeMarketing = v ?? false),
              onViewTap: () => launchUrl(Uri.parse('/marketing-consent.html'), webOnlyWindowName: '_blank'),
            ),
            const SizedBox(height: 40),
          ],

          // 다음/완료 버튼
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isVerified ? _handleNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary600,
                foregroundColor: backgroundWhite,
                elevation: 0,
                disabledBackgroundColor: const Color(0xFFE0E0E0),
                disabledForegroundColor: secondaryGray,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                widget.nextButtonLabel,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),

          // 비회원으로 이용하기 (showSkipButton == true일 때만)
          if (widget.showSkipButton) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: TextButton(
                onPressed: () async {
                  final authService = context.read<AuthService>();
                  await authService.logout();
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  context.go('/guest');
                },
                style: TextButton.styleFrom(
                  foregroundColor: secondaryGray,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: borderGray),
                  ),
                ),
                child: Text(
                  '비회원으로 이용하기',
                  style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ViewButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ViewButton({required this.onTap});

  @override
  State<_ViewButton> createState() => _ViewButtonState();
}

class _ViewButtonState extends State<_ViewButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: RichText(
          text: TextSpan(
            text: '보기',
            style: TextStyle(
              fontSize: 13,
              color: _hovered ? const Color(0xFF1565C0) : const Color(0xFF808080),
              decoration: TextDecoration.underline,
              decorationColor: _hovered ? const Color(0xFF1565C0) : const Color(0xFF808080),
            ),
          ),
        ),
      ),
    );
  }
}
