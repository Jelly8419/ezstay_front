/// 토큰 없음, 만료, 위조 등 인증 실패 시 throw
/// 서비스 레이어에서 throw → 페이지 레이어에서 on UnauthorizedException 처리
class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([this.message = '인증이 만료되었습니다. 다시 로그인해주세요.']);

  @override
  String toString() => message;
}
