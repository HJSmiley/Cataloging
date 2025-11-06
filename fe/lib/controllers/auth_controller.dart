import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthController extends GetxController {
  final ApiService _apiService = ApiService();

  final Rx<User?> _user = Rx<User?>(null);
  final RxString _token = ''.obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;

  User? get user => _user.value;
  String get token => _token.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get isAuthenticated => _token.value.isNotEmpty && _user.value != null;

  @override
  void onInit() {
    super.onInit();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      _token.value = token;
      _apiService.setToken(token);
      await loadUser();
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token.value = token;
    _apiService.setToken(token);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token.value = '';
    _apiService.setToken(null);
  }

  Future<bool> devLogin(String email, String nickname) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      final response = await _apiService.devLogin(email, nickname);
      final token = response['accessToken'] as String;
      await _saveToken(token);

      _user.value = User.fromJson(response['user'] as Map<String, dynamic>);
      _isLoading.value = false;
      return true;
    } catch (e) {
      _error.value = e.toString();
      _isLoading.value = false;
      return false;
    }
  }

  Future<void> loadUser() async {
    if (_token.value.isEmpty) return;

    _isLoading.value = true;

    try {
      final userData = await _apiService.getCurrentUser();
      _user.value = User.fromJson(userData);
      _error.value = '';
    } catch (e) {
      _error.value = e.toString();
      // 토큰이 유효하지 않으면 로그아웃
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

  Future<void> logout() async {
    await _clearToken();
    _user.value = null;
    _error.value = '';
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
