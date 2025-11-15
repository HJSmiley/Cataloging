/**
 * 플랫폼별 설정 (Flutter 의존성)
 * - 플랫폼에 따라 다른 API URL 반환
 * - Controller에서 ApiService 생성 시 사용
 */

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class PlatformConfig {
  // ⚠️ 개발 환경 설정
  // Android/iOS 실제 기기에서 테스트할 때는 컴퓨터의 실제 IP 주소로 변경하세요
  // 예: 'http://192.168.0.10:8000'
  // 터미널에서 확인: ifconfig (Mac/Linux) 또는 ipconfig (Windows)
  static const String _devHostIp =
      'localhost'; // 여기에 실제 IP 입력 (예: '192.168.0.10')

  /// 플랫폼별 Catalog API URL
  static String get catalogApiUrl {
    if (kIsWeb) {
      return 'http://$_devHostIp:8000';
    } else if (Platform.isAndroid) {
      // 에뮬레이터: 10.0.2.2, 실제 기기: 실제 IP
      return _devHostIp == 'localhost'
          ? 'http://10.0.2.2:8000'
          : 'http://$_devHostIp:8000';
    } else {
      return 'http://$_devHostIp:8000'; // iOS, Desktop
    }
  }

  /// 플랫폼별 User API URL
  static String get userApiUrl {
    if (kIsWeb) {
      return 'http://$_devHostIp:8080';
    } else if (Platform.isAndroid) {
      // 에뮬레이터: 10.0.2.2, 실제 기기: 실제 IP
      return _devHostIp == 'localhost'
          ? 'http://10.0.2.2:8080'
          : 'http://$_devHostIp:8080';
    } else {
      return 'http://$_devHostIp:8080'; // iOS, Desktop
    }
  }

  /// 전역 ApiService 인스턴스 (화면에서 사용)
  static final ApiService apiService = ApiService(
    catalogApiBaseUrl: catalogApiUrl,
    userApiBaseUrl: userApiUrl,
  );

  /// 이미지 URL 생성 헬퍼 (static 메서드 대체)
  static String getImageUrl(String? imagePath) {
    return apiService.getImageUrl(imagePath);
  }
}
