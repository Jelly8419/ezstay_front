import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:html' as html show window;
import '../models/user.dart';
import '../config/api_config.dart';

/// 사용자 정보 저장소
class UserRepository {
  static const _storage = FlutterSecureStorage();

  /// 웹에서는 localStorage, 네이티브에서는 secure storage 사용
  /// 웹에서는 flutter_secure_storage와 호환되도록 'flutter.' 접두사 추가
  static String _getWebKey(String key) {
    return 'flutter.$key';
  }

  static Future<void> _writeSecure(String key, String value) async {
    if (kIsWeb) {
      html.window.localStorage[_getWebKey(key)] = value;
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  static Future<String?> _readSecure(String key) async {
    if (kIsWeb) {
      return html.window.localStorage[_getWebKey(key)];
    } else {
      return await _storage.read(key: key);
    }
  }

  static Future<void> _deleteSecure(String key) async {
    if (kIsWeb) {
      html.window.localStorage.remove(_getWebKey(key));
    } else {
      await _storage.delete(key: key);
    }
  }

  /// 사용자 정보 저장
  static Future<void> saveUser(User user) async {
    if (!ApiConfig.isProduction) {
      debugPrint('💾 [USER_REPO] 사용자 정보 저장 중...');
    }

    await _writeSecure('user_id', user.id);
    await _writeSecure('user_email', user.email);
    await _writeSecure('user_name', user.name);
    await _writeSecure('user_mode', user.mode.name);
    await _writeSecure('user_provider', user.provider.name);

    if (user.profileImageUrl != null) {
      await _writeSecure('user_profile_image', user.profileImageUrl!);
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

    final id = await _readSecure('user_id');
    final email = await _readSecure('user_email');
    final name = await _readSecure('user_name');
    final modeStr = await _readSecure('user_mode');
    final providerStr = await _readSecure('user_provider');
    final profileImageUrl = await _readSecure('user_profile_image');

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

    await _deleteSecure('user_id');
    await _deleteSecure('user_email');
    await _deleteSecure('user_name');
    await _deleteSecure('user_mode');
    await _deleteSecure('user_provider');
    await _deleteSecure('user_profile_image');

    if (!ApiConfig.isProduction) {
      debugPrint('✅ [USER_REPO] 사용자 정보 삭제 완료');
    }
  }

  /// 사용자 모드 업데이트
  static Future<void> updateUserMode(UserMode mode) async {
    await _writeSecure('user_mode', mode.name);

    if (!ApiConfig.isProduction) {
      debugPrint('✅ [USER_REPO] 사용자 모드 업데이트: ${mode.name}');
    }
  }

  /// 사용자 프로필 이미지 업데이트
  static Future<void> updateProfileImage(String? imageUrl) async {
    if (imageUrl != null) {
      await _writeSecure('user_profile_image', imageUrl);
    } else {
      await _deleteSecure('user_profile_image');
    }

    if (!ApiConfig.isProduction) {
      debugPrint('✅ [USER_REPO] 프로필 이미지 업데이트');
    }
  }

  /// 사용자 이름 업데이트
  static Future<void> updateUserName(String name) async {
    await _writeSecure('user_name', name);

    if (!ApiConfig.isProduction) {
      debugPrint('✅ [USER_REPO] 사용자 이름 업데이트: $name');
    }
  }

  /// 사용자 ID 가져오기
  static Future<String?> getUserId() async {
    return await _readSecure('user_id');
  }

  /// 사용자 이메일 가져오기
  static Future<String?> getUserEmail() async {
    return await _readSecure('user_email');
  }

  /// 사용자 모드 가져오기
  static Future<UserMode?> getUserMode() async {
    final modeStr = await _readSecure('user_mode');
    if (modeStr == null) return null;

    return UserMode.values.firstWhere(
      (m) => m.name == modeStr,
      orElse: () => UserMode.guest,
    );
  }
}
