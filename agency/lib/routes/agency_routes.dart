import 'package:go_router/go_router.dart';
import '../features/agency_dashboard/presentation/agency_dashboard_screen.dart';
import '../features/auth/presentation/agency_login_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/chat/presentation/agency_chat_screen.dart';
import '../features/profile/presentation/agency_profile_screen.dart';
import '../models/agency/agency_user_item_model.dart';

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
        path: '/agency-profile',
        builder: (context, state) => const AgencyProfileScreen(),
      ),
      GoRoute(
        path: '/chat/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          final extra = state.extra;
          AgencyUserItem? userItem;
          String? initialGameName;

          if (extra is AgencyUserItem) {
            userItem = extra;
          } else if (extra is Map<String, dynamic>) {
            userItem = extra['userItem'] as AgencyUserItem?;
            initialGameName = (extra['gameName'] ?? extra['initialGameName']) as String?;
          }

          return AgencyChatScreen(
            userId: userId,
            userItem: userItem,
            initialGameName: initialGameName,
          );
        },
      ),
    ],
  );
}
