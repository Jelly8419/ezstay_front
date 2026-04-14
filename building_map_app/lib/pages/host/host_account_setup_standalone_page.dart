import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../auth/steps/host_account_step.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

/// 게스트→호스트 전환 전용 페이지
/// 회원가입 플로우와 동일한 UI 스타일 (진행 바 제외)
class HostAccountSetupStandalonePage extends StatelessWidget {
  const HostAccountSetupStandalonePage({super.key});

  // 색상 정의 (register_flow_page.dart와 동일)
  static const primaryBlack = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryBlack),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          '임대인 전환',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: primaryBlack,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.only(
              top: 20,
              left: 24,
              right: 24,
              bottom: 40,
            ),
            child: HostAccountStep(
              isStandaloneMode: true, // Standalone 모드 활성화
              onNext: ({
                required String bankCode,
                required String accountNum,
                required String accountHolderName,
                required bool agreeTerms,
                required bool agreeMarketing,
              }) async {
                // 계좌 등록 완료 → 사용자 정보 새로고침 → 호스트 모드 전환 → 호스트 홈
                final authService = context.read<AuthService>();

                // 1. 사용자 정보 새로고침 (hasBank: true로 업데이트)
                await authService.tryAutoLogin();

                // 2. 호스트 모드로 전환
                await authService.switchUserMode(UserMode.host);

                // 3. 호스트 홈으로 이동
                if (context.mounted) {
                  context.go('/host');
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
