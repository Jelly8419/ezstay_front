import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:html' as html;
import '../models/user.dart';
import '../config/kakao_config.dart';
import '../config/api_config.dart';
import 'token_service.dart';
import '../repositories/user_repository.dart';

/// 인증 서비스 클래스
class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false; // 초기화 완료 여부

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized; // 초기화 완료 여부 getter

  /// 본인인증이 필요한 상태인지 확인
  bool get needsPhoneVerification => _currentUser != null && !(_currentUser!.phoneVerified);

  /// 로그인 상태 변경
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 개발자 바이패스 로그인 (개발 환경 전용)
  ///
  /// 백엔드의 /api/auth/dev-bypass/:userId 엔드포인트를 호출하여
  /// 비밀번호 없이 특정 사용자로 로그인합니다.
  ///
  /// [userId] 로그인할 사용자 ID
  ///
  /// Returns: 로그인 성공 여부
  Future<bool> loginWithDevBypass(String userId) async {
    if (ApiConfig.isProduction) {
      debugPrint('❌ [DEV_BYPASS] 프로덕션 환경에서는 개발자 바이패스를 사용할 수 없습니다');
      return false;
    }

    debugPrint('🚀 [DEV_BYPASS] 개발자 바이패스 로그인 시작 - User ID: $userId');
    _setLoading(true);

    try {
      final backendUrl = ApiConfig.authDevBypassUrl(userId);
      debugPrint('🌐 [DEV_BYPASS] 요청 URL: $backendUrl');

      final response = await http.get(
        Uri.parse(backendUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(ApiConfig.timeout);

      debugPrint('📡 [DEV_BYPASS] 응답 상태: ${response.statusCode}');
      debugPrint('📄 [DEV_BYPASS] 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ [DEV_BYPASS] 로그인 성공');

        // JWT 토큰 저장
        String? accessToken;
        String? refreshToken;

        if (data['data'] != null && data['data']['accessToken'] != null) {
          accessToken = data['data']['accessToken'];
          refreshToken = data['data']['refreshToken'];
        } else if (data['accessToken'] != null) {
          accessToken = data['accessToken'];
          refreshToken = data['refreshToken'];
        }

        if (accessToken != null) {
          debugPrint('🔑 [DEV_BYPASS] Access Token 저장');
          debugPrint('🔑 [DEV_BYPASS] Access Token 길이: ${accessToken.length}');
          debugPrint('🔑 [DEV_BYPASS] Access Token 앞부분: ${accessToken.substring(0, accessToken.length > 30 ? 30 : accessToken.length)}...');
          await _saveTokens(accessToken, refreshToken);

          // 저장 확인
          final savedToken = await TokenService.getAccessToken(skipExpiryCheck: true);
          debugPrint('🔍 [DEV_BYPASS] 저장 후 토큰 확인: ${savedToken != null ? "성공 (${savedToken.length}자)" : "실패 ⚠️"}');
          if (savedToken != null) {
            debugPrint('🔍 [DEV_BYPASS] 저장된 토큰 앞부분: ${savedToken.substring(0, savedToken.length > 30 ? 30 : savedToken.length)}...');
          }

          // 사용자 정보 추출
          Map<String, dynamic>? userInfo;
          if (data['data'] != null && data['data']['user'] != null) {
            userInfo = data['data']['user'];
          } else if (data['user'] != null) {
            userInfo = data['user'];
          }

          if (userInfo != null) {
            final userMode = userInfo['mode'] ?? userInfo['userMode'];
            _currentUser = User(
              id: userInfo['id'].toString(),
              email: userInfo['email'] ?? 'dev@test.com',
              name: userInfo['name'] ?? 'Dev User',
              nickname: userInfo['nickname'],
              mode: UserMode.values.firstWhere(
                (m) => m.name == userMode,
                orElse: () => UserMode.guest,
              ),
              provider: AuthProvider.email,
              profileImageUrl: userInfo['profileImageUrl'],
              phoneVerified: userInfo['phoneVerified'] ?? true, // bypass 로그인은 기본 true
              hasBank: userInfo['hasBank'] ?? false,
            );

            // 사용자 정보 저장
            await UserRepository.saveUser(_currentUser!);
            debugPrint('✅ [DEV_BYPASS] 사용자 정보 저장 완료');
            debugPrint('👤 [DEV_BYPASS] 사용자: ${_currentUser!.email} (${_currentUser!.mode.name})');
          }
        }

        _setLoading(false);
        return true;
      } else {
        debugPrint('❌ [DEV_BYPASS] 로그인 실패: ${response.statusCode} - ${response.body}');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      debugPrint('❌ [DEV_BYPASS] 로그인 에러: $e');
      _setLoading(false);
      return false;
    }
  }

  /// 이메일 로그인
  Future<bool> loginWithEmail(String email, String password, UserMode? mode) async {
    debugPrint('🚀 [LOGIN] 로그인 시작 - Email: $email, Mode: ${mode?.name ?? 'null'}');
    _setLoading(true);

    try {
      // 백엔드 로그인 API 호출
      final backendUrl = ApiConfig.authLoginUrl;

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
      ).timeout(ApiConfig.timeout);

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
              nickname: userInfo['nickname'],
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
          await UserRepository.saveUser(_currentUser!);
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
          await UserRepository.saveUser(_currentUser!);
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
      await UserRepository.saveUser(_currentUser!);

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
    debugPrint('🔧 [KAKAO] Redirect URL: ${KakaoConfig.redirectUrl}');
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
        // 카카오 로그인 시 카카오 닉네임을 nickname으로 사용
        _currentUser = User(
          id: kakaoUser.id.toString(),
          email: kakaoUser.kakaoAccount?.email ?? 'user@kakao.com',
          name: kakaoUser.kakaoAccount?.profile?.nickname ?? '카카오 사용자',
          nickname: kakaoUser.kakaoAccount?.profile?.nickname,
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
      // 백엔드 API 엔드포인트
      final backendUrl = ApiConfig.authKakaoUrl;

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
        debugPrint('✅ [KAKAO_AUTH] 백엔드 인증 응답: $data');

        // JWT 토큰 저장
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];

        if (accessToken != null && refreshToken != null) {
          debugPrint('🔐 [KAKAO_AUTH] JWT 토큰 저장');
          await _saveTokens(accessToken, refreshToken);
          return true;
        }

        debugPrint('⚠️ [KAKAO_AUTH] 응답에 토큰 정보가 없습니다');
        return false;
      } else {
        debugPrint('❌ [KAKAO_AUTH] 백엔드 인증 실패: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [KAKAO_AUTH] 백엔드 인증 에러: $e');
      return false;
    }
  }

  /// 토큰 저장
  Future<void> _saveTokens(String accessToken, String? refreshToken) async {
    await TokenService.saveTokens(accessToken, refreshToken);
  }


  /// 저장된 토큰 불러오기 (자동 갱신 포함)
  Future<String?> getAccessToken({bool autoRefresh = true}) async {
    if (autoRefresh) {
      return await TokenService.getValidAccessToken(autoRefresh: true);
    } else {
      return await TokenService.getAccessToken();
    }
  }

  /// 저장된 리프레시 토큰 불러오기
  Future<String?> getRefreshToken() async {
    return await TokenService.getRefreshToken();
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

  /// OAuth 콜백에서 전달받은 토큰으로 인증 (라우터에서 호출)
  Future<bool> handleOAuthCallback(String accessToken, String refreshToken) async {
    try {
      debugPrint('✅ [AUTH_CALLBACK] OAuth 콜백 처리 시작');
      debugPrint('🔐 Access Token: ${accessToken.substring(0, 20)}...');
      debugPrint('🔄 Refresh Token: ${refreshToken.substring(0, 20)}...');

      // 토큰들 저장
      await _saveTokens(accessToken, refreshToken);

      // 토큰으로 사용자 정보 요청
      final success = await _authenticateWithToken(accessToken);

      if (success) {
        debugPrint('✅ [AUTH_CALLBACK] 인증 성공');
        return true;
      } else {
        debugPrint('❌ [AUTH_CALLBACK] 사용자 정보 가져오기 실패');
        await _clearTokens();
        return false;
      }
    } catch (error) {
      debugPrint('❌ [AUTH_CALLBACK] 에러: $error');
      await _clearTokens();
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
        Uri.parse(ApiConfig.authProfileUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(ApiConfig.timeout);

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
          String userMode;
          if (user['mode'] != null) {
            userMode = user['mode'];
            debugPrint('🔍 [USER_MODE] user[mode]에서 가져옴: $userMode');
          } else if (user['userMode'] != null) {
            userMode = user['userMode'];
            debugPrint('🔍 [USER_MODE] user[userMode]에서 가져옴: $userMode');
          } else {
            // 백엔드가 userMode를 보내주지 않는 경우: 기본값 guest
            // (hasBank로 추론하면 계좌 등록한 게스트가 호스트로 잘못 인식됨)
            userMode = 'guest';
            debugPrint('⚠️ [USER_MODE] 서버 응답에 userMode 없음 - 기본값 guest로 설정');
            debugPrint('⚠️ [USER_MODE] 백엔드에 userMode 필드 추가 필요! (hasBank=${user['hasBank']})');
          }

          debugPrint('🎯 [USER_MODE] 최종 결정된 userMode: $userMode');
          debugPrint('📊 [USER_MODE] 사용자 정보: phoneVerified=${user['phoneVerified']}, hasBank=${user['hasBank']}');

          _currentUser = User(
            id: user['id'].toString(),
            email: user['email'] ?? 'user@kakao.com',
            name: user['name'] ?? '카카오 사용자',
            nickname: user['nickname'],
            profileImageUrl: user['profileImageUrl'],
            mode: UserMode.values.firstWhere(
              (m) => m.name == userMode,
              orElse: () => UserMode.guest,
            ),
            provider: AuthProvider.kakao,
            phoneVerified: user['phoneVerified'] ?? false,
            hasBank: user['hasBank'] ?? false,
          );

          // 검증된 토큰 저장
          await TokenService.saveTokens(token, data['refreshToken']);

          notifyListeners();
          debugPrint('✅ 서버 검증 완료 - 사용자: ${user['name']} (닉네임: ${user['nickname']})');
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
    return !TokenService.isTokenExpired(token);
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
        Uri.parse('${ApiConfig.authKakaoWebUrl}?code=$code'),
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

  /// 앱 시작 시 저장된 토큰으로 자동 로그인 시도 (Non-Blocking)
  Future<void> tryAutoLogin() async {
    try {
      if (!ApiConfig.isProduction) {
        debugPrint('');
        debugPrint('═══════════════════════════════════════════════');
        debugPrint('🔄 [AUTO_LOGIN] 자동 로그인 프로세스 시작 (백그라운드)');
        debugPrint('═══════════════════════════════════════════════');
      }

      // 자동 갱신 활성화하여 토큰 가져오기
      final accessToken = await getAccessToken(autoRefresh: true);

      if (!ApiConfig.isProduction) {
        debugPrint('📊 [AUTO_LOGIN] Access Token 상태: ${accessToken != null ? "✅ 있음" : "❌ 없음"}');
      }

      if (accessToken != null) {
        // 서버에서 토큰 검증 및 사용자 정보 가져오기
        final success = await _authenticateWithToken(accessToken);

        if (success) {
          if (!ApiConfig.isProduction) {
            debugPrint('✅ [AUTO_LOGIN] 자동 로그인 성공');
          }
          return;
        } else {
          // 토큰 검증 실패 - 토큰 제거
          await _clearTokens();
        }
      }

      // 토큰이 없거나 만료된 경우, 저장된 사용자 정보로 복원 시도
      final userInfo = await UserRepository.loadUser();

      if (userInfo != null) {
        _currentUser = userInfo;
        if (!ApiConfig.isProduction) {
          debugPrint('✅ [AUTO_LOGIN] 저장된 사용자 정보 복원: ${userInfo.email}');
          debugPrint('⚠️ [AUTO_LOGIN] 토큰이 없어 API 호출은 불가능합니다. 다시 로그인이 필요합니다.');
        }
      } else {
        if (!ApiConfig.isProduction) {
          debugPrint('ℹ️ [AUTO_LOGIN] 저장된 사용자 정보 없음');
        }
      }
    } catch (e) {
      debugPrint('❌ [AUTO_LOGIN] 자동 로그인 실패: $e');
    } finally {
      // 🔥 성공/실패 무관하게 초기화 완료 표시 (앱 시작 보장)
      _isInitialized = true;
      notifyListeners();

      if (!ApiConfig.isProduction) {
        debugPrint('✅ [AUTO_LOGIN] 초기화 완료');
      }
    }
  }

  /// 저장된 토큰 제거
  Future<void> _clearTokens() async {
    await TokenService.clearTokens();
  }

  /// 저장된 사용자 정보 제거
  Future<void> _clearUserInfo() async {
    await UserRepository.clearUser();
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
        Uri.parse(ApiConfig.authRefreshUrl),
        headers: {
          'Authorization': 'Bearer $refreshToken',
          'Content-Type': 'application/json',
        },
      ).timeout(ApiConfig.timeout);

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
      final backendUrl = ApiConfig.authRegisterUrl;

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
      ).timeout(ApiConfig.timeout);

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
            nickname: data['data']['user']['nickname'],
            mode: UserMode.values.firstWhere(
              (m) => m.name == data['data']['user']['userMode'],
              orElse: () => mode ?? UserMode.guest,
            ),
            provider: AuthProvider.email,
          );

          // 사용자 정보 저장
          await UserRepository.saveUser(_currentUser!);

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
          await UserRepository.saveUser(_currentUser!);
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
      await UserRepository.saveUser(_currentUser!);

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
          Uri.parse(ApiConfig.authLogoutUrl),
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
  Future<void> switchUserMode(UserMode newMode) async {
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        email: _currentUser!.email,
        name: _currentUser!.name,
        nickname: _currentUser!.nickname, // 유지
        profileImageUrl: _currentUser!.profileImageUrl,
        mode: newMode,
        provider: _currentUser!.provider,
        phoneVerified: _currentUser!.phoneVerified, // 유지
        hasBank: _currentUser!.hasBank, // 유지
      );
      await UserRepository.updateUserMode(newMode);
      notifyListeners();
      debugPrint('✅ [AUTH] 사용자 모드 변경: ${newMode.name}');
    }
  }
}