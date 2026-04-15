import 'package:building_map_app/core/utils/app_logger.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../config/api_config.dart';
import '../../../constants/bank_constants.dart';
import '../../../services/token_service.dart';

/// 정산계좌 입력 + 약관동의 단계 (순수 UI/데이터 수집)
///
/// 두 가지 모드:
/// 1. 회원가입 플로우 (isStandaloneMode: false)
///    - API 호출 없음 — 계좌 인증 후 onNext 콜백으로 데이터 전달
///    - 상위(RegisterFlowPage)가 가입 타입에 맞는 API 호출
///
/// 2. 게스트→임대인 전환 (isStandaloneMode: true)
///    - 이미 로그인된 사용자 → POST /api/account 직접 호출
class HostAccountStep extends StatefulWidget {
  final String? realName; // 본인인증 실명 (예금주 초기값)
  /// 회원가입 플로우 전용 콜백. isStandaloneMode: true이면 null 가능.
  final Function({
    required String bankCode,
    required String accountNum,
    required String accountHolderName,
    required bool agreeTerms,
    required bool agreeMarketing,
  })? onNext;
  final bool isStandaloneMode; // true: 게스트→임대인 전환

  const HostAccountStep({
    super.key,
    this.realName,
    this.onNext,
    this.isStandaloneMode = false,
  }) : assert(isStandaloneMode || onNext != null,
            'onNext is required when isStandaloneMode is false');

  @override
  State<HostAccountStep> createState() => _HostAccountStepState();
}

class _HostAccountStepState extends State<HostAccountStep> {
  final _formKey = GlobalKey<FormState>();

  bool _agreeTerms = false;
  bool _agreeMarketing = false;

  String? _selectedBank;
  final _accountController = TextEditingController();
  final _accountHolderController = TextEditingController();
  bool _accountVerified = false;
  bool _isVerifying = false;
  bool _isSubmitting = false; // standalone 모드 전용

  static List<String> get _banks => BankConstants.banks;

  // 색상
  static const primaryBlack = Color(0xFF000000);
  static const secondaryGray = Color(0xFF666666);
  static const borderGray = Color(0xFFE0E0E0);
  static const backgroundColor = Color(0xFFF5F5F5);
  static const successGreen = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    if (widget.realName != null) {
      _accountHolderController.text = widget.realName!;
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  String _getBankCode(String bankName) => BankConstants.getBankCode(bankName);

  /// 계좌 인증 — optionalAuth 엔드포인트이므로 토큰 없어도 호출 가능
  Future<void> _verifyAccount() async {
    if (_selectedBank == null || _accountController.text.isEmpty) {
      _showErrorDialog('은행과 계좌번호를 입력해주세요.');
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final token = await TokenService.getAccessToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/account/verify'),
        headers: headers,
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
          final actualName = data['accountHolderName'];
          final verified = responseData['verified'] == true;

          setState(() {
            _accountVerified = true;
            _isVerifying = false;
            if (!verified && actualName != null) {
              _accountHolderController.text = actualName;
            }
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(verified ? '계좌 확인이 완료되었습니다' : '예금주명이 "$actualName"으로 확인되었습니다'),
              backgroundColor: successGreen,
            ),
          );
        } else {
          throw Exception(responseData['message'] ?? '계좌 확인에 실패했습니다');
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      if (!mounted) return;
      _showErrorDialog('계좌 확인 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.');
    }
  }

  /// 완료 버튼 핸들러
  Future<void> _handleComplete() async {
    if (!widget.isStandaloneMode && !_agreeTerms) {
      _showErrorDialog('필수 약관에 동의해주세요.');
      return;
    }
    if (!_accountVerified) {
      _showErrorDialog('계좌 인증을 완료해주세요.');
      return;
    }

    if (widget.isStandaloneMode) {
      await _upgradeToHost();
    } else {
      // 회원가입 플로우 — 데이터만 상위로 전달
      widget.onNext!(
        bankCode: _getBankCode(_selectedBank!),
        accountNum: _accountController.text,
        accountHolderName: _accountHolderController.text,
        agreeTerms: _agreeTerms,
        agreeMarketing: _agreeMarketing,
      );
    }
  }

  /// Standalone 모드: 게스트→임대인 전환
  /// POST /api/account
  Future<void> _upgradeToHost() async {
    setState(() => _isSubmitting = true);

    try {
      final token = await TokenService.getAccessToken();
      if (token == null) throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/account'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'bank_code': _selectedBank!,
              'account_num': _accountController.text,
              'account_holder_name': _accountHolderController.text,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? '계좌 등록에 실패했습니다');
      }
      final responseData = jsonDecode(response.body);
      if (responseData['success'] != true) {
        throw Exception(responseData['message'] ?? '계좌 등록에 실패했습니다');
      }

      // onNext가 있으면 상위에 위임, 없으면 standalone 페이지에서 직접 처리
      widget.onNext?.call(
        bankCode: _getBankCode(_selectedBank!),
        accountNum: _accountController.text,
        accountHolderName: _accountHolderController.text,
        agreeTerms: true,
        agreeMarketing: false,
      );
    } catch (e) {
      AppLogger.e('❌ [UPGRADE-HOST] 에러: $e');
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      _showErrorDialog('임대인 전환에 실패했습니다.\n${e.toString()}');
    }
  }

  /// "나중에 입력" — 이미 상위에서 게스트 회원가입 완료 후 이동하므로
  /// 여기서는 단순히 /guest로 라우팅 (standalone 아닌 경우에만 표시)
  void _showSkipAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('임차인으로 활동하시겠습니까?'),
        content: const Text(
          '계좌 정보를 나중에 입력하시면 임차인 모드로 활동하게 됩니다.\n'
          '임대인 기능을 사용하시려면 계좌 정보를 등록해야 합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // onNext에 빈 계좌 정보 + skipAccount 플래그로 상위에 위임
              widget.onNext!(
                bankCode: '',
                accountNum: '',
                accountHolderName: '',
                agreeTerms: _agreeTerms,
                agreeMarketing: _agreeMarketing,
              );
            },
            child: Text('임차인으로 활동', style: TextStyle(color: AppColors.primary600)),
          ),
        ],
      ),
    );
  }

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
            style: AppTextStyles.headingLarge.copyWith(color: primaryBlack),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isStandaloneMode
                ? '임대인으로 활동하시려면 정산 계좌 정보를 등록해주세요.'
                : '임대인으로 활동하시려면 정산 계좌 정보가 필요합니다.',
            style: AppTextStyles.bodySmall.copyWith(color: secondaryGray),
          ),
          const SizedBox(height: 32),

          // 은행 선택
          const Text('은행', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedBank,
            decoration: InputDecoration(
              hintText: '은행을 선택하세요',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGray)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGray)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.primary600, width: 2)),
            ),
            items: _banks.map((bank) => DropdownMenuItem(value: bank, child: Text(bank))).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBank = value;
                _accountVerified = false;
              });
            },
          ),
          const SizedBox(height: 16),

          // 계좌번호
          const Text('계좌번호', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _accountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '계좌번호를 입력하세요 (- 제외)',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGray)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGray)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.primary600, width: 2)),
            ),
            onChanged: (_) => setState(() => _accountVerified = false),
          ),
          const SizedBox(height: 16),

          // 계좌 인증 버튼
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _accountVerified || _isVerifying ? null : _verifyAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accountVerified ? successGreen : AppColors.primary600,
                foregroundColor: Colors.white,
                disabledBackgroundColor: backgroundColor,
                disabledForegroundColor: secondaryGray,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isVerifying
                  ? const SizedBox(
                      height: 24, width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : Text(
                      _accountVerified ? '계좌 인증 완료 ✓' : '계좌 인증',
                      style: AppTextStyles.labelLarge,
                    ),
            ),
          ),

          // 예금주명 (인증 완료 후)
          if (_accountVerified && _accountHolderController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('예금주명', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(color: borderGray),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_accountHolderController.text, style: AppTextStyles.bodyMedium.copyWith(color: primaryBlack)),
            ),
          ],
          const SizedBox(height: 32),

          // 약관 동의 (회원가입 플로우에서만)
          if (!widget.isStandaloneMode) ...[
            const Text('약관 동의', style: AppTextStyles.headingSmall),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _agreeTerms,
              onChanged: (value) => setState(() => _agreeTerms = value ?? false),
              title: Text('이용약관 및 개인정보 처리방침 동의 (필수)', style: AppTextStyles.bodySmall),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary600,
            ),
            CheckboxListTile(
              value: _agreeMarketing,
              onChanged: (value) => setState(() => _agreeMarketing = value ?? false),
              title: Text('마케팅 정보 수신 동의 (선택)', style: AppTextStyles.bodySmall),
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
                      ? (!_accountVerified || _isSubmitting)
                      : (!_agreeTerms || !_accountVerified || _isSubmitting))
                  ? null
                  : _handleComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary600,
                foregroundColor: Colors.white,
                disabledBackgroundColor: backgroundColor,
                disabledForegroundColor: secondaryGray,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24, width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : Text(
                      widget.isStandaloneMode ? '임대인 전환 완료' : '회원가입 완료',
                      style: AppTextStyles.labelLarge,
                    ),
            ),
          ),

          // "나중에 입력" (회원가입 플로우에서만)
          if (!widget.isStandaloneMode) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : _showSkipAccountDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: secondaryGray,
                  side: const BorderSide(color: borderGray),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('나중에 입력 (임차인으로 활동)', style: AppTextStyles.labelMedium),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
