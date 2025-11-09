/**
 * API 서비스 클래스 (순수 Dart)
 * - user-api(Spring Boot)와 catalog-api(FastAPI) 통신 담당
 * - JWT 토큰 기반 인증 처리
 * - UTF-8 인코딩 지원으로 한글 처리
 * - Flutter 의존성 없음 (CLI에서도 사용 가능)
 */

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // API 베이스 URL (기본값: localhost)
  final String catalogApiBaseUrl;
  final String userApiBaseUrl;

  ApiService({
    this.catalogApiBaseUrl = 'http://localhost:8000',
    this.userApiBaseUrl = 'http://localhost:8080',
  });

  /**
   * 이미지 URL 생성 헬퍼 함수
   */
  String getImageUrl(String? imagePath) {
    if (imagePath == null) return '';
    return '$catalogApiBaseUrl$imagePath';
  }

  // JWT 토큰 저장 (로그인 후 설정)
  String? _token;

  /**
   * UTF-8 인코딩을 보장하는 JSON 디코딩 헬퍼
   */
  dynamic _decodeUtf8Response(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  /**
   * JWT 토큰 설정
   */
  void setToken(String? token) {
    _token = token;
  }

  /**
   * HTTP 요청 헤더 생성
   */
  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ========== User API (Spring Boot) 연동 ==========

  /**
   * 개발용 간편 로그인
   */
  Future<Map<String, dynamic>> devLogin(String email, String nickname) async {
    final response = await http.post(
      Uri.parse('$userApiBaseUrl/api/auth/dev-login'),
      headers: {'Content-Type': 'application/json'},
      body: utf8.encode(jsonEncode({
        'email': email,
        'nickname': nickname,
      })),
    );

    if (response.statusCode == 200) {
      return _decodeUtf8Response(response);
    } else {
      throw Exception('로그인 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  /**
   * 현재 로그인한 사용자 정보 조회
   */
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$userApiBaseUrl/api/users/me'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(_decodeUtf8Response(response));
    } else {
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
   * 내 카탈로그 목록 조회
   */
  Future<List<dynamic>> getMyCatalogs() async {
    final response = await http.get(
      Uri.parse('$catalogApiBaseUrl/api/user-catalogs/my-catalogs'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return _decodeUtf8Response(response);
    } else {
      throw Exception('카탈로그 목록 조회 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  /**
   * 공개 카탈로그 목록 조회
   */
  Future<List<dynamic>> getPublicCatalogs({String? category}) async {
    final queryParams = <String, String>{};

    if (category != null) queryParams['category'] = category;

    if (_token != null) {
      try {
        final userInfo = await getCurrentUser();
        queryParams['user_id'] = userInfo['user_id'];
      } catch (e) {
        print('사용자 정보 조회 실패: $e');
      }
    }

    final uri = Uri.parse('$catalogApiBaseUrl/api/catalogs/public')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return _decodeUtf8Response(response);
    } else {
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
   * 카탈로그 저장
   */
  Future<Map<String, dynamic>> saveCatalog(String catalogId) async {
    final response = await http.post(
      Uri.parse('$catalogApiBaseUrl/api/user-catalogs/save-catalog'),
      headers: _headers,
      body: utf8.encode(jsonEncode({'catalog_id': catalogId})),
    );

    if (response.statusCode == 200) {
      return _decodeUtf8Response(response);
    } else {
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

  /// 카탈로그 저장 여부 확인
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
   * 아이템 보유 상태 토글
   */
  Future<Map<String, dynamic>> toggleItemOwned(String itemId) async {
    final response = await http.patch(
      Uri.parse('$catalogApiBaseUrl/api/items/$itemId/toggle-owned'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return _decodeUtf8Response(response);
    } else {
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

  /// 파일 업로드 (파일 경로 사용 - 모바일/데스크톱)
  Future<Map<String, dynamic>> uploadFile(String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$catalogApiBaseUrl/api/upload/file'),
    );

    request.headers.addAll(_headers);

    try {
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
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

  /// 파일 업로드 (바이트 배열 사용 - 웹)
  Future<Map<String, dynamic>> uploadFileBytes(
      List<int> fileBytes, String fileName) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$catalogApiBaseUrl/api/upload/file'),
    );

    request.headers.addAll(_headers);

    String contentType = 'image/jpeg';
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
