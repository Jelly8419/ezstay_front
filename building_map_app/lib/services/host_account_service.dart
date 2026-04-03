import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/exceptions.dart';
import '../services/auth_service.dart';
import '../services/kmc_service.dart';
import '../services/user_profile_service.dart';
import '../utils/password_validator.dart';
import '../widgets/common/my_page_dialogs.dart';
import '../widgets/kmc_webview.dart';

/// 호스트 계정 비즈니스 로직 서비스
///
/// 닉네임/비밀번호 변경, 연락처 안내, 탈퇴 처리를
/// [HostMyPage]에서 분리합니다.
class HostAccountService {
  final UserProfileService _userProfileService = UserProfileService();

  /// 닉네임 변경
  ///
  /// 성공 시 새 닉네임 반환. 실패 시 [onError] 호출 후 null 반환.
  Future<String?> changeNickname({
    required BuildContext context,
    required String nickname,
    required void Function(String) onError,
  }) async {
    if (nickname.length < 2 || nickname.length > 20) {
      onError('닉네임은 2~20자로 입력해주세요.');
      return null;
    }

    try {
      final newNickname = await _userProfileService.changeNickname(
        nickname: nickname,
      );
      return newNickname;
    } on UnauthorizedException {
      if (context.mounted) context.go('/login');
      return null;
    } catch (e) {
      onError(e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }

  /// 비밀번호 변경
  ///
  /// 성공 시 true 반환. 실패 시 [onError] 호출 후 false 반환.
  Future<bool> changePassword({
    required BuildContext context,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
    required void Function(String) onError,
  }) async {
    if (newPassword != confirmPassword) {
      onError('새 비밀번호와 비밀번호 확인이 일치하지 않습니다.');
      return false;
    }

    final passwordError = PasswordValidator.validate(newPassword);
    if (passwordError != null) {
      onError(passwordError);
      return false;
    }

    try {
      await _userProfileService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } on UnauthorizedException {
      if (context.mounted) context.go('/login');
      return false;
    } catch (e) {
      onError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  /// 연락처 변경 (KMC 본인인증)
  ///
  /// 인증 성공 시 [onSuccess]에 새 전화번호 전달.
  Future<void> handlePhoneChange(
    BuildContext context, {
    required void Function(String newPhone) onSuccess,
  }) async {
    try {
      final requestResult = await KmcService.requestVerification();
      if (!context.mounted) return;

      final popupResult = await KmcWebViewHelper.openKmcVerification(
        context: context,
        requestResult: requestResult,
      );
      if (!context.mounted || popupResult == null) return;

      final verifyResult = await KmcService.verifyResult(
        apiToken: popupResult['apiToken']!,
        certNum: popupResult['certNum']!,
      );
      if (!context.mounted) return;

      if (verifyResult.verified) {
        onSuccess(verifyResult.phoneNumber);
        showPhoneChangedDialog(context, verifyResult.phoneNumber);
      }
    } on KmcException catch (e) {
      if (context.mounted) {
        showMyPageErrorDialog(context, KmcService.getErrorMessage(e.code));
      }
    } catch (e) {
      if (context.mounted) {
        showMyPageErrorDialog(context, '본인인증 중 오류가 발생했습니다.');
      }
    }
  }

  /// 회원 탈퇴
  ///
  /// 확인 다이얼로그 → 탈퇴 API → 로그아웃 → /login 이동.
  /// 성공 시 true, 취소/실패 시 false 반환.
  Future<bool> withdrawUser({
    required BuildContext context,
    required void Function(String) onError,
  }) async {
    final confirmed = await showWithdrawalConfirmDialog(context);
    if (!confirmed) return false;

    try {
      await _userProfileService.withdrawUser();

      if (context.mounted) {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.logout();

        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      }
      return true;
    } on UnauthorizedException {
      if (context.mounted) context.go('/login');
      return false;
    } catch (e) {
      onError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}
