import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;

  // 초기화
  Future<void> initialize() async {
    _setLoading(true);
    try {
      developer.log('🚀 AuthProvider 초기화 시작', name: 'AuthProvider');

      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        // 토큰 유효성 검증
        final isValid = await _authService.validateToken();
        if (isValid) {
          // 캐시된 사용자 정보 로드
          _user = await _authService.getCachedUser();
          _isLoggedIn = true;

          // 서버에서 최신 사용자 정보 가져오기 (백그라운드)
          _refreshUserInfo();

          developer.log(
            '✅ 기존 로그인 상태 복원: ${_user?.nickname}',
            name: 'AuthProvider',
          );
        } else {
          developer.log('❌ 토큰 무효, 로그아웃 처리', name: 'AuthProvider');
          await _authService.clearToken();
        }
      }

      _clearError();
    } catch (e) {
      developer.log('❌ 초기화 오류: $e', name: 'AuthProvider');
      _setError('초기화 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 개발용 로그인
  Future<void> loginAsDev({
    String email = 'dev@example.com',
    String nickname = '개발자',
  }) async {
    _setLoading(true);
    try {
      developer.log('🔑 개발용 로그인 시작: $email', name: 'AuthProvider');

      final loginResponse = await _authService.createDevUser(
        email: email,
        nickname: nickname,
      );

      _user = loginResponse.user;
      _isLoggedIn = true;
      _clearError();

      developer.log('✅ 로그인 성공: ${_user?.nickname}', name: 'AuthProvider');
      notifyListeners();
    } catch (e) {
      developer.log('❌ 로그인 실패: $e', name: 'AuthProvider');
      _setError('로그인에 실패했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 사용자 정보 새로고침
  Future<void> refreshUser() async {
    if (!_isLoggedIn) return;

    try {
      developer.log('🔄 사용자 정보 새로고침', name: 'AuthProvider');

      final user = await _authService.getCurrentUser();
      _user = user;
      _clearError();

      developer.log('✅ 사용자 정보 새로고침 완료', name: 'AuthProvider');
      notifyListeners();
    } catch (e) {
      developer.log('❌ 사용자 정보 새로고침 실패: $e', name: 'AuthProvider');

      if (e.toString().contains('인증이 만료')) {
        await logout();
      } else {
        _setError('사용자 정보를 불러오는데 실패했습니다: $e');
      }
    }
  }

  // 백그라운드에서 사용자 정보 새로고침 (에러 무시)
  Future<void> _refreshUserInfo() async {
    try {
      final user = await _authService.getCurrentUser();
      _user = user;
      notifyListeners();
    } catch (e) {
      developer.log('⚠️ 백그라운드 사용자 정보 새로고침 실패: $e', name: 'AuthProvider');
    }
  }

  // 사용자 정보 수정
  Future<void> updateUser(UserUpdateRequest updateRequest) async {
    if (!_isLoggedIn) return;

    _setLoading(true);
    try {
      developer.log(
        '✏️ 사용자 정보 수정: ${updateRequest.toJson()}',
        name: 'AuthProvider',
      );

      final updatedUser = await _authService.updateUser(updateRequest);
      _user = updatedUser;
      _clearError();

      developer.log('✅ 사용자 정보 수정 완료', name: 'AuthProvider');
      notifyListeners();
    } catch (e) {
      developer.log('❌ 사용자 정보 수정 실패: $e', name: 'AuthProvider');

      if (e.toString().contains('인증이 만료')) {
        await logout();
      } else {
        _setError('사용자 정보 수정에 실패했습니다: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // 로그아웃
  Future<void> logout() async {
    _setLoading(true);
    try {
      developer.log('🚪 로그아웃 시작', name: 'AuthProvider');

      await _authService.logout();

      _user = null;
      _isLoggedIn = false;
      _clearError();

      developer.log('✅ 로그아웃 완료 - 로그인 페이지로 이동', name: 'AuthProvider');
      notifyListeners();
    } catch (e) {
      developer.log('❌ 로그아웃 오류: $e', name: 'AuthProvider');
      // 로그아웃은 실패해도 상태 초기화 (보안상 중요)
      _user = null;
      _isLoggedIn = false;
      _clearError(); // 에러 표시하지 않음 (로그아웃은 항상 성공으로 처리)

      developer.log('🔒 로그아웃 강제 완료 - 보안상 상태 초기화', name: 'AuthProvider');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // 에러 클리어
  void clearError() {
    _clearError();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
