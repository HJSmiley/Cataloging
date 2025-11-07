/**
 * 스플래시 화면
 * - 앱 시작 시 첫 번째로 표시되는 화면
 * - 로고 애니메이션 표시
 * - 자동 로그인 상태 확인 후 적절한 화면으로 이동
 * - 로그인되어 있으면 홈 화면, 아니면 로그인 화면으로 이동
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // 애니메이션 컨트롤러들
  late AnimationController _controller;
  late Animation<double> _fadeAnimation; // 페이드 인 애니메이션
  late Animation<double> _scaleAnimation; // 스케일 애니메이션

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러 초기화
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // 2초 애니메이션
    );

    // 페이드 인 애니메이션 (투명 → 불투명)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // 스케일 애니메이션 (작게 → 크게)
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // 애니메이션 시작
    _controller.forward();

    // 3초 후 로그인 상태 확인 및 화면 전환
    Future.delayed(const Duration(seconds: 3), () {
      _checkAuthStatus();
    });
  }

  /**
   * 자동 로그인 상태 확인 및 화면 전환
   * - AuthController에서 저장된 토큰 확인
   * - 토큰이 유효하면 사용자 정보 로드
   * - 인증 상태에 따라 홈 화면 또는 로그인 화면으로 이동
   */
  Future<void> _checkAuthStatus() async {
    final authController = Get.find<AuthController>();

    // 저장된 토큰이 있으면 사용자 정보 로드 시도
    if (authController.isAuthenticated) {
      await authController.loadUser(); // user-api에서 사용자 정보 조회
    }

    // 화면이 아직 마운트되어 있으면 적절한 화면으로 이동
    if (mounted) {
      Get.offAll(() => authController.isAuthenticated
          ? const HomeScreen() // 인증됨: 홈 화면으로
          : const LoginScreen()); // 미인증: 로그인 화면으로
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6200EE),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.collections_bookmark,
                        size: 64,
                        color: Color(0xFF6200EE),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Catalog',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
