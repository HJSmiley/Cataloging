import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/catalog.dart';
import '../models/item.dart';
import 'auth_service.dart';

class ApiLogger {
  static void logRequest(
    String method,
    String url,
    Map<String, String> headers, [
    String? body,
  ]) {
    developer.log('🔵 CLIENT REQUEST: $method $url', name: 'ApiService');
    developer.log('   Headers: $headers', name: 'ApiService');
    if (body != null) {
      developer.log('   Body: $body', name: 'ApiService');
    }
  }

  static void logResponse(
    int statusCode,
    String url,
    String responseBody, [
    Duration? duration,
  ]) {
    developer.log(
      '🔴 CLIENT RESPONSE: $statusCode $url ${duration != null ? '(${duration.inMilliseconds}ms)' : ''}',
      name: 'ApiService',
    );
    if (responseBody.isNotEmpty) {
      try {
        final jsonData = json.decode(responseBody);
        final prettyJson = JsonEncoder.withIndent('  ').convert(jsonData);
        developer.log('   Response: $prettyJson', name: 'ApiService');
      } catch (e) {
        developer.log('   Response: $responseBody', name: 'ApiService');
      }
    }
  }

  static void logError(String method, String url, dynamic error) {
    developer.log('❌ CLIENT ERROR: $method $url', name: 'ApiService');
    developer.log('   Error: $error', name: 'ApiService');
  }
}

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';
  static final AuthService _authService = AuthService();

  static Future<Map<String, String>> get headers async {
    final token = await _authService.getToken();
    final baseHeaders = {'Content-Type': 'application/json'};

    if (token != null) {
      baseHeaders['Authorization'] = 'Bearer $token';
    }

    return baseHeaders;
  }

  // 카탈로그 관련 API
  static Future<List<Catalog>> getCatalogs() async {
    final url = '$baseUrl/catalogs/';
    final stopwatch = Stopwatch()..start();

    try {
      final requestHeaders = await headers;
      ApiLogger.logRequest('GET', url, requestHeaders);

      final response = await http.get(Uri.parse(url), headers: requestHeaders);

      stopwatch.stop();
      ApiLogger.logResponse(
        response.statusCode,
        url,
        response.body,
        stopwatch.elapsed,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Catalog.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        await _authService.clearToken();
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        throw Exception('카탈로그 목록을 불러오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      ApiLogger.logError('GET', url, e);
      throw Exception('네트워크 오류: $e');
    }
  }

  static Future<Catalog> getCatalog(String catalogId) async {
    try {
      final requestHeaders = await headers;
      final response = await http.get(
        Uri.parse('$baseUrl/catalogs/$catalogId'),
        headers: requestHeaders,
      );

      if (response.statusCode == 200) {
        return Catalog.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        await _authService.clearToken();
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        throw Exception('카탈로그를 불러오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  static Future<Catalog> createCatalog(CatalogCreate catalogCreate) async {
    final url = '$baseUrl/catalogs/';
    final body = json.encode(catalogCreate.toJson());
    final stopwatch = Stopwatch()..start();

    try {
      final requestHeaders = await headers;
      ApiLogger.logRequest('POST', url, requestHeaders, body);

      final response = await http.post(
        Uri.parse(url),
        headers: requestHeaders,
        body: body,
      );

      stopwatch.stop();
      ApiLogger.logResponse(
        response.statusCode,
        url,
        response.body,
        stopwatch.elapsed,
      );

      if (response.statusCode == 201) {
        return Catalog.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        await _authService.clearToken();
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        throw Exception('카탈로그 생성에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      ApiLogger.logError('POST', url, e);
      throw Exception('네트워크 오류: $e');
    }
  }

  static Future<void> deleteCatalog(String catalogId) async {
    try {
      final requestHeaders = await headers;
      final response = await http.delete(
        Uri.parse('$baseUrl/catalogs/$catalogId'),
        headers: requestHeaders,
      );

      if (response.statusCode == 401) {
        await _authService.clearToken();
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else if (response.statusCode != 200) {
        throw Exception('카탈로그 삭제에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  // 아이템 관련 API
  static Future<List<Item>> getItemsByCatalog(String catalogId) async {
    try {
      final requestHeaders = await headers;
      final response = await http.get(
        Uri.parse('$baseUrl/items/catalog/$catalogId'),
        headers: requestHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Item.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        await _authService.clearToken();
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        throw Exception('아이템 목록을 불러오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  static Future<Item> createItem(ItemCreate itemCreate) async {
    try {
      final requestHeaders = await headers;
      final response = await http.post(
        Uri.parse('$baseUrl/items/'),
        headers: requestHeaders,
        body: json.encode(itemCreate.toJson()),
      );

      if (response.statusCode == 201) {
        return Item.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        await _authService.clearToken();
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        throw Exception('아이템 생성에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  static Future<Item> toggleItemOwned(String itemId) async {
    final url = '$baseUrl/items/$itemId/toggle-owned';
    final stopwatch = Stopwatch()..start();

    try {
      final requestHeaders = await headers;
      ApiLogger.logRequest('PATCH', url, requestHeaders);

      final response = await http.patch(
        Uri.parse(url),
        headers: requestHeaders,
      );

      stopwatch.stop();
      ApiLogger.logResponse(
        response.statusCode,
        url,
        response.body,
        stopwatch.elapsed,
      );

      if (response.statusCode == 200) {
        return Item.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        await _authService.clearToken();
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        throw Exception('아이템 보유 상태 변경에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      ApiLogger.logError('PATCH', url, e);
      throw Exception('네트워크 오류: $e');
    }
  }

  static Future<void> deleteItem(String itemId) async {
    try {
      final requestHeaders = await headers;
      final response = await http.delete(
        Uri.parse('$baseUrl/items/$itemId'),
        headers: requestHeaders,
      );

      if (response.statusCode == 401) {
        await _authService.clearToken();
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else if (response.statusCode != 200) {
        throw Exception('아이템 삭제에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  // 서버 연결 테스트
  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse('http://localhost:8000/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
