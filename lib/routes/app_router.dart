import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static const String initial = '/';
  static const String splash = '/splash';
  static const String login = '/login';
  static const String agencyDashboard = '/agency-dashboard';
  static const String userDashboard = '/user-dashboard';
}

extension AppNavigationExtension on BuildContext {
  void navigateTo(String path, {Object? extra}) {
    go(path, extra: extra);
  }

  void pushRoute(String path, {Object? extra}) {
    push(path, extra: extra);
  }

  void popRoute<T extends Object?>([T? result]) {
    pop(result);
  }
}
