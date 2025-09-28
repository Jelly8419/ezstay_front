import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'mode_selection_page.dart';
import 'host_home_page.dart';
import 'guest_home_page.dart';
import 'user_info_popup.dart';

/// 로그인 페이지
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  late TabController _tabController;
  bool _obscurePassword = true;
  bool _isCodeSent = false;
  bool _isSendingCode = false;
  String _generatedCode = '';
  bool _isCodeVerified = false;
  UserMode? _selectedMode; // 선택된 모드 저장

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 탭 변경 감지 리스너 추가
    _tabController.addListener(() {
      if (_tabController.index == 1) { // 회원가입 탭 선택 시
        _handleSignUpTabSelected();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('EZStay'),
        backgroundColor: const Color(0xFF87CEEB),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          Consumer<AuthService>(
            builder: (context, authService, child) {
              if (authService.isLoggedIn) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.account_circle),
                  onSelected: (value) {
                    if (value == 'logout') {
                      _handleLogout(authService);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'user_info',
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 18),
                          const SizedBox(width: 8),
                          Text(authService.currentUser?.name ?? '사용자'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 18),
                          SizedBox(width: 8),
                          Text('로그아웃'),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          if (authService.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF87CEEB)),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // 로고 섹션
                _buildLogoSection(),
                const SizedBox(height: 48),
                // 탭바와 폼
                _buildAuthForm(authService),
                const SizedBox(height: 32),
                // 소셜 로그인 버튼들
                _buildSocialLoginButtons(authService),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF87CEEB), // 블루스카이 색상
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.home,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'EZStay',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'EZStay에 오신걸 환영합니다',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '간편하게 로그인하고 완벽한 숙소를 찾아보세요',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAuthForm(AuthService authService) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        children: [
          // 탭바
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF87CEEB),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: '로그인'),
                Tab(text: '회원가입'),
              ],
            ),
          ),
          // 탭 내용
          SizedBox(
            height: _isCodeSent ? 350 : 270, // 이름 필드 제거로 높이 감소
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
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: '이메일',
                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF87CEEB)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF87CEEB), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '이메일을 입력해주세요';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return '올바른 이메일 형식을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: '비밀번호',
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF87CEEB)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF87CEEB), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호를 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _handleEmailLogin(authService),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF87CEEB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '로그인',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpForm(AuthService authService) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 선택된 모드 표시
              if (_selectedMode != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF87CEEB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF87CEEB).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedMode == UserMode.host ? Icons.home_work : Icons.person,
                        color: const Color(0xFF87CEEB),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '선택된 모드: ${_selectedMode == UserMode.host ? "집을 내놓고 싶어요" : "집을 찾고 있어요"}',
                        style: const TextStyle(
                          color: Color(0xFF87CEEB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedMode = null;
                          });
                          _handleSignUpTabSelected();
                        },
                        child: const Text(
                          '변경',
                          style: TextStyle(
                            color: Color(0xFF87CEEB),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            // 이메일 입력란과 인증번호 발송 버튼
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: '이메일',
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF87CEEB)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF87CEEB), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '이메일을 입력해주세요';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return '올바른 이메일 형식을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSendingCode ? null : () => _sendVerificationCode(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF87CEEB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSendingCode
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isCodeSent ? '재발송' : '발송',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            // 인증번호 입력 필드 (이메일 발송 후 표시)
            if (_isCodeSent) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _verificationCodeController,
                decoration: InputDecoration(
                  labelText: '인증번호',
                  prefixIcon: const Icon(Icons.verified_outlined, color: Color(0xFF87CEEB)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF87CEEB), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (_isCodeSent && (value == null || value.isEmpty)) {
                    return '인증번호를 입력해주세요';
                  }
                  if (_isCodeSent && value != _generatedCode) {
                    return '인증번호가 일치하지 않습니다';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value == _generatedCode) {
                    setState(() {
                      _isCodeVerified = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('인증번호가 확인되었습니다'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } else {
                    setState(() {
                      _isCodeVerified = false;
                    });
                  }
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: '비밀번호',
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF87CEEB)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF87CEEB), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _handleEmailSignUp(authService),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF87CEEB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '회원가입',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[300])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '또는',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[300])),
          ],
        ),
        const SizedBox(height: 24),
        // 구글 로그인
        _buildSocialButton(
          onPressed: () => _handleGoogleLogin(authService),
          icon: Icons.g_mobiledata,
          text: 'Google로 계속하기',
          color: Colors.white,
          textColor: Colors.black87,
          borderColor: Colors.grey[300]!,
        ),
        const SizedBox(height: 12),
        // 카카오 로그인
        _buildSocialButton(
          onPressed: () => _handleKakaoLogin(authService),
          icon: Icons.chat_bubble,
          text: '카카오로 계속하기',
          color: const Color(0xFFFFE812),
          textColor: const Color(0xFF3C1E1E),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String text,
    required Color color,
    required Color textColor,
    Color? borderColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: borderColor != null ? BorderSide(color: borderColor) : BorderSide.none,
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleEmailLogin(AuthService authService) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await authService.loginWithEmail(
      _emailController.text,
      _passwordController.text,
      null, // 로그인 시에는 기존 모드 사용
    );
    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (mounted) {
      _showErrorSnackBar('로그인에 실패했습니다. 다시 시도해주세요.');
    }
  }

  void _handleEmailSignUp(AuthService authService) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isCodeSent && !_isCodeVerified) {
      _showErrorSnackBar('인증번호를 확인해주세요.');
      return;
    }

    // 선택된 모드가 없다면 에러 표시
    if (_selectedMode == null) {
      _showErrorSnackBar('먼저 사용자 모드를 선택해주세요.');
      return;
    }

    // 선택된 모드로 회원가입 요청
    final success = await authService.signUpWithEmail(
      _emailController.text,
      _passwordController.text,
      _selectedMode!,
    );

    if (success && mounted) {
      // 회원가입 성공 시 본인인증 정보 팝업으로 이동
      Navigator.of(context).popUntil((route) => route.isFirst); // 먼저 메인으로 돌아가기

      // 본인인증 정보 팝업으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const UserInfoPopup(isFromSignup: true),
        ),
      );
    } else if (mounted) {
      _showErrorSnackBar('회원가입에 실패했습니다. 다시 시도해주세요.');
    }
  }

  void _handleGoogleLogin(AuthService authService) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModeSelectionPage(
          onModeSelected: (mode) async {
            final success = await authService.loginWithGoogle(mode);
            if (success && mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
              // 소셜 로그인 성공 시 본인인증 정보 팝업으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserInfoPopup(isFromSignup: true),
                ),
              );
            } else if (mounted) {
              _showErrorSnackBar('Google 로그인에 실패했습니다. 다시 시도해주세요.');
            }
          },
        ),
      ),
    );
  }

  void _handleKakaoLogin(AuthService authService) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModeSelectionPage(
          onModeSelected: (mode) async {
            final success = await authService.loginWithKakao(mode);
            if (success && mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
              // 카카오 로그인 성공 시 본인인증 정보 팝업으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserInfoPopup(isFromSignup: true),
                ),
              );
            } else if (mounted) {
              _showErrorSnackBar('카카오 로그인에 실패했습니다. 다시 시도해주세요.');
            }
          },
        ),
      ),
    );
  }

  void _handleLogout(AuthService authService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF87CEEB),
              foregroundColor: Colors.white,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authService.logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('로그아웃되었습니다'),
            backgroundColor: const Color(0xFF87CEEB),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _sendVerificationCode() async {
    // 이메일 유효성 검사
    if (_emailController.text.isEmpty) {
      _showErrorSnackBar('이메일을 먼저 입력해주세요');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      _showErrorSnackBar('올바른 이메일 형식을 입력해주세요');
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    try {
      // 테스트 환경에서는 고정 인증번호 생성
      _generatedCode = '123456';
      await Future.delayed(const Duration(seconds: 2)); // 시뮬레이션

      setState(() {
        _isCodeSent = true;
        _isSendingCode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_emailController.text}로 인증번호가 발송되었습니다\n테스트용 인증번호: $_generatedCode'),
          backgroundColor: const Color(0xFF87CEEB),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isSendingCode = false;
      });
      _showErrorSnackBar('인증번호 발송에 실패했습니다. 다시 시도해주세요.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _handleSignUpTabSelected() {
    // 이미 모드를 선택했다면 더 이상 모드 선택 페이지로 가지 않음
    if (_selectedMode != null) {
      return;
    }

    // 로그인 탭으로 되돌리기 (즉시)
    _tabController.animateTo(0);

    // 모드 선택 페이지로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModeSelectionPage(
          onModeSelected: (UserMode mode) {
            _selectedMode = mode;
            Navigator.pop(context); // ModeSelectionPage 닫기
            // 잠시 후 회원가입 탭으로 이동
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