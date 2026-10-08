import 'package:go_router/go_router.dart';
import '../features/agency_dashboard/presentation/agency_dashboard_screen.dart';
import '../features/auth/presentation/agency_login_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/employee/presentation/employee_dashboard_screen.dart';
import '../features/profile/presentation/agency_profile_screen.dart';

class AgencyRoutes {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const AgencyLoginScreen(),
      ),
      GoRoute(
        path: '/agency-login',
        builder: (context, state) => const AgencyLoginScreen(),
      ),
      GoRoute(
        path: '/agency-dashboard',
        builder: (context, state) => const AgencyDashboardScreen(),
      ),
      GoRoute(
        path: '/employee-dashboard',
        builder: (context, state) => const EmployeeDashboardScreen(),
      ),
      GoRoute(
        path: '/employee',
        builder: (context, state) => const EmployeeDashboardScreen(),
      ),
      GoRoute(
        path: '/agency-profile',
        builder: (context, state) => const AgencyProfileScreen(),
      ),
    ],
  );
}
