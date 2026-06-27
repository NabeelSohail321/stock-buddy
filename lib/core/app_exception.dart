class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([String message = 'No internet connection. Please check your network.'])
      : super(message);
}

class RequestTimeoutException extends AppException {
  const RequestTimeoutException([String message = 'Request timed out. Please try again.'])
      : super(message);
}

class AuthException extends AppException {
  const AuthException([String message = 'Session expired. Please log in again.'])
      : super(message, 401);
}

class ForbiddenException extends AppException {
  const ForbiddenException([String message = 'You do not have permission to perform this action.'])
      : super(message, 403);
}

class NotFoundException extends AppException {
  const NotFoundException([String message = 'The requested resource was not found.'])
      : super(message, 404);
}

class ValidationException extends AppException {
  const ValidationException(String message) : super(message, 422);
}

class ServerException extends AppException {
  const ServerException([String message = 'A server error occurred. Please try again later.', int? code])
      : super(message, code);
}
