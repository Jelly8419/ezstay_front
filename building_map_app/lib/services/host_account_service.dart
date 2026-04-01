import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/exceptions.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../utils/password_validator.dart';
import '../widgets/common/my_page_dialogs.dart';

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

  /// 연락처 변경 안내 (본인인증 SDK 준비 중)
  void handlePhoneChange(BuildContext context) {
    showMyPageInfoDialog(context, '준비 중입니다', '본인인증 기능은 준비 중입니다.');
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
