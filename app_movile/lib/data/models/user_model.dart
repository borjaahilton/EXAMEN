class UserModel {
  final int id;
  final String nombre;
  final String email;
  final String rol;

  UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Si Django retorna first_name y last_name
    String displayName = '';
    if (json['first_name'] != null || json['last_name'] != null) {
      displayName = '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim();
    }
    if (displayName.isEmpty && json['nombre'] != null) {
      displayName = json['nombre'].toString();
    }
    if (displayName.isEmpty && json['username'] != null) {
      displayName = json['username'].toString();
    }

    return UserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: displayName.isNotEmpty ? displayName : (json['email'] as String? ?? 'Usuario'),
      email: json['email'] as String? ?? '',
      rol: json['rol'] as String? ?? 'cliente',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'email': email,
    'rol': rol,
  };
}

class AuthResponse {
  final String token;
  final UserModel user;

  AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Si la respuesta viene envuelta en { "data": { "token": ..., "user": ... } }
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      final data = json['data'] as Map<String, dynamic>;
      final t = data['access'] ?? data['token'] ?? '';
      final u = data['user'] != null
          ? UserModel.fromJson(data['user'] as Map<String, dynamic>)
          : UserModel.fromJson(data);
      return AuthResponse(token: t.toString(), user: u);
    }

    // Django SimpleJWT retorna directamente { "access": "...", "refresh": "...", "id": ..., "email": ..., "rol": ... }
    final token = json['access'] ?? json['token'] ?? '';
    final user = UserModel.fromJson(json);

    return AuthResponse(
      token: token.toString(),
      user: user,
    );
  }
}
