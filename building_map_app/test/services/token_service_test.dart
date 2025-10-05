import 'package:flutter_test/flutter_test.dart';
import 'package:building_map_app/services/token_service.dart';

void main() {
  group('TokenService', () {
    test('JWT 토큰 만료 여부 확인', () {
      // 만료된 토큰 (exp: 2020-01-01)
      const expiredToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiZXhwIjoxNTc3ODM2ODAwfQ.4Qw-W8iJt8u5eF7Y2RzQ6Q';

      expect(TokenService.isTokenExpired(expiredToken), isTrue);
    });

    test('유효하지 않은 JWT 형식 감지', () {
      const invalidToken = 'invalid.token.format';

      expect(TokenService.isTokenExpired(invalidToken), isTrue);
    });

    test('빈 토큰 감지', () {
      const emptyToken = '';

      expect(TokenService.isTokenExpired(emptyToken), isTrue);
    });
  });
}
