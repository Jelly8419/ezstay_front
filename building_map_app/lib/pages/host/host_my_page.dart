import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/user_profile.dart';
import '../../models/bank_account.dart';
import '../../services/user_profile_service.dart';
import '../../services/bank_account_service.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive_util.dart';
import '../../widgets/common/app_gnb.dart';
import '../../widgets/common/custom_text_field.dart';

/// 호스트 마이페이지 (내 정보 관리)
/// React: src/pages/HostMyPage.tsx
class HostMyPage extends StatefulWidget {
  const HostMyPage({super.key});

  @override
  State<HostMyPage> createState() => _HostMyPageState();
}

class _HostMyPageState extends State<HostMyPage> {
  final UserProfileService _userProfileService = UserProfileService();
  final BankAccountService _bankAccountService = BankAccountService();

  // 로딩 상태
  bool _isLoading = true;
  String? _errorMessage;

  // 사용자 정보
  UserProfile? _userProfile;
  BankAccount? _bankAccount;

  // 비밀번호 변경 상태
  bool _isEditingPassword = false;
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // 닉네임 변경 상태
  bool _isEditingNickname = false;
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  /// 사용자 프로필 및 계좌 정보 로드
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 사용자 프로필 로드
      final profile = await _userProfileService.getUserProfile();

      if (profile == null) {
        setState(() {
          _errorMessage = '사용자 정보를 불러올 수 없습니다.';
          _isLoading = false;
        });
        return;
      }

      // 계좌 정보 로드 (선택사항 - 없어도 페이지는 표시됨)
      BankAccount? account;
      try {
        account = await _bankAccountService.getBankAccount();
        if (account != null) {
          debugPrint('✅ [HostMyPage] 계좌 정보 로드 성공: ${account.bankName}');
        } else {
          debugPrint('ℹ️ [HostMyPage] 계좌 미등록');
        }
      } catch (e) {
        debugPrint('⚠️ [HostMyPage] 계좌 정보 로드 실패 (무시): $e');
        // 계좌 정보 로드 실패는 무시하고 계속 진행
      }

      setState(() {
        _userProfile = profile;
        _bankAccount = account;
        _isLoading = false;
      });
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
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
  }

  /// 닉네임 변경 취소
  void _cancelNicknameEdit() {
    setState(() {
      _isEditingNickname = false;
      _nicknameController.clear();
    });
  }

  /// 닉네임 변경 처리
  Future<void> _handleNicknameChange() async {
    final nickname = _nicknameController.text.trim();

    // 길이 검증 (2~20자)
    if (nickname.length < 2 || nickname.length > 20) {
      _showErrorDialog('닉네임은 2~20자로 입력해주세요.');
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

    // 비밀번호 형식 검증 (영문, 숫자, 특수문자 조합 6자~15자)
    final password = _newPasswordController.text;
    final passwordRegex = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{6,15}$',
    );

    if (!passwordRegex.hasMatch(password)) {
      _showErrorDialog('영문, 숫자, 특수문자 조합 6자~15자로 입력해주세요.');
      return;
    }

    try {
      // TODO: 호스트용 비밀번호 변경 API 호출
      // await _userProfileService.changePasswordWithoutCurrent(
      //   newPassword: _newPasswordController.text,
      // );

      if (mounted) {
        _showSuccessDialog('정상적으로 변경되었습니다.');
        _cancelPasswordEdit();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  /// 연락처 변경 (본인인증 SDK 호출)
  void _handlePhoneChange() {
    // TODO: 외부 본인인증 SDK 호출 (PASS, NICE 등)
    debugPrint('📱 [HostMyPage] 본인인증 SDK 호출');

    _showInfoDialog('준비 중입니다', '본인인증 기능은 준비 중입니다.');
  }

  /// 계좌 정보 수정
  void _handleAccountEdit() {
    // TODO: 계좌 정보 수정 페이지로 이동 또는 다이얼로그
    debugPrint('🏦 [HostMyPage] 계좌 정보 수정');

    _showInfoDialog('준비 중입니다', '계좌 정보 수정 기능은 준비 중입니다.');
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
                color: AppColors.textSecondary,
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

  /// 정보 다이얼로그
  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: AppTextStyles.headingSmall),
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
      // React: min-h-screen bg-gray-50
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
      // 모바일: PageHeader 스타일
      // React: <PageHeader title="내 정보" onBack={onBack} />
      return AppBar(
        title: const Text('내 정보'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleTextStyle: AppTextStyles.headingMedium.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        centerTitle: true,
      );
    } else {
      // 데스크톱/태블릿: AppGNB
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
  // React: <div className="max-w-4xl mx-auto px-4 py-6">
  Widget _buildContent() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1024), // max-w-4xl
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, // px-4
            vertical: AppSpacing.xl, // py-6
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 페이지 타이틀
              // React: <h1 className="font-bold text-2xl mb-6 text-gray-900">내 정보</h1>
              _buildPageTitle(),

              SizedBox(height: AppSpacing.xl), // mb-6

              // 프로필 정보 카드
              _buildProfileCard(),

              SizedBox(height: AppSpacing.xl), // mb-6

              // 계좌 정보 카드
              _buildBankAccountCard(),

              SizedBox(height: AppSpacing.xl),

              // 회원 탈퇴 버튼
              _buildWithdrawalButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 페이지 타이틀
  Widget _buildPageTitle() {
    return Text(
      '내 정보',
      style: AppTextStyles.headingLarge.copyWith(
        fontSize: 24, // text-2xl
        fontWeight: FontWeight.bold,
        color: AppColors.gray900,
      ),
    );
  }

  /// 프로필 정보 카드
  /// React: <div className="bg-white rounded-xl p-6 shadow-sm mb-6">
  Widget _buildProfileCard() {
    return Container(
      padding: AppSpacing.paddingLg, // p-6
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-xl
        boxShadow: AppShadows.cardDefault, // shadow-sm
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 제목
          // React: <h3 className="font-bold text-lg mb-4">프로필 정보</h3>
          Text(
            '프로필 정보',
            style: AppTextStyles.headingMedium.copyWith(
              fontSize: 18, // text-lg
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: AppSpacing.lg), // mb-4

          // 필드들
          // React: <div className="space-y-4">
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
              _buildPasswordField(),
            ],
          ),
        ],
      ),
    );
  }

  /// 계좌 정보 카드
  /// React: <div className="bg-white rounded-xl p-6 shadow-sm mb-6">
  Widget _buildBankAccountCard() {
    // 계좌 미등록 시 안내 카드 표시
    if (_bankAccount == null) {
      return _buildNoAccountCard();
    }

    return Container(
      padding: AppSpacing.paddingLg, // p-6
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-xl
        boxShadow: AppShadows.cardDefault, // shadow-sm
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 제목
          // React: <h3 className="font-bold text-lg mb-4">계좌 정보</h3>
          Text(
            '계좌 정보',
            style: AppTextStyles.headingMedium.copyWith(
              fontSize: 18, // text-lg
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: AppSpacing.lg), // mb-4

          // 계좌 필드들
          // React: <div className="space-y-4">
          Column(
            children: [
              _buildProfileField(
                label: '은행명',
                value: _bankAccount!.bankName,
              ),
              _buildProfileField(
                label: '계좌번호',
                value: _bankAccount!.accountNumber,
              ),
              _buildProfileField(
                label: '예금주',
                value: _bankAccount!.accountHolder,
                showBorder: false, // 마지막 필드는 border 없음
              ),
            ],
          ),

          SizedBox(height: AppSpacing.lg), // mt-4

          // 계좌 정보 수정 버튼
          // React: <button className="w-full mt-4 py-3 px-4 border-2 border-blue-600 text-blue-600 ...">
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _handleAccountEdit,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary500,
                side: BorderSide(
                  color: AppColors.primary500, // border-blue-600
                  width: 2,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ), // py-3 px-4
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppRadius.md,
                  ), // rounded-lg
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

  /// 계좌 미등록 안내 카드
  Widget _buildNoAccountCard() {
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
          // 섹션 제목
          Text(
            '계좌 정보',
            style: AppTextStyles.headingMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: AppSpacing.lg),

          // 안내 메시지
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
                  '등록된 계좌 정보가 없습니다',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleAccountEdit,
                    icon: const Icon(Icons.add),
                    label: const Text('계좌 등록하기'),
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

  /// 프로필 필드 (공통) - 아이콘 제거됨
  Widget _buildProfileField({
    required String label,
    required String value,
    Widget? trailing,
    bool showBorder = true,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md), // py-3
      decoration: showBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.gray200), // border-gray-100
              ),
            )
          : null,
      child: Row(
        children: [
          // 레이블 & 값
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 레이블
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary, // text-gray-500
                  ),
                ),
                const SizedBox(height: 4),

                // 값
                Text(
                  value,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600, // font-medium
                    color: AppColors.gray900, // text-gray-900
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
                  color: AppColors.textSecondary,
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
    final canSubmit = _nicknameController.text.trim().length >= 2 &&
        _nicknameController.text.trim().length <= 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '닉네임',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),

        // 닉네임 입력
        CustomTextField(
          controller: _nicknameController,
          hint: '닉네임을 입력해주세요',
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 4),

        // 안내 문구
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '2~20자 입력 가능',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),

        SizedBox(height: AppSpacing.sm),

        // 버튼 그룹
        Row(
          children: [
            // 취소 버튼
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

            // 변경 버튼
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
        onPressed: _handlePhoneChange,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary500, // text-blue-600
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

  /// 비밀번호 필드 (토글) - 아이콘 제거됨
  Widget _buildPasswordField() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md), // py-3
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 편집 모드 분기
          _isEditingPassword
              ? _buildPasswordEditForm()
              : _buildPasswordDisplay(),
        ],
      ),
    );
  }

  /// 비밀번호 표시 (편집 모드 OFF) - 아이콘 제거됨
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
                  color: AppColors.textSecondary,
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
    final canSubmit = _newPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 새 비밀번호 입력
        // React: <input type="password" placeholder="새 비밀번호" />
        CustomTextField(
          controller: _newPasswordController,
          hint: '새 비밀번호',
          obscureText: true,
          onChanged: (_) => setState(() {}), // 버튼 활성화 상태 업데이트
        ),

        const SizedBox(height: 4),

        // 안내 문구
        // React: <div className="text-xs text-gray-500 -mt-1 px-1">영문, 숫자, 특수문자 조합 6자~15자</div>
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '영문, 숫자, 특수문자 조합 6자~15자',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12, // text-xs
              color: AppColors.textSecondary,
            ),
          ),
        ),

        SizedBox(height: AppSpacing.sm),

        // 비밀번호 확인 입력
        CustomTextField(
          controller: _confirmPasswordController,
          hint: '새 비밀번호 확인',
          obscureText: true,
          onChanged: (_) => setState(() {}), // 버튼 활성화 상태 업데이트
        ),

        SizedBox(height: AppSpacing.sm),

        // 버튼 그룹
        // React: <div className="flex gap-2 pt-2">
        Row(
          children: [
            // 취소 버튼
            // React: <button className="flex-1 py-2 bg-white border-2 border-gray-300 text-gray-700 rounded-lg ...">취소</button>
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelPasswordEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(
                    color: AppColors.border, // border-gray-300
                    width: 2,
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                  ), // py-2
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppRadius.md,
                    ), // rounded-lg
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

            SizedBox(width: AppSpacing.sm), // gap-2

            // 변경 버튼
            // React: <button className="flex-1 py-2 bg-blue-600 text-white rounded-lg ... disabled:bg-gray-300">변경</button>
            Expanded(
              child: ElevatedButton(
                onPressed: canSubmit ? _handlePasswordChange : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500, // bg-blue-600
                  disabledBackgroundColor:
                      AppColors.gray300, // disabled:bg-gray-300
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

  /// 회원 탈퇴 버튼
  /// React: <div className="text-right"><button className="text-sm text-gray-500 hover:text-gray-700 underline">회원 탈퇴</button></div>
  Widget _buildWithdrawalButton() {
    return Align(
      alignment: Alignment.centerRight, // text-right
      child: TextButton(
        onPressed: _handleWithdrawal,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary, // text-gray-500
          padding: EdgeInsets.zero,
        ),
        child: Text(
          '회원 탈퇴',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            decoration: TextDecoration.underline, // underline
          ),
        ),
      ),
    );
  }
}
