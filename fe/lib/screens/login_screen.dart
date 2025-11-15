import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'oauth2_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  /**
   * Google 네이티브 로그인
   */
  Future<void> _handleGoogleLogin() async {
    try {
      final authController = Get.find<AuthController>();

      final success = await authController.googleSignIn();

      if (success) {
        // 로그인 성공 시 자동으로 홈 화면으로 이동
      } else if (authController.error.isNotEmpty) {
        Get.snackbar(
          '로그인 실패',
          authController.error,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      print('Google 로그인 오류: $e');
      Get.snackbar(
        '로그인 오류',
        'Google 로그인 설정을 확인해주세요.\niOS: Info.plist 설정 필요',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 7),
      );
    }
  }

  /**
   * Naver WebView 로그인
   */
  Future<void> _handleNaverLogin() async {
    final authController = Get.find<AuthController>();

    // Backend에서 OAuth2 인증 URL 요청
    final oauthData = await authController.startOAuth2Login('naver');

    if (oauthData != null) {
      // WebView 기반 OAuth2 사용
      Get.to(() => OAuth2Screen(
            provider: 'naver',
            authUrl: oauthData['authUrl']!,
            state: oauthData['state']!,
          ));
    } else {
      // 에러 처리
      Get.snackbar(
        '로그인 실패',
        authController.error,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.collections_bookmark,
                  size: 100,
                  color: Color(0xFF6200EE),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Catalog',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6200EE),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '나만의 컬렉션을 관리하세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 64),

                // Google 로그인 버튼 (네이티브)
                _buildSocialLoginButton(
                  onPressed: _handleGoogleLogin,
                  label: 'Google로 계속하기',
                  backgroundColor: Colors.white,
                  textColor: Colors.black87,
                  borderColor: Colors.grey.shade300,
                  iconText: 'G',
                ),
                const SizedBox(height: 16),

                // Naver 로그인 버튼 (WebView)
                _buildSocialLoginButton(
                  onPressed: _handleNaverLogin,
                  label: 'Naver로 계속하기',
                  backgroundColor: const Color(0xFF03C75A),
                  textColor: Colors.white,
                  iconText: 'N',
                ),

                const SizedBox(height: 48),
                const Text(
                  '로그인하면 서비스 이용약관 및\n개인정보 처리방침에 동의하게 됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required VoidCallback onPressed,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
    String? iconText,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: borderColor != null
              ? BorderSide(color: borderColor)
              : BorderSide.none,
        ),
        elevation: borderColor != null ? 0 : 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconText != null)
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              child: Text(
                iconText,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
