import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../models/item.dart';
import '../services/api_service.dart';

class ItemProvider with ChangeNotifier {
  List<Item> _items = [];
  bool _isLoading = false;
  String? _error;

  // CatalogProvider 참조를 위한 콜백
  Function(String catalogId, {bool? owned, bool? deleted})? _onItemChanged;

  List<Item> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // CatalogProvider와 연동을 위한 콜백 설정
  void setOnItemChangedCallback(
    Function(String catalogId, {bool? owned, bool? deleted}) callback,
  ) {
    _onItemChanged = callback;
  }

  Future<void> loadItems(String catalogId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await ApiService.getItemsByCatalog(catalogId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createItem(ItemCreate itemCreate) async {
    try {
      developer.log('➕ 아이템 생성: ${itemCreate.name}', name: 'ItemProvider');

      final newItem = await ApiService.createItem(itemCreate);
      _items.add(newItem);
      notifyListeners();

      // CatalogProvider에 아이템 추가 알림
      _onItemChanged?.call(itemCreate.catalogId, owned: newItem.owned);

      developer.log('✅ 아이템 생성 완료: ${newItem.name}', name: 'ItemProvider');
    } catch (e) {
      developer.log('❌ 아이템 생성 실패: $e', name: 'ItemProvider');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleItemOwned(String itemId) async {
    try {
      // 기존 아이템 정보 저장 (로깅용)
      final oldItem = _items.firstWhere((item) => item.itemId == itemId);

      developer.log(
        '🔄 아이템 보유 상태 토글: ${oldItem.name} (${oldItem.owned ? '보유' : '미보유'} → ${!oldItem.owned ? '보유' : '미보유'})',
        name: 'ItemProvider',
      );

      final updatedItem = await ApiService.toggleItemOwned(itemId);
      final index = _items.indexWhere((item) => item.itemId == itemId);
      if (index != -1) {
        _items[index] = updatedItem;
        notifyListeners();

        // CatalogProvider에 보유 상태 변경 알림
        _onItemChanged?.call(updatedItem.catalogId, owned: updatedItem.owned);

        developer.log(
          '✅ 보유 상태 변경 완료: ${updatedItem.name} - ${updatedItem.owned ? '보유' : '미보유'}',
          name: 'ItemProvider',
        );
      }
    } catch (e) {
      developer.log('❌ 보유 상태 변경 실패: $e', name: 'ItemProvider');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      // 삭제할 아이템 정보 저장
      final itemToDelete = _items.firstWhere((item) => item.itemId == itemId);

      developer.log('🗑️ 아이템 삭제: ${itemToDelete.name}', name: 'ItemProvider');

      await ApiService.deleteItem(itemId);
      _items.removeWhere((item) => item.itemId == itemId);
      notifyListeners();

      // CatalogProvider에 아이템 삭제 알림
      _onItemChanged?.call(itemToDelete.catalogId, deleted: true);

      developer.log('✅ 아이템 삭제 완료: ${itemToDelete.name}', name: 'ItemProvider');
    } catch (e) {
      developer.log('❌ 아이템 삭제 실패: $e', name: 'ItemProvider');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
