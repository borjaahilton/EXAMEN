class ApiEndpoints {
  // IP directa de la PC con la conexión del teléfono Samsung:
  static String baseUrl = 'http://192.168.93.53:8000';

  // Rutas de Django REST API
  static const String authLogin = '/auth/login/';
  static const String authRegister = '/auth/register/';
  static const String products = '/products/';
  static const String orders = '/orders/';
  static const String myOrders = '/orders/mine/';
  static const String adminOrders = '/admin/orders/';

  static String orderStatus(int id) => '/orders/$id/status/';
  static String productDetail(int id) => '/products/$id/';
}
