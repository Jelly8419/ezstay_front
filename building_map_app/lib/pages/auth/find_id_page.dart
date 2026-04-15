import 'package:building_map_app/core/utils/app_logger.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../services/kmc_service.dart';
import '../../services/verification_service.dart';
import '../../widgets/kmc_webview.dart';

/// 아이디 찾기 페이지
///
/// 플로우: KMC 본인인증 → DI로 이메일 조회 → 이메일 표시 → 로그인 이동
class FindIdPage extends StatefulWidget {
  const FindIdPage({super.key});

  @override
  State<FindIdPage> createState() => _FindIdPageState();
}

class _FindIdPageState extends State<FindIdPage> {
  // 단계: 0=본인인증 대기, 1=결과 표시
  int _step = 0;
  bool _isLoading = false;
  String? _foundEmail;

  static const _primaryBlack = Color(0xFF000000);
  static const _textGray = Color(0xFF666666);
  static const _borderGray = Color(0xFFE0E0E0);
  static const _backgroundWhite = Color(0xFFFFFFFF);

  /// KMC 본인인증 실행 → certNum 수신 → /find-id API 호출
  Future<void> _handleKmcVerification() async {
    setState(() => _isLoading = true);

    try {
      // 1. KMC 인증 요청 데이터 생성
      final requestResult = await KmcService.requestVerification();

      if (!mounted) return;

      // 2. KMC 팝업 열기
      final popupResult = await KmcWebViewHelper.openKmcVerification(
        context: context,
        requestResult: requestResult,
      );

      if (!mounted) return;

      if (popupResult == null) {
        // 사용자가 팝업 취소
        return;
      }

      // 3. KMC 결과 검증 → certNum 수신
      final verifyResult = await KmcService.verifyResult(
        apiToken: popupResult['apiToken']!,
        certNum: popupResult['certNum']!,
        purpose: 'find_id',
      );

      if (!mounted) return;

      // 4. certNum으로 아이디(이메일) 조회
      final email = await VerificationService.findId(certNum: verifyResult.certNum);

      if (!mounted) return;

      setState(() {
        _foundEmail = email;
        _step = 1;
      });
    } on KmcException catch (e) {
      if (mounted) _showErrorDialog(KmcService.getErrorMessage(e.code));
    } on VerificationException catch (e) {
      if (mounted) _showErrorDialog(e.message);
    } catch (e) {
      AppLogger.e('❌ [FIND_ID] 오류: $e');
      if (mounted) _showErrorDialog('아이디 찾기 중 오류가 발생했습니다.');
    } finally {
      // 어떤 경로로 종료되든 _isLoading 복구 보장
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 로컬 dev-verify (개발 환경 전용)
  Future<void> _handleDevVerification() async {
    setState(() => _isLoading = true);

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
        final certNum = result['certNum']?.toString() ?? '';
        final email = await VerificationService.findId(certNum: certNum);
        if (mounted) {
          setState(() {
            _foundEmail = email;
            _step = 1;
          });
        }
      } else {
        final message = data['message']?.toString() ?? 'dev-verify 호출 실패';
        if (mounted) _showErrorDialog(message);
      }
    } on VerificationException catch (e) {
      if (mounted) _showErrorDialog(e.message);
    } catch (e) {
      AppLogger.e('❌ [FIND_ID] dev-verify 에러: $e');
      if (mounted) _showErrorDialog('테스트 인증 중 오류가 발생했습니다');
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          '오류',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _primaryBlack,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, color: _textGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundWhite,
      appBar: AppBar(
        backgroundColor: _backgroundWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primaryBlack),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '아이디 찾기',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _primaryBlack,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: _step == 0 ? _buildVerifyStep() : _buildResultStep(),
          ),
        ),
      ),
    );
  }

  /// Step 0: 본인인증 안내 + 버튼
  Widget _buildVerifyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '본인인증으로\n아이디를 찾아드립니다',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _primaryBlack,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '가입 시 등록한 휴대폰으로 본인인증을 진행해주세요',
          style: TextStyle(fontSize: 16, color: _textGray),
        ),
        const SizedBox(height: 48),

        // 본인인증 안내 박스
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderGray),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFF666666)),
                  SizedBox(width: 6),
                  Text(
                    '본인인증 안내',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF444444),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '• 휴대폰 본인인증이 진행됩니다\n• 가입 시 등록한 번호와 동일해야 합니다',
                style: TextStyle(fontSize: 13, color: _textGray, height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleKmcVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              foregroundColor: _backgroundWhite,
              disabledBackgroundColor: _borderGray,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_backgroundWhite),
                    ),
                  )
                : const Text(
                    '본인인증 시작',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
          ),
        ),
        if (!ApiConfig.isProduction) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _isLoading ? null : _handleDevVerification,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF888888),
                side: const BorderSide(color: Color(0xFFCCCCCC)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('[Dev] 테스트 인증', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ],
    );
  }

  /// Step 1: 이메일 결과 표시
  Widget _buildResultStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '아이디 찾기 완료',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _primaryBlack,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '본인인증으로 확인된 계정 정보입니다',
          style: TextStyle(fontSize: 16, color: _textGray),
        ),
        const SizedBox(height: 40),

        // 이메일 표시 박스
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary600.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 40, color: AppColors.primary600),
              const SizedBox(height: 12),
              const Text(
                '가입된 이메일 주소',
                style: TextStyle(fontSize: 13, color: _textGray),
              ),
              const SizedBox(height: 6),
              Text(
                _foundEmail ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _primaryBlack,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // 로그인으로 이동
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              foregroundColor: _backgroundWhite,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '로그인하기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 비밀번호 찾기 이동
        SizedBox(
          height: 56,
          child: OutlinedButton(
            onPressed: () => context.push('/reset-password'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryBlack,
              side: const BorderSide(color: _borderGray, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '비밀번호 찾기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }
}
