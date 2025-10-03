import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:html' as html;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../config/kakao_config.dart';

/// 인증 서비스 클래스
class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false; // 초기화 완료 여부
  static const _storage = FlutterSecureStorage();

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized; // 초기화 완료 여부 getter

  /// 로그인 상태 변경
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 이메일 로그인
  Future<bool> loginWithEmail(String email, String password, UserMode? mode) async {
    debugPrint('🚀 [LOGIN] 로그인 시작 - Email: $email, Mode: ${mode?.name ?? 'null'}');
    _setLoading(true);

    try {
      // 백엔드 로그인 API 호출
      const String backendUrl = 'http://localhost:8080/api/auth/login';

      final requestBody = json.encode({
        'email': email,
        'password': password,
        if (mode != null) 'user_mode': mode.name, // mode가 null이 아닐 때만 포함
      });

      debugPrint('🌐 [LOGIN] 백엔드 요청 시작 - URL: $backendUrl');
      debugPrint('📦 [LOGIN] 요청 데이터: $requestBody');

      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 [LOGIN] 백엔드 응답 받음 - Status: ${response.statusCode}');
      debugPrint('📄 [LOGIN] 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ [LOGIN] 로그인 성공');
        debugPrint('📦 [LOGIN] 응답 데이터 구조: ${data.keys}');
        debugPrint('📦 [LOGIN] 전체 응답: $data');

        // JWT 토큰 저장 - 다양한 응답 구조 처리
        String? accessToken;
        String? refreshToken;

        // 응답 구조 확인 및 토큰 추출
        if (data['data'] != null && data['data']['accessToken'] != null) {
          // { success: true, data: { accessToken, refreshToken, user } } 구조
          accessToken = data['data']['accessToken'];
          refreshToken = data['data']['refreshToken'];
          debugPrint('🔑 [LOGIN] 토큰 위치: data 객체 내부');
        } else if (data['accessToken'] != null) {
          // { accessToken, refreshToken, user } 구조
          accessToken = data['accessToken'];
          refreshToken = data['refreshToken'];
          debugPrint('🔑 [LOGIN] 토큰 위치: 최상위');
        }

        if (accessToken != null) {
          debugPrint('🔑 [LOGIN] Access Token 발견: ${accessToken.substring(0, 20)}...');
          await _saveTokens(accessToken, refreshToken);

          // 사용자 정보 추출
          Map<String, dynamic>? userInfo;
          if (data['data'] != null && data['data']['user'] != null) {
            userInfo = data['data']['user'];
            debugPrint('👤 [LOGIN] 사용자 정보 위치: data.user');
          } else if (data['user'] != null) {
            userInfo = data['user'];
            debugPrint('👤 [LOGIN] 사용자 정보 위치: user');
          }

          // 사용자 정보 설정
          if (userInfo != null) {
            final userMode = userInfo['mode'] ?? userInfo['userMode'];
            _currentUser = User(
              id: userInfo['id'].toString(),
              email: email,
              name: userInfo['name'] ?? email.split('@')[0],
              mode: UserMode.values.firstWhere(
                (m) => m.name == userMode,
                orElse: () => mode ?? UserMode.guest,
              ),
              provider: AuthProvider.email,
            );
          } else {
            // 사용자 정보가 없는 경우 기본값 설정
            _currentUser = User(
              id: 'user_${DateTime.now().millisecondsSinceEpoch}',
              email: email,
              name: email.split('@')[0],
              mode: mode ?? UserMode.guest,
              provider: AuthProvider.email,
            );
          }

          // 사용자 정보도 저장
          await _saveUserInfo(_currentUser!);
          debugPrint('✅ [LOGIN] 토큰 및 사용자 정보 저장 완료');
        } else {
          // 토큰이 없으면 기본 사용자 정보만 설정
          _currentUser = User(
            id: 'user_${DateTime.now().millisecondsSinceEpoch}',
            email: email,
            name: email.split('@')[0],
            mode: mode ?? UserMode.guest, // null일 때 기본값 사용
            provider: AuthProvider.email,
          );

          // 사용자 정보 저장
          await _saveUserInfo(_currentUser!);
        }

        _setLoading(false);
        return true;
      } else if (response.statusCode == 401) {
        debugPrint('로그인 실패: 이메일 또는 비밀번호가 잘못되었습니다');
        _setLoading(false);
        return false;
      } else {
        debugPrint('로그인 실패: ${response.statusCode} - ${response.body}');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      debugPrint('❌ [LOGIN] 로그인 에러 발생: $e');
      debugPrint('⚠️ [LOGIN] 백엔드 연결 실패 - 시뮬레이션 모드로 전환');
      // 백엔드 연결 실패 시 시뮬레이션으로 처리 (개발 환경)
      await Future.delayed(const Duration(seconds: 1));

      _currentUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: email.split('@')[0],
        mode: mode ?? UserMode.guest,
        provider: AuthProvider.email,
      );

      // 사용자 정보 저장
      await _saveUserInfo(_currentUser!);

      _setLoading(false);
      return true;
    }
  }

  /// 구글 로그인
  Future<bool> loginWithGoogle(UserMode? mode) async {
    _setLoading(true);

    try {
      // TODO: Google Sign-In 구현
      await Future.delayed(const Duration(seconds: 2)); // 시뮬레이션

      _currentUser = User(
        id: 'google_${DateTime.now().millisecondsSinceEpoch}',
        email: 'user@gmail.com',
        name: 'Google User',
        profileImageUrl: 'https://example.com/profile.jpg',
        mode: mode ?? UserMode.guest,
        provider: AuthProvider.google,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  /// 카카오 로그인
  Future<bool> loginWithKakao(UserMode? mode) async {
    debugPrint('🚀 [KAKAO] 로그인 시작');
    debugPrint('🔧 [KAKAO] API 키: ${KakaoConfig.restApiKey}');
    debugPrint('🔧 [KAKAO] Redirect URL: ${KakaoConfig.redirectUrl}');
    debugPrint('🔧 [KAKAO] Auth URL: ${KakaoConfig.authUrl}');
    _setLoading(true);

    try {
      if (kIsWeb) {
        // 웹에서는 브라우저에서 직접 OAuth URL 열기
        debugPrint('웹 환경: 브라우저에서 카카오 로그인 페이지 열기');
        html.window.location.href = KakaoConfig.authUrl;
        // 웹에서는 리다이렉트로 처리되므로 여기서는 false 반환
        _setLoading(false);
        return false;
      } else {
        // 모바일에서는 기존 Flutter SDK 사용
        return await _loginWithKakaoMobile(mode);
      }
    } catch (error) {
      debugPrint('카카오 로그인 에러: $error');
      _setLoading(false);
      return false;
    }
  }

  /// 모바일 환경 카카오 로그인
  Future<bool> _loginWithKakaoMobile(UserMode? mode) async {
    try {
      // 1. 카카오 로그인 시도
      kakao.OAuthToken? token;

      // 카카오톡 앱이 설치되어 있는지 확인
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          // 카카오톡으로 로그인
          token = await kakao.UserApi.instance.loginWithKakaoTalk();
          debugPrint('카카오톡으로 로그인 성공');
        } catch (error) {
          debugPrint('카카오톡으로 로그인 실패 $error');

          // 사용자가 카카오톡 설치 후 디바이스 권한 요청 화면에서 로그인을 취소한 경우,
          // 의도적인 로그인 취소로 보고 카카오계정으로 로그인 시도 없이 로그인 취소로 처리 (예: 뒤로 가기)
          if (error is PlatformException && error.code == 'CANCELED') {
            _setLoading(false);
            return false;
          }
          // 카카오톡에 연결된 카카오계정이 없는 경우, 카카오계정으로 로그인
          try {
            token = await kakao.UserApi.instance.loginWithKakaoAccount();
            debugPrint('카카오계정으로 로그인 성공');
          } catch (error) {
            debugPrint('카카오계정으로 로그인 실패 $error');
            _setLoading(false);
            return false;
          }
        }
      } else {
        try {
          // 카카오계정으로 로그인
          token = await kakao.UserApi.instance.loginWithKakaoAccount();
          debugPrint('카카오계정으로 로그인 성공');
        } catch (error) {
          debugPrint('카카오계정으로 로그인 실패 $error');
          _setLoading(false);
          return false;
        }
      }

      // 2. 사용자 정보 가져오기
      final kakaoUser = await kakao.UserApi.instance.me();

      debugPrint('카카오 사용자 정보: ${kakaoUser.toString()}');

      // 3. 백엔드에 토큰 전송 및 인증 처리
      final success = await _authenticateWithBackend(token, kakaoUser, mode);

      if (success) {
        // 4. 로컬 사용자 정보 설정
        _currentUser = User(
          id: kakaoUser.id.toString(),
          email: kakaoUser.kakaoAccount?.email ?? 'user@kakao.com',
          name: kakaoUser.kakaoAccount?.profile?.nickname ?? '카카오 사용자',
          profileImageUrl: kakaoUser.kakaoAccount?.profile?.profileImageUrl,
          mode: mode ?? UserMode.guest,
          provider: AuthProvider.kakao,
        );

        _setLoading(false);
        return true;
      } else {
        _setLoading(false);
        return false;
      }
    } catch (error) {
      debugPrint('모바일 카카오 로그인 에러: $error');
      _setLoading(false);
      return false;
    }
  }

  /// 백엔드와 카카오 토큰 인증 처리
  Future<bool> _authenticateWithBackend(kakao.OAuthToken token, kakao.User kakaoUser, UserMode? mode) async {
    try {
      // 백엔드 API 엔드포인트 (실제 백엔드 URL로 변경 필요)
      const String backendUrl = 'http://localhost:8080/auth/kakao';

      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'access_token': token.accessToken,
          'refresh_token': token.refreshToken,
          'user_mode': mode?.name ?? 'guest',
          'kakao_user_id': kakaoUser.id,
          'email': kakaoUser.kakaoAccount?.email,
          'nickname': kakaoUser.kakaoAccount?.profile?.nickname,
          'profile_image': kakaoUser.kakaoAccount?.profile?.profileImageUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('백엔드 인증 성공: $data');

        // JWT 토큰 저장 등 추가 처리
        if (data['accessToken'] != null && data['refreshToken'] != null) {
          await _saveTokens(data['accessToken'], data['refreshToken']);
        }

        return true;
      } else {
        debugPrint('백엔드 인증 실패: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('백엔드 인증 에러: $e');
      // 백엔드 연결 실패해도 로그인은 성공으로 처리 (개발 환경)
      return true;
    }
  }

  /// 토큰 저장
  Future<void> _saveTokens(String accessToken, String? refreshToken) async {
    debugPrint('💾 [TOKEN] 토큰 저장 시작...');
    debugPrint('💾 [TOKEN] Access Token 길이: ${accessToken.length}');
    debugPrint('💾 [TOKEN] Access Token 미리보기: ${accessToken.substring(0, accessToken.length > 50 ? 50 : accessToken.length)}...');

    await _storage.write(key: 'access_token', value: accessToken);
    debugPrint('✅ [TOKEN] Access Token 저장 완료');

    if (refreshToken != null) {
      debugPrint('💾 [TOKEN] Refresh Token 길이: ${refreshToken.length}');
      await _storage.write(key: 'refresh_token', value: refreshToken);
      debugPrint('✅ [TOKEN] Refresh Token 저장 완료');
    }

    // 저장 확인
    final savedAccessToken = await _storage.read(key: 'access_token');
    final savedRefreshToken = await _storage.read(key: 'refresh_token');
    debugPrint('🔍 [TOKEN] 저장 확인 - Access: ${savedAccessToken != null ? "OK" : "FAIL"}');
    debugPrint('🔍 [TOKEN] 저장 확인 - Refresh: ${savedRefreshToken != null ? "OK" : "FAIL"}');
  }

  /// 사용자 정보 저장
  Future<void> _saveUserInfo(User user) async {
    await _storage.write(key: 'user_id', value: user.id);
    await _storage.write(key: 'user_email', value: user.email);
    await _storage.write(key: 'user_name', value: user.name);
    await _storage.write(key: 'user_mode', value: user.mode.name);
    await _storage.write(key: 'user_provider', value: user.provider.name);
    if (user.profileImageUrl != null) {
      await _storage.write(key: 'user_profile_image', value: user.profileImageUrl);
    }
    debugPrint('사용자 정보 저장 완료');
  }

  /// 저장된 사용자 정보 불러오기
  Future<User?> _loadUserInfo() async {
    final id = await _storage.read(key: 'user_id');
    final email = await _storage.read(key: 'user_email');
    final name = await _storage.read(key: 'user_name');
    final modeStr = await _storage.read(key: 'user_mode');
    final providerStr = await _storage.read(key: 'user_provider');
    final profileImageUrl = await _storage.read(key: 'user_profile_image');

    if (id == null || email == null || name == null || modeStr == null || providerStr == null) {
      return null;
    }

    return User(
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
  }

  /// 저장된 토큰 불러오기
  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  /// 저장된 리프레시 토큰 불러오기
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  /// 웹에서 카카오 로그인 콜백 처리 (JWT 토큰 기반)
  Future<bool> handleKakaoWebCallback() async {
    if (!kIsWeb) return false;

    try {
      final uri = Uri.parse(html.window.location.href);
      debugPrint('🔍 [CALLBACK] 현재 URL: ${uri.toString()}');
      debugPrint('🔍 [CALLBACK] 경로: ${uri.path}');
      debugPrint('🔍 [CALLBACK] 쿼리 파라미터: ${uri.queryParameters}');

      // /auth/callback 경로 체크
      if (uri.path == '/auth/callback') {
        // 에러 파라미터 체크
        final errorParam = uri.queryParameters['error'];
        if (errorParam != null) {
          debugPrint('❌ 카카오 로그인 에러: $errorParam');
          html.window.history.replaceState({}, '', '/');
          return false;
        }

        // 백엔드에서 전달받은 토큰들 체크
        final accessToken = uri.queryParameters['token'];
        final refreshToken = uri.queryParameters['refresh'];

        if (accessToken != null) {
          debugPrint('🔐 Access Token 발견: ${accessToken.substring(0, 20)}...');
          if (refreshToken != null) {
            debugPrint('🔄 Refresh Token 발견: ${refreshToken.substring(0, 20)}...');
          }

          // 토큰들 저장
          await _saveTokens(accessToken, refreshToken);

          // 토큰으로 사용자 정보 요청
          final success = await _authenticateWithToken(accessToken);

          if (success) {
            // URL에서 파라미터 제거
            html.window.history.replaceState({}, '', '/');
            debugPrint('✅ 카카오 로그인 성공');
            return true;
          } else {
            debugPrint('❌ 사용자 정보 가져오기 실패');
            await _clearTokens();
            html.window.history.replaceState({}, '', '/');
            return false;
          }
        }
      }

      // 카카오 인증 코드 처리 (기존 방식 - 하위 호환성)
      final code = uri.queryParameters['code'];
      if (code != null) {
        debugPrint('🔑 카카오 인증 코드 발견: $code');
        return await _handleKakaoAuthCode(code);
      }

      return false;
    } catch (error) {
      debugPrint('❌ 웹 카카오 콜백 처리 에러: $error');
      html.window.history.replaceState({}, '', '/');
      return false;
    }
  }

  /// JWT 토큰으로 사용자 정보 인증
  Future<bool> _authenticateWithToken(String token) async {
    try {
      // 토큰 기본 검증 (형식 확인)
      if (!_isValidTokenFormat(token)) {
        debugPrint('❌ 토큰 형식이 유효하지 않음');
        return false;
      }

      // 토큰 유효성 검증 및 사용자 정보 요청
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10)); // 타임아웃 설정

      if (response.statusCode == 200) {
        debugPrint('🔍 서버 응답: ${response.body}');
        final data = json.decode(response.body);
        debugPrint('🔍 파싱된 데이터: $data');

        if (data['success'] == true && data['data'] != null && data['data']['user'] != null) {
          final user = data['data']['user'];

          // 사용자 데이터 유효성 검증
          if (!_isValidUserData(user)) {
            debugPrint('❌ 서버에서 받은 사용자 데이터가 유효하지 않음');
            return false;
          }

          // 서버에서 검증된 사용자 정보로 설정
          _currentUser = User(
            id: user['id'].toString(),
            email: user['email'] ?? 'user@kakao.com',
            name: user['name'] ?? '카카오 사용자',
            profileImageUrl: user['profileImageUrl'],
            mode: UserMode.guest, // 기본값, 나중에 사용자가 선택
            provider: AuthProvider.kakao,
          );

          // 검증된 토큰 저장
          await _storage.write(key: 'access_token', value: token);
          if (data['refreshToken'] != null) {
            await _storage.write(key: 'refresh_token', value: data['refreshToken']);
          }

          notifyListeners();
          debugPrint('✅ 서버 검증 완료 - 사용자: ${user['name']}');
          return true;
        } else {
          debugPrint('❌ 서버 응답 데이터 형식 오류');
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ 토큰이 유효하지 않음 (401) - refresh 토큰으로 갱신 시도');

        // Refresh 토큰으로 갱신 시도
        final refreshSuccess = await _refreshAccessToken();
        if (refreshSuccess) {
          // 새로운 액세스 토큰으로 재시도
          final newAccessToken = await getAccessToken();
          if (newAccessToken != null) {
            return await _authenticateWithToken(newAccessToken);
          }
        }

        return false;
      } else if (response.statusCode == 403) {
        debugPrint('❌ 접근 권한 없음 (403)');
      } else {
        debugPrint('❌ 서버 오류: ${response.statusCode} - ${response.body}');
      }

      return false;
    } on TimeoutException {
      debugPrint('❌ 서버 요청 타임아웃');
      return false;
    } on FormatException catch (e) {
      debugPrint('❌ JSON 파싱 오류: $e');
      return false;
    } catch (error) {
      debugPrint('❌ 토큰 인증 에러: $error');
      return false;
    }
  }

  /// JWT 토큰 형식 검증 (기본적인 형식만 확인)
  bool _isValidTokenFormat(String token) {
    // JWT는 일반적으로 header.payload.signature 형태
    final parts = token.split('.');
    return parts.length == 3 &&
           parts.every((part) => part.isNotEmpty) &&
           token.length > 10; // 최소 길이 확인
  }

  /// 사용자 데이터 유효성 검증
  bool _isValidUserData(Map<String, dynamic> user) {
    return user['id'] != null &&
           user['id'].toString().isNotEmpty &&
           user['email'] != null &&
           user['name'] != null;
  }

  /// 카카오 인증 코드 처리 (기존 방식 유지)
  Future<bool> _handleKakaoAuthCode(String code) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/auth/kakao?code=$code'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['token'] != null) {
          // JWT 토큰으로 사용자 정보 재요청
          final success = await _authenticateWithToken(data['token']);

          if (success) {
            html.window.history.replaceState({}, '', '/');
            return true;
          }
        }
      }

      return false;
    } catch (error) {
      debugPrint('❌ 카카오 코드 처리 에러: $error');
      return false;
    }
  }

  /// 앱 시작 시 저장된 토큰으로 자동 로그인 시도
  Future<void> tryAutoLogin() async {
    final accessToken = await getAccessToken();

    if (accessToken != null) {
      // 서버에서 토큰 검증 및 사용자 정보 가져오기
      final success = await _authenticateWithToken(accessToken);

      if (success) {
        _isInitialized = true;
        notifyListeners();
        return;
      } else {
        // 만료된 토큰 제거
        await _clearTokens();
      }
    }

    // 토큰이 없거나 만료된 경우, 저장된 사용자 정보로 복원 시도
    final userInfo = await _loadUserInfo();

    if (userInfo != null) {
      _currentUser = userInfo;
    }

    // 초기화 완료 표시
    _isInitialized = true;
    notifyListeners();
  }

  /// 저장된 토큰 제거
  Future<void> _clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    debugPrint('🗑️ 토큰 삭제 완료');
  }

  /// 저장된 사용자 정보 제거
  Future<void> _clearUserInfo() async {
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_name');
    await _storage.delete(key: 'user_mode');
    await _storage.delete(key: 'user_provider');
    await _storage.delete(key: 'user_profile_image');
    debugPrint('🗑️ 사용자 정보 삭제 완료');
  }

  /// Refresh 토큰으로 Access 토큰 갱신
  Future<bool> _refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        debugPrint('❌ Refresh 토큰이 없음');
        return false;
      }

      debugPrint('🔄 Access 토큰 갱신 시도...');

      final response = await http.post(
        Uri.parse('http://localhost:8080/api/auth/refresh'),
        headers: {
          'Authorization': 'Bearer $refreshToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['accessToken'] != null) {
          // 새로운 토큰들 저장
          await _saveTokens(
            data['accessToken'],
            data['refreshToken'] ?? refreshToken, // 새 refresh token이 없으면 기존 것 유지
          );

          debugPrint('✅ Access 토큰 갱신 성공');
          return true;
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ Refresh 토큰도 만료됨 - 재로그인 필요');
        await _clearTokens();
      } else {
        debugPrint('❌ 토큰 갱신 서버 오류: ${response.statusCode}');
      }

      return false;
    } catch (error) {
      debugPrint('❌ 토큰 갱신 에러: $error');
      return false;
    }
  }

  /// 회원가입 (이메일)
  Future<bool> signUpWithEmail(String email, String password, UserMode mode) async {
    debugPrint('🚀 [SIGNUP] 회원가입 시작 - Email: $email, Mode: ${mode.name}');
    _setLoading(true);

    try {
      // 백엔드 회원가입 API 호출
      const String backendUrl = 'http://localhost:8080/api/auth/register';

      final requestBody = json.encode({
        'email': email,
        'password': password,
        'user_mode': mode.name,
      });

      debugPrint('📦 [SIGNUP] 요청 데이터: $requestBody');

      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        debugPrint('회원가입 성공: $data');
        debugPrint('🔍 [SIGNUP] 백엔드에서 받은 userMode: ${data['data']['user']['userMode']}');

        // 회원가입 성공 시 JWT 토큰이 반환되면 저장
        if (data['data']['accessToken'] != null) {
          await _saveTokens(data['data']['accessToken'], data['data']['refreshToken']);

          // 사용자 정보 설정
          _currentUser = User(
            id: data['data']['user']['id'].toString(),
            email: email,
            name: data['data']['user']['name'] ?? email.split('@')[0],
            mode: UserMode.values.firstWhere(
              (m) => m.name == data['data']['user']['userMode'],
              orElse: () => mode ?? UserMode.guest,
            ),
            provider: AuthProvider.email,
          );

          // 사용자 정보 저장
          await _saveUserInfo(_currentUser!);

          debugPrint('✅ [SIGNUP] 생성된 사용자 모드: ${_currentUser?.mode.name}');
          debugPrint('✅ [SIGNUP] 현재 로그인 상태: $isLoggedIn');
        } else {
          // 토큰이 없으면 기본 사용자 정보만 설정
          _currentUser = User(
            id: 'user_${DateTime.now().millisecondsSinceEpoch}',
            email: email,
            name: email.split('@')[0],
            mode: mode ?? UserMode.guest,
            provider: AuthProvider.email,
          );

          // 사용자 정보 저장
          await _saveUserInfo(_currentUser!);
        }

        _setLoading(false);
        return true;
      } else {
        debugPrint('회원가입 실패: ${response.statusCode} - ${response.body}');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      debugPrint('회원가입 에러: $e');
      // 백엔드 연결 실패 시 시뮬레이션으로 처리 (개발 환경)
      await Future.delayed(const Duration(seconds: 1));

      _currentUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: email.split('@')[0],
        mode: mode ?? UserMode.guest,
        provider: AuthProvider.email,
      );

      // 사용자 정보 저장
      await _saveUserInfo(_currentUser!);

      _setLoading(false);
      return true;
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    try {
      // 서버에 로그아웃 요청 (토큰 무효화)
      final accessToken = await getAccessToken();
      if (accessToken != null) {
        await http.post(
          Uri.parse('http://localhost:8080/api/auth/logout'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        );
      }
    } catch (e) {
      debugPrint('⚠️ 서버 로그아웃 요청 실패: $e');
    }

    // 로컬 상태, 토큰 및 사용자 정보 정리
    _currentUser = null;
    await _clearTokens();
    await _clearUserInfo();
    notifyListeners();
    debugPrint('👋 로그아웃 완료');
  }

  /// 사용자 모드 변경
  void switchUserMode(UserMode newMode) {
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        email: _currentUser!.email,
        name: _currentUser!.name,
        profileImageUrl: _currentUser!.profileImageUrl,
        mode: newMode,
        provider: _currentUser!.provider,
      );
      notifyListeners();
    }
  }
}