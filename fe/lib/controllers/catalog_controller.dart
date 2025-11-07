/**
 * 카탈로그 데이터 관리 컨트롤러
 * - GetX 반응형 상태 관리 사용
 * - catalog-api(FastAPI)와 연동하여 카탈로그/아이템 CRUD
 * - 사용자별 수집 상태 관리 (owned 체크박스)
 * - 카탈로그 저장/복사 기능 (다른 사용자 카탈로그를 내 컬렉션에 추가)
 */

import 'package:get/get.dart';
import '../models/catalog.dart';
import '../models/item.dart';
import '../services/api_service.dart';

class CatalogController extends GetxController {
  // API 서비스 인스턴스 (catalog-api 통신용)
  final ApiService _apiService = ApiService();

  // 반응형 상태 변수들 (GetX .obs로 UI 자동 업데이트)
  final RxList<Catalog> _myCatalogs = <Catalog>[].obs; // 내 카탈로그 목록 (홈 화면)
  final RxList<Catalog> _publicCatalogs = <Catalog>[].obs; // 공개 카탈로그 목록 (탐색 화면)
  final Rx<Catalog?> _currentCatalog = Rx<Catalog?>(null); // 현재 보고 있는 카탈로그
  final RxList<Item> _currentCatalogItems = <Item>[].obs; // 현재 카탈로그의 아이템 목록
  final RxBool _isLoading = false.obs; // 로딩 상태
  final RxString _error = ''.obs; // 에러 메시지
  final RxSet<String> _savedCatalogIds =
      <String>{}.obs; // 저장한 카탈로그 ID 집합 (중복 방지)
  final RxMap<String, String> _originalToCopiedIdMap =
      <String, String>{}.obs; // 원본→복사본 ID 매핑

  // Getter들 (UI에서 접근용)
  List<Catalog> get myCatalogs => _myCatalogs;
  List<Catalog> get publicCatalogs => _publicCatalogs;
  Catalog? get currentCatalog => _currentCatalog.value;
  List<Item> get currentCatalogItems => _currentCatalogItems;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;

  // 카탈로그 저장 여부 확인 (탐색 화면에서 저장 버튼 상태 결정)
  bool isCatalogSaved(String catalogId) => _savedCatalogIds.contains(catalogId);

  // 원본 카탈로그 ID로 복사본 카탈로그 ID 조회
  String? getCopiedCatalogId(String originalCatalogId) =>
      _originalToCopiedIdMap[originalCatalogId];

  /**
   * JWT 토큰 설정
   * - AuthController에서 로그인 성공 시 호출
   * - catalog-api 인증을 위해 API 서비스에 토큰 전달
   */
  void setApiToken(String? token) {
    _apiService.setToken(token);
  }

  // 이미지 업로드 메서드 추가
  Future<String?> uploadImage(String filePath) async {
    try {
      final uploadResult = await _apiService.uploadFile(filePath);
      return uploadResult['file_url'] as String?;
    } catch (e) {
      _error.value = e.toString();
      return null;
    }
  }

  Future<String?> uploadImageBytes(List<int> fileBytes, String fileName) async {
    try {
      final uploadResult =
          await _apiService.uploadFileBytes(fileBytes, fileName);
      return uploadResult['file_url'] as String?;
    } catch (e) {
      _error.value = e.toString();
      return null;
    }
  }

  /**
   * 내 카탈로그 목록 로드 (홈 화면용)
   * - catalog-api의 /api/user-catalogs/my-catalogs 엔드포인트 호출
   * - 내가 생성한 카탈로그 + 저장한 카탈로그(복사본) 모두 조회
   * - 저장된 카탈로그 매핑 정보 구축 (중복 저장 방지 및 UI 상태 관리용)
   */
  Future<void> loadMyCatalogs() async {
    _isLoading.value = true;
    _error.value = '';

    try {
      // catalog-api에서 내 카탈로그 목록 조회
      final data = await _apiService.getMyCatalogs();
      _myCatalogs.value = data.map((json) => Catalog.fromJson(json)).toList();

      // 저장된 카탈로그 ID들과 원본-복사본 매핑을 구축
      _savedCatalogIds.clear();
      _originalToCopiedIdMap.clear();

      for (final catalog in _myCatalogs) {
        if (catalog.originalCatalogId != null) {
          // 복사본 카탈로그인 경우 (다른 사용자 카탈로그를 저장한 것)
          _savedCatalogIds.add(catalog.originalCatalogId!); // 원본 ID를 저장됨으로 표시
          _originalToCopiedIdMap[catalog.originalCatalogId!] =
              catalog.catalogId; // 원본→복사본 매핑
        }
      }

      _error.value = '';
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadPublicCatalogs({String? category}) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      final data = await _apiService.getPublicCatalogs(category: category);
      _publicCatalogs.value =
          data.map((json) => Catalog.fromJson(json)).toList();

      // 저장 상태는 이미 loadMyCatalogs에서 구축된 매핑을 사용

      _error.value = '';
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadCatalog(String catalogId) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      final data = await _apiService.getCatalog(catalogId);
      _currentCatalog.value = Catalog.fromJson(data);
      await loadCatalogItems(catalogId);
      _error.value = '';
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadCatalogItems(String catalogId) async {
    try {
      final data = await _apiService.getItemsByCatalog(catalogId);
      _currentCatalogItems.value =
          data.map((json) => Item.fromJson(json)).toList();
    } catch (e) {
      _error.value = e.toString();
    }
  }

  Future<Catalog?> createCatalog({
    required String title,
    required String description,
    String category = '미분류',
    List<String>? tags,
    String visibility = 'public',
    String? thumbnailUrl,
  }) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      final data = await _apiService.createCatalog(
        title: title,
        description: description,
        category: category,
        tags: tags,
        visibility: visibility,
        thumbnailUrl: thumbnailUrl,
      );
      final catalog = Catalog.fromJson(data);
      _myCatalogs.add(catalog);
      _error.value = '';
      return catalog;
    } catch (e) {
      _error.value = e.toString();
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> updateCatalog(
    String catalogId, {
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    String? visibility,
    String? thumbnailUrl,
  }) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      final data = await _apiService.updateCatalog(
        catalogId,
        title: title,
        description: description,
        category: category,
        tags: tags,
        visibility: visibility,
        thumbnailUrl: thumbnailUrl,
      );
      final catalog = Catalog.fromJson(data);

      final index = _myCatalogs.indexWhere((c) => c.catalogId == catalogId);
      if (index != -1) {
        _myCatalogs[index] = catalog;
      }

      if (_currentCatalog.value?.catalogId == catalogId) {
        _currentCatalog.value = catalog;
      }

      _error.value = '';
      return true;
    } catch (e) {
      _error.value = e.toString();
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> deleteCatalog(String catalogId) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      await _apiService.deleteCatalog(catalogId);

      // 삭제할 카탈로그 찾기
      final catalogToDelete =
          _myCatalogs.firstWhereOrNull((c) => c.catalogId == catalogId);

      // 내 카탈로그 목록에서 제거
      _myCatalogs.removeWhere((c) => c.catalogId == catalogId);

      // 현재 카탈로그가 삭제된 카탈로그인 경우 초기화
      if (_currentCatalog.value?.catalogId == catalogId) {
        _currentCatalog.value = null;
        _currentCatalogItems.clear();
      }

      // 저장된 카탈로그(복사본)를 삭제하는 경우, 원본 카탈로그의 저장 상태도 제거
      if (catalogToDelete?.originalCatalogId != null) {
        final originalCatalogId = catalogToDelete!.originalCatalogId!;
        _savedCatalogIds.remove(originalCatalogId);
        _originalToCopiedIdMap.remove(originalCatalogId);
      }

      _error.value = '';
      return true;
    } catch (e) {
      _error.value = e.toString();
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> saveCatalog(String catalogId) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      await _apiService.saveCatalog(catalogId);
      // 저장 성공 시 내 카탈로그를 다시 로드하여 상태 업데이트
      await loadMyCatalogs();
      _error.value = '';
      return true;
    } catch (e) {
      _error.value = e.toString();
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> checkCatalogOwnership(String catalogId) async {
    try {
      final result = await _apiService.checkCatalogOwnership(catalogId);
      return result['is_owned'] ?? false;
    } catch (e) {
      _error.value = e.toString();
      return false;
    }
  }

  Future<bool> checkCatalogSaved(String originalCatalogId) async {
    try {
      final result = await _apiService.checkCatalogSaved(originalCatalogId);
      final isSaved = result['is_saved'] ?? false;
      final copiedCatalogId = result['copied_catalog_id'] as String?;

      // 저장 상태를 로컬 캐시에도 반영
      if (isSaved) {
        _savedCatalogIds.add(originalCatalogId);
        if (copiedCatalogId != null) {
          _originalToCopiedIdMap[originalCatalogId] = copiedCatalogId;
        }
      } else {
        _savedCatalogIds.remove(originalCatalogId);
        _originalToCopiedIdMap.remove(originalCatalogId);
      }

      return isSaved;
    } catch (e) {
      _error.value = e.toString();
      return false;
    }
  }

  Future<bool> createItem({
    required String catalogId,
    required String name,
    required String description,
    String? imageUrl,
    Map<String, String>? userFields,
  }) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      final data = await _apiService.createItem(
        catalogId: catalogId,
        name: name,
        description: description,
        imageUrl: imageUrl,
        userFields: userFields,
      );
      final item = Item.fromJson(data);
      _currentCatalogItems.add(item);

      // 카탈로그 정보 갱신
      if (_currentCatalog.value?.catalogId == catalogId) {
        await loadCatalog(catalogId);
      }

      _error.value = '';
      return true;
    } catch (e) {
      _error.value = e.toString();
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /**
   * 아이템 보유 상태 토글 (핵심 기능)
   * - 사용자가 체크박스 클릭 시 호출
   * - catalog-api의 /api/items/{itemId}/toggle-owned 엔드포인트 호출
   * - owned 상태를 True ↔ False로 변경
   * - UI 즉시 업데이트 후 카탈로그 수집률 갱신
   */
  Future<bool> toggleItemOwned(String itemId) async {
    try {
      // catalog-api에 아이템 상태 토글 요청
      final data = await _apiService.toggleItemOwned(itemId);
      final updatedItem = Item.fromJson(data);

      // 현재 아이템 목록에서 해당 아이템 업데이트
      final index = _currentCatalogItems.indexWhere((i) => i.itemId == itemId);
      if (index != -1) {
        _currentCatalogItems[index] = updatedItem; // UI 즉시 반영
      }

      // 카탈로그 정보 갱신 (수집률 업데이트)
      if (_currentCatalog.value != null) {
        await loadCatalog(_currentCatalog.value!.catalogId);
      }

      return true; // 토글 성공
    } catch (e) {
      _error.value = e.toString();
      return false; // 토글 실패
    }
  }

  Future<bool> deleteItem(String itemId) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      await _apiService.deleteItem(itemId);
      _currentCatalogItems.removeWhere((i) => i.itemId == itemId);

      // 카탈로그 정보 갱신
      if (_currentCatalog.value != null) {
        await loadCatalog(_currentCatalog.value!.catalogId);
      }

      _error.value = '';
      return true;
    } catch (e) {
      _error.value = e.toString();
      return false;
    } finally {
      _isLoading.value = false;
    }
  }
}
