import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Inicio de sesión contra Django SimpleJWT
  Future<AuthResponse> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiEndpoints.authLogin,
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    return AuthResponse.fromJson(response as Map<String, dynamic>);
  }

  /// Registro de nuevo cliente en Django
  Future<AuthResponse> register(String nombreCompleto, String email, String password) async {
    // Dividir nombre y apellido para el modelo User de Django
    final parts = nombreCompleto.trim().split(' ');
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    await _apiClient.post(
      ApiEndpoints.authRegister,
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    // Luego de registrarse en Django, iniciamos sesión automáticamente para obtener el token JWT
    return await login(email, password);
  }
}
