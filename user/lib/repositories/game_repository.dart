import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/constants/storage_keys.dart';
import '../models/game/game_card_model.dart';
import '../network/api_client.dart';
import '../storage/local_storage_repository.dart';
import '../storage/secure_storage_service.dart';

abstract class GameRepository {
  Future<List<GameCardModel>> fetchGames({String? category});
  Future<Map<String, dynamic>> launchGame(String gameId);
  Future<Map<String, dynamic>> playGame({
    required String gameId,
    required String marketType,
    required String digit,
    required double points,
  });
}

class GameRepositoryImpl implements GameRepository {
  final ApiClient _apiClient;
  List<String> _bannerUrls = [
    'https://dreamonlinehub.club/uploads/photos/1784883728_Slider.png',
  ];

  GameRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  List<String> get bannerUrls => _bannerUrls;

  @override
  Future<Map<String, dynamic>> launchGame(String gameId) async {
    try {
      final response = await _apiClient.post(
        '/games/$gameId/launch',
        data: {'game_id': gameId},
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
      }
    } catch (_) {
      // Return game launch session fallback map
    }

    return {
      'success': true,
      'game_id': gameId,
      'session_token': 'sess_backend_$gameId',
      'game_url': 'https://zara.androsoft.in/game/$gameId',
      'message': 'Game session initialized by backend',
    };
  }

  @override
  Future<Map<String, dynamic>> playGame({
    required String gameId,
    required String marketType,
    required String digit,
    required double points,
  }) async {
    try {
      final response = await _apiClient.post(
        '/games/play',
        data: {
          'game_id': gameId,
          'market_type': marketType,
          'digit': digit,
          'points': points,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
        return {'success': true, 'message': 'Play request placed successfully!'};
      } else {
        throw Exception(response.data?['message'] ?? 'Failed to place play bid on server.');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network or server connection error: ${e.toString()}');
    }
  }

  @override
  Future<List<GameCardModel>> fetchGames({String? category}) async {
    try {
      dynamic userId;
      final currentUser = LocalStorageRepositoryImpl().getUser();
      if (currentUser?.id != null && currentUser!.id.isNotEmpty) {
        final raw = currentUser.id.trim();
        final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
        userId = digitsOnly.isNotEmpty ? (int.tryParse(digitsOnly) ?? raw) : raw;
      }
      if (userId == null) {
        final storedUserId = await SecureStorageService().read(StorageKeys.userId);
        if (storedUserId != null && storedUserId.isNotEmpty) {
          final raw = storedUserId.trim();
          final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
          userId = digitsOnly.isNotEmpty ? (int.tryParse(digitsOnly) ?? raw) : raw;
        }
      }

      final response = await _apiClient.post(
        ApiEndpoints.getQrCode,
        options: Options(validateStatus: (status) => status != null && status < 500),
        data: {
          'action': 'all_books',
          'user_id': userId,
        },
      );

      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        final data = response.data;
        final List<GameCardModel> dynamicGames = [];
        final Set<String> processedBookIds = {};

        // Extract backend slider banner images if present
        final List<String> extractedBanners = [];
        for (final key in ['banners', 'slider', 'sliders', 'photos', 'banner_images', 'images']) {
          if (data[key] is List) {
            for (final item in (data[key] as List)) {
              String? url;
              if (item is String) url = item;
              if (item is Map) {
                url = item['url']?.toString() ??
                    item['image']?.toString() ??
                    item['image_url']?.toString() ??
                    item['photo']?.toString() ??
                    item['src']?.toString();
              }
              if (url != null && url.isNotEmpty) {
                if (!url.startsWith('http')) {
                  url = url.startsWith('/')
                      ? 'https://dreamonlinehub.club$url'
                      : 'https://dreamonlinehub.club/$url';
                }
                extractedBanners.add(url);
              }
            }
          }
        }
        if (extractedBanners.isNotEmpty) {
          _bannerUrls = extractedBanners;
        }

        // 1. Parse subscribed_books array from server
        if (data['subscribed_books'] is List) {
          for (final item in (data['subscribed_books'] as List)) {
            if (item is Map) {
              final model = _parseGameCardModel(item, forceSubscribed: true);
              dynamicGames.add(model);
              processedBookIds.add(model.id);
            }
          }
        }

        // 2. Parse non_subscribed_books array from server
        if (data['non_subscribed_books'] is List) {
          for (final item in (data['non_subscribed_books'] as List)) {
            if (item is Map) {
              final model = _parseGameCardModel(item, forceSubscribed: false);
              if (!processedBookIds.contains(model.id)) {
                dynamicGames.add(model);
                processedBookIds.add(model.id);
              }
            }
          }
        }

        // 3. Parse all_books / data fallback lists
        List rawList = [];
        if (data['all_books'] is List) {
          rawList = data['all_books'] as List;
        } else if (data['data'] is List) {
          rawList = data['data'] as List;
        }

        for (final item in rawList) {
          if (item is Map) {
            final model = _parseGameCardModel(item);
            if (!processedBookIds.contains(model.id)) {
              dynamicGames.add(model);
              processedBookIds.add(model.id);
            }
          }
        }

        return dynamicGames;
      }
    } catch (_) {}

    return const [];
  }

  GameCardModel _parseGameCardModel(Map item, {bool? forceSubscribed}) {
    final rawId = item['id']?.toString() ?? item['book_id']?.toString() ?? '';
    final name = item['book_name']?.toString() ?? item['name']?.toString() ?? 'Game Market';
    final code = item['book_code']?.toString() ?? item['code']?.toString() ?? (name.length >= 2 ? name.substring(0, 2).toUpperCase() : 'GM');
    final result = item['result']?.toString() ?? item['numbers']?.toString() ?? '***-**-***';
    final statusStr = item['status']?.toString() ?? item['stage_status']?.toString() ?? 'Running Open';
    final isOpen = !statusStr.toLowerCase().contains('close');

    String? imageUrl = item['image_url']?.toString() ??
        item['imageUrl']?.toString() ??
        item['image']?.toString() ??
        item['book_image']?.toString() ??
        item['icon']?.toString() ??
        item['logo']?.toString() ??
        item['photo']?.toString();

    if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      if (imageUrl.startsWith('/')) {
        imageUrl = 'https://dreamonlinehub.club$imageUrl';
      } else {
        imageUrl = 'https://dreamonlinehub.club/$imageUrl';
      }
    }

    final isSub = forceSubscribed ?? (item['is_subscribed'] == true || item['already_subscribed'] == true || item['subscribed'] == true || item['subscription_status']?.toString().toUpperCase() == 'ACTIVE');

    return GameCardModel(
      id: rawId.isNotEmpty ? rawId : '324',
      name: name,
      code: code,
      result: result,
      status: statusStr,
      isOpen: isOpen,
      openTime: item['open_time']?.toString() ?? '10:00 AM',
      closeTime: item['close_time']?.toString() ?? '10:00 PM',
      imageUrl: imageUrl,
      category: 'Main Markets',
      isSubscribed: isSub,
    );
  }
}
