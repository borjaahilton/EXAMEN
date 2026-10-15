import 'package:flutter/material.dart';
import '../data/models/product_model.dart';
import '../data/services/product_service.dart';

class CatalogProvider extends ChangeNotifier {
  final ProductService _productService;

  List<ProductModel> _allProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  CatalogProvider({ProductService? productService})
      : _productService = productService ?? ProductService();

  List<ProductModel> get products {
    if (_searchQuery.trim().isEmpty) {
      return _allProducts;
    }
    return _allProducts.where((p) {
      final nameMatches = p.nombre.toLowerCase().contains(_searchQuery.toLowerCase());
      final descMatches = p.descripcion.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatches || descMatches;
    }).toList();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchCatalog({bool soloDisponibles = true, String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allProducts = await _productService.getProducts(
        soloDisponibles: soloDisponibles,
        token: token,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
