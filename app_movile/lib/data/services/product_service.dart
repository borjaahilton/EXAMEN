import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/product_model.dart';

class ProductService {
  final ApiClient _apiClient;

  ProductService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Obtiene la lista de platos desde la API Django (si token es admin, Django retorna todos)
  Future<List<ProductModel>> getProducts({bool soloDisponibles = true, String? token}) async {
    final response = await _apiClient.get(ApiEndpoints.products, token: token);

    List<dynamic> rawList = [];
    if (response is List) {
      rawList = response;
    } else if (response is Map && response['data'] != null) {
      rawList = response['data'] as List<dynamic>;
    } else if (response is Map && response['results'] != null) {
      rawList = response['results'] as List<dynamic>;
    }

    return rawList
        .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Consulta el detalle de un plato específico
  Future<ProductModel> getProductById(int id, {String? token}) async {
    final response = await _apiClient.get(ApiEndpoints.productDetail(id), token: token);
    final map = (response is Map && response.containsKey('data'))
        ? response['data'] as Map<String, dynamic>
        : response as Map<String, dynamic>;
    return ProductModel.fromJson(map);
  }

  /// Admin: Registrar un nuevo plato en Django
  Future<ProductModel> createProduct({
    required String nombre,
    required String descripcion,
    required double precio,
    required bool disponible,
    String? imagenUrl,
    required String token,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.products,
      token: token,
      body: {
        'nombre': nombre.trim(),
        'descripcion': descripcion.trim(),
        'precio': precio,
        'disponible': disponible,
        'imagen_url': imagenUrl?.trim() ?? '',
      },
    );

    final map = (response is Map && response.containsKey('data'))
        ? response['data'] as Map<String, dynamic>
        : response as Map<String, dynamic>;

    return ProductModel.fromJson(map);
  }

  /// Admin: Actualizar datos de un plato (precio, disponibilidad, etc.)
  Future<ProductModel> updateProduct(
    int id, {
    Map<String, dynamic>? data,
    required String token,
  }) async {
    final response = await _apiClient.patch(
      ApiEndpoints.productDetail(id),
      token: token,
      body: data,
    );

    final map = (response is Map && response.containsKey('data'))
        ? response['data'] as Map<String, dynamic>
        : response as Map<String, dynamic>;

    return ProductModel.fromJson(map);
  }
}
