/**
 * 사용자 인증 상태 관리 컨트롤러
 * - GetX 반응형 상태 관리 사용
 * - user-api(Spring Boot)와 연동하여 JWT 토큰 기반 인증
 * - SharedPreferences로 토큰 영구 저장 (자동 로그인)
 * - 전역적으로 사용자 인증 상태 관리
 */

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthController extends GetxController {
  // API 서비스 인스턴스 (user-api 통신용)
  final ApiService _apiService = ApiService();

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
   */
  Future<void> logout() async {
    await _clearToken(); // 토큰 삭제
    _user.value = null; // 사용자 정보 초기화
    _error.value = ''; // 에러 메시지 초기화

    // CatalogController에서도 토큰 제거
    final catalogController = Get.find<CatalogController>();
    catalogController.setApiToken(null);
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
