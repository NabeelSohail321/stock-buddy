import 'package:flutter/foundation.dart';
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

  // Get all users
  Future<void> fetchUsers() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _users = await _userService.getUsers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create user
  Future<bool> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    _isLoading = true;
    _error = '';
    _successMessage = '';
    notifyListeners();

    try {
      await _userService.createUser(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      _successMessage = 'User created successfully!';
      await fetchUsers(); // Refresh the users list
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user
  Future<bool> updateUser({
    required String userId,
    required String name,
    required String role,
    required bool isActive,
  }) async {
    _isLoading = true;
    _error = '';
    _successMessage = '';
    notifyListeners();

    try {
      await _userService.updateUser(
        userId: userId,
        name: name,
        role: role,
        isActive: isActive,
      );

      _successMessage = 'User updated successfully!';
      await fetchUsers(); // Refresh the users list
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reset user password
  Future<bool> resetUserPassword({
    required String userId,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = '';
    _successMessage = '';
    notifyListeners();

    try {
      await _userService.resetUserPassword(
        userId: userId,
        newPassword: newPassword,
      );

      _successMessage = 'Password reset successfully!';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
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