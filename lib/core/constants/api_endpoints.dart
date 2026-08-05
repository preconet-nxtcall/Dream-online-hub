class ApiEndpoints {
  static const String baseUrl = 'https://api.example.com/v1';
  static const String socketUrl = 'https://socket.example.com';

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';
  static const String refreshToken = '/auth/refresh-token';

  // Agency Specific Endpoints
  static const String agencyDashboard = '/agency/dashboard';
  static const String agencyAgents = '/agency/agents';

  // User Specific Endpoints
  static const String userDashboard = '/user/dashboard';
  static const String userServices = '/user/services';
}
