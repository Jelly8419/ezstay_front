import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../shared/widgets/app_buttons.dart';
import '../shared/widgets/app_inputs.dart';
import '../features/web/web_layout.dart';
import 'mode_selection_page.dart';
import 'user_info_popup.dart';

/// 로그인 페이지 - 새 디자인 시스템 적용
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  late TabController _tabController;
  bool _isCodeSent = false;
  bool _isSendingCode = false;
  String _generatedCode = '';
  bool _isCodeVerified = false;
  UserMode? _selectedMode;
  bool _isLoggingIn = false;
  bool _isSigningUp = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _handleSignUpTabSelected();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          if (authService.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
              ),
            );
          }

          return ResponsiveLayout(
            mobile: _buildMobileLayout(authService),
            desktop: _buildDesktopLayout(authService),
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(AuthService authService) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        children: [
          SizedBox(height: AppSpacing.xxl),
          _buildLogoSection(),
          SizedBox(height: AppSpacing.xl),
          _buildAuthCard(authService),
          SizedBox(height: AppSpacing.lg),
          _buildSocialLoginButtons(authService),
          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(AuthService authService) {
    return WebContainer(
      maxWidth: 480,
      child: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          children: [
            SizedBox(height: AppSpacing.xxxl),
            _buildLogoSection(),
            SizedBox(height: AppSpacing.xl),
            _buildAuthCard(authService),
            SizedBox(height: AppSpacing.lg),
            _buildSocialLoginButtons(authService),
            SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // 로고
        Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.primary50,
            borderRadius: AppRadius.radiusXl,
            boxShadow: AppShadows.shadowMd,
          ),
          child: Icon(
            Icons.home,
            size: 48,
            color: AppColors.primary600,
          ),
        ),
        SizedBox(height: AppSpacing.lg),

        // 타이틀
        Text(
          'EZStay에 오신 것을 환영합니다',
          style: AppTextStyles.displayMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.sm),

        // 서브타이틀
        Text(
          '간편하게 로그인하고 완벽한 숙소를 찾아보세요',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAuthCard(AuthService authService) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusLg,
        boxShadow: AppShadows.shadowMd,
      ),
      child: Column(
        children: [
          // 탭바
          Container(
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                topRight: Radius.circular(AppRadius.lg),
              ),
            ),
            padding: EdgeInsets.all(AppSpacing.xs),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary500,
                borderRadius: AppRadius.radiusMd,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.neutral0,
              unselectedLabelColor: AppColors.neutral600,
              labelStyle: AppTextStyles.labelMedium,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: '로그인'),
                Tab(text: '회원가입'),
              ],
            ),
          ),

          // 탭 내용
          SizedBox(
            height: _isCodeSent ? 420 : 340,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLoginForm(authService),
                _buildSignUpForm(authService),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(AuthService authService) {
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 이메일
            AppTextField(
              label: '이메일',
              hintText: 'email@example.com',
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: AppSpacing.md),

            // 비밀번호
            AppPasswordField(
              label: '비밀번호',
              hintText: '비밀번호를 입력하세요',
              controller: _passwordController,
            ),
            SizedBox(height: AppSpacing.lg),

            // 로그인 버튼
            AppPrimaryButton(
              text: '로그인',
              onPressed: () => _handleEmailLogin(authService),
              isLoading: _isLoggingIn,
              icon: Icons.login,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpForm(AuthService authService) {
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 선택된 모드 표시
              if (_selectedMode != null) ...[
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(color: AppColors.primary200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedMode == UserMode.host ? Icons.home_work : Icons.person,
                        color: AppColors.primary600,
                        size: AppSizes.iconSm,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _selectedMode == UserMode.host ? "집을 내놓고 싶어요" : "집을 찾고 있어요",
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      AppTextButton(
                        text: '변경',
                        onPressed: () {
                          setState(() {
                            _selectedMode = null;
                          });
                          _handleSignUpTabSelected();
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.md),
              ],

              // 이메일과 인증번호 발송
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AppTextField(
                      label: '이메일',
                      hintText: 'email@example.com',
                      controller: _emailController,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 28), // 라벨 높이만큼 공간 확보
                        AppPrimaryButton(
                          text: _isCodeSent ? '재발송' : '발송',
                          onPressed: _isSendingCode ? null : _sendVerificationCode,
                          isLoading: _isSendingCode,
                          fullWidth: true,
                          height: AppSizes.inputHeightMd,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 인증번호 입력
              if (_isCodeSent) ...[
                SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: '인증번호',
                  hintText: '6자리 숫자',
                  controller: _verificationCodeController,
                  prefixIcon: Icons.verified_outlined,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (value == _generatedCode) {
                      setState(() => _isCodeVerified = true);
                      _showSuccessSnackBar('인증번호가 확인되었습니다');
                    } else {
                      setState(() => _isCodeVerified = false);
                    }
                  },
                ),
              ],

              SizedBox(height: AppSpacing.md),

              // 비밀번호
              AppPasswordField(
                label: '비밀번호',
                hintText: '8자 이상 입력하세요',
                controller: _passwordController,
              ),

              SizedBox(height: AppSpacing.lg),

              // 회원가입 버튼
              AppPrimaryButton(
                text: '회원가입',
                onPressed: () => _handleEmailSignUp(authService),
                isLoading: _isSigningUp,
                icon: Icons.person_add,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButtons(AuthService authService) {
    return Column(
      children: [
        // 구분선
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('또는', style: AppTextStyles.bodySmallSecondary),
            ),
            Expanded(child: Divider(color: AppColors.divider)),
          ],
        ),
        SizedBox(height: AppSpacing.lg),

        // 구글 로그인
        AppSecondaryButton(
          text: 'Google로 계속하기',
          onPressed: () => _handleGoogleLogin(authService),
          icon: Icons.g_mobiledata,
        ),
        SizedBox(height: AppSpacing.sm),

        // 카카오 로그인
        SizedBox(
          width: double.infinity,
          height: AppSizes.buttonHeightMd,
          child: ElevatedButton(
            onPressed: () => _handleKakaoLogin(authService),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFE812),
              foregroundColor: const Color(0xFF3C1E1E),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.radiusMd,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble, size: AppSizes.iconSm),
                SizedBox(width: AppSpacing.sm),
                Text(
                  '카카오로 계속하기',
                  style: AppTextStyles.buttonText.copyWith(
                    color: const Color(0xFF3C1E1E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleEmailLogin(AuthService authService) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoggingIn = true);

    final success = await authService.loginWithEmail(
      _emailController.text,
      _passwordController.text,
      null,
    );

    setState(() => _isLoggingIn = false);

    if (success && mounted) {
      context.go('/');
    } else if (mounted) {
      _showErrorSnackBar('로그인에 실패했습니다. 다시 시도해주세요.');
    }
  }

  void _handleEmailSignUp(AuthService authService) async {
    if (!_formKey.currentState!.validate()) return;

    if (_isCodeSent && !_isCodeVerified) {
      _showErrorSnackBar('인증번호를 확인해주세요.');
      return;
    }

    if (_selectedMode == null) {
      _showErrorSnackBar('먼저 사용자 모드를 선택해주세요.');
      return;
    }

    setState(() => _isSigningUp = true);

    final success = await authService.signUpWithEmail(
      _emailController.text,
      _passwordController.text,
      _selectedMode!,
    );

    setState(() => _isSigningUp = false);

    if (success && mounted) {
      context.go('/');
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UserInfoPopup(isFromSignup: true),
          ),
        );
      }
    } else if (mounted) {
      _showErrorSnackBar('회원가입에 실패했습니다. 다시 시도해주세요.');
    }
  }

  void _handleGoogleLogin(AuthService authService) async {
    context.push('/mode-selection', extra: 'google');
  }

  void _handleKakaoLogin(AuthService authService) async {
    context.push('/mode-selection', extra: 'kakao');
  }

  void _sendVerificationCode() async {
    if (_emailController.text.isEmpty) {
      _showErrorSnackBar('이메일을 먼저 입력해주세요');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      _showErrorSnackBar('올바른 이메일 형식을 입력해주세요');
      return;
    }

    setState(() => _isSendingCode = true);

    try {
      _generatedCode = '123456';
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isCodeSent = true;
        _isSendingCode = false;
      });

      _showSuccessSnackBar('${_emailController.text}로 인증번호가 발송되었습니다\n테스트용 인증번호: $_generatedCode');
    } catch (e) {
      setState(() => _isSendingCode = false);
      _showErrorSnackBar('인증번호 발송에 실패했습니다. 다시 시도해주세요.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
        ),
      ),
    );
  }

  void _handleSignUpTabSelected() {
    if (_selectedMode != null) return;

    _tabController.animateTo(0);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModeSelectionPage(
          onModeSelected: (UserMode mode) {
            _selectedMode = mode;
            Navigator.pop(context);
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _tabController.animateTo(1);
              }
            });
          },
        ),
      ),
    );
  }
}
