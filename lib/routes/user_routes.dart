import 'package:go_router/go_router.dart';
import '../features/agency_dashboard/presentation/agency_dashboard_screen.dart';
import '../features/auth/presentation/agency_login_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/user_login_screen.dart';
import '../features/chat/presentation/user_chat_screen.dart';
import '../features/game_play/presentation/game_arena_screen.dart';
import '../features/profile/presentation/agency_profile_screen.dart';
import '../features/profile/presentation/user_profile_screen.dart';
import '../features/user_dashboard/presentation/user_dashboard_screen.dart';
import '../models/agency/agency_user_item_model.dart';
import '../models/game/game_card_model.dart';

class UserRoutes {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const UserLoginScreen(),
      ),
      GoRoute(
        path: '/user-login',
        builder: (context, state) => const UserLoginScreen(),
      ),
      GoRoute(
        path: '/agency-login',
        builder: (context, state) => const AgencyLoginScreen(),
      ),
      GoRoute(
        path: '/user-dashboard',
        builder: (context, state) => const UserDashboardScreen(),
      ),
      GoRoute(
        path: '/agency-dashboard',
        builder: (context, state) => const AgencyDashboardScreen(),
      ),
      GoRoute(
        path: '/user-profile',
        builder: (context, state) => const UserProfileScreen(),
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

          return UserChatScreen(
            userId: userId,
            userItem: userItem,
            initialGameName: initialGameName,
          );
        },
      ),
      GoRoute(
        path: '/game-arena/:gameId',
        builder: (context, state) {
          final gameId = state.pathParameters['gameId'] ?? '';
          final extraMap = state.extra as Map<String, dynamic>?;
          final game = extraMap?['game'] as GameCardModel?;
          final launchData = extraMap?['launch_data'] as Map<String, dynamic>?;
          return GameArenaScreen(gameId: gameId, game: game, launchData: launchData);
        },
      ),
    ],
  );
}
