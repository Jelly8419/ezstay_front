import 'package:building_map_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import '../../core/exceptions.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/user_profile.dart';
import '../../models/bank_account.dart';
import '../../services/user_profile_service.dart';
import '../../services/refund_account_service.dart';

import '../../services/auth_service.dart';
import '../../services/kmc_service.dart';
import '../../widgets/kmc_webview.dart';
import '../../widgets/common/my_page_dialogs.dart';
import '../../models/user.dart';
import '../../utils/responsive_util.dart';
import '../../widgets/common/app_gnb.dart';
import '../../widgets/common/app_footer.dart';
import '../../providers/gnb_provider.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../utils/password_validator.dart';
import '../../utils/text_input_validator.dart';

/// 게스트 마이페이지 (내 정보 관리)
/// React: src/pages/GuestMyPage.tsx
class GuestMyPage extends StatefulWidget {
  const GuestMyPage({super.key});

  @override
  State<GuestMyPage> createState() => _GuestMyPageState();
}

class _GuestMyPageState extends State<GuestMyPage> {
  final UserProfileService _userProfileService = UserProfileService();
  final RefundAccountService _refundAccountService = RefundAccountService();

  // 로딩 상태
  bool _isLoading = true;
  String? _errorMessage;

  // 사용자 정보
  UserProfile? _userProfile;

  // 환급 계좌 정보
  BankAccount? _refundAccount;

  // 연락처 변경 상태
  bool _isChangingPhone = false;

  // 비밀번호 변경 상태
  bool _isEditingPassword = false;
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // 닉네임 변경 상태
  bool _isEditingNickname = false;
  final TextEditingController _nicknameController = TextEditingController();
  String? _nicknameError;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  /// 사용자 프로필 및 환급 계좌 로드
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _userProfileService.getUserProfile();

      if (profile == null) {
        setState(() {
          _errorMessage = '사용자 정보를 불러올 수 없습니다.';
          _isLoading = false;
        });
        return;
      }

      // 환급 계좌 로드 (실패해도 무시 - 페이지는 표시됨)
      BankAccount? refundAccount;
      try {
        refundAccount = await _refundAccountService.getRefundAccount();
        if (refundAccount != null) {
        } else {
        }
      } on UnauthorizedException {
        if (mounted) context.go('/login');
      } catch (e) {
        AppLogger.w('⚠️ [GuestMyPage] 환급 계좌 로드 실패 (무시): $e');
      }

      setState(() {
        _userProfile = profile;
        _refundAccount = refundAccount;
        _isLoading = false;
      });
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// 비밀번호 변경 취소
  void _cancelPasswordEdit() {
    setState(() {
      _isEditingPassword = false;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
  }

  /// 닉네임 변경 취소
  void _cancelNicknameEdit() {
    setState(() {
      _isEditingNickname = false;
      _nicknameController.clear();
      _nicknameError = null;
    });
  }

  /// 닉네임 변경 처리
  Future<void> _handleNicknameChange() async {
    final nickname = _nicknameController.text.trim();

    final error = TextInputValidator.validate(nickname, minLength: 2, maxLength: 20);
    if (error != null) {
      setState(() => _nicknameError = error);
      return;
    }

    try {
      final newNickname = await _userProfileService.changeNickname(
        nickname: nickname,
      );

      if (mounted) {
        // 프로필 정보 업데이트
        setState(() {
          _userProfile = _userProfile!.copyWith(nickname: newNickname);
          _isEditingNickname = false;
          _nicknameController.clear();
        });
        _showSuccessDialog('닉네임이 성공적으로 변경되었습니다.');
      }
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  /// 비밀번호 변경 처리
  Future<void> _handlePasswordChange() async {
    // 비밀번호 일치 확인
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorDialog('새 비밀번호와 비밀번호 확인이 일치하지 않습니다.');
      return;
    }

    // 비밀번호 형식 검증
    final passwordError = PasswordValidator.validate(_newPasswordController.text);
    if (passwordError != null) {
      _showErrorDialog(passwordError);
      return;
    }

    try {
      await _userProfileService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        _showSuccessDialog('정상적으로 변경되었습니다.');
        _cancelPasswordEdit();
      }
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  /// 연락처 변경 (KMC 본인인증)
  Future<void> _handlePhoneChange() async {
    setState(() => _isChangingPhone = true);
    try {
      final requestResult = await KmcService.requestVerification();
      if (!mounted) return;

      final popupResult = await KmcWebViewHelper.openKmcVerification(
        context: context,
        requestResult: requestResult,
      );
      if (!mounted) return;

      if (popupResult == null) {
        setState(() => _isChangingPhone = false);
        return;
      }

      final verifyResult = await KmcService.verifyResult(
        apiToken: popupResult['apiToken']!,
        certNum: popupResult['certNum']!,
      );
      if (!mounted) return;

      if (verifyResult.verified) {
        setState(() {
          _userProfile = _userProfile!.copyWith(
            phoneNumber: verifyResult.phoneNumber,
          );
          _isChangingPhone = false;
        });
        showPhoneChangedDialog(context, verifyResult.phoneNumber);
      } else {
        setState(() => _isChangingPhone = false);
        _showErrorDialog('본인인증에 실패했습니다. 다시 시도해주세요.');
      }
    } on KmcException catch (e) {
      if (mounted) {
        setState(() => _isChangingPhone = false);
        _showErrorDialog(KmcService.getErrorMessage(e.code));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChangingPhone = false);
        _showErrorDialog('본인인증 중 오류가 발생했습니다.');
      }
    }
  }

  // ──────────────────────────────────────────────
  // 환급 계좌 관련 핸들러
  // ──────────────────────────────────────────────

  /// 환급 계좌 등록/수정 페이지로 이동
  void _handleRefundAccountEdit() async {
    final result = await context.push<BankAccount>('/guest/my-page/refund-account');
    if (result != null && mounted) {
      setState(() {
        _refundAccount = result;
      });
    }
  }

  /// 회원 탈퇴
  Future<void> _handleWithdrawal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('회원 탈퇴', style: AppTextStyles.headingSmall),
        content: Text(
          '정말 탈퇴하시겠습니까?\n모든 데이터가 삭제되며 복구할 수 없습니다.',
          style: AppTextStyles.bodyMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '취소',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            child: Text(
              '탈퇴',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral0,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _userProfileService.withdrawUser();

        if (mounted) {
          // 로그아웃 처리
          final authService = Provider.of<AuthService>(context, listen: false);
          await authService.logout();

          // 로그인 페이지로 이동
          if (mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        }
      } on UnauthorizedException {
        if (mounted) context.go('/login');
      } catch (e) {
        if (mounted) {
          _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
        }
      }
    }
  }

  /// 성공 다이얼로그
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('성공', style: AppTextStyles.headingSmall),
        content: Text(message, style: AppTextStyles.bodyMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            child: Text(
              '확인',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 에러 다이얼로그
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('오류', style: AppTextStyles.headingSmall),
        content: Text(message, style: AppTextStyles.bodyMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            child: Text(
              '확인',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral0,
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
      backgroundColor: AppColors.gray50,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _userProfile != null
          ? _buildContent()
          : const Center(child: Text('데이터를 불러올 수 없습니다.')),
    );
  }

  /// AppBar (반응형)
  PreferredSizeWidget _buildAppBar() {
    final isMobile = ResponsiveUtil.isMobile(context);

    if (isMobile) {
      return AppBar(
        title: const Text('내 정보'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/guest');
            }
          },
        ),
        titleTextStyle: AppTextStyles.headingMedium.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        centerTitle: true,
      );
    } else {
      return const AppGNB();
    }
  }

  /// 에러 뷰
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error500),
          SizedBox(height: AppSpacing.lg),
          Text(
            _errorMessage ?? '오류가 발생했습니다.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: _loadUserProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
            ),
          ),
        ],
      ),
    );
  }

  /// 메인 컨텐츠
  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1024),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageTitle(),

                  SizedBox(height: AppSpacing.xl),
                  // 프로필 정보 카드
                  _buildProfileCard(),

                  SizedBox(height: AppSpacing.xl),

                  // 환급 계좌 카드
                  _buildRefundAccountSection(),

                  SizedBox(height: AppSpacing.xl),

                  // 고객센터 링크 항목 (모바일만)
                  if (ResponsiveUtil.isMobile(context))
                    _buildMenuLinkItem(
                      label: '고객 센터',
                      onTap: () => context.go('/support'),
                    ),

                  if (ResponsiveUtil.isMobile(context)) ...[
                    // 모바일: 회원 탈퇴(우측) + 모드 전환(전체 너비)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleWithdrawal,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: Text(
                          '회원 탈퇴',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _switchMode(
                          context,
                          Provider.of<AuthService>(context, listen: false),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary500,
                          side: const BorderSide(color: AppColors.primary500),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        child: Text(
                          '임대인 모드로 전환',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // 웹/태블릿: 기존 우측 정렬 회원 탈퇴 텍스트 버튼만
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleWithdrawal,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: Text(
                          '회원 탈퇴',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
          if (!ResponsiveUtil.isMobile(context)) const AppFooter(),
        ],
      ),
    );
  }

  /// 페이지 타이틀
  Widget _buildPageTitle() {
    return Text(
      '내 정보',
      style: AppTextStyles.displaySmall.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.gray900,
      ),
    );
  }

  /// 프로필 정보 카드
  Widget _buildProfileCard() {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.cardDefault,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 제목 + [임차인] 배지
          Row(
            children: [
              Text(
                '프로필 정보',
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary500,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '임차인',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.neutral0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.lg),
          Column(
            children: [
              _buildProfileField(
                label: '이름',
                value: _userProfile!.name,
              ),
              _buildNicknameField(),
              _buildProfileField(
                label: '이메일',
                value: _userProfile!.email,
              ),
              _buildPhoneField(),
              // 소셜 로그인 사용자는 비밀번호 변경 불필요
              if (Provider.of<AuthService>(context, listen: false).currentUser?.provider == AuthProvider.email)
                _buildPasswordField(),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // 환급 계좌 카드 UI (호스트 마이페이지 패턴)
  // ──────────────────────────────────────────────

  /// 환급 계좌 카드
  Widget _buildRefundAccountSection() {
    // 계좌 미등록 시 안내 카드 표시
    if (_refundAccount == null) {
      return _buildNoRefundAccountCard();
    }

    return Container(
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
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: AppSpacing.lg),

          // 계좌 필드들
          Column(
            children: [
              _buildProfileField(
                label: '은행명',
                value: _refundAccount!.bankName,
              ),
              _buildProfileField(
                label: '계좌번호',
                value: _refundAccount!.accountNumber,
              ),
              _buildProfileField(
                label: '예금주',
                value: _refundAccount!.accountHolder,
              ),
            ],
          ),

          SizedBox(height: AppSpacing.lg),

          // 계좌 정보 수정 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _handleRefundAccountEdit,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary500,
                side: BorderSide(
                  color: AppColors.primary500,
                  width: 2,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(
                '계좌 정보 수정',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary500,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 환급 계좌 미등록 안내 카드
  Widget _buildNoRefundAccountCard() {
    return Container(
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
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: AppSpacing.lg),

          Center(
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_outlined,
                  size: 64,
                  color: AppColors.neutral400,
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  '등록된 환급 계좌가 없습니다',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleRefundAccountEdit,
                    icon: const Icon(Icons.add),
                    label: const Text('환급 계좌 등록하기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      foregroundColor: AppColors.neutral0,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // 프로필 필드 위젯들
  // ──────────────────────────────────────────────

  /// 프로필 필드 (공통)
  Widget _buildProfileField({
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.gray200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
          ),

          if (trailing != null) trailing,
        ],
      ),
    );
  }

  /// 닉네임 필드 (편집 기능 포함)
  Widget _buildNicknameField() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: _isEditingNickname
          ? _buildNicknameEditForm()
          : _buildNicknameDisplay(),
    );
  }

  /// 닉네임 표시 (편집 모드 OFF)
  Widget _buildNicknameDisplay() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '닉네임',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _userProfile!.nickname ?? '미설정',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isEditingNickname = true;
              _nicknameController.text = _userProfile!.nickname ?? '';
            });
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary500,
            padding: EdgeInsets.zero,
          ),
          child: Text(
            '변경',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary500,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// 닉네임 편집 폼 (편집 모드 ON)
  Widget _buildNicknameEditForm() {
    final trimmed = _nicknameController.text.trim();
    final canSubmit = _nicknameError == null &&
        TextInputValidator.isValid(trimmed, minLength: 2, maxLength: 20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '닉네임',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),

        CustomTextField(
          controller: _nicknameController,
          hint: '닉네임을 입력해주세요',
          onChanged: (v) {
            setState(() {
              _nicknameError = TextInputValidator.validate(v.trim(), minLength: 2, maxLength: 20);
            });
          },
        ),

        Padding(
          padding: const EdgeInsets.only(left: 4, top: 4),
          child: Text(
            _nicknameError ?? '2~20자, 한글/영어만 입력 가능',
            style: AppTextStyles.bodySmall.copyWith(
              color: _nicknameError != null ? AppColors.error500 : AppColors.textSecondary,
            ),
          ),
        ),

        SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelNicknameEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(
                    color: AppColors.border,
                    width: 2,
                  ),
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
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

            SizedBox(width: AppSpacing.sm),

            Expanded(
              child: ElevatedButton(
                onPressed: canSubmit ? _handleNicknameChange : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  disabledBackgroundColor: AppColors.gray300,
                  foregroundColor: AppColors.neutral0,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  '변경',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutral0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 연락처 필드 (변경 버튼 포함)
  Widget _buildPhoneField() {
    return _buildProfileField(
      label: '연락처',
      value: _userProfile!.phoneNumber,
      trailing: TextButton(
        onPressed: _isChangingPhone ? null : _handlePhoneChange,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary500,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          '변경',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.primary500,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 비밀번호 필드 (토글)
  Widget _buildPasswordField() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _isEditingPassword
              ? _buildPasswordEditForm()
              : _buildPasswordDisplay(),
        ],
      ),
    );
  }

  /// 비밀번호 표시 (편집 모드 OFF)
  Widget _buildPasswordDisplay() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '비밀번호',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '••••••••',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
        ),

        TextButton(
          onPressed: () => setState(() => _isEditingPassword = true),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary500,
            padding: EdgeInsets.zero,
          ),
          child: Text(
            '변경',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary500,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// 비밀번호 편집 폼 (편집 모드 ON)
  Widget _buildPasswordEditForm() {
    final canSubmit =
        _currentPasswordController.text.isNotEmpty &&
        _newPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _currentPasswordController,
          hint: '현재 비밀번호',
          obscureText: true,
          onChanged: (_) => setState(() {}),
        ),

        SizedBox(height: AppSpacing.sm),

        CustomTextField(
          controller: _newPasswordController,
          hint: '새 비밀번호',
          obscureText: true,
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 4),

        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            PasswordValidator.policyDescription,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),

        SizedBox(height: AppSpacing.sm),

        CustomTextField(
          controller: _confirmPasswordController,
          hint: '새 비밀번호 확인',
          obscureText: true,
          onChanged: (_) => setState(() {}),
        ),

        SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelPasswordEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(
                    color: AppColors.border,
                    width: 2,
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppRadius.md,
                    ),
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

            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton(
                onPressed: canSubmit ? _handlePasswordChange : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  disabledBackgroundColor:
                      AppColors.gray300,
                  foregroundColor: AppColors.neutral0,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  '변경',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutral0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 고객센터 링크 항목 (> 화살표 스타일)
  Widget _buildMenuLinkItem({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// 모드 전환 다이얼로그 (게스트→호스트)
  void _switchMode(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('임대인 모드로 전환', style: AppTextStyles.headingSmall),
        content: Text(
          '임대인 모드로 전환하시겠습니까?\n방 등록 및 관리 기능을 사용할 수 있습니다.',
          style: AppTextStyles.bodyMedium,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              '취소',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final currentUser = authService.currentUser;

              // 본인인증 + 계좌 등록 완료 → 서버 모드 전환
              if (currentUser != null &&
                  currentUser.phoneVerified &&
                  currentUser.hasBank) {
                try {
                  final ok = await authService.switchUserMode(UserMode.host);
                  if (!ok || !mounted) return;
                  final uid =
                      int.tryParse(authService.currentUser?.id ?? '0') ?? 0;
                  if (uid != 0) {
                    // ignore: use_build_context_synchronously
                    context.read<GNBProvider>().startChatUnreadWatch(
                      uid,
                      userMode: 'host',
                    );
                  }
                  // ignore: use_build_context_synchronously
                  context.go('/host');
                } on SwitchModeRequiresBankException {
                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    context.go('/host/account-setup-standalone');
                  }
                }
                return;
              }

              // 본인인증 완료 + 계좌 미등록
              if (currentUser != null &&
                  currentUser.phoneVerified &&
                  !currentUser.hasBank) {
                if (mounted) {
                  // ignore: use_build_context_synchronously
                  context.go('/host/account-setup-standalone');
                }
                return;
              }

              // 본인인증 필요
              if (mounted) {
                // ignore: use_build_context_synchronously
                context.go('/register/host/kakao');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              foregroundColor: AppColors.neutral0,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.radiusSm,
              ),
            ),
            child: Text(
              '전환하기',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
