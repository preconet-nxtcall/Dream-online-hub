import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../models/game/game_card_model.dart';
import '../../../models/user/recharge_record_model.dart';
import '../../../providers/game_provider.dart';
import '../../../network/api_client.dart';
import '../../../storage/local_storage_repository.dart';
import '../../../storage/secure_storage_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/common/app_logout_dialog.dart';
import '../../../widgets/common/draggable_chat_button.dart';
import '../../profile/presentation/user_profile_screen.dart';
import 'widgets/banner_carousel_widget.dart';
import 'widgets/game_card_widget.dart';
import 'widgets/recharge_records_widget.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  int _currentNavIndex = 0;
  int _displayedGamesCount = 20;
  final GlobalKey<RechargeRecordsWidgetState> _rechargeRecordsKey = GlobalKey();

  // ignore: unused_field
  double _pendingAmount = 0.0;
  // ignore: unused_field
  double _successfulAmount = 0.0;

  Timer? _summaryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().fetchGames();
      _fetchRechargeSummary();
    });
    _summaryTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _fetchRechargeSummary();
    });
  }

  @override
  void dispose() {
    _summaryTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRechargeSummary() async {
    try {
      final apiClient = ApiClient();
      int userId = 0;
      final currentUser = LocalStorageRepositoryImpl().getUser();
      if (currentUser?.id != null && currentUser!.id.isNotEmpty) {
        final digitsOnly = currentUser.id.replaceAll(RegExp(r'\D'), '');
        if (digitsOnly.isNotEmpty) {
          userId = int.tryParse(digitsOnly) ?? 0;
        }
      }
      if (userId == 0) {
        try {
          final storedUserId = await SecureStorageService().read(StorageKeys.userId);
          if (storedUserId != null && storedUserId.isNotEmpty) {
            final digitsOnly = storedUserId.replaceAll(RegExp(r'\D'), '');
            if (digitsOnly.isNotEmpty) {
              userId = int.tryParse(digitsOnly) ?? 0;
            }
          }
        } catch (_) {}
      }

      final response = await apiClient.post(
        ApiEndpoints.getQrCode,
        options: Options(validateStatus: (status) => status != null && status < 500),
        data: {
          'action': 'recharge_records',
          'user_id': userId,
        },
      );

      if (!mounted) return;
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true && data['categorized'] is Map) {
        final cat = data['categorized'] as Map;
        double pendingSum = 0.0;
        double successSum = 0.0;
        int pendingCount = 0;

        if (cat['pending'] is List) {
          final pendingList = cat['pending'] as List;
          pendingCount = pendingList.length;
          for (final item in pendingList) {
            pendingSum += double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
          }
        }
        if (cat['successful'] is List) {
          for (final item in (cat['successful'] as List)) {
            successSum += double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
          }
        }

        setState(() {
          _pendingAmount = pendingSum;
          _successfulAmount = successSum;
          if (pendingCount > _rechargeNotificationCount) {
            _hasSeenNotifications = false;
          }
          _rechargeNotificationCount = pendingCount;
        });
        return;
      }

      final rawList = (data is Map<String, dynamic> && data['success'] == true)
          ? (data['data'] is List
              ? data['data'] as List
              : (data['recharges'] is List ? data['recharges'] as List : null))
          : null;

      if (rawList != null) {
        double pendingSum = 0.0;
        double successSum = 0.0;
        int pendingCount = 0;

        for (final item in rawList) {
          final amt = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
          final status = (item['stage_status'] ?? item['status'] ?? '').toString().toLowerCase();

          if (status.contains('done') || status.contains('successful') || status.contains('approved')) {
            successSum += amt;
          } else if (status.contains('pending')) {
            pendingSum += amt;
            pendingCount++;
          }
        }

        setState(() {
          _pendingAmount = pendingSum;
          _successfulAmount = successSum;
          if (pendingCount > _rechargeNotificationCount) {
            _hasSeenNotifications = false;
          }
          _rechargeNotificationCount = pendingCount;
        });
      } else {
        _calculateFromLocalStorage();
      }
    } catch (_) {
      if (mounted) {
        _calculateFromLocalStorage();
      }
    }
  }

  void _calculateFromLocalStorage() {
    final localRecharges = LocalStorageRepositoryImpl().getSubmittedRecharges();
    double pendingSum = 0.0;
    double successSum = 0.0;

    int pendingCount = 0;
    for (final item in localRecharges) {
      double amt = 0.0;
      String status = '';
      if (item is Map) {
        amt = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
        status = (item['status'] ?? '').toString().toLowerCase();
      } else if (item is RechargeRecordModel) {
        amt = item.amount;
        status = item.status.toLowerCase();
      }

      if (status.contains('done') || status.contains('successful') || status.contains('approved')) {
        successSum += amt;
      } else if (status.contains('pending')) {
        pendingSum += amt;
        pendingCount++;
      }
    }

    if (mounted) {
      setState(() {
        _pendingAmount = pendingSum;
        _successfulAmount = successSum;
        // Only count truly pending records — never inflate badge with approved/done history
        if (pendingCount > _rechargeNotificationCount) {
          _hasSeenNotifications = false;
        }
        _rechargeNotificationCount = pendingCount;
      });
    }
  }

  int _rechargeNotificationCount = 0;
  bool _hasSeenNotifications = false;

  void _showUserRechargeNotificationsModal(BuildContext context, bool isDark) {
    // Mark as seen FIRST — do NOT call _fetchRechargeSummary() here because it fires
    // asynchronously and can reset _hasSeenNotifications=false AFTER it is set to true,
    // making the badge reappear while the modal is already open (race condition).
    // The periodic 15-second timer keeps the count fresh without this race.
    if (mounted) {
      setState(() {
        _hasSeenNotifications = true;
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.70,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0A091A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF2E2756) : const Color(0xFFECEAFE),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Color(0xFFFFD700),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Recharge Status',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (_rechargeNotificationCount > 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        _rechargeNotificationCount > 99
                                            ? '99+ Total'
                                            : '$_rechargeNotificationCount Total',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF7C3AED),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                'Order Game Name & Recharge Status',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          color: isDark ? Colors.white60 : Colors.grey[600],
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Single Line Notifications List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _UserRechargeSingleLineNotificationsWidget(isDark: isDark),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onPlayGame(GameCardModel game) async {
    // Show immediate loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(color: Color(0xFFFFD700), strokeWidth: 2),
            ),
            AppSpacing.hGapMd,
            Expanded(child: Text('Connecting to ${game.name} backend game engine...')),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF2C2F36),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final gameProvider = context.read<GameProvider>();
    final launchResult = await gameProvider.launchGame(game.id);

    if (!mounted) return;

    if (launchResult['success'] == true) {
      context.push(
        '/game-arena/${game.id}',
        extra: {
          'game': game,
          'launch_data': launchResult,
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(launchResult['message'] ?? 'Failed to initialize game with backend'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onOpenChat([String? gameName]) async {
    final secureStorage = SecureStorageService();
    final storedAgentId = await secureStorage.read(StorageKeys.chatAgentId);
    final currentUser = LocalStorageRepositoryImpl().getUser();

    final rawUserAgency = currentUser?.agencyId;
    final validUserAgency = (rawUserAgency != null &&
            rawUserAgency.isNotEmpty &&
            rawUserAgency != 'null' &&
            rawUserAgency != '0')
        ? rawUserAgency
        : ((storedAgentId != null &&
                storedAgentId.isNotEmpty &&
                storedAgentId != 'null')
            ? storedAgentId
            : 'ADMIN-1');

    final agentId = (validUserAgency.startsWith('AGENCY-') || validUserAgency.toUpperCase().contains('ADMIN') || validUserAgency.contains('@'))
        ? validUserAgency
        : 'AGENCY-$validUserAgency';

    if (!mounted) return;
    context.push(
      '/chat/$agentId',
      extra: gameName != null ? {'gameName': gameName} : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF010A26),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF021038) : const Color(0xFFEFF4FF),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0034A3),
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Color(0xFF010A26),
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          toolbarHeight: 66,
          titleSpacing: 14,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0044C4), Color(0xFF032279)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFFF8C00).withValues(alpha: 0.8),
                  width: 1.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8C00).withValues(alpha: 0.3),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          title: Row(
            children: [
              // Star Logo Icon + Title
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF031A5E),
                  border: Border.all(
                    color: const Color(0xFFFF8C00),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8C00).withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Fair',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'Biz',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFFF8C00),
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color: const Color(0xFFFF8C00).withValues(alpha: 0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '— Fair Online Hub —',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Notification Button (Shows Only Recharge Status Notifications for User)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showUserRechargeNotificationsModal(context, isDark),
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: const Color(0xFF0E0921),
                          border: Border.all(
                            color: (_rechargeNotificationCount > 0 && !_hasSeenNotifications) ? const Color(0xFFF59E0B) : const Color(0xFF3C2373),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_rechargeNotificationCount > 0 && !_hasSeenNotifications)
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                                  : const Color(0xFF6B39CF).withValues(alpha: 0.2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          (_rechargeNotificationCount > 0 && !_hasSeenNotifications)
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_none_rounded,
                          color: (_rechargeNotificationCount > 0 && !_hasSeenNotifications)
                              ? const Color(0xFFFFD700)
                              : const Color(0xFFA78BFA),
                          size: 20,
                        ),
                      ),
                      if (_rechargeNotificationCount > 0 && !_hasSeenNotifications)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF04020A), width: 1.5),
                            ),
                            child: Text(
                              _rechargeNotificationCount > 99
                                  ? '99+'
                                  : '$_rechargeNotificationCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Logout / Exit Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => AppLogoutDialog.show(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color(0xFF0E0921),
                      border: Border.all(
                        color: const Color(0xFF3C2373),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B39CF).withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.exit_to_app_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: _currentNavIndex == 2
                ? const UserProfileScreen()
                : RefreshIndicator(
                    onRefresh: () async {
                      await gameProvider.fetchGames();
                      await _fetchRechargeSummary();
                      await _rechargeRecordsKey.currentState?.refreshRecords();
                    },
                    color: const Color(0xFFFFD700),
                    child: _currentNavIndex == 0
                        ? _buildHomeBody(gameProvider, isDark)
                        : _buildHistoryBody(isDark),
                  ),
          ),
          DraggableFloatingChatButton(
            onTap: () => _onOpenChat(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF042168),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: const Color(0xFFFF8C00).withValues(alpha: 0.6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8C00).withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BottomNavigationBar(
            currentIndex: _currentNavIndex,
            onTap: (index) {
              setState(() {
                _currentNavIndex = index;
              });
              if (index == 1) {
                _rechargeRecordsKey.currentState?.refreshRecords();
              }
            },
            selectedItemColor: const Color(0xFFFF8C00),
            unselectedItemColor: const Color(0xFF94A3B8),
            selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.3),
            unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 11),
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded, color: Color(0xFFFF8C00)),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.subtitles_outlined),
                activeIcon: Icon(Icons.subtitles_rounded, color: Color(0xFFFF8C00)),
                label: 'Records',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded, color: Color(0xFFFF8C00)),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildHomeBody(GameProvider provider, bool isDark) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD700)),
      );
    }

    if (provider.errorMessage != null && provider.games.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
            AppSpacing.vGapMd,
            Text(provider.errorMessage!),
            AppSpacing.vGapLg,
            ElevatedButton(
              onPressed: () => provider.fetchGames(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFFFD700),
      backgroundColor: const Color(0xFF1F222A),
      onRefresh: () => provider.fetchGames(),
      child: ListView(
        padding: AppSpacing.pAllMd,
        children: [
        // Hero Banner Carousel (Randomly displays max 4 images on load/refresh)
        Builder(
          builder: (context) {
            final gameImages = provider.games
                .where((g) => g.imageUrl != null && g.imageUrl!.isNotEmpty)
                .map((g) => g.imageUrl!)
                .toList();

            final allBanners = <String>{
              ...provider.bannerUrls,
              ...gameImages,
            }.toList();

            allBanners.shuffle();
            final random4Banners = allBanners.take(4).toList();

            return BannerCarouselWidget(
              networkBannerUrls: random4Banners.isNotEmpty ? random4Banners : null,
            );
          },
        ),

        const SizedBox(height: 16),

        // Main Markets Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9400).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFF9400).withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.sports_esports_rounded,
                    size: 18,
                    color: Color(0xFFFF9400),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Popular Gaming Hub',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Showing ${provider.games.take(_displayedGamesCount).length} of ${provider.games.length} Games',
                style: const TextStyle(
                  color: Color(0xFFD97706),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.vGapMd,

        // Game Cards 2x2 Square Grid Layout
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: provider.games.take(_displayedGamesCount).length,
          itemBuilder: (context, index) {
            final game = provider.games.take(_displayedGamesCount).elementAt(index);
            return GameCardWidget(
              key: ValueKey('game_${game.id}'),
              game: game,
              isSquare: true,
              onPlay: () => _onPlayGame(game),
            );
          },
        ),

        // Pagination Controls / Load More Games Button
        if (_displayedGamesCount < provider.games.length)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _displayedGamesCount += 20;
                    });
                  },
                  icon: const Icon(Icons.expand_more_rounded, color: Colors.white),
                  label: Text(
                    'Load More Games (Showing ${provider.games.take(_displayedGamesCount).length} of ${provider.games.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ),
          ),
      ],
      ),
    );
  }

  Widget _buildHistoryBody(bool isDark) {
    return ListView(
      padding: AppSpacing.pAllMd,
      children: [
        RechargeRecordsWidget(key: _rechargeRecordsKey),
      ],
    );
  }
}

class _PlayGameModal extends StatefulWidget {
  final GameCardModel game;

  const _PlayGameModal({required this.game});

  @override
  State<_PlayGameModal> createState() => _PlayGameModalState();
}

class _PlayGameModalState extends State<_PlayGameModal> {
  String _selectedMarketType = 'Single Digit';
  final TextEditingController _digitController = TextEditingController();
  double _selectedPoints = 50.0;
  final List<double> _pointOptions = [10.0, 50.0, 100.0, 500.0];

  @override
  void dispose() {
    _digitController.dispose();
    super.dispose();
  }

  Future<void> _submitPlayRequest() async {
    final digit = _digitController.text.trim();
    if (digit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid digit or number to play'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final gameProvider = context.read<GameProvider>();
    final result = await gameProvider.playGame(
      gameId: widget.game.id,
      marketType: _selectedMarketType.toLowerCase().replaceAll(' ', '_'),
      digit: digit,
      points: _selectedPoints,
    );

    if (!mounted) return;

    Navigator.pop(context);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  result['message'] ?? 'Successfully placed bid on ${widget.game.name}!',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF198754),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to process play request'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gameProvider = context.watch<GameProvider>();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              AppSpacing.vGapLg,

              // Header Game Banner
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2F36),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.game.code,
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.game.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Result: ${widget.game.result} • ${widget.game.status}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.vGapLg,
              const Divider(),
              AppSpacing.vGapLg,

              // 1. Select Market Type
              const Text(
                '1. Select Market Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              AppSpacing.vGapSm,
              Row(
                children: [
                  for (final type in ['Single Digit', 'Jodi Digit', 'Single Panna'])
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedMarketType = type),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedMarketType == type
                                ? const Color(0xFF2C2F36)
                                : (isDark ? Colors.grey[800] : Colors.grey[100]),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedMarketType == type ? const Color(0xFFFFD700) : Colors.transparent,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            type,
                            style: TextStyle(
                              color: _selectedMarketType == type ? const Color(0xFFFFD700) : (isDark ? Colors.white : Colors.black87),
                              fontWeight: _selectedMarketType == type ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              AppSpacing.vGapLg,

              // 2. Enter Number / Digit
              const Text(
                '2. Enter Play Digit',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              AppSpacing.vGapSm,
              TextField(
                controller: _digitController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: _selectedMarketType == 'Single Digit'
                      ? 'Enter 1 Digit (e.g. 5)'
                      : _selectedMarketType == 'Jodi Digit'
                          ? 'Enter 2 Digits (e.g. 58)'
                          : 'Enter 3 Digits Panna (e.g. 140)',
                  prefixIcon: const Icon(Icons.pin_rounded, color: Color(0xFFFFD700)),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              AppSpacing.vGapLg,

              // 3. Select Points / Amount
              const Text(
                '3. Select Points',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              AppSpacing.vGapSm,
              Row(
                children: [
                  for (final pts in _pointOptions)
                    Expanded(
                      child: ChoiceChip(
                        label: Text('₹${pts.toInt()}'),
                        selected: _selectedPoints == pts,
                        selectedColor: const Color(0xFFFFD700),
                        onSelected: (val) {
                          if (val) setState(() => _selectedPoints = pts);
                        },
                      ),
                    ),
                ],
              ),
              AppSpacing.vGapXl,

              // Submit Button
              ElevatedButton(
                onPressed: gameProvider.isPlayingGame ? null : _submitPlayRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2F36),
                  foregroundColor: const Color(0xFFFFD700),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: gameProvider.isPlayingGame
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Color(0xFFFFD700), strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flash_on_rounded, color: Color(0xFFFFD700)),
                          SizedBox(width: 8),
                          Text(
                            'CONFIRM & PLAY NOW',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserRechargeSingleLineNotificationsWidget extends StatefulWidget {
  final bool isDark;
  const _UserRechargeSingleLineNotificationsWidget({required this.isDark});

  @override
  State<_UserRechargeSingleLineNotificationsWidget> createState() => _UserRechargeSingleLineNotificationsWidgetState();
}

class _UserRechargeSingleLineNotificationsWidgetState extends State<_UserRechargeSingleLineNotificationsWidget> {
  bool _isLoading = true;
  List<RechargeRecordModel> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final apiClient = ApiClient();
      int userId = 0;
      final currentUser = LocalStorageRepositoryImpl().getUser();
      if (currentUser?.id != null && currentUser!.id.isNotEmpty) {
        final digitsOnly = currentUser.id.replaceAll(RegExp(r'\D'), '');
        if (digitsOnly.isNotEmpty) {
          userId = int.tryParse(digitsOnly) ?? 0;
        }
      }
      if (userId == 0) {
        try {
          final storedUserId = await SecureStorageService().read(StorageKeys.userId);
          if (storedUserId != null && storedUserId.isNotEmpty) {
            final digitsOnly = storedUserId.replaceAll(RegExp(r'\D'), '');
            if (digitsOnly.isNotEmpty) {
              userId = int.tryParse(digitsOnly) ?? 0;
            }
          }
        } catch (_) {}
      }

      final response = await apiClient.post(
        ApiEndpoints.getQrCode,
        options: Options(validateStatus: (status) => status != null && status < 500),
        data: {
          'action': 'recharge_records',
          'user_id': userId,
        },
      );

      if (!mounted) return;
      final List<RechargeRecordModel> fetched = [];
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        List rawList = [];
        if (data['data'] is List && (data['data'] as List).isNotEmpty) {
          rawList.addAll(data['data'] as List);
        } else if (data['recharges'] is List && (data['recharges'] as List).isNotEmpty) {
          rawList.addAll(data['recharges'] as List);
        } else if (data['categorized'] is Map) {
          final cat = data['categorized'] as Map;
          if (cat['pending'] is List) rawList.addAll(cat['pending'] as List);
          if (cat['successful'] is List) rawList.addAll(cat['successful'] as List);
          if (cat['rejected'] is List) rawList.addAll(cat['rejected'] as List);
        }

        for (final item in rawList) {
          final idVal = item['recharge_id'] ?? item['id'] ?? '';
          final bookIdVal = item['book_id']?.toString();
          final rawBookName = item['book_name']?.toString() ?? item['book']?.toString();

          String resolvedBookName = 'Lucky Vault';
          if (rawBookName != null && rawBookName.isNotEmpty) {
            resolvedBookName = rawBookName;
          } else if (bookIdVal != null) {
            switch (bookIdVal) {
              case '324': resolvedBookName = 'Lucky Vault'; break;
              case '323': resolvedBookName = 'Dice Verse'; break;
              case '322': resolvedBookName = 'Jackpot Spin'; break;
              case '321': resolvedBookName = 'Gold Rush Pro'; break;
              case '310': resolvedBookName = 'Infinity Fortune'; break;
              case '309': resolvedBookName = 'Crown Riches'; break;
            }
          }

          final rawAmount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
          final rawStatus = item['stage_status']?.toString() ?? item['status']?.toString() ?? 'PENDING';

          fetched.add(
            RechargeRecordModel(
              id: idVal.toString(),
              bookName: resolvedBookName,
              transactionDetails: '₹${rawAmount.toStringAsFixed(0)}',
              amount: rawAmount,
              status: rawStatus,
              date: item['date']?.toString() ?? 'Recent',
            ),
          );
        }
      }

      if (fetched.isEmpty) {
        final local = LocalStorageRepositoryImpl().getSubmittedRecharges();
        for (final item in local) {
          if (item is RechargeRecordModel) {
            fetched.add(item);
          } else if (item is Map) {
            fetched.add(
              RechargeRecordModel(
                id: (item['id'] ?? '').toString(),
                bookName: (item['bookName'] ?? 'Lucky Vault').toString(),
                transactionDetails: '₹${item['amount']}',
                amount: double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0,
                status: (item['status'] ?? 'PENDING').toString(),
                date: (item['date'] ?? 'Recent').toString(),
              ),
            );
          }
        }
      }

      setState(() {
        _records = fetched;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _visibleCount = 20;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _NotificationSkeletonList(isDark: widget.isDark);
    }

    if (_records.isEmpty) {
      return Center(
        child: Text(
          'No recharge status notifications.',
          style: TextStyle(
            fontSize: 13,
            color: widget.isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      );
    }

    final displayRecords = _records.take(_visibleCount).toList();
    final remainingCount = _records.length - displayRecords.length;

    return ListView.builder(
      itemCount: displayRecords.length + (remainingCount > 0 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == displayRecords.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _visibleCount += 20;
                  });
                },
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFFFFD700)),
                label: Text(
                  'Load More Notifications ($remainingCount remaining)',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFD700)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          );
        }

        final record = displayRecords[index];
        final st = record.status.toLowerCase();

        Color statusColor = const Color(0xFFF59E0B);
        String statusText = 'Pending';

        if (st.contains('done') || st.contains('successful') || st.contains('approved')) {
          statusColor = const Color(0xFF10B981);
          statusText = 'Approved';
        } else if (st.contains('reject') || st.contains('fail') || st.contains('cancel')) {
          statusColor = const Color(0xFFEF4444);
          statusText = 'Rejected';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF13102B) : const Color(0xFFF8F7FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDark ? const Color(0xFF2E2756) : const Color(0xFFECEAFE),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.sports_esports_rounded, color: Color(0xFFFFD700), size: 18),
              const SizedBox(width: 10),
              // Single Line Format: Game Name • ₹Amount
              Expanded(
                child: Text(
                  '${record.bookName} • ₹${record.amount.toStringAsFixed(0)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Single Line Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationSkeletonList extends StatefulWidget {
  final bool isDark;
  const _NotificationSkeletonList({required this.isDark});

  @override
  State<_NotificationSkeletonList> createState() => _NotificationSkeletonListState();
}

class _NotificationSkeletonListState extends State<_NotificationSkeletonList>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _opacityAnim = Tween<double>(begin: 0.25, end: 0.75).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark ? const Color(0xFF231E40) : const Color(0xFFEBE9FE);
    final borderColor = widget.isDark ? const Color(0xFF2E2756) : const Color(0xFFDDD6FE);

    return AnimatedBuilder(
      animation: _opacityAnim,
      builder: (context, child) {
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: 5,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF13102B) : const Color(0xFFF8F7FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  // Icon Circle Skeleton
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: baseColor.withValues(alpha: _opacityAnim.value),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title Line Skeleton
                  Expanded(
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: baseColor.withValues(alpha: _opacityAnim.value),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Status Pill Skeleton
                  Container(
                    width: 68,
                    height: 22,
                    decoration: BoxDecoration(
                      color: baseColor.withValues(alpha: _opacityAnim.value),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}


