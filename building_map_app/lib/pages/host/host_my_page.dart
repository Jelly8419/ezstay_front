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
import '../../widgets/common/custom_text_field.dart';
import '../../utils/password_validator.dart';

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
          debugPrint('✅ [HostMyPage] 계좌 정보 로드 성공: ${account.bankName}');
        } else {
          debugPrint('ℹ️ [HostMyPage] 계좌 미등록');
        }
      } on UnauthorizedException {
        if (mounted) context.go('/login');
      } catch (e) {
        debugPrint('⚠️ [HostMyPage] 계좌 정보 로드 실패 (무시): $e');
        // 계좌 정보 로드 실패는 무시하고 계속 진행
      }

      // 영수증 설정 로드 (선택사항 - 없어도 페이지는 표시됨)
      Map<String, dynamic>? receipt;
      try {
        receipt = await _receiptService.getReceipt();
        if (receipt != null) {
          debugPrint('✅ [HostMyPage] 영수증 설정 로드 성공');
        } else {
          debugPrint('ℹ️ [HostMyPage] 영수증 설정 없음');
        }
      } on UnauthorizedException {
        if (mounted) context.go('/login');
      } catch (e) {
        debugPrint('⚠️ [HostMyPage] 영수증 설정 로드 실패 (무시): $e');
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

  /// 연락처 변경 (본인인증 SDK 호출)
  void _handlePhoneChange() {
    // TODO: 외부 본인인증 SDK 호출 (PASS, NICE 등)
    debugPrint('📱 [HostMyPage] 본인인증 SDK 호출');

    _showInfoDialog('준비 중입니다', '본인인증 기능은 준비 중입니다.');
  }

  /// 계좌 정보 수정
  Future<void> _handleAccountEdit() async {
    debugPrint('🏦 [HostMyPage] 계좌 정보 수정 페이지로 이동');
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
      _receiptBusinessNameController.text =
          _savedReceipt?['businessName'] ?? '';
      _receiptRepNameController.text = _savedReceipt?['repName'] ?? '';
      _receiptEmailController.text = _savedReceipt?['email'] ?? '';
      _receiptNumberInputType = 'phone'; // 기본값
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
  /// PUT /api/host/receipt
  Future<void> _handleSaveReceipt() async {
    // 유효성 검증 (필드별 에러 표시)
    setState(() {
      _validateReceiptFields();
    });

    if (_receiptFieldErrors.isNotEmpty) {
      return;
    }

    try {
      final receiptData = await _receiptService.saveReceipt(
        type: _receiptType,
        number: _receiptNumberController.text,
        businessName: _receiptBusinessNameController.text.isNotEmpty
            ? _receiptBusinessNameController.text
            : null,
        repName: _receiptRepNameController.text.isNotEmpty
            ? _receiptRepNameController.text
            : null,
        email: _receiptEmailController.text.isNotEmpty
            ? _receiptEmailController.text
            : null,
      );

      if (mounted) {
        setState(() {
          _savedReceipt = receiptData;
          _isEditingReceipt = false;
        });
        _showSuccessDialog('영수증 정보가 저장되었습니다.');
      }
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  /// 영수증 설정 삭제
  /// DELETE /api/host/receipt
  Future<void> _handleDeleteReceipt() async {
    try {
      await _receiptService.deleteReceipt();

      if (mounted) {
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
    } on UnauthorizedException {
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  /// 영수증 종류 이름 반환
  String _getReceiptTypeName(String? type) {
    switch (type) {
      case 'personal':
        return '개인소득공제용 현금영수증';
      case 'business':
        return '사업자증빙용 현금영수증';
      case 'tax_invoice':
        return '전자세금계산서';
      default:
        return '-';
    }
  }

  /// 영수증 필드 유효성 검증 (실시간 + 저장 시)
  /// 에러가 있으면 _receiptFieldErrors에 저장, 없으면 null
  bool _validateReceiptFields() {
    _receiptFieldErrors.clear();

    if (_receiptType.isEmpty) {
      _receiptFieldErrors['type'] = '영수증 종류를 선택해주세요.';
    }

    final number = _receiptNumberController.text.trim();

    if (_receiptType == 'personal') {
      if (number.isEmpty) {
        _receiptFieldErrors['number'] = _receiptNumberInputType == 'phone'
            ? '휴대폰 번호를 입력해주세요.'
            : '현금영수증 카드 번호를 입력해주세요.';
      } else if (_receiptNumberInputType == 'phone') {
        _receiptFieldErrors['number'] = _validatePhone(number);
      } else {
        _receiptFieldErrors['number'] = _validateCardNumber(number);
      }
    } else if (_receiptType == 'business') {
      if (number.isEmpty) {
        _receiptFieldErrors['number'] = _receiptNumberInputType == 'phone'
            ? '휴대폰 번호를 입력해주세요.'
            : '사업자 등록번호를 입력해주세요.';
      } else if (_receiptNumberInputType == 'phone') {
        _receiptFieldErrors['number'] = _validatePhone(number);
      } else {
        _receiptFieldErrors['number'] = _validateBusinessNumber(number);
      }
    } else if (_receiptType == 'tax_invoice') {
      if (number.isEmpty) {
        _receiptFieldErrors['number'] = '사업자 등록번호를 입력해주세요.';
      } else {
        _receiptFieldErrors['number'] = _validateBusinessNumber(number);
      }

      if (_receiptBusinessNameController.text.trim().isEmpty) {
        _receiptFieldErrors['businessName'] = '사업자명을 입력해주세요.';
      }
      if (_receiptRepNameController.text.trim().isEmpty) {
        _receiptFieldErrors['repName'] = '대표자 이름을 입력해주세요.';
      }

      final email = _receiptEmailController.text.trim();
      if (email.isNotEmpty) {
        _receiptFieldErrors['email'] = _validateEmail(email);
      }
    }

    // null 값(에러 없음) 제거
    _receiptFieldErrors.removeWhere((_, v) => v == null);
    return _receiptFieldErrors.isEmpty;
  }

  /// 휴대폰 번호 형식 검증 (숫자만 10~11자리)
  String? _validatePhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10 || digits.length > 11) {
      return '휴대폰 번호는 10~11자리 숫자로 입력해주세요.';
    }
    if (!digits.startsWith('01')) {
      return '올바른 휴대폰 번호를 입력해주세요.';
    }
    return null;
  }

  /// 현금영수증 카드 번호 검증 (숫자만 13~16자리)
  String? _validateCardNumber(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 13 || digits.length > 16) {
      return '현금영수증 카드 번호는 13~16자리 숫자로 입력해주세요.';
    }
    return null;
  }

  /// 사업자 등록번호 검증 (숫자만 10자리)
  String? _validateBusinessNumber(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 10) {
      return '사업자 등록번호는 10자리 숫자로 입력해주세요.';
    }
    return null;
  }

  /// 이메일 형식 검증
  String? _validateEmail(String value) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) {
      return '올바른 이메일 주소를 입력해주세요.';
    }
    return null;
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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/host');
            }
          },
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
                  // React: <div className="bg-white rounded-xl p-6 shadow-sm mb-6">
                  _buildSettlementCard(),

                  SizedBox(height: AppSpacing.xl),

                  // 회원 탈퇴 버튼
                  _buildWithdrawalButton(),
                ],
              ),
            ),
          ),
          const AppFooter(),
        ],
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
              // 소셜 로그인 사용자는 비밀번호 변경 불필요
              if (Provider.of<AuthService>(context, listen: false).currentUser?.provider == AuthProvider.email)
                _buildPasswordField(),
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
            style: AppTextStyles.headingMedium.copyWith(
              fontSize: 18, // text-lg
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: AppSpacing.xl), // mb-6 = 24px

          // 정산 받을 계좌 서브섹션
          _buildBankAccountSubsection(),

          // React: <div className="border-t border-gray-200 pt-6">
          Container(
            padding: EdgeInsets.only(top: AppSpacing.xl), // pt-6 = 24px
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.gray200), // border-gray-200
              ),
            ),
            child: _buildReceiptSubsection(),
          ),
        ],
      ),
    );
  }

  /// 정산 받을 계좌 서브섹션
  /// React: <div className="mb-8">
  ///   <h4 className="font-semibold text-gray-900 mb-4">정산 받을 계좌</h4>
  Widget _buildBankAccountSubsection() {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.xl), // mb-8 = 32px
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // React: <h4 className="font-semibold text-gray-900 mb-4">정산 받을 계좌</h4>
          Text(
            '정산 받을 계좌',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600, // font-semibold
              color: AppColors.gray900, // text-gray-900
            ),
          ),

          SizedBox(height: AppSpacing.md), // mb-4 = 16px

          if (_bankAccount != null) ...[
            // React: <div className="py-3 px-4 bg-gray-50 rounded-lg">
            Container(
              padding: EdgeInsets.symmetric(
                vertical: AppSpacing.md, // py-3 = 12px
                horizontal: AppSpacing.md, // px-4 = 16px
              ),
              decoration: BoxDecoration(
                color: AppColors.gray50, // bg-gray-50
                borderRadius: BorderRadius.circular(AppRadius.sm), // rounded-lg
              ),
              child: Row(
                children: [
                  // React: <Building2 className="w-5 h-5 text-gray-400" />
                  Icon(
                    Icons.account_balance,
                    size: 20, // w-5 h-5
                    color: AppColors.neutral400, // text-gray-400
                  ),
                  SizedBox(width: AppSpacing.sm), // gap-2
                  // React: <span className="font-medium text-gray-900">
                  Expanded(
                    child: Text(
                      '${_bankAccount!.bankName} ${_bankAccount!.accountNumber} (${_bankAccount!.accountHolder})',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500, // font-medium
                        color: AppColors.gray900, // text-gray-900
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.md), // mt-4 = 16px

            // React: <button className="w-full mt-4 py-3 px-4 border-2 border-blue-600 text-blue-600 rounded-lg ...">
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _handleAccountEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary500,
                  side: BorderSide(
                    color: AppColors.primary600, // border-blue-600
                    width: 2,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, // px-4
                    vertical: AppSpacing.md, // py-3 = 12px
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppRadius.sm,
                    ), // rounded-lg = 8px
                  ),
                ),
                child: Text(
                  '변경',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary600, // text-blue-600
                    fontWeight: FontWeight.bold, // font-bold
                  ),
                ),
              ),
            ),
          ] else ...[
            // 계좌 미등록 시
            Container(
              padding: EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance,
                    size: 20,
                    color: AppColors.neutral400,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    '등록된 계좌가 없습니다',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray900,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.md),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _handleAccountEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary500,
                  side: BorderSide(
                    color: AppColors.primary600,
                    width: 2,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                child: Text(
                  '등록',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 수수료에 대한 영수증 발급 서브섹션
  /// React: <h4 className="font-semibold text-gray-900 mb-4">수수료에 대한 영수증 발급</h4>
  Widget _buildReceiptSubsection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // React: <h4 className="font-semibold text-gray-900 mb-4">
        Text(
          '수수료에 대한 영수증 발급',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600, // font-semibold
            color: AppColors.gray900, // text-gray-900
          ),
        ),

        SizedBox(height: AppSpacing.md), // mb-4 = 16px

        if (!_isEditingReceipt) ...[
          // 표시 모드
          // React: <div className="py-3 px-4 bg-gray-50 rounded-lg">
          Container(
            padding: EdgeInsets.symmetric(
              vertical: AppSpacing.md, // py-3
              horizontal: AppSpacing.md, // px-4
            ),
            decoration: BoxDecoration(
              color: AppColors.gray50, // bg-gray-50
              borderRadius: BorderRadius.circular(AppRadius.sm), // rounded-lg
            ),
            child: Row(
              children: [
                // React: <FileText className="w-5 h-5 text-gray-400" />
                Icon(
                  Icons.description_outlined,
                  size: 20, // w-5 h-5
                  color: AppColors.neutral400, // text-gray-400
                ),
                SizedBox(width: AppSpacing.sm), // gap-2
                // React: <span className="font-medium text-gray-900">
                Expanded(
                  child: Text(
                    _savedReceipt != null
                        ? '신청 - ${_getReceiptTypeName(_savedReceipt!['receiptType'])} (${_savedReceipt!['receiptNumber']})'
                        : '신청 안함',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500, // font-medium
                      color: AppColors.gray900, // text-gray-900
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: AppSpacing.md), // mt-4

          // React: <button className="w-full mt-4 py-3 px-4 border-2 border-blue-600 text-blue-600 rounded-lg ...">
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _startEditingReceipt,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary500,
                side: BorderSide(
                  color: AppColors.primary600, // border-blue-600
                  width: 2,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, // px-4
                  vertical: AppSpacing.md, // py-3
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppRadius.sm,
                  ), // rounded-lg
                ),
              ),
              child: Text(
                '변경',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary600, // text-blue-600
                  fontWeight: FontWeight.bold, // font-bold
                ),
              ),
            ),
          ),
        ] else ...[
          // 편집 모드
          _buildReceiptEditForm(),
        ],
      ],
    );
  }

  /// 영수증 편집 폼
  Widget _buildReceiptEditForm() {
    final canSubmit = _receiptType.isNotEmpty &&
        _receiptNumberController.text.isNotEmpty &&
        (_receiptType != 'tax_invoice' ||
            (_receiptBusinessNameController.text.isNotEmpty &&
                _receiptRepNameController.text.isNotEmpty));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 영수증 종류
        Text(
          '영수증 종류',
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w500, // font-medium
            color: AppColors.neutral700, // text-gray-700
          ),
        ),
        SizedBox(height: AppSpacing.sm), // mb-2 = 8px

          // React: <select className="w-full px-4 py-3 border border-gray-300 rounded-lg ...">
          DropdownButtonFormField<String>(
            initialValue: _receiptType.isEmpty ? null : _receiptType,
            hint: Text(
              '선택하세요',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'personal',
                child: Text('개인소득공제용 현금영수증'),
              ),
              DropdownMenuItem(
                value: 'business',
                child: Text('사업자증빙용 현금영수증'),
              ),
              DropdownMenuItem(
                value: 'tax_invoice',
                child: Text('전자세금계산서'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _receiptType = value ?? '';
                _receiptNumberInputType = 'phone'; // 종류 변경 시 기본값
                // 종류 변경 시 입력값 초기화
                _receiptNumberController.clear();
                _receiptBusinessNameController.clear();
                _receiptRepNameController.clear();
                _receiptEmailController.clear();
                _receiptFieldErrors.clear();
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm), // rounded-lg
                borderSide: BorderSide(color: AppColors.gray300), // border-gray-300
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: AppColors.gray300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(
                  color: AppColors.primary500, // focus:ring-blue-500
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md, // px-4
                vertical: AppSpacing.md, // py-3 = 12px
              ),
            ),
          ),

          // 조건부 입력 필드들
          if (_receiptType == 'personal') ...[
            SizedBox(height: AppSpacing.md),
            // 번호 종류 선택 라디오
            Text(
              '번호 종류',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.neutral700,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _buildRadioOption(
                  label: '휴대폰 번호',
                  value: 'phone',
                  groupValue: _receiptNumberInputType,
                  onChanged: (value) {
                    setState(() {
                      _receiptNumberInputType = value;
                      _receiptNumberController.clear();
                      _receiptFieldErrors.remove('number');
                    });
                  },
                ),
                SizedBox(width: AppSpacing.md),
                _buildRadioOption(
                  label: '현금영수증 카드 번호',
                  value: 'card',
                  groupValue: _receiptNumberInputType,
                  onChanged: (value) {
                    setState(() {
                      _receiptNumberInputType = value;
                      _receiptNumberController.clear();
                      _receiptFieldErrors.remove('number');
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            _buildReceiptInputField(
              label: _receiptNumberInputType == 'phone'
                  ? '휴대폰 번호'
                  : '현금영수증 카드 번호',
              placeholder: _receiptNumberInputType == 'phone'
                  ? "'-' 없이 숫자만 입력해주세요 (예: 01012345678)"
                  : "'-' 없이 숫자만 입력해주세요",
              controller: _receiptNumberController,
              keyboardType: TextInputType.number,
              errorText: _receiptFieldErrors['number'],
            ),
          ],

          if (_receiptType == 'business') ...[
            SizedBox(height: AppSpacing.md),
            // 번호 종류 선택 라디오
            Text(
              '번호 종류',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.neutral700,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _buildRadioOption(
                  label: '휴대폰 번호',
                  value: 'phone',
                  groupValue: _receiptNumberInputType,
                  onChanged: (value) {
                    setState(() {
                      _receiptNumberInputType = value;
                      _receiptNumberController.clear();
                      _receiptFieldErrors.remove('number');
                    });
                  },
                ),
                SizedBox(width: AppSpacing.md),
                _buildRadioOption(
                  label: '사업자 등록번호',
                  value: 'bizno',
                  groupValue: _receiptNumberInputType,
                  onChanged: (value) {
                    setState(() {
                      _receiptNumberInputType = value;
                      _receiptNumberController.clear();
                      _receiptFieldErrors.remove('number');
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            _buildReceiptInputField(
              label: _receiptNumberInputType == 'phone'
                  ? '휴대폰 번호'
                  : '사업자 등록번호',
              placeholder: _receiptNumberInputType == 'phone'
                  ? "'-' 없이 숫자만 입력해주세요 (예: 01012345678)"
                  : "'-' 없이 숫자만 입력해주세요 (10자리)",
              controller: _receiptNumberController,
              keyboardType: TextInputType.number,
              errorText: _receiptFieldErrors['number'],
            ),
          ],

          if (_receiptType == 'tax_invoice') ...[
            SizedBox(height: AppSpacing.md),
            _buildReceiptInputField(
              label: '사업자 등록번호',
              placeholder: "'-' 없이 숫자만 입력해주세요 (10자리)",
              controller: _receiptNumberController,
              keyboardType: TextInputType.number,
              errorText: _receiptFieldErrors['number'],
            ),
            SizedBox(height: AppSpacing.md),
            _buildReceiptInputField(
              label: '사업자명',
              placeholder: '사업자명을 입력해 주세요.',
              controller: _receiptBusinessNameController,
              errorText: _receiptFieldErrors['businessName'],
            ),
            SizedBox(height: AppSpacing.md),
            _buildReceiptInputField(
              label: '대표자 이름',
              placeholder: '대표자 이름을 입력해 주세요',
              controller: _receiptRepNameController,
              errorText: _receiptFieldErrors['repName'],
            ),
            SizedBox(height: AppSpacing.md),
            _buildReceiptInputField(
              label: '이메일 주소 (선택)',
              placeholder: '이메일 주소를 입력해 주세요',
              controller: _receiptEmailController,
              keyboardType: TextInputType.emailAddress,
              errorText: _receiptFieldErrors['email'],
            ),
          ],

        SizedBox(height: AppSpacing.md),

        // 버튼 영역
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.sm),
          child: Column(
            children: [
              Row(
                children: [
                  // 취소 버튼
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancelReceiptEdit,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.neutral700,
                        side: BorderSide(
                          color: AppColors.gray300,
                          width: 2,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
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

                  // 저장 버튼
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canSubmit ? _handleSaveReceipt : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary600,
                        disabledBackgroundColor: AppColors.gray300,
                        foregroundColor: AppColors.neutral0,
                        padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      child: Text(
                        '저장',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.neutral0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 삭제 버튼 (기존 설정이 있을 때만 표시)
              if (_savedReceipt != null) ...[
                SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _handleDeleteReceipt,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error500,
                      side: BorderSide(
                        color: AppColors.error500,
                        width: 2,
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    child: Text(
                      '영수증 설정 삭제',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.error500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 라디오 버튼 옵션
  /// React: <label className="flex items-center gap-2 cursor-pointer">
  ///   <input type="radio" className="w-4 h-4 text-blue-600 focus:ring-blue-500" />
  ///   <span className="text-gray-900">...</span>
  Widget _buildRadioOption({
    required String label,
    required String value,
    required String groupValue,
    required void Function(String) onChanged,
  }) {
    final isSelected = value == groupValue;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // w-4 h-4 커스텀 라디오 버튼
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? AppColors.primary600
                    : AppColors.gray300,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary600, // text-blue-600
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(width: AppSpacing.sm), // gap-2 = 8px
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.gray900, // text-gray-900
            ),
          ),
        ],
      ),
    );
  }

  /// 영수증 입력 필드 (공통)
  /// React: <input className="w-full px-4 py-3 border border-gray-300 rounded-lg
  ///   focus:ring-2 focus:ring-blue-500 focus:border-blue-500" />
  Widget _buildReceiptInputField({
    required String label,
    required String placeholder,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.neutral700,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: (_) => setState(() {
            // 입력 시 해당 필드 에러 클리어
            _receiptFieldErrors.removeWhere((_, v) => v == errorText);
          }),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            errorText: hasError ? errorText : null,
            errorStyle: AppTextStyles.bodySmall.copyWith(
              color: AppColors.error500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(
                color: hasError ? AppColors.error500 : AppColors.gray300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(
                color: hasError ? AppColors.error500 : AppColors.primary500,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(color: AppColors.error500),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(color: AppColors.error500, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ],
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
    final canSubmit = _currentPasswordController.text.isNotEmpty &&
        _newPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 현재 비밀번호 입력
        CustomTextField(
          controller: _currentPasswordController,
          hint: '현재 비밀번호',
          obscureText: true,
          onChanged: (_) => setState(() {}),
        ),

        SizedBox(height: AppSpacing.sm),

        // 새 비밀번호 입력
        CustomTextField(
          controller: _newPasswordController,
          hint: '새 비밀번호',
          obscureText: true,
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 4),

        // 안내 문구
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            PasswordValidator.policyDescription,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12,
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
          onChanged: (_) => setState(() {}),
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
