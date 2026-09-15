import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../models/game/game_card_model.dart';
import '../../../../network/api_client.dart';
import '../../../../storage/local_storage_repository.dart';
import '../../../../storage/secure_storage_service.dart';

class GameCardWidget extends StatefulWidget {
  final GameCardModel game;
  final VoidCallback onPlay;
  final bool isSquare;

  const GameCardWidget({
    super.key,
    required this.game,
    required this.onPlay,
    this.isSquare = false,
  });

  @override
  State<GameCardWidget> createState() => _GameCardWidgetState();
}

class _GameCardWidgetState extends State<GameCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _isSubscribed = widget.game.isSubscribed;
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant GameCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.isSubscribed != widget.game.isSubscribed) {
      setState(() {
        _isSubscribed = widget.game.isSubscribed;
      });
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.isSquare) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (_isSubscribed) {
                _scaleController.forward();
                _scaleController.reverse();
                _fetchAndShowBookRecord();
              } else {
                _showSubscribeDialog(context);
              }
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16132A) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFFFD700).withValues(alpha: 0.35)
                      : const Color(0xFFFFD700).withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Top 65% Card Height: Full Game Image Banner
                  Expanded(
                    flex: 65,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16.5)),
                            child: (widget.game.imageUrl != null && widget.game.imageUrl!.isNotEmpty)
                                ? Image.network(
                                    widget.game.imageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFF252140),
                                      alignment: Alignment.center,
                                      child: Text(
                                        widget.game.code,
                                        style: const TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 22,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFF252140),
                                    alignment: Alignment.center,
                                    child: Text(
                                      widget.game.code,
                                      style: const TextStyle(
                                        color: Color(0xFFFFD700),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 22,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                          ),
                        ),

                        // Top Gradient Overlay for Badge Contrast
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16.5)),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.6),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),

                        // Top Left: Game Code Badge
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              widget.game.code,
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),

                        // Top Right: Floating Status Badge
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Builder(
                            builder: (context) {
                              final rawStatus = widget.game.status.trim();
                              final upper = rawStatus.toUpperCase();

                              String displayStatusText = 'Open';
                              Color statusBgColor = const Color(0xFF064E3B);
                              Color statusTextColor = const Color(0xFF34D399);

                              if (upper.contains('CLOSE') && !upper.contains('RUNNING CLOSE')) {
                                displayStatusText = 'Closed';
                                statusBgColor = const Color(0xFF7F1D1D);
                                statusTextColor = const Color(0xFFFCA5A5);
                              } else if (!_isSubscribed) {
                                displayStatusText = 'Close';
                                statusBgColor = const Color(0xFF78350F);
                                statusTextColor = const Color(0xFFFBBF24);
                              }

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusBgColor.withValues(alpha: 0.88),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: statusTextColor.withValues(alpha: 0.6),
                                    width: 0.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: statusTextColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      displayStatusText,
                                      style: TextStyle(
                                        color: statusTextColor,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 9.5,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom 35% Card Height: Info & Action Button
                  Expanded(
                    flex: 35,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Game Name
                          Text(
                            widget.game.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 5),

                          // Action Button (Subscribe or Play with gradient & glow)
                          if (!_isSubscribed)
                            Container(
                              width: double.infinity,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2E294A), Color(0xFF1E1A36)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.85),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                onTap: () => _showSubscribeDialog(context),
                                borderRadius: BorderRadius.circular(10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.notifications_active_outlined,
                                      size: 13,
                                      color: Color(0xFFFFD700),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Get ID',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFFFFD700),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                onTap: () {
                                  _scaleController.forward();
                                  _scaleController.reverse();
                                  _fetchAndShowBookRecord();
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.language_rounded,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Open Site',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0C1636),
              Color(0xFF070D22),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFF0066FF).withValues(alpha: 0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0066FF).withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Left: Square rounded game logo thumbnail
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF050B1E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: (widget.game.imageUrl != null && widget.game.imageUrl!.isNotEmpty)
                    ? Image.network(
                        widget.game.imageUrl!,
                        fit: BoxFit.cover,
                        width: 54,
                        height: 54,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            widget.game.code,
                            style: const TextStyle(
                              color: Color(0xFF00B2FF),
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              letterSpacing: 0.5,
                            ),
                          );
                        },
                      )
                    : Text(
                        widget.game.code,
                        style: const TextStyle(
                          color: Color(0xFF00B2FF),
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // Center: Game Title & Subtitle Tags
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.game.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _getCategoryTags(widget.game.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Right: Vibrant Blue Pill Action Button ("Open Site >" / "Get ID >")
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    colors: _isSubscribed
                        ? [const Color(0xFF0052FF), const Color(0xFF0038B8)]
                        : [const Color(0xFF0080FF), const Color(0xFF0055FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: const Color(0xFF60A5FA).withValues(alpha: 0.8),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_isSubscribed) {
                        _scaleController.forward();
                        _scaleController.reverse();
                        _fetchAndShowBookRecord();
                      } else {
                        _showSubscribeDialog(context);
                      }
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isSubscribed ? 'Open Site' : 'Get ID',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12.5,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryTags(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('sky') || lower.contains('exch')) {
      return 'Sports   |   Casino   |   Live Games';
    } else if (lower.contains('dream') || lower.contains('444')) {
      return 'Casino   |   Slots   |   Live Casino';
    } else if (lower.contains('lotus') || lower.contains('365')) {
      return 'Sports   |   Casino   |   Cricket';
    } else if (lower.contains('gold') || lower.contains('vault')) {
      return 'Casino   |   Matka   |   Card Games';
    } else {
      return 'Sports   |   Casino   |   Games';
    }
  }

  Future<int> _resolveUserId() async {
    try {
      final currentUser = LocalStorageRepositoryImpl().getUser();
      if (currentUser?.id != null && currentUser!.id.isNotEmpty) {
        final digitsOnly = currentUser.id.replaceAll(RegExp(r'\D'), '');
        if (digitsOnly.isNotEmpty) {
          final parsed = int.tryParse(digitsOnly);
          if (parsed != null && parsed > 0) return parsed;
        }
      }
      final storedUserId = await SecureStorageService().read(StorageKeys.userId);
      if (storedUserId != null && storedUserId.isNotEmpty) {
        final digitsOnly = storedUserId.replaceAll(RegExp(r'\D'), '');
        if (digitsOnly.isNotEmpty) {
          final parsed = int.tryParse(digitsOnly);
          if (parsed != null && parsed > 0) return parsed;
        }
      }
    } catch (_) {}
    return 0;
  }

  int _resolveBookId() {
    final digitsOnly = widget.game.id.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isNotEmpty) {
      final parsed = int.tryParse(digitsOnly);
      if (parsed != null && parsed > 0) return parsed;
    }
    return 0;
  }

  Future<void> _handleSubscribeAction(BuildContext dialogCtx) async {
    Navigator.pop(dialogCtx);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text('Processing Get ID request for ${widget.game.name}...'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF232530),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final apiClient = ApiClient();
      final userId = await _resolveUserId();
      final bookId = _resolveBookId();

      final response = await apiClient.post(
        ApiEndpoints.getQrCode,
        options: Options(validateStatus: (status) => status != null && status < 500),
        data: {
          'action': 'click_on_book',
          'user_id': userId,
          'book_id': bookId,
        },
      );

      if (!mounted) return;
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final isSubscribed = data['is_subscribed'] == true || data['already_subscribed'] == true;
        String rawMsg = data['message']?.toString() ?? 'Get ID record set successfully!';
        final cleanedMsg = rawMsg
            .replaceAll(RegExp(r'subscription', caseSensitive: false), 'Get ID')
            .replaceAll(RegExp(r'subscribed', caseSensitive: false), 'Get ID')
            .replaceAll(RegExp(r'subscribe', caseSensitive: false), 'Get ID');

        if (isSubscribed) {
          setState(() {
            _isSubscribed = true;
          });
          Map accountData = {};
          if (data['data'] is Map) {
            accountData = data['data'] as Map;
          } else if (data['book'] is Map) {
            accountData = data['book'] as Map;
          } else if (data['user_book'] is Map) {
            accountData = data['user_book'] as Map;
          } else if (data['record'] is Map) {
            accountData = data['record'] as Map;
          } else {
            accountData = data;
          }

          final link = (accountData['website_link'] ?? accountData['site_link'] ?? accountData['link'] ?? accountData['url'] ?? '')?.toString().trim() ?? '';
          final rawUser = (accountData['username'] ?? accountData['user_name'] ?? accountData['client_username'] ?? accountData['user'] ?? accountData['account_username'] ?? '')?.toString().trim() ?? '';
          final user = (rawUser == 'null' || rawUser == '0') ? '' : rawUser;

          final rawPass = (accountData['password'] ?? accountData['pass'] ?? accountData['client_password'] ?? accountData['account_password'] ?? '')?.toString().trim() ?? '';
          final pass = (rawPass == 'null' || rawPass == '0') ? '' : rawPass;
          _showAccountDetailsDialog(context, link, user, pass);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(cleanedMsg.isNotEmpty ? cleanedMsg : 'Get ID record set successfully!'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          setState(() {
            _isSubscribed = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(cleanedMsg),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        String rawErr = (data is Map<String, dynamic> && data['message'] != null)
            ? data['message'].toString()
            : 'Failed to complete Get ID request.';
        final cleanedErr = rawErr
            .replaceAll(RegExp(r'subscription', caseSensitive: false), 'Get ID')
            .replaceAll(RegExp(r'subscribed', caseSensitive: false), 'Get ID')
            .replaceAll(RegExp(r'subscribe', caseSensitive: false), 'Get ID');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cleanedErr),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Get ID error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  Future<void> _fetchAndShowBookRecord() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Color(0xFFFFD700),
                    strokeWidth: 2.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Opening ${widget.game.name}...',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'Fetching active ID credentials...',
                      style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF14102B),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
      ),
    );

    try {
      final apiClient = ApiClient();
      final userId = await _resolveUserId();
      final bookId = _resolveBookId();

      final response = await apiClient.post(
        ApiEndpoints.getQrCode,
        options: Options(validateStatus: (status) => status != null && status < 500),
        data: {
          'action': 'click_on_book',
          'user_id': userId,
          'book_id': bookId,
        },
      );

      if (!mounted) return;
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        Map accountData = {};
        if (data['data'] is Map) {
          accountData = data['data'] as Map;
        } else if (data['book'] is Map) {
          accountData = data['book'] as Map;
        } else if (data['user_book'] is Map) {
          accountData = data['user_book'] as Map;
        } else if (data['record'] is Map) {
          accountData = data['record'] as Map;
        } else {
          accountData = data;
        }

        final link = (accountData['website_link'] ?? accountData['site_link'] ?? accountData['link'] ?? accountData['url'] ?? '')?.toString().trim() ?? '';
        final rawUser = (accountData['username'] ?? accountData['user_name'] ?? accountData['client_username'] ?? accountData['user'] ?? accountData['account_username'] ?? '')?.toString().trim() ?? '';
        final user = (rawUser == 'null' || rawUser == '0') ? '' : rawUser;

        final rawPass = (accountData['password'] ?? accountData['pass'] ?? accountData['client_password'] ?? accountData['account_password'] ?? '')?.toString().trim() ?? '';
        final pass = (rawPass == 'null' || rawPass == '0') ? '' : rawPass;

        _showAccountDetailsDialog(context, link, user, pass);
      } else {
        final errMsg = (data is Map<String, dynamic> && data['message'] != null)
            ? data['message'].toString()
            : 'Book record not found or inactive.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading record: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  Future<void> _openWebsiteLink(String urlString) async {
    if (urlString.trim().isEmpty) return;
    try {
      String formattedUrl = urlString.trim();
      if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
        formattedUrl = 'https://$formattedUrl';
      }
      final uri = Uri.parse(formattedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        final uri = Uri.parse(urlString.trim());
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening website: $urlString'),
            backgroundColor: const Color(0xFF6366F1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAccountDetailsDialog(BuildContext context, String link, String username, String password) {
    final bool hasFullCredentials = username.trim().isNotEmpty && password.trim().isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF121026),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: hasFullCredentials
                  ? const Color(0xFFFFD700).withValues(alpha: 0.4)
                  : const Color(0xFFFFB703).withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          elevation: 20,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.78,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Glowing Icon Badge (Compact 48x48)
                  if (hasFullCredentials)
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.4),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 24),
                    )
                  else
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB703), Color(0xFFD97706)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFB703).withValues(alpha: 0.45),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const SandClockLoaderWidget(size: 24, color: Colors.white),
                    ),
                  const SizedBox(height: 10),

                  // Game Name Title & Badge
                  Text(
                    widget.game.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasFullCredentials
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFFFFB703).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasFullCredentials
                            ? const Color(0xFF10B981).withValues(alpha: 0.5)
                            : const Color(0xFFFFB703).withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!hasFullCredentials) ...[
                          const Icon(Icons.hourglass_top_rounded, color: Color(0xFFFFB703), size: 12),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          hasFullCredentials ? 'Active ID Record' : 'Getting Username & Password...',
                          style: TextStyle(
                            color: hasFullCredentials ? const Color(0xFF10B981) : const Color(0xFFFFB703),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Credential Rows
                  if (link.isNotEmpty) ...[
                    _buildCredentialRow('Website Link', link, icon: Icons.language_rounded, isLink: true),
                    const SizedBox(height: 8),
                  ],
                  if (username.isNotEmpty) ...[
                    _buildCredentialRow('Username', username, icon: Icons.person_outline_rounded),
                    const SizedBox(height: 8),
                  ],
                  if (password.isNotEmpty) ...[
                    _buildCredentialRow('Password', password, icon: Icons.lock_outline_rounded),
                    const SizedBox(height: 8),
                  ],

                  // Compact Cyber Gold Loading Box when username & password missing
                  if (!hasFullCredentials) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF231C3D),
                            Color(0xFF16102B),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFB703).withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SandClockLoaderWidget(size: 20, color: Color(0xFFFFB703)),
                              const SizedBox(width: 8),
                              Text(
                                'Please wait a few minutes...',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFFD700),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your username & password are being generated. Please wait to get login credentials.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFCBD5E1),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Compact Progress Timeline Steps
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F0B1E),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Get ID Request Submitted',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF10B981),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const SandClockLoaderWidget(size: 13, color: Color(0xFFFFB703), showParticles: false),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Agency Support assigning ID & Pass...',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: const Color(0xFFFFB703),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Time Estimate Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB703).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFFB703).withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_outlined, color: Color(0xFFFFB703), size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  'Estimated Time: 5 - 10 Minutes',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFFFFB703),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  const SizedBox(height: 10),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF221F3A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                          ),
                        ),
                      ),
                      if (link.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                if (link.isNotEmpty) {
                                  _openWebsiteLink(link);
                                } else {
                                  widget.onPlay();
                                }
                              },
                              icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 15),
                              label: Text(
                                'Visit Now',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13.5,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCredentialRow(String label, String value, {required IconData icon, bool isLink = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1834),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D294B)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF272346),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFFFD700), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: isLink ? () => _openWebsiteLink(value) : null,
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isLink ? const Color(0xFF38BDF8) : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      decoration: isLink ? TextDecoration.underline : TextDecoration.none,
                      decorationColor: const Color(0xFF38BDF8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Color(0xFFFFD700), size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied to clipboard!'),
                  duration: const Duration(seconds: 1),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSubscribeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF121026),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          elevation: 16,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.78,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Info Blue Circle Icon (Compact 48x48)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF131D38),
                      border: Border.all(
                        color: const Color(0xFF3B82F6),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF3B82F6),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title: Get ID for [Game Name]?
                  Text(
                    'Get ID for ${widget.game.name}?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Game Badge Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'MARKET: ${widget.game.name.toUpperCase()}',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  Text(
                    "Press OK to get ID for ${widget.game.name} and unlock active game credentials!",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Actions: Cancel & OK Buttons
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF25213B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // OK Button
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextButton(
                            onPressed: () => _handleSubscribeAction(ctx),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SandClockLoaderWidget extends StatefulWidget {
  final double size;
  final Color color;
  final bool showParticles;
  const SandClockLoaderWidget({
    super.key,
    this.size = 36,
    this.color = const Color(0xFFFFB703),
    this.showParticles = true,
  });

  @override
  State<SandClockLoaderWidget> createState() => _SandClockLoaderWidgetState();
}

class _SandClockLoaderWidgetState extends State<SandClockLoaderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _flipAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 0).chain(CurveTween(curve: Curves.ease)), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 3.14159).chain(CurveTween(curve: Curves.elasticOut)), weight: 40),
    ]).animate(_controller);

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Transform.rotate(
            angle: _flipAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: widget.showParticles
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Icon(
          Icons.hourglass_bottom_rounded,
          color: widget.color,
          size: widget.size,
        ),
      ),
    );
  }
}

