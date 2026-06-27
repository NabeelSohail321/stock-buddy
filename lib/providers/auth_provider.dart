import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../models/user_model.dart';
import '../notification_services.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  final LocalStorageService _localStorageService;

  AuthProvider({
    required ApiService apiService,
    required LocalStorageService localStorageService,
  })  : _apiService = apiService,
        _localStorageService = localStorageService;

  bool _isLoading = false;
  String _error = '';
  User? _currentUser;
  String? _token;

  bool get isLoading => _isLoading;
  String get error => _error;
  String get errorMessage => _error;
  User? get currentUser => _currentUser;
  String? get token => _token;

  Future<void> initialize() async {
    try {
      _token = await _localStorageService.getToken();
      _currentUser = await _localStorageService.getUser();
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthProvider] initialize error: $e');
    }
  }

  Future<bool> verifyToken() async {
    if (_token == null || _token!.isEmpty) return false;

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _apiService.verifyToken(_token!);
      if (response['valid'] == true) {
        final userData = response['user'];
        if (userData != null) {
          _currentUser = User.fromJson(userData);
          await _localStorageService.saveAuthData(_token!, _currentUser!);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
      await logout();
      _isLoading = false;
      notifyListeners();
      return false;
    } on AuthException {
      await logout();
      _isLoading = false;
      notifyListeners();
      return false;
    } on NetworkException catch (e) {
      // Allow offline usage — token present but unverified
      _isLoading = false;
      _error = e.message;
      notifyListeners();
      return _token != null && _token!.isNotEmpty;
    } catch (e) {
      await logout();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    if (_token == null || _token!.isEmpty) {
      final token = await _localStorageService.getToken();
      if (token == null || token.isEmpty) return false;
      _token = token;
    }
    return verifyToken();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      String? deviceToken;
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          deviceToken = await NotificationServices().getDeviceToken();
        } catch (_) {}
      }

      final authResponse = await _apiService.register(
        name: name,
        email: email,
        password: password,
        deviceToken: deviceToken,
      );

      await _localStorageService.saveAuthData(authResponse.token, authResponse.user);
      _token = authResponse.token;
      _currentUser = authResponse.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _isLoading = false;
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      String? deviceToken;
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          deviceToken = await NotificationServices().getDeviceToken();
        } catch (_) {}
      }

      final authResponse = await _apiService.login(
        email: email,
        password: password,
        deviceToken: deviceToken,
      );

      await _localStorageService.saveAuthData(authResponse.token, authResponse.user);
      _token = authResponse.token;
      _currentUser = authResponse.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _isLoading = false;
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _localStorageService.clearAuthData();
    _token = null;
    _currentUser = null;
    _error = '';
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}
