/**
 * Flutter 카탈로그 앱 메인 진입점
 * - 수집가를 위한 카탈로그 관리 앱
 * - GetX 상태 관리 라이브러리 사용
 * - user-api(Spring Boot)와 catalog-api(FastAPI) 연동
 * - JWT 토큰 기반 인증 시스템
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/auth_controller.dart';
import 'controllers/catalog_controller.dart';
import 'screens/splash_screen.dart';

/**
 * 앱 시작점
 * - Flutter 프레임워크 초기화
 * - MyApp 위젯을 루트로 설정
 */
void main() {
  runApp(const MyApp());
}

/**
 * 메인 앱 위젯
 * - GetX 상태 관리 설정
 * - 전역 컨트롤러 초기화
 * - 앱 테마 및 라우팅 설정
 */
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1단계: GetX 전역 컨트롤러 초기화
    // AuthController: 사용자 인증 상태 관리 (user-api 연동)
    Get.put(AuthController());
    // CatalogController: 카탈로그 데이터 관리 (catalog-api 연동)
    Get.put(CatalogController());

    // 2단계: GetMaterialApp으로 앱 설정
    return GetMaterialApp(
      title: 'Catalog', // 앱 제목
      debugShowCheckedModeBanner: false, // 디버그 배너 숨김
      theme: ThemeData(
        primarySwatch: Colors.blue, // 기본 색상 팔레트
        useMaterial3: true, // Material Design 3 사용
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6200EE), // 시드 색상 (보라색)
          brightness: Brightness.light, // 라이트 테마
        ),
      ),
      home: const SplashScreen(), // 3단계: 스플래시 화면으로 시작
    );
  }
}
