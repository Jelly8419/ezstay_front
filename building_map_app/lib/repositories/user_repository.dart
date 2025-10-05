import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../config/api_config.dart';

/// 사용자 정보 저장소
class UserRepository {
  static const _storage = FlutterSecureStorage();

  /// 사용자 정보 저장
  static Future<void> saveUser(User user) async {
    if (!ApiConfig.isProduction) {
      debugPrint('💾 [USER_REPO] 사용자 정보 저장 중...');
    }

    await _storage.write(key: 'user_id', value: user.id);
    await _storage.write(key: 'user_email', value: user.email);
    await _storage.write(key: 'user_name', value: user.name);
    await _storage.write(key: 'user_mode', value: user.mode.name);
    await _storage.write(key: 'user_provider', value: user.provider.name);

    if (user.profileImageUrl != null) {
      await _storage.write(key: 'user_profile_image', value: user.profileImageUrl);
    }

    if (!ApiConfig.isProduction) {
      debugPrint('✅ [USER_REPO] 사용자 정보 저장 완료');
    }
  }

  /// 저장된 사용자 정보 불러오기
  static Future<User?> loadUser() async {
    if (!ApiConfig.isProduction) {
      debugPrint('🔍 [USER_REPO] 사용자 정보 불러오기 시도...');
    }

    final id = await _storage.read(key: 'user_id');
    final email = await _storage.read(key: 'user_email');
    final name = await _storage.read(key: 'user_name');
    final modeStr = await _storage.read(key: 'user_mode');
    final providerStr = await _storage.read(key: 'user_provider');
    final profileImageUrl = await _storage.read(key: 'user_profile_image');

    if (id == null || email == null || name == null || modeStr == null || providerStr == null) {
      if (!ApiConfig.isProduction) {
        debugPrint('⚠️ [USER_REPO] 저장된 사용자 정보 없음');
      }
      return null;
    }

    final user = User(
      id: id,
      email: email,
      name: name,
      mode: UserMode.values.firstWhere(
        (m) => m.name == modeStr,
        orElse: () => UserMode.guest,
      ),
      provider: AuthProvider.values.firstWhere(
        (p) => p.name == providerStr,
        orElse: () => AuthProvider.email,
      ),
      profileImageUrl: profileImageUrl,
    );

    if (!ApiConfig.isProduction) {
      debugPrint('✅ [USER_REPO] 사용자 정보 불러오기 성공: ${user.email}');
    }

    return user;
  }

  /// 사용자 정보 삭제
  static Future<void> clearUser() async {
    if (!ApiConfig.isProduction) {
      debugPrint('🗑️ [USER_REPO] 사용자 정보 삭제 중...');
    }

    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_name');
    await _storage.delete(key: 'user_mode');
    await _storage.delete(key: 'user_provider');
    await _storage.delete(key: 'user_profile_image');

    if (!ApiConfig.isProduction) {
      debugPrint('✅ [USER_REPO] 사용자 정보 삭제 완료');
    }
  }

  /// 사용자 모드 업데이트
  static Future<void> updateUserMode(UserMode mode) async {
    await _storage.write(key: 'user_mode', value: mode.name);

    if (!ApiConfig.isProduction) {
      debugPrint('✅ [USER_REPO] 사용자 모드 업데이트: ${mode.name}');
    }
  }

  /// 사용자 프로필 이미지 업데이트
  static Future<void> updateProfileImage(String? imageUrl) async {
    if (imageUrl != null) {
      await _storage.write(key: 'user_profile_image', value: imageUrl);
    } else {
      await _storage.delete(key: 'user_profile_image');
    }

    if (!ApiConfig.isProduction) {
      debugPrint('✅ [USER_REPO] 프로필 이미지 업데이트');
    }
  }

  /// 사용자 이름 업데이트
  static Future<void> updateUserName(String name) async {
    await _storage.write(key: 'user_name', value: name);

    if (!ApiConfig.isProduction) {
      debugPrint('✅ [USER_REPO] 사용자 이름 업데이트: $name');
    }
  }

  /// 사용자 ID 가져오기
  static Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  /// 사용자 이메일 가져오기
  static Future<String?> getUserEmail() async {
    return await _storage.read(key: 'user_email');
  }

  /// 사용자 모드 가져오기
  static Future<UserMode?> getUserMode() async {
    final modeStr = await _storage.read(key: 'user_mode');
    if (modeStr == null) return null;

    return UserMode.values.firstWhere(
      (m) => m.name == modeStr,
      orElse: () => UserMode.guest,
    );
  }
}
