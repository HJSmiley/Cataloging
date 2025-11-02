import 'package:flutter/foundation.dart';
import '../models/catalog.dart';
import '../services/api_service.dart';

class CatalogProvider with ChangeNotifier {
  List<Catalog> _catalogs = [];
  bool _isLoading = false;
  String? _error;

  List<Catalog> get catalogs => _catalogs;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
