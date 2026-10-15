import 'package:flutter/material.dart';
import '../data/models/order_model.dart';
import '../data/models/product_model.dart';
import '../data/services/order_service.dart';
import '../data/services/product_service.dart';

class AdminProvider extends ChangeNotifier {
  final OrderService _orderService;
  final ProductService _productService;

  List<OrderModel> _orders = [];
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  AdminProvider({
    OrderService? orderService,
    ProductService? productService,
  })  : _orderService = orderService ?? OrderService(),
        _productService = productService ?? ProductService();

  List<OrderModel> get orders => _orders;
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // KPIs
  int get pendingOrdersCount => _orders.where((o) => o.estado == 'pendiente').length;
  int get cookingOrdersCount => _orders.where((o) => o.estado == 'en preparacion').length;
  double get totalRevenue => _orders.fold(0.0, (sum, o) => sum + o.total);

  Future<void> fetchAdminData(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _orderService.getAdminOrders(token),
        _productService.getProducts(soloDisponibles: false, token: token),
      ]);

      _orders = results[0] as List<OrderModel>;
      _products = results[1] as List<ProductModel>;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus(int orderId, String newStatus, String token) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus, token);
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final old = _orders[index];
        _orders[index] = OrderModel(
          id: old.id,
          clienteId: old.clienteId,
          fecha: old.fecha,
          estado: newStatus,
          tipoEntrega: old.tipoEntrega,
          total: old.total,
          notas: old.notas,
          items: old.items,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createProduct({
    required String nombre,
    required String descripcion,
    required double precio,
    required bool disponible,
    String? imagenUrl,
    required String token,
  }) async {
    try {
      final newProd = await _productService.createProduct(
        nombre: nombre,
        descripcion: descripcion,
        precio: precio,
        disponible: disponible,
        imagenUrl: imagenUrl,
        token: token,
      );
      _products.insert(0, newProd);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleProductAvailability(ProductModel product, String token) async {
    try {
      final updated = await _productService.updateProduct(
        product.id,
        data: {'disponible': !product.disponible},
        token: token,
      );
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProductPrice(int productId, double newPrice, String token) async {
    try {
      final updated = await _productService.updateProduct(
        productId,
        data: {'precio': newPrice},
        token: token,
      );
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
