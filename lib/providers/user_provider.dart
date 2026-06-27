import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService;

  UserProvider(this._userService);

  bool _isLoading = false;
  String _error = '';
  String _successMessage = '';
  List<dynamic> _users = [];

  bool get isLoading => _isLoading;
  String get error => _error;
  String get successMessage => _successMessage;
  List<dynamic> get users => _users;

  Future<void> fetchUsers() async {
    _setLoading(true);
    try {
      _users = await _userService.getUsers();
      _setLoading(false);
    } on AppException catch (e) {
      _error = e.message;
      _setLoading(false);
    } catch (_) {
      _error = 'Failed to load users. Please try again.';
      _setLoading(false);
    }
  }

  Future<bool> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    _setLoading(true);
    try {
      await _userService.createUser(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      _successMessage = 'User created successfully!';
      await fetchUsers();
      return true;
    } on AppException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'Failed to create user. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateUser({
    required String userId,
    required String name,
    required String role,
    required bool isActive,
  }) async {
    _setLoading(true);
    try {
      await _userService.updateUser(
        userId: userId,
        name: name,
        role: role,
        isActive: isActive,
      );
      _successMessage = 'User updated successfully!';
      await fetchUsers();
      return true;
    } on AppException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'Failed to update user. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetUserPassword({
    required String userId,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      await _userService.resetUserPassword(
        userId: userId,
        newPassword: newPassword,
      );
      _successMessage = 'Password reset successfully!';
      _setLoading(false);
      return true;
    } on AppException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'Failed to reset password. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _error = '';
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  void clearSuccessMessage() {
    _successMessage = '';
    notifyListeners();
  }
}
