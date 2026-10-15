class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([super.message = 'Sin conexión a internet o servidor inalcanzable.']);
}

class TimeoutConnectionException extends AppException {
  TimeoutConnectionException([super.message = 'Tiempo de espera agotado al conectar con el servidor.']);
}

class UnauthorizedException extends AppException {
  UnauthorizedException([String message = 'Credenciales incorrectas o sesión expirada.'])
      : super(message, 401);
}

class ForbiddenException extends AppException {
  ForbiddenException([String message = 'No tienes permisos para realizar esta acción.'])
      : super(message, 403);
}

class ServerException extends AppException {
  ServerException([super.message = 'Error en el servidor de Sabores de Huaraz.', super.statusCode]);
}
