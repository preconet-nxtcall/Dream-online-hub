import 'dart:convert';
import '../utils/logger.dart';

class FCMDeepLinkTarget {
  final String routePath;
  final String? userId;
  final String? gameId;
  final Map<String, dynamic> rawData;

  FCMDeepLinkTarget({
    required this.routePath,
    this.userId,
    this.gameId,
    required this.rawData,
  });
}

class FCMDeepLinkRouter {
  static FCMDeepLinkTarget? parsePayload(dynamic data) {
    if (data == null) return null;

    Map<String, dynamic> payloadMap = {};
    if (data is Map<String, dynamic>) {
      payloadMap = data;
    } else if (data is String && data.trim().startsWith('{')) {
      try {
        payloadMap = jsonDecode(data);
      } catch (e) {
        AppLogger.error('Failed to parse JSON notification payload: $e');
        return null;
      }
    }

    final type = (payloadMap['type'] ?? payloadMap['target'] ?? '').toString();
    final userId = (payloadMap['user_id'] ?? payloadMap['userId'] ?? payloadMap['sender_id'] ?? '').toString();
    final gameId = (payloadMap['game_id'] ?? payloadMap['gameId'] ?? '').toString();

    // 1. Reused Shared Chat Screen (Agency & User Apps)
    if (type == 'chat' || userId.isNotEmpty) {
      final targetUserId = userId.isNotEmpty ? userId : 'agency_support_1';
      return FCMDeepLinkTarget(
        routePath: '/chat/$targetUserId',
        userId: targetUserId,
        rawData: payloadMap,
      );
    }

    // 2. User App Dashboard & Game Arena
    if (type == 'user_dashboard' || type == 'user') {
      return FCMDeepLinkTarget(
        routePath: '/user-dashboard',
        rawData: payloadMap,
      );
    }

    if (type == 'game_arena' || type == 'game' || gameId.isNotEmpty) {
      final targetGameId = gameId.isNotEmpty ? gameId : 'kalyan_morning';
      return FCMDeepLinkTarget(
        routePath: '/game-arena/$targetGameId',
        gameId: targetGameId,
        rawData: payloadMap,
      );
    }

    // 3. Agency App Dashboard
    if (type == 'agency_dashboard' || type == 'agency') {
      return FCMDeepLinkTarget(
        routePath: '/agency-dashboard',
        rawData: payloadMap,
      );
    }

    return FCMDeepLinkTarget(
      routePath: '/agency-dashboard',
      rawData: payloadMap,
    );
  }
}

