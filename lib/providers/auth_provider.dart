import 'dart:io';

import 'package:flutter/foundation.dart';

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
  String _errorMessage = '';
  User? _currentUser;
  String? _token;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  String? get token => _token;

  Future<void> initialize() async {
    try {
      _token = await _localStorageService.getToken();
      _currentUser = await _localStorageService.getUser();
      print('Initialized - Token: $_token, User: $_currentUser');
      notifyListeners();
    } catch (e) {
      print('Initialize error: $e');
    }
  }

  // Future<bool> isLoggedIn() async {
  //   // Check if we have a token and it's not empty
  //   if (_token != null && _token!.isNotEmpty) {
  //     return true;
  //   }
  //
  //   // Fallback: check local storage directly
  //   final token = await _localStorageService.getToken();
  //   return token != null && token.isNotEmpty;
  // }

  Future<bool> verifyToken() async {
    if (_token == null || _token!.isEmpty) {
      print('No token available for verification');
      return false;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      print('Verifying token...');
      final response = await _apiService.verifyToken(_token!);

      if (response['valid'] == true) {
        // Token is valid, update user data if needed
        final userData = response['user'];
        if (userData != null) {
          _currentUser = User.fromJson(userData);
          // Save updated user data to local storage
          await _localStorageService.saveAuthData(_token!, _currentUser!);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Token is invalid, clear auth data
        await logout();
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Token verification error: $e');
      // If token verification fails, clear auth data
      await logout();
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

// Update the isLoggedIn method to verify token
  Future<bool> isLoggedIn() async {
    // First check if we have a token locally
    if (_token == null || _token!.isEmpty) {
      // Fallback: check local storage directly
      final token = await _localStorageService.getToken();
      if (token == null || token.isEmpty) {
        return false;
      }
      _token = token;
    }

    // Now verify the token with the server
    return await verifyToken();
  }
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      String? deviceToken;

      // Only get device token for mobile platforms
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          NotificationServices notificationServices = NotificationServices();
          deviceToken = await notificationServices.getDeviceToken();
          print('Device token retrieved: $deviceToken');
        } catch (e) {
          print('Failed to get device token: $e');
          // Continue with registration even if device token fails
        }
      }

      print('Starting registration for: $email');
      final authResponse = await _apiService.register(
        name: name,
        email: email,
        password: password,
        deviceToken: deviceToken, // Pass device token to API service
      );

      print('Registration successful, saving data...');
      await _localStorageService.saveAuthData(
        authResponse.token,
        authResponse.user,
      );

      _token = authResponse.token;
      _currentUser = authResponse.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Registration error: $e');
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      String? deviceToken;

      // Only get device token for mobile platforms
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          NotificationServices notificationServices = NotificationServices();
          deviceToken = await notificationServices.getDeviceToken();
          print('Device token retrieved: $deviceToken');
        } catch (e) {
          print('Failed to get device token: $e');
          // Continue with login even if device token fails
        }
      }

      print('Starting login for: $email');
      final authResponse = await _apiService.login(
        email: email,
        password: password,
        deviceToken: deviceToken, // Pass device token to API service
      );

      print('Login successful, saving data...');
      await _localStorageService.saveAuthData(
        authResponse.token,
        authResponse.user,
      );

      _token = authResponse.token;
      _currentUser = authResponse.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Login error: $e');
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _localStorageService.clearAuthData();
    _token = null;
    _currentUser = null;
    _errorMessage = '';
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}