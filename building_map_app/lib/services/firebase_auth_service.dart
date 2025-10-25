import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'token_service.dart';
import '../config/api_config.dart';

/// Firebase 인증 서비스
/// 백엔드에서 Custom Token을 발급받아 Firebase Authentication 로그인
class FirebaseAuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final ApiClient _apiClient = ApiClient();

  /// 현재 Firebase 사용자
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  /// Firebase 인증 상태 스트림
  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  /// Firebase Custom Token 발급 및 로그인
  ///
  /// 백엔드 API에서 Custom Token을 받아서 Firebase에 로그인합니다.
  /// 이 토큰은 Firestore 보안 규칙 적용을 위해 필요합니다.
  Future<firebase_auth.User?> signInWithCustomToken() async {
    try {
      debugPrint('🔐 [FIREBASE_AUTH] Custom Token 발급 요청 중...');

      // 1. 액세스 토큰 가져오기
      final accessToken = await TokenService.getValidAccessToken(autoRefresh: true);
      if (accessToken == null) {
        throw Exception('액세스 토큰이 없습니다. 먼저 로그인하세요.');
      }

      // 2. 백엔드에서 Firebase Custom Token 발급 (Authorization 헤더 포함)
      final url = Uri.parse('${ApiConfig.baseUrl}/api/chats/custom-token');
      final httpResponse = await _apiClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (httpResponse == null) {
        throw Exception('서버 응답이 없습니다');
      }

      final response = jsonDecode(httpResponse.body);

      if (!response['success']) {
        throw Exception(response['message'] ?? 'Custom Token 발급 실패');
      }

      final customToken = response['data']['customToken'] as String;
      final uid = response['data']['uid'].toString();

      debugPrint('✅ [FIREBASE_AUTH] Custom Token 발급 성공: UID=$uid');

      // 3. Custom Token으로 Firebase Authentication 로그인
      final userCredential =
          await _firebaseAuth.signInWithCustomToken(customToken);

      debugPrint(
          '✅ [FIREBASE_AUTH] Firebase 로그인 성공: ${userCredential.user?.uid}');

      return userCredential.user;
    } catch (e) {
      debugPrint('❌ [FIREBASE_AUTH] Firebase 로그인 실패: $e');
      rethrow;
    }
  }

  /// Firebase 로그아웃
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      debugPrint('✅ [FIREBASE_AUTH] Firebase 로그아웃 완료');
    } catch (e) {
      debugPrint('❌ [FIREBASE_AUTH] Firebase 로그아웃 실패: $e');
      rethrow;
    }
  }

  /// 현재 로그인 상태 확인
  bool get isSignedIn => currentUser != null;

  /// Firebase 인증 확인 및 필요시 재로그인
  Future<void> ensureAuthenticated() async {
    if (!isSignedIn) {
      debugPrint('⚠️ [FIREBASE_AUTH] Firebase 미인증 상태 - 재로그인 시도');
      await signInWithCustomToken();
    } else {
      debugPrint(
          '✅ [FIREBASE_AUTH] Firebase 인증 상태 확인: ${currentUser?.uid}');
    }
  }

  /// 현재 사용자 UID 가져오기
  String? get currentUserUid => currentUser?.uid;
}
