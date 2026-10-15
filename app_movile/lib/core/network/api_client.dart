import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import '../errors/exceptions.dart';

class ApiClient {
  static const Duration defaultTimeout = Duration(seconds: 10);
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _buildHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Ejecuta la petición intentando primero la URL activa y, si falla por red,
  /// conmuta automáticamente entre la IP de red (192.168.93.53) y localhost (127.0.0.1).
  Future<http.Response> _sendWithFallback(
    Future<http.Response> Function(String currentBase) call,
  ) async {
    final primary = ApiEndpoints.baseUrl;
    final fallback = primary.contains('192.168.93.53')
        ? 'http://127.0.0.1:8000'
        : 'http://192.168.93.53:8000';

    try {
      return await call(primary).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Reintento automático transparente con la dirección IP secundaria
      return await call(fallback).timeout(defaultTimeout);
    }
  }

  Future<dynamic> get(String endpoint, {String? token}) async {
    try {
      final response = await _sendWithFallback((base) {
        final uri = Uri.parse('$base$endpoint');
        return _client.get(uri, headers: _buildHeaders(token: token));
      });

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw TimeoutConnectionException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(e.toString());
    }
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await _sendWithFallback((base) {
        final uri = Uri.parse('$base$endpoint');
        return _client.post(
          uri,
          headers: _buildHeaders(token: token),
          body: encodedBody,
        );
      });

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw TimeoutConnectionException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(e.toString());
    }
  }

  Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await _sendWithFallback((base) {
        final uri = Uri.parse('$base$endpoint');
        return _client.patch(
          uri,
          headers: _buildHeaders(token: token),
          body: encodedBody,
        );
      });

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw TimeoutConnectionException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(e.toString());
    }
  }

  dynamic _handleResponse(http.Response response) {
    dynamic jsonBody;
    try {
      jsonBody = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      jsonBody = null;
    }

    String message = 'Ocurrió un error inesperado';
    if (jsonBody is Map) {
      if (jsonBody['detail'] != null) {
        message = jsonBody['detail'].toString();
      } else if (jsonBody['message'] != null) {
        message = jsonBody['message'].toString();
      } else if (jsonBody['non_field_errors'] != null) {
        final list = jsonBody['non_field_errors'];
        message = list is List ? list.join(', ') : list.toString();
      } else {
        final errorFields = <String>[];
        jsonBody.forEach((key, value) {
          if (value is List) {
            errorFields.add('$key: ${value.join(', ')}');
          } else {
            errorFields.add('$key: $value');
          }
        });
        if (errorFields.isNotEmpty) {
          message = errorFields.join('\n');
        }
      }
    } else if (jsonBody is String) {
      message = jsonBody;
    }

    switch (response.statusCode) {
      case 200:
      case 201:
        return jsonBody;
      case 400:
        throw AppException(message, 400);
      case 401:
        throw UnauthorizedException(message);
      case 403:
        throw ForbiddenException(message);
      case 404:
        throw AppException(message, 404);
      case 500:
      default:
        throw ServerException(message, response.statusCode);
    }
  }
}
