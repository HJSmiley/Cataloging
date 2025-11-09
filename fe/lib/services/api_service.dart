/**
 * API 서비스 클래스
 * - user-api(Spring Boot)와 catalog-api(FastAPI) 통신 담당
 * - JWT 토큰 기반 인증 처리
 * - 플랫폼별 API URL 자동 설정
 * - UTF-8 인코딩 지원으로 한글 처리
 */

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  /**
   * 플랫폼별 Catalog API 베이스 URL 설정
   * - 웹: localhost:8000 (개발 서버 직접 접근)
   * - 안드로이드: 10.0.2.2:8000 (에뮬레이터 호스트 매핑)
   * - iOS: localhost:8000 (시뮬레이터는 호스트와 네트워크 공유)
   */
  static String get catalogApiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000'; // 웹 브라우저
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000'; // 안드로이드 에뮬레이터 (특수 IP)
    } else if (Platform.isIOS) {
      return 'http://localhost:8000'; // iOS 시뮬레이터
    } else {
      return 'http://localhost:8000'; // 기타 플랫폼 (macOS, Windows 등)
    }
  }

  /**
   * 플랫폼별 User API 베이스 URL 설정
   * - catalog-api와 동일한 패턴으로 포트만 8080로 변경
   */
  static String get userApiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080'; // 웹 브라우저
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080'; // 안드로이드 에뮬레이터
    } else if (Platform.isIOS) {
      return 'http://localhost:8080'; // iOS 시뮬레이터
    } else {
      return 'http://localhost:8080'; // 기타 플랫폼
    }
  }

  /**
   * 이미지 URL 생성 헬퍼 함수
   * - catalog-api의 /uploads 경로로 이미지 접근
   * - null 체크로 안전한 URL 생성
   */
  static String getImageUrl(String? imagePath) {
    if (imagePath == null) return '';
    return '$catalogApiBaseUrl$imagePath';
  }

  // JWT 토큰 저장 (로그인 후 설정)
  String? _token;

  /**
   * UTF-8 인코딩을 보장하는 JSON 디코딩 헬퍼
   * - 한글 등 유니코드 문자 정상 처리
   * - response.body 대신 response.bodyBytes 사용
   */
  dynamic _decodeUtf8Response(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  /**
   * JWT 토큰 설정
   * - 로그인 성공 시 AuthController에서 호출
   * - 이후 모든 API 요청에 Authorization 헤더 자동 추가
   */
  void setToken(String? token) {
    _token = token;
  }

  /**
   * HTTP 요청 헤더 생성
   * - UTF-8 인코딩 명시
   * - JWT 토큰이 있으면 Authorization 헤더 추가
   */
  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8',
        if (_token != null) 'Authorization': 'Bearer $_token', // JWT 토큰 포함
      };

  // ========== User API (Spring Boot) 연동 ==========

  /**
   * 개발용 간편 로그인
   * - user-api의 /api/auth/dev-login 엔드포인트 호출
   * - OAuth2 없이 이메일/닉네임만으로 로그인
   * - JWT 토큰 발급받아 AuthController에서 저장
   * - 개발 및 테스트 환경에서 사용
   */
  Future<Map<String, dynamic>> devLogin(String email, String nickname) async {
    final response = await http.post(
      Uri.parse(
          '$userApiBaseUrl/api/auth/dev-login'), // Spring Boot AuthController
      headers: {'Content-Type': 'application/json'},
      body: utf8.encode(jsonEncode({
        'email': email, // 사용자 이메일
        'nickname': nickname, // 사용자 닉네임
      })),
    );

    if (response.statusCode == 200) {
      // 로그인 성공: JWT 토큰과 사용자 정보 반환
      return _decodeUtf8Response(response);
    } else {
      // 로그인 실패: 에러 메시지와 함께 예외 발생
      throw Exception('로그인 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  /**
   * 현재 로그인한 사용자 정보 조회
   * - user-api의 /api/users/me 엔드포인트 호출
   * - JWT 토큰 필수 (Authorization 헤더)
   * - 마이페이지 화면에서 프로필 표시용
   */
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$userApiBaseUrl/api/users/me'), // Spring Boot UserController
      headers: _headers, // JWT 토큰 포함
    );

    if (response.statusCode == 200) {
      // 사용자 정보 조회 성공
      return Map<String, dynamic>.from(_decodeUtf8Response(response));
    } else {
      // 조회 실패 (토큰 만료, 권한 없음 등)
      throw Exception('사용자 정보 조회 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  /// 사용자 정보 수정
  Future<Map<String, dynamic>> updateUser({
    String? nickname,
    String? introduction,
    String? profileImage,
  }) async {
    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (introduction != null) body['introduction'] = introduction;
    if (profileImage != null) body['profileImage'] = profileImage;

    final response = await http.put(
      Uri.parse('$userApiBaseUrl/api/users/me'),
      headers: _headers,
      body: utf8.encode(jsonEncode(body)),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(_decodeUtf8Response(response));
    } else {
      throw Exception('사용자 정보 수정 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  /// 회원 탈퇴
  Future<void> deleteUser() async {
    final response = await http.delete(
      Uri.parse('$userApiBaseUrl/api/users/me'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('회원 탈퇴 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  // ========== Catalog API (FastAPI) 연동 ==========

  /**
   * 내 카탈로그 목록 조회 (홈 화면용)
   * - catalog-api의 /api/user-catalogs/my-catalogs 엔드포인트 호출
   * - 내가 생성한 카탈로그 + 저장한 카탈로그 (복사본) 모두 반환
   * - JWT 토큰으로 사용자 인증 후 해당 사용자 소유 카탈로그만 조회
   * - 각 카탈로그의 수집률(completion_rate) 포함
   */
  Future<List<dynamic>> getMyCatalogs() async {
    final response = await http.get(
      Uri.parse(
          '$catalogApiBaseUrl/api/user-catalogs/my-catalogs'), // FastAPI UserCatalogRouter
      headers: _headers, // JWT 토큰 포함
    );

    if (response.statusCode == 200) {
      // 카탈로그 목록 조회 성공
      return _decodeUtf8Response(response);
    } else {
      // 조회 실패 (인증 오류, 서버 오류 등)
      throw Exception('카탈로그 목록 조회 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  /**
   * 공개 카탈로그 목록 조회 (탐색 화면용)
   * - catalog-api의 /api/catalogs/public 엔드포인트 호출
   * - 모든 사용자의 공개 카탈로그를 최신순으로 조회
   * - 로그인 불필요 (선택적 인증)
   * - 로그인한 경우 자신의 카탈로그는 제외하여 표시
   */
  Future<List<dynamic>> getPublicCatalogs({String? category}) async {
    final queryParams = <String, String>{};

    // 카테고리 필터 적용
    if (category != null) queryParams['category'] = category;

    // 로그인한 사용자가 있으면 user_id 추가 (자신의 카탈로그 제외용)
    if (_token != null) {
      try {
        final userInfo = await getCurrentUser();
        queryParams['user_id'] = userInfo['user_id']; // 현재 사용자 ID
      } catch (e) {
        // 사용자 정보 조회 실패 시 무시하고 계속 진행 (비로그인 상태로 처리)
        print('사용자 정보 조회 실패: $e');
      }
    }

    final uri = Uri.parse('$catalogApiBaseUrl/api/catalogs/public')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      // 공개 카탈로그 목록 조회 성공
      return _decodeUtf8Response(response);
    } else {
      // 조회 실패
      throw Exception('공개 카탈로그 조회 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  /// 카탈로그 상세 조회
  Future<Map<String, dynamic>> getCatalog(String catalogId) async {
    final response = await http.get(
      Uri.parse('$catalogApiBaseUrl/api/catalogs/$catalogId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return _decodeUtf8Response(response);
    } else {
      throw Exception('카탈로그 조회 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  /// 카탈로그 생성
  Future<Map<String, dynamic>> createCatalog({
    required String title,
    required String description,
    String category = '미분류',
    List<String>? tags,
    String visibility = 'public',
    String? thumbnailUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$catalogApiBaseUrl/api/catalogs/'),
      headers: _headers,
      body: utf8.encode(jsonEncode({
        'title': title,
        'description': description,
        'category': category,
        'tags': tags ?? [],
        'visibility': visibility,
        'thumbnail_url': thumbnailUrl,
      })),
    );

    if (response.statusCode == 201) {
      return _decodeUtf8Response(response);
    } else {
      throw Exception('카탈로그 생성 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  /// 카탈로그 수정
  Future<Map<String, dynamic>> updateCatalog(
    String catalogId, {
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    String? visibility,
    String? thumbnailUrl,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (category != null) body['category'] = category;
    if (tags != null) body['tags'] = tags;
    if (visibility != null) body['visibility'] = visibility;
    if (thumbnailUrl != null) body['thumbnail_url'] = thumbnailUrl;

    final response = await http.put(
      Uri.parse('$catalogApiBaseUrl/api/catalogs/$catalogId'),
      headers: _headers,
      body: utf8.encode(jsonEncode(body)),
    );

    if (response.statusCode == 200) {
      return _decodeUtf8Response(response);
    } else {
      throw Exception('카탈로그 수정 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  /// 카탈로그 삭제
  Future<void> deleteCatalog(String catalogId) async {
    final response = await http.delete(
      Uri.parse('$catalogApiBaseUrl/api/catalogs/$catalogId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('카탈로그 삭제 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  /**
   * 카탈로그 저장 (다른 사용자의 카탈로그를 내 컬렉션에 복사)
   * - catalog-api의 /api/user-catalogs/save-catalog 엔드포인트 호출
   * - 원본 카탈로그와 모든 아이템을 완전 복사하여 새 카탈로그 생성
   * - 복사본은 현재 사용자 소유가 되어 자유롭게 수정 가능
   * - 중복 저장 방지 (같은 원본 카탈로그는 한 번만 저장 가능)
   */
  Future<Map<String, dynamic>> saveCatalog(String catalogId) async {
    final response = await http.post(
      Uri.parse(
          '$catalogApiBaseUrl/api/user-catalogs/save-catalog'), // FastAPI UserCatalogRouter
      headers: _headers, // JWT 토큰 포함
      body:
          utf8.encode(jsonEncode({'catalog_id': catalogId})), // 저장할 원본 카탈로그 ID
    );

    if (response.statusCode == 200) {
      // 카탈로그 저장 성공: 복사본 카탈로그 ID 반환
      return _decodeUtf8Response(response);
    } else {
      // 저장 실패 (중복 저장, 권한 없음 등)
      throw Exception('카탈로그 저장 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  /// 카탈로그 소유권 확인
  Future<Map<String, dynamic>> checkCatalogOwnership(String catalogId) async {
    final response = await http.get(
      Uri.parse(
          '$catalogApiBaseUrl/api/user-catalogs/check-ownership/$catalogId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return _decodeUtf8Response(response);
    } else {
      throw Exception('소유권 확인 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  /// 카탈로그 저장 여부 확인 (원본 카탈로그 ID 기준)
  Future<Map<String, dynamic>> checkCatalogSaved(
      String originalCatalogId) async {
    final response = await http.get(
      Uri.parse(
          '$catalogApiBaseUrl/api/user-catalogs/check-saved/$originalCatalogId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return _decodeUtf8Response(response);
    } else {
      throw Exception('저장 여부 확인 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  // ========== Item API ==========

  /// 카탈로그의 아이템 목록 조회
  Future<List<dynamic>> getItemsByCatalog(String catalogId,
      {bool? owned}) async {
    final queryParams = <String, String>{};
    if (owned != null) queryParams['owned'] = owned.toString();
    final uri = Uri.parse('$catalogApiBaseUrl/api/items/catalog/$catalogId')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return _decodeUtf8Response(response);
    } else {
      throw Exception('아이템 목록 조회 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  /// 아이템 상세 조회
  Future<Map<String, dynamic>> getItem(String itemId) async {
    final response = await http.get(
      Uri.parse('$catalogApiBaseUrl/api/items/$itemId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return _decodeUtf8Response(response);
    } else {
      throw Exception('아이템 조회 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  /// 아이템 생성
  Future<Map<String, dynamic>> createItem({
    required String catalogId,
    required String name,
    required String description,
    String? imageUrl,
    Map<String, String>? userFields,
  }) async {
    final response = await http.post(
      Uri.parse('$catalogApiBaseUrl/api/items/'),
      headers: _headers,
      body: utf8.encode(jsonEncode({
        'catalog_id': catalogId,
        'name': name,
        'description': description,
        'image_url': imageUrl,
        'user_fields': userFields ?? {},
      })),
    );

    if (response.statusCode == 201) {
      return _decodeUtf8Response(response);
    } else {
      throw Exception('아이템 생성 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  /// 아이템 수정
  Future<Map<String, dynamic>> updateItem(
    String itemId, {
    String? name,
    String? description,
    String? imageUrl,
    Map<String, String>? userFields,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (imageUrl != null) body['image_url'] = imageUrl;
    if (userFields != null) body['user_fields'] = userFields;

    final response = await http.put(
      Uri.parse('$catalogApiBaseUrl/api/items/$itemId'),
      headers: _headers,
      body: utf8.encode(jsonEncode(body)),
    );

    if (response.statusCode == 200) {
      return _decodeUtf8Response(response);
    } else {
      throw Exception('아이템 수정 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  /**
   * 아이템 보유 상태 토글 (핵심 기능)
   * - catalog-api의 /api/items/{itemId}/toggle-owned 엔드포인트 호출
   * - 사용자가 체크박스 클릭 시 호출되어 owned 상태를 True ↔ False로 변경
   * - 변경 후 카탈로그의 수집률(completion_rate) 자동 업데이트
   * - 실시간으로 UI에 반영되어 수집 진행 상황 추적 가능
   */
  Future<Map<String, dynamic>> toggleItemOwned(String itemId) async {
    final response = await http.patch(
      Uri.parse(
          '$catalogApiBaseUrl/api/items/$itemId/toggle-owned'), // FastAPI ItemRouter
      headers: _headers, // JWT 토큰 포함
    );

    if (response.statusCode == 200) {
      // 상태 토글 성공: 업데이트된 아이템 정보 반환
      return _decodeUtf8Response(response);
    } else {
      // 토글 실패 (권한 없음, 아이템 없음 등)
      throw Exception('아이템 상태 토글 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  /// 아이템 삭제
  Future<void> deleteItem(String itemId) async {
    final response = await http.delete(
      Uri.parse('$catalogApiBaseUrl/api/items/$itemId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('아이템 삭제 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  // ========== Upload API ==========

  /// 파일 업로드 (웹과 모바일 모두 지원)
  Future<Map<String, dynamic>> uploadFile(String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$catalogApiBaseUrl/api/upload/file'),
    );

    request.headers.addAll(_headers);

    try {
      if (kIsWeb) {
        // 웹 환경에서는 파일 경로를 직접 사용할 수 없으므로
        // 이 메서드는 웹에서 사용하지 않고 uploadFileBytes를 사용
        throw Exception('웹 환경에서는 uploadFileBytes를 사용하세요');
      } else {
        // 모바일 환경에서는 파일 경로 사용 가능
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      }
    } catch (e) {
      throw Exception('파일 읽기 실패: $e');
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return _decodeUtf8Response(response);
    } else {
      throw Exception('파일 업로드 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  /// 파일 업로드 (바이트 배열 사용 - 웹 환경용)
  Future<Map<String, dynamic>> uploadFileBytes(
      List<int> fileBytes, String fileName) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$catalogApiBaseUrl/api/upload/file'),
    );

    request.headers.addAll(_headers);

    // MIME 타입 추론
    String contentType = 'image/jpeg'; // 기본값
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        contentType = 'image/jpeg';
        break;
      case 'png':
        contentType = 'image/png';
        break;
      case 'gif':
        contentType = 'image/gif';
        break;
      case 'webp':
        contentType = 'image/webp';
        break;
    }

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
      contentType: MediaType.parse(contentType),
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return _decodeUtf8Response(response);
    } else {
      throw Exception('파일 업로드 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }
}
