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
import '../../services/bank_account_service.dart';
import '../../services/receipt_service.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../../utils/responsive_util.dart';
import '../../widgets/common/app_gnb.dart';
import '../../widgets/common/app_footer.dart';
import '../../providers/gnb_provider.dart';
import '../../widgets/common/my_page_dialogs.dart';
import '../../services/host_receipt_service.dart';
import '../../services/host_account_service.dart';
import '../../widgets/host/host_bank_account_section.dart';
import '../../widgets/host/host_nickname_edit_section.dart';
import '../../widgets/host/host_password_edit_section.dart';
import '../../widgets/host/host_receipt_display_section.dart';
import '../../widgets/common/profile_info_row.dart';
import '../../utils/text_input_validator.dart';

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
  final ReceiptService _receiptService = ReceiptService();
  final HostReceiptService _hostReceiptService = HostReceiptService();
  final HostAccountService _hostAccountService = HostAccountService();

  // 로딩 상태
  bool _isLoading = true;
  String? _errorMessage;

  // 사용자 정보
  UserProfile? _userProfile;
  BankAccount? _bankAccount;

  // 비밀번호 변경 상태
  bool _isEditingPassword = false;
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // 닉네임 변경 상태
  bool _isEditingNickname = false;
  final TextEditingController _nicknameController = TextEditingController();
  String? _nicknameError;

  // 영수증 발급 관련 상태
  bool _isEditingReceipt = false;
  String _receiptType = ''; // 'personal' | 'business' | 'tax_invoice' | ''
  // 번호 입력 종류: 'phone' (휴대폰번호) | 'card' (현금영수증카드번호) | 'bizno' (사업자등록번호)
  String _receiptNumberInputType = 'phone';
  final TextEditingController _receiptNumberController =
      TextEditingController();
  final TextEditingController _receiptBusinessNameController =
      TextEditingController();
  final TextEditingController _receiptRepNameController =
      TextEditingController();
  final TextEditingController _receiptEmailController =
      TextEditingController();

  // 영수증 필드별 에러 메시지
  final Map<String, String?> _receiptFieldErrors = {};

  // 저장된 영수증 정보 (GET /api/host/receipt에서 로드)
  Map<String, dynamic>? _savedReceipt;

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
    _receiptNumberController.dispose();
    _receiptBusinessNameController.dispose();
    _receiptRepNameController.dispose();
    _receiptEmailController.dispose();
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
        } else {
        }
      } on UnauthorizedException {
        if (mounted) context.go('/login');
      } catch (e) {
        AppLogger.w('⚠️ [HostMyPage] 계좌 정보 로드 실패 (무시): $e');
        // 계좌 정보 로드 실패는 무시하고 계속 진행
      }

      // 영수증 설정 로드 (선택사항 - 없어도 페이지는 표시됨)
      Map<String, dynamic>? receipt;
      try {
        receipt = await _receiptService.getReceipt();
        if (receipt != null) {
        } else {
        }
      } on UnauthorizedException {
        if (mounted) context.go('/login');
      } catch (e) {
        AppLogger.w('⚠️ [HostMyPage] 영수증 설정 로드 실패 (무시): $e');
      }

      setState(() {
        _userProfile = profile;
        _bankAccount = account;
        _savedReceipt = receipt;
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
    final error = TextInputValidator.validate(
      _nicknameController.text.trim(),
      minLength: 2,
      maxLength: 20,
    );
    if (error != null) {
      setState(() => _nicknameError = error);
      return;
    }
    final newNickname = await _hostAccountService.changeNickname(
      context: context,
      nickname: _nicknameController.text.trim(),
      onError: _showErrorDialog,
    );
    if (newNickname != null && mounted) {
      setState(() {
        _userProfile = _userProfile!.copyWith(nickname: newNickname);
        _isEditingNickname = false;
        _nicknameController.clear();
      });
      _showSuccessDialog('닉네임이 성공적으로 변경되었습니다.');
    }
  }

  /// 비밀번호 변경 처리
  Future<void> _handlePasswordChange() async {
    final success = await _hostAccountService.changePassword(
      context: context,
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
      onError: _showErrorDialog,
    );
    if (success && mounted) {
      _showSuccessDialog('정상적으로 변경되었습니다.');
      _cancelPasswordEdit();
    }
  }

  /// 연락처 변경 (KMC 본인인증)
  Future<void> _handlePhoneChange() async {
    await _hostAccountService.handlePhoneChange(
      context,
      onSuccess: (newPhone) {
        setState(() {
          _userProfile = _userProfile!.copyWith(phoneNumber: newPhone);
        });
      },
    );
  }

  /// 계좌 정보 수정
  Future<void> _handleAccountEdit() async {
    final result =
        await context.push<dynamic>('/host/my-page/settlement-account');
    if (result != null && mounted) {
      _loadUserProfile();
    }
  }

  /// 영수증 편집 시작 (저장된 값 로드)
  void _startEditingReceipt() {
    setState(() {
      _isEditingReceipt = true;
      _receiptType = _savedReceipt?['receiptType'] ?? '';
      _receiptNumberController.text = _savedReceipt?['receiptNumber'] ?? '';
      _receiptBusinessNameController.text = _savedReceipt?['businessName'] ?? '';
      _receiptRepNameController.text = _savedReceipt?['repName'] ?? '';
      _receiptEmailController.text = _savedReceipt?['email'] ?? '';
      _receiptNumberInputType = 'phone';
      _receiptFieldErrors.clear();
    });
  }

  /// 영수증 편집 취소
  void _cancelReceiptEdit() {
    setState(() {
      _isEditingReceipt = false;
      _receiptType = '';
      _receiptNumberInputType = 'phone';
      _receiptNumberController.clear();
      _receiptBusinessNameController.clear();
      _receiptRepNameController.clear();
      _receiptEmailController.clear();
      _receiptFieldErrors.clear();
    });
  }

  /// 영수증 정보 저장
  Future<void> _handleSaveReceipt() async {
    // 유효성 검증 결과를 _receiptFieldErrors에 반영해 UI 업데이트
    setState(() {
      _hostReceiptService.validateFields(
        receiptType: _receiptType,
        receiptNumberInputType: _receiptNumberInputType,
        number: _receiptNumberController.text.trim(),
        businessName: _receiptBusinessNameController.text,
        repName: _receiptRepNameController.text,
        email: _receiptEmailController.text.trim(),
        errors: _receiptFieldErrors,
      );
    });
    if (_receiptFieldErrors.isNotEmpty) return;

    final receiptData = await _hostReceiptService.saveReceipt(
      context: context,
      receiptType: _receiptType,
      receiptNumberInputType: _receiptNumberInputType,
      number: _receiptNumberController.text,
      businessName: _receiptBusinessNameController.text,
      repName: _receiptRepNameController.text,
      email: _receiptEmailController.text,
      errors: _receiptFieldErrors,
      onError: _showErrorDialog,
    );
    if (receiptData != null && mounted) {
      setState(() {
        _savedReceipt = receiptData;
        _isEditingReceipt = false;
      });
      _showSuccessDialog('영수증 정보가 저장되었습니다.');
    }
  }

  /// 영수증 설정 삭제
  Future<void> _handleDeleteReceipt() async {
    final success = await _hostReceiptService.deleteReceipt(
      context: context,
      onError: _showErrorDialog,
    );
    if (success && mounted) {
      setState(() {
        _savedReceipt = null;
        _isEditingReceipt = false;
        _receiptType = '';
        _receiptNumberInputType = 'phone';
        _receiptNumberController.clear();
        _receiptBusinessNameController.clear();
        _receiptRepNameController.clear();
        _receiptEmailController.clear();
        _receiptFieldErrors.clear();
      });
      _showSuccessDialog('영수증 설정이 삭제되었습니다.');
    }
  }

  /// 영수증 종류 이름 반환
  String _getReceiptTypeName(String? type) =>
      _hostReceiptService.getReceiptTypeName(type);

  /// 회원 탈퇴
  Future<void> _handleWithdrawal() async {
    await _hostAccountService.withdrawUser(
      context: context,
      onError: _showErrorDialog,
    );
  }

  void _showSuccessDialog(String message) =>
      showMyPageSuccessDialog(context, message);

  void _showErrorDialog(String message) =>
      showMyPageErrorDialog(context, message);

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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/host');
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

                  // 정산 정보 카드 (계좌 + 영수증)
                  _buildSettlementCard(),

                  SizedBox(height: AppSpacing.xl),

                  // 정산 / 고객센터 링크 항목 (모바일만)
                  if (ResponsiveUtil.isMobile(context)) ...[
                    _buildMenuLinkItem(
                      label: '정산',
                      onTap: () => context.go('/host/settlement'),
                    ),
                    _buildMenuLinkItem(
                      label: '고객 센터',
                      onTap: () => context.go('/support'),
                    ),
                  ],

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
                          '임차인 모드로 전환',
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
      style: AppTextStyles.headingLarge.copyWith(
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
          // 섹션 제목 + [임대인] 배지
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
                  '임대인',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.neutral0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.lg), // mb-4

          // 필드들
          // React: <div className="space-y-4">
          Column(
            children: [
              ProfileInfoRow(
                label: '이름',
                value: _userProfile!.name,
              ),
              HostNicknameEditSection(
                isEditing: _isEditingNickname,
                currentNickname: _userProfile!.nickname,
                nicknameController: _nicknameController,
                nicknameError: _nicknameError,
                onStartEdit: () => setState(() {
                  _isEditingNickname = true;
                  _nicknameController.text = _userProfile!.nickname ?? '';
                }),
                onCancel: _cancelNicknameEdit,
                onSave: _handleNicknameChange,
                onFieldChanged: () => setState(() {
                  _nicknameError = TextInputValidator.validate(
                    _nicknameController.text.trim(),
                    minLength: 2,
                    maxLength: 20,
                  );
                }),
              ),
              ProfileInfoRow(
                label: '이메일',
                value: _userProfile!.email,
              ),
              _buildPhoneField(),
              // 소셜 로그인 사용자는 비밀번호 변경 불필요
              if (Provider.of<AuthService>(context, listen: false).currentUser?.provider == AuthProvider.email)
                HostPasswordEditSection(
                  isEditing: _isEditingPassword,
                  currentPasswordController: _currentPasswordController,
                  newPasswordController: _newPasswordController,
                  confirmPasswordController: _confirmPasswordController,
                  onStartEdit: () => setState(() => _isEditingPassword = true),
                  onCancel: _cancelPasswordEdit,
                  onSave: _handlePasswordChange,
                  onFieldChanged: () => setState(() {}),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 정산 정보 카드 (계좌 + 영수증)
  /// React: <div className="bg-white rounded-xl p-6 shadow-sm mb-6">
  ///   <h3 className="font-bold text-lg mb-6">정산 정보</h3>
  ///   - 정산 받을 계좌 (h4)
  ///   - border-t border-gray-200 pt-6
  ///   - 수수료에 대한 영수증 발급 (h4)
  Widget _buildSettlementCard() {
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
          // React: <h3 className="font-bold text-lg mb-6">정산 정보</h3>
          Text(
            '정산 정보',
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: AppSpacing.xl), // mb-6 = 24px

          // 정산 받을 계좌 서브섹션
          HostBankAccountSection(
            bankAccount: _bankAccount,
            onEdit: _handleAccountEdit,
          ),

          // React: <div className="border-t border-gray-200 pt-6">
          Container(
            padding: EdgeInsets.only(top: AppSpacing.xl), // pt-6 = 24px
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.gray200), // border-gray-200
              ),
            ),
            child: HostReceiptDisplaySection(
              isEditing: _isEditingReceipt,
              savedReceipt: _savedReceipt,
              receiptTypeName: _savedReceipt != null
                  ? _getReceiptTypeName(_savedReceipt!['receiptType'])
                  : '',
              onStartEdit: _startEditingReceipt,
              receiptType: _receiptType,
              receiptNumberInputType: _receiptNumberInputType,
              receiptNumberController: _receiptNumberController,
              receiptBusinessNameController: _receiptBusinessNameController,
              receiptRepNameController: _receiptRepNameController,
              receiptEmailController: _receiptEmailController,
              receiptFieldErrors: _receiptFieldErrors,
              onReceiptTypeChanged: (value) {
                setState(() {
                  _receiptType = value;
                  _receiptNumberInputType = 'phone';
                  _receiptNumberController.clear();
                  _receiptBusinessNameController.clear();
                  _receiptRepNameController.clear();
                  _receiptEmailController.clear();
                  _receiptFieldErrors.clear();
                });
              },
              onNumberInputTypeChanged: (value) {
                setState(() {
                  _receiptNumberInputType = value;
                  _receiptNumberController.clear();
                  _receiptFieldErrors.remove('number');
                });
              },
              onCancel: _cancelReceiptEdit,
              onSave: _handleSaveReceipt,
              onDelete: _handleDeleteReceipt,
              onFieldChanged: () => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  /// 연락처 필드 (변경 버튼 포함)
  Widget _buildPhoneField() {
    return ProfileInfoRow(
      label: '연락처',
      value: _userProfile!.phoneNumber,
      trailing: TextButton(
        onPressed: _handlePhoneChange,
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

  /// 정산/고객센터 링크 항목 (> 화살표 스타일)
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

  /// 모드 전환 다이얼로그 (호스트→게스트)
  void _switchMode(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('임차인 모드로 전환', style: AppTextStyles.headingSmall),
        content: Text(
          '임차인 모드로 전환하시겠습니까?\n방 검색 및 예약 기능을 사용할 수 있습니다.',
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
              final ok = await authService.switchUserMode(UserMode.guest);
              if (!ok || !mounted) return;
              final uid = int.tryParse(authService.currentUser?.id ?? '0') ?? 0;
              if (uid != 0) {
                // ignore: use_build_context_synchronously
                context.read<GNBProvider>().startChatUnreadWatch(
                  uid,
                  userMode: 'guest',
                );
              }
              // ignore: use_build_context_synchronously
              context.go('/guest');
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
