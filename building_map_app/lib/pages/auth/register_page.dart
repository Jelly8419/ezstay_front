import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../../core/theme/app_colors.dart';
import '../../config/api_config.dart';

/// 회원가입 페이지 - 미니멀 디자인
class RegisterPage extends StatefulWidget {
  final UserMode mode; // mode_selection에서 전달받음
  final String? initialEmail; // 소셜 로그인 시 자동 입력
  final String? initialName; // 소셜 로그인 시 자동 입력
  final bool isSocialLogin; // 소셜 로그인 여부

  const RegisterPage({
    super.key,
    required this.mode,
    this.initialEmail,
    this.initialName,
    this.isSocialLogin = false,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // 호스트용 계좌 정보
  final _accountController = TextEditingController();
  final _accountHolderController = TextEditingController();
  String? _selectedBank;
  bool _accountVerified = false;

  bool _isRegistering = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;
  bool _agreeMarketing = false;

  // 은행 목록
  static const List<String> _banks = [
    '국민은행', '신한은행', '우리은행', '하나은행', 'KB국민은행',
    '기업은행', '농협은행', '카카오뱅크', '토스뱅크', '새마을금고',
    '신협', '우체국예금보험', '경남은행', '광주은행', '대구은행',
    '부산은행', '수협은행', '전북은행', '제주은행', '산업은행',
    '수출입은행', 'SC제일은행', '씨티은행'
  ];

  @override
  void initState() {
    super.initState();
    // 소셜 로그인인 경우 초기값 설정
    if (widget.isSocialLogin) {
      if (widget.initialEmail != null) {
        _emailController.text = widget.initialEmail!;
      }
      if (widget.initialName != null) {
        _nameController.text = widget.initialName!;
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _accountController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  // ============= 색상 정의 (login_page와 동일) =============
  static const primaryBlack = Color(0xFF000000);
  static const secondaryGray = Color(0xFF808080);
  static const borderGray = Color(0xFFE0E0E0);
  static const backgroundWhite = Color(0xFFFFFFFF);
  static const hintGray = Color(0xFFCCCCCC);
  static const textGray = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      appBar: AppBar(
        backgroundColor: backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryBlack),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.only(
              top: 40,
              left: 24,
              right: 24,
              bottom: 40,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 제목
                  const Text(
                    '회원가입',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: primaryBlack,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // 부제목 (선택한 모드 표시)
                  Text(
                    widget.mode == UserMode.guest
                        ? '게스트로 가입하기'
                        : '호스트로 가입하기',
                    style: const TextStyle(
                      fontSize: 16,
                      color: textGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // 소셜 로그인 시 이메일 표시 (읽기 전용)
                  if (widget.isSocialLogin) ...[
                    const Text(
                      '이메일 주소',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: textGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 52,
                      child: TextFormField(
                        controller: _emailController,
                        enabled: false, // 읽기 전용
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: primaryBlack,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Color(0xFFF5F5F5), // 비활성 배경색
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: borderGray,
                              width: 1,
                            ),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: borderGray,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 이메일/비밀번호 필드 (일반 회원가입일 때만)
                  if (!widget.isSocialLogin) ...[
                    // 이메일 라벨
                    const Text(
                      '이메일 주소',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: textGray,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 이메일 입력
                  SizedBox(
                    height: 52,
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: primaryBlack,
                      ),
                      decoration: InputDecoration(
                        hintText: 'email@example.com',
                        hintStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: hintGray,
                        ),
                        filled: true,
                        fillColor: backgroundWhite,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: borderGray,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: borderGray,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.primary600,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.error500,
                            width: 1,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '이메일을 입력해주세요';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return '올바른 이메일 형식이 아닙니다';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 비밀번호 라벨
                  const Text(
                    '비밀번호',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: textGray,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 비밀번호 입력
                  SizedBox(
                    height: 52,
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: primaryBlack,
                      ),
                      decoration: InputDecoration(
                        hintText: '8자 이상, 영문과 숫자 포함',
                        hintStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: hintGray,
                        ),
                        filled: true,
                        fillColor: backgroundWhite,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: borderGray,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: borderGray,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.primary600,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.error500,
                            width: 1,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: secondaryGray,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력해주세요';
                        }
                        if (value.length < 8) {
                          return '비밀번호는 8자 이상이어야 합니다';
                        }
                        if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d).+$')
                            .hasMatch(value)) {
                          return '영문과 숫자를 포함해야 합니다';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 비밀번호 확인 라벨
                  const Text(
                    '비밀번호 확인',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: textGray,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 비밀번호 확인 입력
                  SizedBox(
                    height: 52,
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: primaryBlack,
                      ),
                      decoration: InputDecoration(
                        hintText: '비밀번호를 다시 입력해 주세요.',
                        hintStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: hintGray,
                        ),
                        filled: true,
                        fillColor: backgroundWhite,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: borderGray,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: borderGray,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.primary600,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.error500,
                            width: 1,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: secondaryGray,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호 확인을 입력해주세요';
                        }
                        if (value != _passwordController.text) {
                          return '비밀번호가 일치하지 않습니다';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ],

                  // 이름 라벨 (소셜 로그인 시 읽기 전용)
                  const Text(
                    '이름',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: textGray,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 이름 입력
                  SizedBox(
                    height: 52,
                    child: TextFormField(
                      controller: _nameController,
                      enabled: !widget.isSocialLogin, // 소셜 로그인 시 읽기 전용
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: primaryBlack,
                      ),
                      decoration: InputDecoration(
                        hintText: '실명을 입력해 주세요.',
                        hintStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: hintGray,
                        ),
                        filled: true,
                        fillColor: widget.isSocialLogin
                            ? Color(0xFFF5F5F5)  // 소셜 로그인 시 회색 배경
                            : backgroundWhite,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: borderGray,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: borderGray,
                            width: 1,
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: borderGray,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.primary600,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.error500,
                            width: 1,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '이름을 입력해주세요';
                        }
                        if (value.length < 2) {
                          return '이름은 2자 이상이어야 합니다';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 전화번호 라벨
                  const Text(
                    '전화번호',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: textGray,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 전화번호 입력
                  SizedBox(
                    height: 52,
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: primaryBlack,
                      ),
                      decoration: InputDecoration(
                        hintText: '010-0000-0000',
                        hintStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: hintGray,
                        ),
                        filled: true,
                        fillColor: backgroundWhite,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: borderGray,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: borderGray,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.primary600,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.error500,
                            width: 1,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '전화번호를 입력해주세요';
                        }
                        // 010-0000-0000 또는 01000000000 형식
                        if (!RegExp(r'^01[016789][-]?\d{3,4}[-]?\d{4}$')
                            .hasMatch(value)) {
                          return '올바른 전화번호 형식이 아닙니다';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 호스트용 계좌 정보 (호스트 모드일 때만)
                  if (widget.mode == UserMode.host) ...[
                    // 정산 정보 섹션 제목
                    const Text(
                      '정산 정보',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primaryBlack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '수익 정산을 위한 계좌 정보를 입력해주세요',
                      style: TextStyle(
                        fontSize: 14,
                        color: textGray,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 은행 선택 라벨
                    const Text(
                      '은행',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: textGray,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 은행 선택 드롭다운
                    SizedBox(
                      height: 52,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          hintText: '은행을 선택해주세요',
                          hintStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: hintGray,
                          ),
                          filled: true,
                          fillColor: backgroundWhite,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: borderGray,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: borderGray,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.primary600,
                              width: 1.5,
                            ),
                          ),
                        ),
                        items: _banks.map((bank) {
                          return DropdownMenuItem(
                            value: bank,
                            child: Text(bank),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBank = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 계좌번호 라벨
                    const Text(
                      '계좌번호',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: textGray,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 계좌번호 입력 + 확인 버튼
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: TextFormField(
                              controller: _accountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: primaryBlack,
                              ),
                              decoration: InputDecoration(
                                hintText: '계좌번호를 입력해주세요',
                                hintStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: hintGray,
                                ),
                                filled: true,
                                fillColor: backgroundWhite,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: borderGray,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: borderGray,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.primary600,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _verifyAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accountVerified
                                  ? AppColors.success500
                                  : AppColors.primary600,
                              foregroundColor: backgroundWhite,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _accountVerified ? '확인완료' : '확인하기',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 예금주 라벨
                    const Text(
                      '예금주',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: textGray,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 예금주 입력
                    SizedBox(
                      height: 52,
                      child: TextFormField(
                        controller: _accountHolderController,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: primaryBlack,
                        ),
                        decoration: InputDecoration(
                          hintText: '예금주명을 입력해주세요',
                          hintStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: hintGray,
                          ),
                          filled: true,
                          fillColor: backgroundWhite,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: borderGray,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: borderGray,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.primary600,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 약관 동의
                  InkWell(
                    onTap: () {
                      setState(() {
                        _agreeTerms = !_agreeTerms;
                      });
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _agreeTerms,
                            onChanged: (value) {
                              setState(() {
                                _agreeTerms = value ?? false;
                              });
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            activeColor: AppColors.primary600,
                            side: const BorderSide(
                              color: borderGray,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '이용약관 및 개인정보처리방침 동의 (필수)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 마케팅 수신 동의
                  InkWell(
                    onTap: () {
                      setState(() {
                        _agreeMarketing = !_agreeMarketing;
                      });
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _agreeMarketing,
                            onChanged: (value) {
                              setState(() {
                                _agreeMarketing = value ?? false;
                              });
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            activeColor: AppColors.primary600,
                            side: const BorderSide(
                              color: borderGray,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '마케팅 정보 수신 동의 (선택)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 회원가입 버튼
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isRegistering ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary600,
                        foregroundColor: backgroundWhite,
                        disabledBackgroundColor: borderGray,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isRegistering
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    backgroundWhite),
                              ),
                            )
                          : const Text(
                              '가입하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),

                  // 소셜 로그인이 아닌 경우에만 카카오 간편가입 표시
                  if (!widget.isSocialLogin) ...[
                    const SizedBox(height: 40),

                    // 구분선
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: borderGray,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '또는',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: secondaryGray,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            color: borderGray,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 카카오 간편가입
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _handleKakaoSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE812),
                          foregroundColor: const Color(0xFF3C1E1E),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '카카오로 간편가입',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeTerms) {
      _showErrorDialog('이용약관 및 개인정보처리방침에 동의해주세요.');
      return;
    }

    // 호스트 모드일 때 계좌 인증 확인
    if (widget.mode == UserMode.host) {
      if (_selectedBank == null || _accountController.text.isEmpty || _accountHolderController.text.isEmpty) {
        _showErrorDialog('정산 정보를 모두 입력해주세요.');
        return;
      }
      if (!_accountVerified) {
        _showErrorDialog('계좌 확인을 먼저 완료해주세요.');
        return;
      }
    }

    setState(() => _isRegistering = true);

    try {
      final authService = context.read<AuthService>();
      bool success;

      if (widget.isSocialLogin) {
        // 소셜 로그인: 추가 정보만 업데이트
        // TODO: 백엔드 API에 추가 정보 전송 (전화번호, 계좌 정보)
        // 현재는 임시로 성공 처리
        success = true;

        // 추가 정보 업데이트 API 호출 필요
        // await authService.updateUserProfile(
        //   phone: _phoneController.text,
        //   bankCode: _getBankCode(_selectedBank!),
        //   accountNumber: _accountController.text,
        //   accountHolder: _accountHolderController.text,
        // );
      } else {
        // 일반 이메일 회원가입
        success = await authService.signUpWithEmail(
          _emailController.text,
          _passwordController.text,
          widget.mode, // UserMode.guest 또는 UserMode.host
        );
      }

      if (mounted) {
        setState(() => _isRegistering = false);

        if (success) {
          // 회원가입 성공 → 홈으로 이동
          if (widget.mode == UserMode.host) {
            context.go('/host');
          } else {
            context.go('/guest');
          }
        } else {
          _showErrorDialog('회원가입에 실패했습니다.\n다시 시도해주세요.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRegistering = false);
        _showErrorDialog('회원가입 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.');
      }
    }
  }

  /// 카카오 간편가입 처리
  Future<void> _handleKakaoSignup() async {
    // 웹 환경에서는 로그인 페이지로 이동 (전체 페이지 리다이렉트 방식)
    if (kIsWeb) {
      _showInfoDialog(
        '카카오 간편가입',
        '로그인 페이지에서 "카카오로 계속하기" 버튼을 눌러주세요.\n'
        '카카오 로그인 후 자동으로 회원가입 페이지로 이동됩니다.',
        onConfirm: () {
          context.go('/login');
        },
      );
      return;
    }

    // 모바일 환경에서는 직접 카카오 로그인 호출
    try {
      final authService = context.read<AuthService>();

      // 카카오 로그인 실행 (guest 모드로 기본 설정)
      final success = await authService.loginWithKakao(UserMode.guest);

      if (success && mounted) {
        // 카카오 로그인 성공 → RegisterPage를 소셜 로그인 모드로 다시 로드
        final currentUser = authService.currentUser;
        context.pushReplacement(
          '/register',
          extra: {
            'mode': UserMode.guest,
            'email': currentUser?.email,
            'name': currentUser?.name,
            'isSocialLogin': true,
          },
        );
      } else if (mounted) {
        _showErrorDialog('카카오 로그인에 실패했습니다.\n다시 시도해주세요.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('카카오 로그인 중 오류가 발생했습니다.');
      }
    }
  }

  /// 계좌 인증
  Future<void> _verifyAccount() async {
    if (_accountController.text.isEmpty || _selectedBank == null || _accountHolderController.text.isEmpty) {
      _showErrorDialog('모든 정보를 입력해주세요.');
      return;
    }

    try {
      final authService = context.read<AuthService>();
      final token = await authService.getAccessToken();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/account/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'bank_code': _getBankCode(_selectedBank!),
          'account_num': _accountController.text,
          'account_holder_name': _accountHolderController.text,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final data = responseData['data'];
          final actualName = data['accountHolderName']; // 실제 예금주명
          final verified = responseData['verified'] == true;

          if (verified) {
            // 이름이 정확히 일치하는 경우
            setState(() {
              _accountVerified = true;
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('계좌 확인이 완료되었습니다'),
                  backgroundColor: AppColors.success500,
                ),
              );
            }
          } else {
            // 이름이 다른 경우 - 실제 예금주명으로 업데이트
            setState(() {
              _accountVerified = true;
              _accountHolderController.text = actualName;
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('예금주명이 "$actualName"으로 확인되었습니다'),
                  backgroundColor: AppColors.success500,
                ),
              );
            }
          }
        } else {
          // API 호출은 성공했지만 계좌 확인 실패
          _showErrorDialog(responseData['message'] ?? '계좌 확인에 실패했습니다');
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('계좌 확인 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.');
      }
    }
  }

  /// 은행명을 은행코드로 변환
  String _getBankCode(String bankName) {
    const bankCodes = {
      '국민은행': '004',
      '신한은행': '088',
      '우리은행': '020',
      '하나은행': '081',
      'KB국민은행': '004',
      '기업은행': '003',
      '농협은행': '011',
      '카카오뱅크': '090',
      '토스뱅크': '092',
      '새마을금고': '045',
      '신협': '048',
      '우체국예금보험': '071',
      '경남은행': '039',
      '광주은행': '034',
      '대구은행': '031',
      '부산은행': '032',
      '수협은행': '007',
      '전북은행': '037',
      '제주은행': '035',
      '산업은행': '002',
      '수출입은행': '008',
      'SC제일은행': '023',
      '씨티은행': '027',
    };
    return bankCodes[bankName] ?? '004';
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          '회원가입 실패',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: primaryBlack,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textGray,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '확인',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message, {VoidCallback? onConfirm}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: primaryBlack,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textGray,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onConfirm != null) {
                onConfirm();
              }
            },
            child: Text(
              '확인',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
