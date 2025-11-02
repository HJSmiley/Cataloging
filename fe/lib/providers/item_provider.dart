import 'package:flutter/foundation.dart';
import '../models/item.dart';
import '../services/api_service.dart';

class ItemProvider with ChangeNotifier {
  List<Item> _items = [];
  bool _isLoading = false;
  String? _error;

  List<Item> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
      final newItem = await ApiService.createItem(itemCreate);
      _items.add(newItem);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleItemOwned(String itemId) async {
    try {
      final updatedItem = await ApiService.toggleItemOwned(itemId);
      final index = _items.indexWhere((item) => item.itemId == itemId);
      if (index != -1) {
        _items[index] = updatedItem;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await ApiService.deleteItem(itemId);
      _items.removeWhere((item) => item.itemId == itemId);
      notifyListeners();
    } catch (e) {
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
