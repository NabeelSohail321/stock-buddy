class ApiConstants {
  static const String baseUrl = 'https://stock-buddy-serverr-production.up.railway.app/api';
  static const String register = '/auth/register';
  static const String login = '/auth/login';

  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 30);
}