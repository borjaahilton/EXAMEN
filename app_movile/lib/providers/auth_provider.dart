import 'package:flutter/material.dart';
import '../core/storage/session_manager.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final SessionManager _sessionManager;

  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({
    AuthService? authService,
    SessionManager? sessionManager,
  })  : _authService = authService ?? AuthService(),
        _sessionManager = sessionManager ?? SessionManager();

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> checkExistingSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final savedToken = await _sessionManager.getToken();
      final savedUser = await _sessionManager.getUser();

      if (savedToken != null && savedUser != null) {
        _token = savedToken;
        _currentUser = savedUser;
      }
    } catch (_) {
      // Ignorar error al verificar sesión inicial
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      _token = response.token;
      _currentUser = response.user;
      await _sessionManager.saveSession(token: _token!, user: _currentUser!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String nombre, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.register(nombre, email, password);
      _token = response.token;
      _currentUser = response.user;
      await _sessionManager.saveSession(token: _token!, user: _currentUser!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _sessionManager.clearSession();
    _token = null;
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}
