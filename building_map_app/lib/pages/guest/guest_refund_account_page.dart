import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../constants/bank_constants.dart';
import '../../models/bank_account.dart';
import '../../services/refund_account_service.dart';
import '../../utils/responsive_util.dart';
import '../../widgets/common/app_gnb.dart';
import '../../widgets/common/app_footer.dart';

/// 게스트 환급 계좌 등록/수정 페이지
/// /guest/my-page/refund-account
class GuestRefundAccountPage extends StatefulWidget {
  const GuestRefundAccountPage({super.key});

  @override
  State<GuestRefundAccountPage> createState() => _GuestRefundAccountPageState();
}

class _GuestRefundAccountPageState extends State<GuestRefundAccountPage> {
  final RefundAccountService _refundAccountService = RefundAccountService();
  final _formKey = GlobalKey<FormState>();

  // 계좌 입력 상태
  String? _selectedBank;
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();
  bool _accountVerified = false;
  bool _isVerifying = false;
  bool _isSaving = false;

  // 기존 계좌 로드
  bool _isLoading = true;
  BankAccount? _existingAccount;

  @override
  void initState() {
    super.initState();
    _loadExistingAccount();
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  /// 기존 환급 계좌 로드
  Future<void> _loadExistingAccount() async {
    try {
      final account = await _refundAccountService.getRefundAccount();
      if (mounted) {
        setState(() {
          _existingAccount = account;
          if (account != null) {
            _selectedBank = account.bankName;
            _accountHolderController.text = account.accountHolder;
            // 마스킹된 계좌번호는 프리필하지 않음
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 예금주 확인
  Future<void> _verifyAccount() async {
    if (_selectedBank == null || _accountNumberController.text.isEmpty) {
      _showErrorSnackBar('은행과 계좌번호를 입력해주세요.');
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final result = await _refundAccountService.verifyAccount(
        bankCode: BankConstants.getBankCode(_selectedBank!),
        accountNum: _accountNumberController.text,
        accountHolderName: _accountHolderController.text,
      );

      if (!mounted) return;

      final verified = result['verified'] as bool;
      final actualName = result['accountHolderName'] as String?;

      setState(() {
        _isVerifying = false;
        _accountVerified = verified;
        if (verified && actualName != null) {
          _accountHolderController.text = actualName;
        }
      });

      if (verified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('예금주 확인이 완료되었습니다.'),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        );
      } else {
        final message = actualName != null
            ? '예금주 정보가 일치하지 않습니다. (실제 예금주: $actualName)'
            : '예금주 정보가 일치하지 않습니다.';
        _showErrorSnackBar(message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  /// 계좌 저장
  Future<void> _saveAccount() async {
    if (!_accountVerified) {
      _showErrorSnackBar('먼저 예금주 확인을 완료해주세요.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final account = await _refundAccountService.saveRefundAccount(
        bankCode: BankConstants.getBankCode(_selectedBank!),
        accountNum: _accountNumberController.text,
        accountHolderName: _accountHolderController.text,
      );

      if (!mounted) return;

      // 성공 시 결과를 pop으로 전달
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _existingAccount != null ? '환급 계좌가 수정되었습니다.' : '환급 계좌가 등록되었습니다.',
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      );

      context.pop(account);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: Text(
                _existingAccount != null ? '환급 계좌 수정' : '환급 계좌 등록',
                style: AppTextStyles.headingSmall,
              ),
              centerTitle: true,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
            )
          : null,
      body: Column(
        children: [
          if (!isMobile) const AppGNB(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 데스크톱에서만 뒤로가기 + 타이틀
                    if (!ResponsiveUtil.isMobile(context)) ...[
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back),
                            tooltip: '뒤로가기',
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            _existingAccount != null ? '환급 계좌 수정' : '환급 계좌 등록',
                            style: AppTextStyles.headingLarge.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray900,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sm),
                    ],

                    // 안내 문구
                    Text(
                      '호스트 귀책으로 계약 취소 시, 위약금을 환급받을 계좌를 등록해주세요.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    SizedBox(height: AppSpacing.xl),

                    // 계좌 정보 입력 카드
                    Container(
                      padding: AppSpacing.paddingLg,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: AppShadows.cardDefault,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '계좌 정보',
                            style: AppTextStyles.headingMedium.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: AppSpacing.lg),

                          // 은행 선택
                          Text(
                            '은행',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedBank,
                            decoration: InputDecoration(
                              hintText: '은행을 선택하세요',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                borderSide: BorderSide(color: AppColors.primary500, width: 2),
                              ),
                            ),
                            items: BankConstants.banks.map((bank) {
                              return DropdownMenuItem(value: bank, child: Text(bank));
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedBank = value;
                                _accountVerified = false;
                              });
                            },
                          ),

                          SizedBox(height: AppSpacing.lg),

                          // 계좌번호
                          Text(
                            '계좌번호',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            controller: _accountNumberController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              hintText: '계좌번호를 입력하세요 (- 제외)',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                borderSide: BorderSide(color: AppColors.primary500, width: 2),
                              ),
                            ),
                            onChanged: (_) {
                              setState(() => _accountVerified = false);
                            },
                          ),

                          SizedBox(height: AppSpacing.lg),

                          // 예금주 확인 버튼
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: (_accountVerified || _isVerifying)
                                  ? null
                                  : _verifyAccount,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accountVerified
                                    ? const Color(0xFF4CAF50)
                                    : AppColors.primary500,
                                foregroundColor: AppColors.neutral0,
                                disabledBackgroundColor: AppColors.gray200,
                                disabledForegroundColor: AppColors.textSecondary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
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
                                      _accountVerified ? '예금주 확인 완료 ✓' : '예금주 확인',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),

                          // 인증 완료 후 예금주명 표시
                          if (_accountVerified && _accountHolderController.text.isNotEmpty) ...[
                            SizedBox(height: AppSpacing.lg),
                            Text(
                              '예금주명',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gray50,
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                _accountHolderController.text,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: AppSpacing.xl),

                    // 하단 버튼 영역
                    Row(
                      children: [
                        // 취소 버튼
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _isSaving ? null : () => context.pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: BorderSide(color: AppColors.border, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                              ),
                              child: Text(
                                '취소',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: AppSpacing.md),

                        // 수정 완료 버튼
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: (_accountVerified && !_isSaving)
                                  ? _saveAccount
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary500,
                                disabledBackgroundColor: AppColors.gray300,
                                foregroundColor: AppColors.neutral0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      '수정 완료',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.neutral0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }
}
