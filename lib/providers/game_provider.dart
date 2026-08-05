import 'package:flutter/foundation.dart';
import '../models/game/game_card_model.dart';
import '../repositories/game_repository.dart';

class GameProvider extends ChangeNotifier {
  final GameRepository _gameRepository;

  List<GameCardModel> _games = [];
  bool _isLoading = false;
  bool _isPlayingGame = false;
  bool _isLaunchingGame = false;
  String? _errorMessage;
  String _selectedCategory = 'All';

  GameProvider({GameRepository? gameRepository})
      : _gameRepository = gameRepository ?? GameRepositoryImpl();

  List<GameCardModel> get games => _games;
  bool get isLoading => _isLoading;
  bool get isPlayingGame => _isPlayingGame;
  bool get isLaunchingGame => _isLaunchingGame;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;

  /// Call backend API to launch game provided by backend
  Future<Map<String, dynamic>> launchGame(String gameId) async {
    _isLaunchingGame = true;
    notifyListeners();

    try {
      final result = await _gameRepository.launchGame(gameId);
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Failed to launch game: ${e.toString()}'};
    } finally {
      _isLaunchingGame = false;
      notifyListeners();
    }
  }

  Future<void> fetchGames() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _games = await _gameRepository.fetchGames();
    } catch (e) {
      _errorMessage = 'Failed to load games. Tap to refresh.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send play request to backend
  Future<Map<String, dynamic>> playGame({
    required String gameId,
    required String marketType,
    required String digit,
    required double points,
  }) async {
    _isPlayingGame = true;
    notifyListeners();

    try {
      final result = await _gameRepository.playGame(
        gameId: gameId,
        marketType: marketType,
        digit: digit,
        points: points,
      );
      return result;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      return {'success': false, 'message': msg};
    } finally {
      _isPlayingGame = false;
      notifyListeners();
    }
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }
}
