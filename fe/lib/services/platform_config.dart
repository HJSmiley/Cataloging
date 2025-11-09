/**
 * 플랫폼별 설정 (Flutter 의존성)
 * - 플랫폼에 따라 다른 API URL 반환
 * - Controller에서 ApiService 생성 시 사용
 */

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class PlatformConfig {
  /// 플랫폼별 Catalog API URL
  static String get catalogApiUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000'; // 안드로이드 에뮬레이터
    } else {
      return 'http://localhost:8000'; // iOS, Desktop
    }
  }

  /// 플랫폼별 User API URL
  static String get userApiUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080'; // 안드로이드 에뮬레이터
    } else {
      return 'http://localhost:8080'; // iOS, Desktop
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
