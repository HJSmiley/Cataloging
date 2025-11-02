import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/catalog.dart';
import '../models/item.dart';

class ApiLogger {
  static void logRequest(
    String method,
    String url,
    Map<String, String> headers, [
    String? body,
  ]) {
    print('🔵 CLIENT REQUEST: $method $url');
    print('   Headers: $headers');
    if (body != null) {
      print('   Body: $body');
    }
  }

  static void logResponse(
    int statusCode,
    String url,
    String responseBody, [
    Duration? duration,
  ]) {
    print(
      '🔴 CLIENT RESPONSE: $statusCode $url ${duration != null ? '(${duration.inMilliseconds}ms)' : ''}',
    );
    if (responseBody.isNotEmpty) {
      try {
        final jsonData = json.decode(responseBody);
        final prettyJson = JsonEncoder.withIndent('  ').convert(jsonData);
        print('   Response: $prettyJson');
      } catch (e) {
        print('   Response: $responseBody');
      }
    }
  }

  static void logError(String method, String url, dynamic error) {
    print('❌ CLIENT ERROR: $method $url');
    print('   Error: $error');
  }
}

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';
  static const String userId = 'flutter-user-1'; // 개발용 임시 사용자 ID

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': userId,
  };

  // 카탈로그 관련 API
  static Future<List<Catalog>> getCatalogs() async {
    final url = '$baseUrl/catalogs/';
    final stopwatch = Stopwatch()..start();

    try {
      ApiLogger.logRequest('GET', url, headers);

      final response = await http.get(Uri.parse(url), headers: headers);

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
      final response = await http.get(
        Uri.parse('$baseUrl/catalogs/$catalogId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Catalog.fromJson(json.decode(response.body));
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
      ApiLogger.logRequest('POST', url, headers, body);

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
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
      final response = await http.delete(
        Uri.parse('$baseUrl/catalogs/$catalogId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('카탈로그 삭제에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  // 아이템 관련 API
  static Future<List<Item>> getItemsByCatalog(String catalogId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/items/catalog/$catalogId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Item.fromJson(json)).toList();
      } else {
        throw Exception('아이템 목록을 불러오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  static Future<Item> createItem(ItemCreate itemCreate) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/items/'),
        headers: headers,
        body: json.encode(itemCreate.toJson()),
      );

      if (response.statusCode == 201) {
        return Item.fromJson(json.decode(response.body));
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
      ApiLogger.logRequest('PATCH', url, headers);

      final response = await http.patch(Uri.parse(url), headers: headers);

      stopwatch.stop();
      ApiLogger.logResponse(
        response.statusCode,
        url,
        response.body,
        stopwatch.elapsed,
      );

      if (response.statusCode == 200) {
        return Item.fromJson(json.decode(response.body));
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
      final response = await http.delete(
        Uri.parse('$baseUrl/items/$itemId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
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
