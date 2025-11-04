import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _baseUrl = 'http://localhost:8081/api';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  String? _cachedToken;
  User? _cachedUser;

  // 토큰 관리
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;

    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);

    developer.log(
      '🔐 토큰 저장됨: ${token.substring(0, 20)}...',
      name: 'AuthService',
    );
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    _cachedUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);

    developer.log('🔓 토큰 및 사용자 정보 삭제됨', name: 'AuthService');
  }

  // 사용자 정보 관리
  Future<User?> getCachedUser() async {
    if (_cachedUser != null) return _cachedUser;

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      _cachedUser = User.fromJson(json.decode(userJson));
    }
    return _cachedUser;
  }

  Future<void> saveUser(User user) async {
    _cachedUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));

    developer.log(
      '👤 사용자 정보 저장됨: ${user.nickname} (${user.email})',
      name: 'AuthService',
    );
  }

  // 인증 상태 확인
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // HTTP 헤더 생성
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    final headers = {'Content-Type': 'application/json'};

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // 개발용 사용자 생성 및 로그인
  Future<LoginResponse> createDevUser({
    String email = 'dev@example.com',
    String nickname = '개발자',
  }) async {
    try {
      developer.log('🚀 개발용 사용자 생성 요청: $email', name: 'AuthService');

      final response = await http.post(
        Uri.parse('$_baseUrl/dev/create-user'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'nickname': nickname}),
      );

      developer.log('📡 응답 상태: ${response.statusCode}', name: 'AuthService');
      developer.log('📡 응답 본문: ${response.body}', name: 'AuthService');

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(
          json.decode(response.body),
        );

        // 토큰과 사용자 정보 저장
        await saveToken(loginResponse.accessToken);
        await saveUser(loginResponse.user);

        developer.log(
          '✅ 로그인 성공: ${loginResponse.user.nickname}',
          name: 'AuthService',
        );
        return loginResponse;
      } else {
        throw Exception('사용자 생성 실패: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ 사용자 생성 오류: $e', name: 'AuthService');
      rethrow;
    }
  }

  // 현재 사용자 정보 조회
  Future<User> getCurrentUser() async {
    try {
      developer.log('👤 현재 사용자 정보 조회 요청', name: 'AuthService');

      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/users/me'),
        headers: headers,
      );

      developer.log('📡 응답 상태: ${response.statusCode}', name: 'AuthService');
      developer.log('📡 응답 본문: ${response.body}', name: 'AuthService');

      if (response.statusCode == 200) {
        final user = User.fromJson(json.decode(response.body));
        await saveUser(user);

        developer.log('✅ 사용자 정보 조회 성공: ${user.nickname}', name: 'AuthService');
        return user;
      } else if (response.statusCode == 401) {
        // 토큰 만료 또는 무효
        await clearToken();
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        throw Exception('사용자 정보 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ 사용자 정보 조회 오류: $e', name: 'AuthService');
      rethrow;
    }
  }

  // 사용자 정보 수정
  Future<User> updateUser(UserUpdateRequest updateRequest) async {
    try {
      developer.log(
        '✏️ 사용자 정보 수정 요청: ${updateRequest.toJson()}',
        name: 'AuthService',
      );

      final headers = await getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/users/me'),
        headers: headers,
        body: json.encode(updateRequest.toJson()),
      );

      developer.log('📡 응답 상태: ${response.statusCode}', name: 'AuthService');
      developer.log('📡 응답 본문: ${response.body}', name: 'AuthService');

      if (response.statusCode == 200) {
        final user = User.fromJson(json.decode(response.body));
        await saveUser(user);

        developer.log('✅ 사용자 정보 수정 성공: ${user.nickname}', name: 'AuthService');
        return user;
      } else if (response.statusCode == 401) {
        await clearToken();
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        throw Exception('사용자 정보 수정 실패: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ 사용자 정보 수정 오류: $e', name: 'AuthService');
      rethrow;
    }
  }

  // 로그아웃
  Future<void> logout() async {
    try {
      developer.log('🚪 로그아웃 요청', name: 'AuthService');

      // 서버에 로그아웃 요청 (선택사항)
      final headers = await getAuthHeaders();
      await http.post(Uri.parse('$_baseUrl/auth/logout'), headers: headers);

      // 로컬 데이터 삭제
      await clearToken();

      developer.log('✅ 로그아웃 완료', name: 'AuthService');
    } catch (e) {
      developer.log('❌ 로그아웃 오류: $e', name: 'AuthService');
      // 로그아웃은 실패해도 로컬 데이터는 삭제
      await clearToken();
    }
  }

  // JWT 토큰 검증
  Future<bool> validateToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      developer.log('🔍 토큰 검증 요청', name: 'AuthService');

      final response = await http.post(
        Uri.parse('$_baseUrl/test/validate-token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token}),
      );

      developer.log('📡 토큰 검증 응답: ${response.statusCode}', name: 'AuthService');
      developer.log('📡 응답 본문: ${response.body}', name: 'AuthService');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final isValid = result['valid'] == true;

        if (!isValid) {
          await clearToken();
        }

        developer.log(isValid ? '✅ 토큰 유효함' : '❌ 토큰 무효함', name: 'AuthService');
        return isValid;
      } else {
        await clearToken();
        return false;
      }
    } catch (e) {
      developer.log('❌ 토큰 검증 오류: $e', name: 'AuthService');
      return false;
    }
  }
}
