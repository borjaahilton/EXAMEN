import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/order_model.dart';

class OrderService {
  final ApiClient _apiClient;

  OrderService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Envía un nuevo pedido a la API Django (/orders/)
  Future<OrderModel> createOrder({
    required String tipoEntrega,
    String? notas,
    required List<Map<String, dynamic>> items,
    required String token,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.orders,
      token: token,
      body: {
        'items': items,
      },
    );

    final map = (response is Map && response.containsKey('data'))
        ? response['data'] as Map<String, dynamic>
        : response as Map<String, dynamic>;

    return OrderModel.fromJson(map);
  }

  /// Consulta el historial del cliente autenticado (/orders/mine/)
  Future<List<OrderModel>> getMyOrders(String token) async {
    final response = await _apiClient.get(ApiEndpoints.myOrders, token: token);

    List<dynamic> rawList = [];
    if (response is List) {
      rawList = response;
    } else if (response is Map && response['data'] != null) {
      rawList = response['data'] as List<dynamic>;
    } else if (response is Map && response['results'] != null) {
      rawList = response['results'] as List<dynamic>;
    }

    return rawList
        .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Admin: Consulta todos los pedidos del restaurante (/admin/orders/)
  Future<List<OrderModel>> getAdminOrders(String token) async {
    final response = await _apiClient.get(ApiEndpoints.adminOrders, token: token);

    List<dynamic> rawList = [];
    if (response is List) {
      rawList = response;
    } else if (response is Map && response['data'] != null) {
      rawList = response['data'] as List<dynamic>;
    } else if (response is Map && response['results'] != null) {
      rawList = response['results'] as List<dynamic>;
    }

    return rawList
        .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Admin: Actualizar el estado de un pedido en Django (`/orders/<id>/status/`)
  Future<void> updateOrderStatus(int orderId, String newStatus, String token) async {
    await _apiClient.patch(
      ApiEndpoints.orderStatus(orderId),
      token: token,
      body: {
        'estado': newStatus,
      },
    );
  }
}
