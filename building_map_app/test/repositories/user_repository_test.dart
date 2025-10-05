import 'package:flutter_test/flutter_test.dart';
import 'package:building_map_app/repositories/user_repository.dart';
import 'package:building_map_app/models/user.dart';

void main() {
  group('UserRepository', () {
    test('사용자 저장 및 불러오기', () async {
      final testUser = User(
        id: 'test_id',
        email: 'test@example.com',
        name: 'Test User',
        mode: UserMode.guest,
        provider: AuthProvider.email,
      );

      // 저장
      await UserRepository.saveUser(testUser);

      // 불러오기
      final loadedUser = await UserRepository.loadUser();

      expect(loadedUser, isNotNull);
      expect(loadedUser?.id, equals(testUser.id));
      expect(loadedUser?.email, equals(testUser.email));
      expect(loadedUser?.name, equals(testUser.name));
      expect(loadedUser?.mode, equals(testUser.mode));

      // 정리
      await UserRepository.clearUser();
    });

    test('사용자 모드 업데이트', () async {
      final testUser = User(
        id: 'test_id',
        email: 'test@example.com',
        name: 'Test User',
        mode: UserMode.guest,
        provider: AuthProvider.email,
      );

      await UserRepository.saveUser(testUser);
      await UserRepository.updateUserMode(UserMode.host);

      final mode = await UserRepository.getUserMode();
      expect(mode, equals(UserMode.host));

      // 정리
      await UserRepository.clearUser();
    });

    test('사용자 삭제', () async {
      final testUser = User(
        id: 'test_id',
        email: 'test@example.com',
        name: 'Test User',
        mode: UserMode.guest,
        provider: AuthProvider.email,
      );

      await UserRepository.saveUser(testUser);
      await UserRepository.clearUser();

      final loadedUser = await UserRepository.loadUser();
      expect(loadedUser, isNull);
    });
  });
}
