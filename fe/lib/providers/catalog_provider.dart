import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../models/catalog.dart';
import '../services/api_service.dart';

class CatalogProvider with ChangeNotifier {
  List<Catalog> _catalogs = [];
  bool _isLoading = false;
  String? _error;

  List<Catalog> get catalogs => _catalogs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 특정 카탈로그 조회
  Catalog? getCatalogById(String catalogId) {
    try {
      return _catalogs.firstWhere((catalog) => catalog.catalogId == catalogId);
    } catch (e) {
      return null;
    }
  }

  Future<void> loadCatalogs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _catalogs = await ApiService.getCatalogs();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCatalog(CatalogCreate catalogCreate) async {
    try {
      final newCatalog = await ApiService.createCatalog(catalogCreate);
      _catalogs.add(newCatalog);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCatalog(String catalogId) async {
    try {
      await ApiService.deleteCatalog(catalogId);
      _catalogs.removeWhere((catalog) => catalog.catalogId == catalogId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // 특정 카탈로그의 수집률 업데이트
  Future<void> updateCatalogCompletionRate(String catalogId) async {
    try {
      developer.log('🔄 카탈로그 수집률 업데이트: $catalogId', name: 'CatalogProvider');

      // 서버에서 최신 카탈로그 정보 가져오기
      final updatedCatalog = await ApiService.getCatalog(catalogId);

      // 로컬 목록에서 해당 카탈로그 업데이트
      final index = _catalogs.indexWhere(
        (catalog) => catalog.catalogId == catalogId,
      );
      if (index != -1) {
        _catalogs[index] = updatedCatalog;

        developer.log(
          '✅ 수집률 업데이트 완료: ${updatedCatalog.title} - ${updatedCatalog.completionRate}%',
          name: 'CatalogProvider',
        );

        notifyListeners();
      }
    } catch (e) {
      developer.log('❌ 수집률 업데이트 실패: $e', name: 'CatalogProvider');
      // 수집률 업데이트 실패는 치명적이지 않으므로 에러를 설정하지 않음
    }
  }

  // 아이템 변경 시 호출되는 메서드
  void onItemChanged(String catalogId, {bool? owned, bool? deleted}) {
    final catalog = getCatalogById(catalogId);
    if (catalog == null) return;

    developer.log(
      '📊 아이템 변경 감지: ${catalog.title} (owned: $owned, deleted: $deleted)',
      name: 'CatalogProvider',
    );

    // 서버에서 최신 정보를 가져와 수집률 업데이트
    updateCatalogCompletionRate(catalogId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
