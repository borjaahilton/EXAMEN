import 'package:flutter/material.dart';
import '../data/models/order_model.dart';
import '../data/services/order_service.dart';
import 'cart_provider.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService;

  List<OrderModel> _myOrders = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  OrderModel? _lastCreatedOrder;

  OrderProvider({OrderService? orderService})
      : _orderService = orderService ?? OrderService();

  List<OrderModel> get myOrders => _myOrders;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  OrderModel? get lastCreatedOrder => _lastCreatedOrder;

  Future<void> fetchMyOrders(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myOrders = await _orderService.getMyOrders(token);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitOrder({
    required String tipoEntrega,
    String? notas,
    required List<CartItem> cartItems,
    required String token,
  }) async {
    if (cartItems.isEmpty) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final itemsPayload = cartItems.map((item) {
        return {
          'producto': item.product.id,
          'producto_id': item.product.id,
          'cantidad': item.quantity,
        };
      }).toList();

      final order = await _orderService.createOrder(
        tipoEntrega: tipoEntrega,
        notas: notas,
        items: itemsPayload,
        token: token,
      );

      _lastCreatedOrder = order;
      _myOrders.insert(0, order);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
}
