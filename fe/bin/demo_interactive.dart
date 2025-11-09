#!/usr/bin/env dart
/**
 * 카탈로깅 앱 대화형 데모 CLI
 * - Flutter의 ApiService를 직접 사용 (순수 Dart)
 * - 서버 응답 로그 출력
 * - 클라이언트 상태 출력
 */

import 'dart:io';
import 'dart:convert';
import 'package:cataloging/services/api_service.dart';
import 'package:cataloging/models/user.dart';
import 'package:cataloging/models/catalog.dart';
import 'package:cataloging/models/item.dart';

// ANSI 색상
const reset = '\x1B[0m';
const red = '\x1B[31m';
const green = '\x1B[32m';
const yellow = '\x1B[33m';
const blue = '\x1B[34m';
const magenta = '\x1B[35m';
const cyan = '\x1B[36m';
const bold = '\x1B[1m';
const dim = '\x1B[2m';

// 클라이언트 상태
class ClientState {
  User? currentUser;
  String? token;
  List<Catalog> myCatalogs = [];
  Catalog? currentCatalog;
  List<Item> currentItems = [];

  void clear() {
    currentUser = null;
    token = null;
    myCatalogs.clear();
    currentCatalog = null;
    currentItems.clear();
  }
}

final clientState = ClientState();
final apiService = ApiService(); // 기본 URL 사용 (localhost)

void main() async {
  printHeader();

  while (true) {
    printMenu();
    final choice = stdin.readLineSync();

    try {
      switch (choice) {
        case '1':
          await login();
          break;
        case '2':
          await getUserInfo();
          break;
        case '3':
          await createCatalog();
          break;
        case '4':
          await getMyCatalogs();
          break;
        case '6':
          await getCatalogDetail();
          break;
        case '7':
          await createItem();
          break;
        case '8':
          await getItems();
          break;
        case '9':
          await toggleItemOwned();
          break;
        case 's':
          printClientState();
          break;
        case 'c':
          clearState();
          break;
        case 'q':
          print('\n${green}데모를 종료합니다.$reset\n');
          exit(0);
        default:
          print('${red}잘못된 선택입니다.$reset\n');
      }
    } catch (e) {
      printError('오류 발생: $e');
    }

    print('\n${dim}계속하려면 Enter를 누르세요...$reset');
    stdin.readLineSync();
  }
}

void printHeader() {
  print('$bold$cyan');
  print('╔════════════════════════════════════════════════════════════╗');
  print('║     카탈로깅 앱 - 대화형 데모 CLI                          ║');
  print('║     Flutter ApiService 직접 사용 (순수 Dart)               ║');
  print('╚════════════════════════════════════════════════════════════╝');
  print('$reset\n');
}

void printMenu() {
  print(
      '\n$bold$blue━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$reset');
  print('$bold$cyan[메뉴]$reset');
  print('  ${bold}인증$reset');
  print('    1. 로그인');
  print('    2. 사용자 정보 조회');
  print('  ${bold}카탈로그$reset');
  print('    3. 카탈로그 생성');
  print('    4. 내 카탈로그 목록');
  print('    6. 카탈로그 상세 조회');
  print('  ${bold}아이템$reset');
  print('    7. 아이템 생성');
  print('    8. 아이템 목록 조회');
  print('    9. 아이템 보유 상태 토글');
  print('  ${bold}기타$reset');
  print('    s. 클라이언트 상태 출력');
  print('    c. 상태 초기화');
  print('    q. 종료');
  print(
      '$bold$blue━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$reset');
  stdout.write('\n선택: ');
}

// ========== 1. 로그인 ==========
Future<void> login() async {
  printSection('1️⃣ 로그인');

  stdout.write('이메일 (기본값: collector@example.com): ');
  final email = stdin.readLineSync()?.trim();
  final finalEmail = email?.isEmpty ?? true ? 'collector@example.com' : email!;

  stdout.write('닉네임 (기본값: 수집왕): ');
  final nickname = stdin.readLineSync()?.trim();
  final finalNickname = nickname?.isEmpty ?? true ? '수집왕' : nickname!;

  printApiCall('POST', '${apiService.userApiBaseUrl}/api/auth/dev-login');
  printRequestBody({'email': finalEmail, 'nickname': finalNickname});

  print('\n${yellow}⏳ 서버에 요청 중...$reset\n');

  final response = await apiService.devLogin(finalEmail, finalNickname);

  printServerResponse('로그인 응답', response);

  // 클라이언트 상태 업데이트
  clientState.token = response['accessToken'] as String;
  clientState.currentUser =
      User.fromJson(response['user'] as Map<String, dynamic>);
  apiService.setToken(clientState.token);

  printClientStateUpdate('토큰 저장 및 사용자 정보 설정', {
    'token': '${clientState.token!.substring(0, 30)}...',
    'user': {
      'id': clientState.currentUser!.id,
      'email': clientState.currentUser!.email,
      'nickname': clientState.currentUser!.nickname,
    }
  });
}

// ========== 2. 사용자 정보 조회 ==========
Future<void> getUserInfo() async {
  printSection('2️⃣ 사용자 정보 조회');

  if (clientState.token == null) {
    printError('먼저 로그인해주세요.');
    return;
  }

  printApiCall('GET', '${apiService.userApiBaseUrl}/api/users/me');
  printRequestHeaders(
      {'Authorization': 'Bearer ${clientState.token!.substring(0, 30)}...'});

  print('\n${yellow}⏳ 서버에 요청 중...$reset\n');

  final userData = await apiService.getCurrentUser();

  printServerResponse('사용자 정보', userData);

  clientState.currentUser = User.fromJson(userData);

  printClientStateUpdate('사용자 정보 업데이트', {
    'id': clientState.currentUser!.id,
    'email': clientState.currentUser!.email,
    'nickname': clientState.currentUser!.nickname,
  });
}

// ========== 3. 카탈로그 생성 ==========
Future<void> createCatalog() async {
  printSection('3️⃣ 카탈로그 생성');

  if (clientState.token == null) {
    printError('먼저 로그인해주세요.');
    return;
  }

  stdout.write('제목 (기본값: 포켓몬 카드 컬렉션): ');
  final title = stdin.readLineSync()?.trim();
  final finalTitle = title?.isEmpty ?? true ? '포켓몬 카드 컬렉션' : title!;

  printApiCall('POST', '${apiService.catalogApiBaseUrl}/api/catalogs');
  printRequestBody({
    'title': finalTitle,
    'description': '1세대 포켓몬 카드 151종 수집',
    'category': '카드',
  });

  print('\n${yellow}⏳ 서버에 요청 중...$reset\n');

  final catalogData = await apiService.createCatalog(
    title: finalTitle,
    description: '1세대 포켓몬 카드 151종 수집',
    category: '카드',
  );

  printServerResponse('카탈로그 생성 응답', catalogData);

  final catalog = Catalog.fromJson(catalogData);
  clientState.myCatalogs.add(catalog);
  clientState.currentCatalog = catalog;

  printClientStateUpdate('카탈로그 목록에 추가', {
    'catalog_id': catalog.catalogId,
    'title': catalog.title,
    'total_catalogs': clientState.myCatalogs.length,
  });
}

// ========== 4. 내 카탈로그 목록 ==========
Future<void> getMyCatalogs() async {
  printSection('4️⃣ 내 카탈로그 목록');

  if (clientState.token == null) {
    printError('먼저 로그인해주세요.');
    return;
  }

  printApiCall(
      'GET', '${apiService.catalogApiBaseUrl}/api/user-catalogs/my-catalogs');

  print('\n${yellow}⏳ 서버에 요청 중...$reset\n');

  final catalogsData = await apiService.getMyCatalogs();

  printServerResponse('내 카탈로그 목록 (${catalogsData.length}개)', catalogsData);

  clientState.myCatalogs =
      catalogsData.map((json) => Catalog.fromJson(json)).toList();

  printClientStateUpdate('카탈로그 목록 업데이트', {
    'total_count': clientState.myCatalogs.length,
    'catalogs': clientState.myCatalogs.map((c) => c.title).toList(),
  });
}

// ========== 6. 카탈로그 상세 조회 ==========
Future<void> getCatalogDetail() async {
  printSection('6️⃣ 카탈로그 상세 조회');

  if (clientState.myCatalogs.isEmpty) {
    printError('먼저 카탈로그를 생성하거나 목록을 조회해주세요.');
    return;
  }

  print('\n${cyan}사용 가능한 카탈로그:$reset');
  for (var i = 0; i < clientState.myCatalogs.length; i++) {
    print('  ${i + 1}. ${clientState.myCatalogs[i].title}');
  }

  stdout.write('\n선택 (기본값: 1): ');
  final choice = stdin.readLineSync()?.trim();
  final index = int.tryParse(choice ?? '1') ?? 1;

  if (index < 1 || index > clientState.myCatalogs.length) {
    printError('잘못된 선택입니다.');
    return;
  }

  final catalogId = clientState.myCatalogs[index - 1].catalogId;

  printApiCall(
      'GET', '${apiService.catalogApiBaseUrl}/api/catalogs/$catalogId');

  print('\n${yellow}⏳ 서버에 요청 중...$reset\n');

  final catalogData = await apiService.getCatalog(catalogId);

  printServerResponse('카탈로그 상세 정보', catalogData);

  clientState.currentCatalog = Catalog.fromJson(catalogData);

  printClientStateUpdate('현재 카탈로그 설정', {
    'catalog_id': clientState.currentCatalog!.catalogId,
    'title': clientState.currentCatalog!.title,
    'item_count': clientState.currentCatalog!.itemCount,
  });
}

// ========== 7. 아이템 생성 ==========
Future<void> createItem() async {
  printSection('7️⃣ 아이템 생성');

  if (clientState.currentCatalog == null) {
    printError('먼저 카탈로그를 선택해주세요. (메뉴 6)');
    return;
  }

  stdout.write('아이템 이름 (기본값: 피카츄): ');
  final name = stdin.readLineSync()?.trim();
  final finalName = name?.isEmpty ?? true ? '피카츄' : name!;

  printApiCall('POST', '${apiService.catalogApiBaseUrl}/api/items');
  printRequestBody({
    'catalog_id': clientState.currentCatalog!.catalogId,
    'name': finalName,
    'description': '전기 타입 포켓몬',
  });

  print('\n${yellow}⏳ 서버에 요청 중...$reset\n');

  final itemData = await apiService.createItem(
    catalogId: clientState.currentCatalog!.catalogId,
    name: finalName,
    description: '전기 타입 포켓몬',
    userFields: {'number': '025'},
  );

  printServerResponse('아이템 생성 응답', itemData);

  final item = Item.fromJson(itemData);
  clientState.currentItems.add(item);

  printClientStateUpdate('아이템 목록에 추가', {
    'item_id': item.itemId,
    'name': item.name,
    'owned': item.owned,
  });
}

// ========== 8. 아이템 목록 조회 ==========
Future<void> getItems() async {
  printSection('8️⃣ 아이템 목록 조회');

  if (clientState.currentCatalog == null) {
    printError('먼저 카탈로그를 선택해주세요. (메뉴 6)');
    return;
  }

  final catalogId = clientState.currentCatalog!.catalogId;

  printApiCall(
      'GET', '${apiService.catalogApiBaseUrl}/api/items/catalog/$catalogId');

  print('\n${yellow}⏳ 서버에 요청 중...$reset\n');

  final itemsData = await apiService.getItemsByCatalog(catalogId);

  printServerResponse('아이템 목록 (${itemsData.length}개)', itemsData);

  clientState.currentItems =
      itemsData.map((json) => Item.fromJson(json)).toList();

  printClientStateUpdate('아이템 목록 업데이트', {
    'total_count': clientState.currentItems.length,
    'items': clientState.currentItems
        .map((item) => {
              'name': item.name,
              'owned': item.owned,
            })
        .toList(),
  });
}

// ========== 9. 아이템 보유 상태 토글 ==========
Future<void> toggleItemOwned() async {
  printSection('9️⃣ 아이템 보유 상태 토글');

  if (clientState.currentItems.isEmpty) {
    printError('먼저 아이템 목록을 조회해주세요. (메뉴 8)');
    return;
  }

  print('\n${cyan}사용 가능한 아이템:$reset');
  for (var i = 0; i < clientState.currentItems.length; i++) {
    final item = clientState.currentItems[i];
    final status = item.owned ? '✅' : '❌';
    print('  ${i + 1}. $status ${item.name}');
  }

  stdout.write('\n선택 (기본값: 1): ');
  final choice = stdin.readLineSync()?.trim();
  final index = int.tryParse(choice ?? '1') ?? 1;

  if (index < 1 || index > clientState.currentItems.length) {
    printError('잘못된 선택입니다.');
    return;
  }

  final item = clientState.currentItems[index - 1];
  final itemId = item.itemId;

  printApiCall('PATCH',
      '${apiService.catalogApiBaseUrl}/api/items/$itemId/toggle-owned');

  print('\n${yellow}⏳ 서버에 요청 중...$reset\n');

  final toggledData = await apiService.toggleItemOwned(itemId);

  printServerResponse('토글 응답', toggledData);

  final toggledItem = Item.fromJson(toggledData);
  clientState.currentItems[index - 1] = toggledItem;

  printClientStateUpdate('아이템 상태 업데이트', {
    'item_id': toggledItem.itemId,
    'name': toggledItem.name,
    'owned': '${item.owned} → ${toggledItem.owned}',
  });
}

// ========== 유틸리티 함수 ==========

void printSection(String title) {
  print('\n$bold$magenta');
  print('╔════════════════════════════════════════════════════════════╗');
  print('║  $title');
  print('╚════════════════════════════════════════════════════════════╝');
  print('$reset\n');
}

void printApiCall(String method, String url) {
  print('$bold$cyan[API 호출]$reset');
  print('  $bold$method$reset $url');
}

void printRequestHeaders(Map<String, String> headers) {
  print('\n$bold$cyan[요청 헤더]$reset');
  headers.forEach((key, value) {
    print('  $key: $value');
  });
}

void printRequestBody(Map<String, dynamic> body) {
  print('\n$bold$cyan[요청 본문]$reset');
  print('  ${jsonEncode(body)}');
}

void printServerResponse(String title, dynamic data) {
  print('$bold$green[서버 응답] $title$reset');
  final jsonStr = JsonEncoder.withIndent('  ').convert(data);
  print('$green$jsonStr$reset');
}

void printClientStateUpdate(String title, Map<String, dynamic> state) {
  print('\n$bold$yellow[클라이언트 상태 업데이트] $title$reset');
  final jsonStr = JsonEncoder.withIndent('  ').convert(state);
  print('$yellow$jsonStr$reset');
}

void printClientState() {
  printSection('📊 클라이언트 상태');

  print('$bold$cyan[인증 상태]$reset');
  if (clientState.token != null) {
    print('  ✅ 로그인됨');
    print('  Token: ${clientState.token!.substring(0, 30)}...');
    if (clientState.currentUser != null) {
      print(
          '  User: ${clientState.currentUser!.nickname} (${clientState.currentUser!.email})');
    }
  } else {
    print('  ❌ 로그인 안 됨');
  }

  print('\n$bold$cyan[카탈로그 상태]$reset');
  print('  내 카탈로그: ${clientState.myCatalogs.length}개');
  for (var catalog in clientState.myCatalogs) {
    print('    - ${catalog.title}');
  }

  if (clientState.currentCatalog != null) {
    print('  현재 카탈로그: ${clientState.currentCatalog!.title}');
  }

  print('\n$bold$cyan[아이템 상태]$reset');
  print('  현재 아이템: ${clientState.currentItems.length}개');
  for (var item in clientState.currentItems) {
    final status = item.owned ? '✅' : '❌';
    print('    $status ${item.name}');
  }
}

void clearState() {
  clientState.clear();
  apiService.setToken(null);
  print('\n${green}✓ 클라이언트 상태가 초기화되었습니다.$reset');
}

void printError(String message) {
  print('\n${red}❌ $message$reset');
}
