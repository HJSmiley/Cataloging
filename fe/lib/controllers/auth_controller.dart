/**
 * 사용자 인증 상태 관리 컨트롤러
 * - GetX 반응형 상태 관리 사용
 * - user-api(Spring Boot)와 연동하여 JWT 토큰 기반 인증
 * - SharedPreferences로 토큰 영구 저장 (자동 로그인)
 * - 전역적으로 사용자 인증 상태 관리
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/platform_config.dart';
import '../services/google_sign_in_service.dart';
import '../screens/home_screen.dart';
import 'catalog_controller.dart';

class AuthController extends GetxController {
  // API 서비스 인스턴스 (플랫폼별 URL 설정)
  final ApiService _apiService = ApiService(
    catalogApiBaseUrl: PlatformConfig.catalogApiUrl,
    userApiBaseUrl: PlatformConfig.userApiUrl,
  );

  // 반응형 상태 변수들 (GetX .obs로 UI 자동 업데이트)
  final Rx<User?> _user = Rx<User?>(null); // 현재 로그인한 사용자 정보
  final RxString _token = ''.obs; // JWT 액세스 토큰
  final RxBool _isLoading = false.obs; // 로딩 상태
  final RxString _error = ''.obs; // 에러 메시지

  // Getter들 (UI에서 접근용)
  User? get user => _user.value;
  String get token => _token.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get isAuthenticated =>
      _token.value.isNotEmpty && _user.value != null; // 인증 여부 확인
  ApiService get apiService => _apiService; // ApiService 접근용

  /**
   * 컨트롤러 초기화
   * - 앱 시작 시 자동 호출
   * - 저장된 토큰이 있으면 자동 로그인 시도
   */
  @override
  void onInit() {
    super.onInit();
    _loadToken(); // 저장된 토큰 로드 및 자동 로그인
  }

  /**
   * 저장된 JWT 토큰 로드 (자동 로그인)
   * - SharedPreferences에서 토큰 읽기
   * - 토큰이 있으면 API 서비스에 설정하고 사용자 정보 로드
   */
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token'); // 저장된 토큰 조회

    if (token != null) {
      _token.value = token;
      _apiService.setToken(token); // API 서비스에 토큰 설정
      await loadUser(); // 사용자 정보 로드
    }
  }

  /**
   * JWT 토큰 저장
   * - SharedPreferences에 영구 저장
   * - API 서비스에도 설정하여 이후 요청에 자동 포함
   */
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token); // 영구 저장
    _token.value = token;
    _apiService.setToken(token); // API 서비스에 설정
  }

  /**
   * JWT 토큰 삭제 (로그아웃)
   * - SharedPreferences에서 토큰 제거
   * - API 서비스에서도 토큰 제거
   */
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token'); // 저장된 토큰 삭제
    _token.value = '';
    _apiService.setToken(null); // API 서비스에서 토큰 제거
  }

  /**
   * REST API 기반 OAuth2 로그인 시작
   * - Backend에서 OAuth2 인증 URL 요청
   * - OAuth2Screen으로 이동하여 로그인 진행
   */
  Future<Map<String, String>?> startOAuth2Login(String provider) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      // Backend에서 OAuth2 인증 URL 요청
      final response = await _apiService.getOAuthUrl(provider);

      _isLoading.value = false;

      return {
        'authUrl': response['authUrl'] as String,
        'state': response['state'] as String,
      };
    } catch (e) {
      _error.value = e.toString();
      _isLoading.value = false;
      return null;
    }
  }

  /**
   * OAuth2 로그인 데이터 저장
   * - OAuth2Screen에서 콜백 처리 후 호출
   * - JWT 토큰 저장 및 사용자 정보 설정
   */
  Future<void> saveLoginData(
      String accessToken, Map<String, dynamic> userData) async {
    // 1단계: JWT 토큰 저장
    await _saveToken(accessToken);

    // 2단계: 사용자 정보 설정
    _user.value = User.fromJson(userData);

    // 3단계: CatalogController에도 토큰 전달 (catalog-api 인증용)
    final catalogController = Get.find<CatalogController>();
    catalogController.setApiToken(accessToken);
  }

  /**
   * 네이티브 Google Sign-In 로그인
   * - google_sign_in 패키지 사용
   * - WebView 차단 문제 해결
   * - 백엔드 토큰 로그인 API 호출
   */
  Future<bool> googleSignIn() async {
    _isLoading.value = true;
    _error.value = '';

    try {
      print('Google Sign-In 시작...');

      // Google Sign-In SDK로 로그인
      final googleSignInService = Get.find<GoogleSignInService>();
      final account = await googleSignInService.signIn();

      if (account == null) {
        _error.value = '로그인이 취소되었습니다';
        _isLoading.value = false;
        return false;
      }

      print('Google 계정 정보: ${account.email}');
      print('Google 프로필 사진: ${account.photoUrl}');

      // 백엔드에 사용자 정보 전달하여 JWT 받기
      final response = await _apiService.devLogin(
        account.email,
        account.displayName ?? account.email.split('@')[0],
      );

      print('백엔드 로그인 성공');

      // JWT 토큰 저장
      final token = response['accessToken'] as String;
      await _saveToken(token);

      // 사용자 정보 설정
      final userData = response['user'] as Map<String, dynamic>;
      _user.value = User.fromJson(userData);

      // CatalogController에도 토큰 전달
      final catalogController = Get.find<CatalogController>();
      catalogController.setApiToken(token);

      // 최초 회원가입 시에만 Google 프로필 사진 업데이트
      // (기존 사용자는 프로필 이미지 유지)
      final hasProfileImage = userData['profileImage'] != null &&
          (userData['profileImage'] as String).isNotEmpty;

      if (!hasProfileImage && account.photoUrl != null) {
        try {
          print('최초 회원가입: 프로필 사진 설정 ${account.photoUrl}');
          final updatedUser = await _apiService.updateUser(
            profileImage: account.photoUrl,
          );
          // 업데이트된 사용자 정보로 갱신
          _user.value = User.fromJson(updatedUser);
        } catch (e) {
          print('프로필 사진 업데이트 실패: $e');
          // 프로필 사진 업데이트 실패해도 로그인은 성공으로 처리
        }
      } else if (hasProfileImage) {
        print('기존 사용자: 프로필 이미지 유지');
      }

      _isLoading.value = false;

      // 홈 화면으로 이동
      Get.offAll(() => const HomeScreen());
      Get.snackbar(
        '로그인 성공',
        '환영합니다!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      print('Google Sign-In 오류: $e');
      _error.value = 'Google 로그인 실패: ${e.toString()}';
      _isLoading.value = false;
      return false;
    }
  }

  /**
   * 개발용 간편 로그인
   * - 로그인 화면에서 호출
   * - user-api의 /api/auth/dev-login 엔드포인트 호출
   * - JWT 토큰 발급받아 저장하고 사용자 정보 설정
   * - CatalogController에도 토큰 전달하여 catalog-api 인증 준비
   */
  Future<bool> devLogin(String email, String nickname) async {
    _isLoading.value = true; // 로딩 상태 시작
    _error.value = ''; // 에러 메시지 초기화

    try {
      // 1단계: user-api에 로그인 요청
      final response = await _apiService.devLogin(email, nickname);

      // 2단계: JWT 토큰 추출 및 저장
      final token = response['accessToken'] as String;
      await _saveToken(token);

      // 3단계: 사용자 정보 설정
      _user.value = User.fromJson(response['user'] as Map<String, dynamic>);

      // 4단계: CatalogController에도 토큰 전달 (catalog-api 인증용)
      final catalogController = Get.find<CatalogController>();
      catalogController.setApiToken(token);

      _isLoading.value = false;
      return true; // 로그인 성공
    } catch (e) {
      _error.value = e.toString(); // 에러 메시지 설정
      _isLoading.value = false;
      return false; // 로그인 실패
    }
  }

  /**
   * 사용자 정보 로드
   * - 자동 로그인 시 또는 토큰 갱신 후 호출
   * - user-api의 /api/users/me 엔드포인트 호출
   * - 토큰이 만료되었으면 자동 로그아웃 처리
   */
  Future<void> loadUser() async {
    if (_token.value.isEmpty) return; // 토큰이 없으면 실행하지 않음

    _isLoading.value = true;

    try {
      // user-api에서 현재 사용자 정보 조회
      final userData = await _apiService.getCurrentUser();
      _user.value = User.fromJson(userData);

      // CatalogController에도 토큰 전달 (catalog-api 인증용)
      final catalogController = Get.find<CatalogController>();
      catalogController.setApiToken(_token.value);

      _error.value = '';
    } catch (e) {
      _error.value = e.toString();
      // 토큰이 유효하지 않으면 (만료, 무효 등) 자동 로그아웃
      await logout();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> updateUser({
    String? nickname,
    String? introduction,
    String? profileImage,
  }) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      final userData = await _apiService.updateUser(
        nickname: nickname,
        introduction: introduction,
        profileImage: profileImage,
      );
      _user.value = User.fromJson(userData);
      _isLoading.value = false;
      return true;
    } catch (e) {
      _error.value = e.toString();
      _isLoading.value = false;
      return false;
    }
  }

  /**
   * 로그아웃 처리
   * - 저장된 토큰 삭제
   * - 사용자 정보 초기화
   * - CatalogController에서도 토큰 제거
   * - Google 네이티브 로그아웃
   */
  Future<void> logout() async {
    // Google 로그아웃
    try {
      final googleSignInService = Get.find<GoogleSignInService>();
      await googleSignInService.signOut();
    } catch (e) {
      print('Google 로그아웃 오류: $e');
    }

    await _clearToken(); // 토큰 삭제
    _user.value = null; // 사용자 정보 초기화
    _error.value = ''; // 에러 메시지 초기화

    // CatalogController에서도 토큰 제거
    final catalogController = Get.find<CatalogController>();
    catalogController.setApiToken(null);
  }

  /**
   * OAuth2 콜백 처리
   * - WebView에서 로그인 완료 후 호출
   * - JWT 토큰 저장 및 사용자 정보 설정
   */
  Future<bool> handleOAuth2Callback(
      String accessToken, Map<String, dynamic> userData) async {
    try {
      // 1단계: JWT 토큰 저장
      await _saveToken(accessToken);

      // 2단계: 사용자 정보 설정
      _user.value = User.fromJson(userData);

      // 3단계: CatalogController에도 토큰 전달 (catalog-api 인증용)
      final catalogController = Get.find<CatalogController>();
      catalogController.setApiToken(accessToken);

      return true;
    } catch (e) {
      _error.value = e.toString();
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    _isLoading.value = true;
    _error.value = '';

    try {
      await _apiService.deleteUser();
      await logout();
      return true;
    } catch (e) {
      _error.value = e.toString();
      _isLoading.value = false;
      return false;
    }
  }
}
