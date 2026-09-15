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
import '../../../providers/auth_provider.dart';
import '../../../providers/game_provider.dart';
import '../../../network/api_client.dart';
import '../../../storage/local_storage_repository.dart';
import '../../../storage/secure_storage_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/common/app_logout_dialog.dart';
import '../../profile/presentation/user_profile_screen.dart';
import 'widgets/banner_carousel_widget.dart';
import 'widgets/game_card_widget.dart';
import 'widgets/recharge_now_widget.dart';
import 'widgets/recharge_records_widget.dart';
import 'widgets/withdraw_request_widget.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentNavIndex = 0;
  int _displayedGamesCount = 25;
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

  Set<String> _seenNotificationKeys = {};
  List<String> _currentFetchedNotificationKeys = [];
  int _rechargeNotificationCount = 0;
  bool _hasSeenNotifications = false;

  void _updateNotificationCount(List<Map<String, dynamic>> items) {
    final storage = LocalStorageRepositoryImpl();
    _seenNotificationKeys = storage.getSeenNotificationKeys();

    final List<String> allKeys = [];
    int unseenCount = 0;

    for (final item in items) {
      final id = (item['id'] ?? item['recharge_id'] ?? item['withdrawal_id'] ?? '').toString().trim();
      final status = (item['stage_status'] ?? item['status'] ?? 'PENDING').toString().trim().toUpperCase();
      final isWithdraw = item['type'] == 'withdraw' || id.startsWith('W') || (item['transactionDetails']?.toString().contains('Withdrawal') ?? false);
      final prefix = isWithdraw ? 'W' : 'R';

      if (id.isNotEmpty) {
        final cleanId = id.replaceAll(RegExp(r'^[RW]_?'), '');
        final key = '${prefix}_${cleanId}_$status';
        allKeys.add(key);
        if (!_seenNotificationKeys.contains(key)) {
          unseenCount++;
        }
      }
    }

    _currentFetchedNotificationKeys = allKeys;
    _rechargeNotificationCount = unseenCount;
    _hasSeenNotifications = (unseenCount == 0);
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

      final responses = await Future.wait([
        apiClient.post(
          ApiEndpoints.getQrCode,
          options: Options(validateStatus: (status) => status != null && status < 500),
          data: {'action': 'recharge_records', 'user_id': userId},
        ),
        apiClient.post(
          ApiEndpoints.getQrCode,
          options: Options(validateStatus: (status) => status != null && status < 500),
          data: {'action': 'withdraw_records', 'user_id': userId},
        ),
      ]);

      if (!mounted) return;
      final List<Map<String, dynamic>> allItems = [];
      double pendingSum = 0.0;
      double successSum = 0.0;

      // 1. Process Recharge Records
      final rData = responses[0].data;
      if (rData is Map<String, dynamic> && rData['success'] == true) {
        List rawList = [];
        if (rData['categorized'] is Map) {
          final cat = rData['categorized'] as Map;
          if (cat['pending'] is List) rawList.addAll(cat['pending'] as List);
          if (cat['successful'] is List) rawList.addAll(cat['successful'] as List);
          if (cat['rejected'] is List) rawList.addAll(cat['rejected'] as List);
        } else if (rData['data'] is List) {
          rawList.addAll(rData['data'] as List);
        } else if (rData['recharges'] is List) {
          rawList.addAll(rData['recharges'] as List);
        }

        for (final item in rawList) {
          if (item is Map) {
            final m = Map<String, dynamic>.from(item);
            m['type'] = 'recharge';
            allItems.add(m);
            final amt = double.tryParse(m['amount']?.toString() ?? '0') ?? 0.0;
            final status = (m['stage_status'] ?? m['status'] ?? '').toString().toLowerCase();
            if (status.contains('done') || status.contains('successful') || status.contains('approved')) {
              successSum += amt;
            } else if (status.contains('pending')) {
              pendingSum += amt;
            }
          }
        }
      }

      // 2. Process Withdrawal Records
      final wData = responses[1].data;
      if (wData is Map<String, dynamic> && wData['success'] == true) {
        List rawWList = [];
        if (wData['categorized'] is Map) {
          final cat = wData['categorized'] as Map;
          if (cat['pending'] is List) rawWList.addAll(cat['pending'] as List);
          if (cat['successful'] is List) rawWList.addAll(cat['successful'] as List);
          if (cat['rejected'] is List) rawWList.addAll(cat['rejected'] as List);
        } else if (wData['data'] is List) {
          rawWList.addAll(wData['data'] as List);
        } else if (wData['withdrawals'] is List) {
          rawWList.addAll(wData['withdrawals'] as List);
        }

        for (final item in rawWList) {
          if (item is Map) {
            final m = Map<String, dynamic>.from(item);
            m['type'] = 'withdraw';
            allItems.add(m);
          }
        }
      }

      // 3. Merge local submitted recharges
      final localList = LocalStorageRepositoryImpl().getSubmittedRecharges();
      for (final item in localList) {
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          final idStr = (m['id'] ?? '').toString();
          if (idStr.isNotEmpty && !allItems.any((r) => (r['id'] ?? r['recharge_id'])?.toString() == idStr)) {
            m['type'] = 'recharge';
            allItems.add(m);
          }
        }
      }

      if (mounted) {
        setState(() {
          _pendingAmount = pendingSum;
          _successfulAmount = successSum;
          _updateNotificationCount(allItems);
        });
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
    final List<Map<String, dynamic>> allItems = [];

    for (final item in localRecharges) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        m['type'] = 'recharge';
        allItems.add(m);
        final amt = double.tryParse(m['amount']?.toString() ?? '0') ?? 0.0;
        final status = (m['status'] ?? '').toString().toLowerCase();
        if (status.contains('done') || status.contains('successful') || status.contains('approved')) {
          successSum += amt;
        } else if (status.contains('pending')) {
          pendingSum += amt;
        }
      } else if (item is RechargeRecordModel) {
        allItems.add({
          'id': item.id,
          'status': item.status,
          'amount': item.amount,
          'type': 'recharge',
        });
        if (item.status.toLowerCase().contains('done') || item.status.toLowerCase().contains('successful') || item.status.toLowerCase().contains('approved')) {
          successSum += item.amount;
        } else if (item.status.toLowerCase().contains('pending')) {
          pendingSum += item.amount;
        }
      }
    }

    if (mounted) {
      setState(() {
        _pendingAmount = pendingSum;
        _successfulAmount = successSum;
        _updateNotificationCount(allItems);
      });
    }
  }

  void _showUserRechargeNotificationsModal(BuildContext context, bool isDark) {
    // Persist all current notification keys as SEEN!
    final repo = LocalStorageRepositoryImpl();
    _seenNotificationKeys = repo.getSeenNotificationKeys();
    _seenNotificationKeys.addAll(_currentFetchedNotificationKeys);
    repo.saveSeenNotificationKeys(_seenNotificationKeys);

    if (mounted) {
      setState(() {
        _hasSeenNotifications = true;
        _rechargeNotificationCount = 0;
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: BoxDecoration(
            color: const Color(0xFF070D22),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: const Color(0xFF0066FF).withValues(alpha: 0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0066FF).withValues(alpha: 0.3),
                blurRadius: 28,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00D2FF), Color(0xFF0066FF)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0088FF).withValues(alpha: 0.6),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Text(
                                      'Notifications',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (_rechargeNotificationCount > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0066FF).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFF00B2FF).withValues(alpha: 0.5)),
                                        ),
                                        child: Text(
                                          _rechargeNotificationCount > 99
                                              ? '99+ New'
                                              : '$_rechargeNotificationCount New',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF00B2FF),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Recharge & Withdrawal status updates',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Notifications List
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: _UserRechargeSingleLineNotificationsWidget(isDark: true),
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
        statusBarColor: Color(0xFF040816),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildDreamHubSideDrawer(context),
        backgroundColor: const Color(0xFF060B1E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF070E26),
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Color(0xFF040816),
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          toolbarHeight: 68,
          titleSpacing: 14,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A1332), Color(0xFF060B1E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.2),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          title: Row(
            children: [
              // Left: Hamburger Menu Button (Matching Reference)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1435),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF0066FF).withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0066FF).withValues(alpha: 0.25),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.menu_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Center: DreamHub App Logo & Title
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xFF031A5E),
                          border: Border.all(
                            color: const Color(0xFF00B2FF),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00B2FF).withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Dream',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Hub',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF00B2FF),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    shadows: [
                                      Shadow(
                                        color: const Color(0xFF00B2FF).withValues(alpha: 0.6),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '— Dream Online Hub —',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Right Section: Notifications Bell & Profile Avatar (Matching Reference style)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showUserRechargeNotificationsModal(context, isDark),
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1435),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (_rechargeNotificationCount > 0 && !_hasSeenNotifications)
                                ? const Color(0xFF00B2FF)
                                : const Color(0xFF0066FF).withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0066FF).withValues(alpha: 0.25),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          (_rechargeNotificationCount > 0 && !_hasSeenNotifications)
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_none_rounded,
                          color: (_rechargeNotificationCount > 0 && !_hasSeenNotifications)
                              ? const Color(0xFF00B2FF)
                              : Colors.white.withValues(alpha: 0.8),
                          size: 20,
                        ),
                      ),
                      if (_rechargeNotificationCount > 0 && !_hasSeenNotifications)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF060B1E), width: 1),
                            ),
                            child: Text(
                              _rechargeNotificationCount > 99
                                  ? '99+'
                                  : '$_rechargeNotificationCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
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

              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _currentNavIndex = 4; // Navigate to Profile
                    });
                  },
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1435),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0066FF).withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0066FF).withValues(alpha: 0.25),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: _buildSelectedTabBody(gameProvider, isDark),
        ),
        bottomNavigationBar: _buildReferenceBottomNavigationBar(),
      ),
    );
  }

  Widget _buildSelectedTabBody(GameProvider gameProvider, bool isDark) {
    switch (_currentNavIndex) {
      case 0:
        return RefreshIndicator(
          onRefresh: () async {
            await gameProvider.fetchGames();
            await _fetchRechargeSummary();
          },
          color: const Color(0xFF00B2FF),
          child: _buildHomeBody(gameProvider, isDark),
        );
      case 1:
        return const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: RechargeNowWidget(),
        );
      case 2:
        return const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: WithdrawRequestWidget(),
        );
      case 3:
        return RefreshIndicator(
          onRefresh: () async {
            await _rechargeRecordsKey.currentState?.refreshRecords();
          },
          color: const Color(0xFF00B2FF),
          child: _buildHistoryBody(isDark),
        );
      case 4:
        return const UserProfileScreen();
      default:
        return _buildHomeBody(gameProvider, isDark);
    }
  }

  Widget _buildReferenceBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF070D22),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF0066FF).withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066FF).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: _buildNavItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Dashboard',
              ),
            ),
            Expanded(
              child: _buildNavItem(
                index: 1,
                icon: Icons.flash_on_rounded,
                label: 'Recharge',
              ),
            ),
            Expanded(
              child: _buildMiddleSupportNavItem(),
            ),
            Expanded(
              child: _buildNavItem(
                index: 2,
                icon: Icons.card_giftcard_rounded,
                label: 'Withdraw',
              ),
            ),
            Expanded(
              child: _buildNavItem(
                index: 3,
                icon: Icons.receipt_long_rounded,
                label: 'Records',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiddleSupportNavItem() {
    return GestureDetector(
      onTap: () => _onOpenChat(),
      behavior: HitTestBehavior.opaque,
      child: Transform.translate(
        offset: const Offset(0, -6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF0052FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00B2FF).withValues(alpha: 0.65),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Chat',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF00B2FF),
                  fontWeight: FontWeight.w900,
                  fontSize: 11.5,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentNavIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentNavIndex = index;
        });
        if (index == 3) {
          _rechargeRecordsKey.currentState?.refreshRecords();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? const Color(0xFF0066FF) : Colors.transparent,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0066FF).withValues(alpha: 0.6),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.45),
              size: 20,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? const Color(0xFF00B2FF) : Colors.white.withValues(alpha: 0.45),
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                fontSize: 10.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildHomeBody(GameProvider provider, bool isDark) {
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

    final displayedGames = provider.games.take(_displayedGamesCount).toList();

    return RefreshIndicator(
      color: const Color(0xFF00B2FF),
      backgroundColor: const Color(0xFF070D22),
      onRefresh: () => provider.fetchGames(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 250) {
            if (_displayedGamesCount < provider.games.length) {
              setState(() {
                _displayedGamesCount = (_displayedGamesCount + 25).clamp(0, provider.games.length);
              });
            }
          }
          return false;
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          children: [
            // Hero Banner Carousel
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
            const SizedBox(height: 14),

            // Main Games Section Header (Matching Reference: "Games" on left, "View All >" on right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Games',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _displayedGamesCount = provider.games.length;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF00B2FF),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF00B2FF),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Games Horizontal Row Cards List (Matching Reference layout)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedGames.length,
              itemBuilder: (context, index) {
                final game = displayedGames[index];
                return GameCardWidget(
                  key: ValueKey('game_${game.id}'),
                  game: game,
                  isSquare: false,
                  onPlay: () => _onPlayGame(game),
                );
              },
            ),

            const SizedBox(height: 14),

          // Trust & Feature Banner (Matching Reference bottom feature card)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
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
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Left Column: Safe • Secure • Trusted
                Expanded(
                  flex: 6,
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0066FF).withValues(alpha: 0.2),
                          border: Border.all(
                            color: const Color(0xFF00B2FF).withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: Color(0xFF00B2FF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Safe  •  Secure  •  Trusted',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your gaming experience, our priority.',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Vertical Divider
                Container(
                  height: 32,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: Colors.white.withValues(alpha: 0.15),
                ),

                // Right Column: 24/7 Customer Support >
                Expanded(
                  flex: 5,
                  child: InkWell(
                    onTap: () => _onOpenChat(),
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0066FF).withValues(alpha: 0.2),
                            border: Border.all(
                              color: const Color(0xFF00B2FF).withValues(alpha: 0.6),
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.groups_rounded,
                            color: Color(0xFF00B2FF),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Text(
                                      '24/7',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: Color(0xFF00B2FF),
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Customer Support',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
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

  Widget _buildDreamHubSideDrawer(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final user = authProv.currentUser ?? LocalStorageRepositoryImpl().getUser();
    final userName = user?.name.isNotEmpty == true ? user!.name : 'Final Test';
    final userEmail = user?.email.isNotEmpty == true ? user!.email : 'finaltest1@gmail.com';

    return Drawer(
      width: (MediaQuery.of(context).size.width * 0.82).clamp(280.0, 330.0),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0C1433),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          border: Border.all(
            color: const Color(0xFF0066FF).withValues(alpha: 0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0066FF).withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row (User Avatar, User Info, Close Button)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Container with Glowing Outer Ring matching reference
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D2FF), Color(0xFF0066FF)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0088FF).withValues(alpha: 0.8),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2.5),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF162350),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // User Account Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0C2454),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF0088FF).withValues(alpha: 0.6),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_user_rounded,
                                  color: Color(0xFF00B2FF),
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'User Account',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF00B2FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Close (X) Icon Button
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Navigation Items List
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // 1. Home
                      _buildDrawerItem(
                        icon: Icons.home_rounded,
                        label: 'Home',
                        isSelected: _currentNavIndex == 0,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _currentNavIndex = 0);
                        },
                      ),

                      // 2. Recharge
                      _buildDrawerItem(
                        icon: Icons.flash_on_rounded,
                        label: 'Recharge',
                        isSelected: _currentNavIndex == 1,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _currentNavIndex = 1);
                        },
                      ),

                      // 3. Withdraw
                      _buildDrawerItem(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Withdraw',
                        isSelected: _currentNavIndex == 2,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _currentNavIndex = 2);
                        },
                      ),

                      // 4. Recharge Records
                      _buildDrawerItem(
                        icon: Icons.receipt_long_rounded,
                        label: 'Recharge Records',
                        isSelected: _currentNavIndex == 3,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _currentNavIndex = 3);
                          _rechargeRecordsKey.currentState?.refreshRecords();
                        },
                      ),

                      // 5. Profile
                      _buildDrawerItem(
                        icon: Icons.person_rounded,
                        label: 'Profile',
                        isSelected: _currentNavIndex == 4,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _currentNavIndex = 4);
                        },
                      ),

                      // 6. Change Password
                      _buildDrawerItem(
                        icon: Icons.lock_rounded,
                        label: 'Change Password',
                        isSelected: false,
                        onTap: () {
                          Navigator.pop(context);
                          UserProfileScreen.showUpdatePasswordDialog(context);
                        },
                      ),

                      // 7. Tutorial / Help
                      _buildDrawerItem(
                        icon: Icons.help_outline_rounded,
                        label: 'Tutorial / Help',
                        badgeText: 'NEW',
                        subtitle: 'Learn how to get ID & how to use',
                        isSelected: false,
                        onTap: () {
                          Navigator.pop(context);
                          _onOpenChat();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Bottom Sign Out Button matching reference picture pill format
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141C3D),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        AppLogoutDialog.show(context);
                      },
                      borderRadius: BorderRadius.circular(25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sign out',
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    String? badgeText,
    String? subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF1E60FF), Color(0xFF004BE8)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isSelected ? null : const Color(0xFF131A36),
        border: Border.all(
          color: isSelected
              ? Colors.transparent
              : const Color(0xFF1E294E).withValues(alpha: 0.7),
          width: 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0038B8)
                        : const Color(0xFF1A2346),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (badgeText != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF93C3C),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badgeText,
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.white.withValues(alpha: 0.54),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
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

      final List<RechargeRecordModel> fetched = [];

      // 1. Fetch Recharge Records
      final rechargeResp = await apiClient.post(
        ApiEndpoints.getQrCode,
        options: Options(validateStatus: (status) => status != null && status < 500),
        data: {
          'action': 'recharge_records',
          'user_id': userId,
        },
      );

      if (!mounted) return;
      final rData = rechargeResp.data;
      if (rData is Map<String, dynamic>) {
        final isSuccess = rData['success'] == true ||
            rData['success'] == 1 ||
            rData['success'] == '1' ||
            rData['success'] == 'true';
        if (isSuccess || rData['data'] != null || rData['recharges'] != null || rData['categorized'] != null) {
          List rawList = [];
          if (rData['data'] is List && (rData['data'] as List).isNotEmpty) {
            rawList.addAll(rData['data'] as List);
          } else if (rData['recharges'] is List && (rData['recharges'] as List).isNotEmpty) {
            rawList.addAll(rData['recharges'] as List);
          } else if (rData['records'] is List && (rData['records'] as List).isNotEmpty) {
            rawList.addAll(rData['records'] as List);
          } else if (rData['categorized'] is Map) {
            final cat = rData['categorized'] as Map;
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
                transactionDetails: 'Recharge • ₹${rawAmount.toStringAsFixed(0)}',
                amount: rawAmount,
                status: rawStatus,
                date: item['date']?.toString() ?? 'Recent',
              ),
            );
          }
        }
      }

      // 2. Fetch Withdrawal Records
      try {
        final withdrawResp = await apiClient.post(
          ApiEndpoints.getQrCode,
          options: Options(validateStatus: (status) => status != null && status < 500),
          data: {
            'action': 'withdraw_records',
            'user_id': userId,
          },
        );

        if (mounted && withdrawResp.data is Map<String, dynamic>) {
          final wData = withdrawResp.data;
          final isWSuccess = wData['success'] == true ||
              wData['success'] == 1 ||
              wData['success'] == '1' ||
              wData['success'] == 'true';

          if (isWSuccess || wData['data'] != null || wData['withdrawals'] != null || wData['categorized'] != null) {
            List rawWList = [];
            if (wData['data'] is List && (wData['data'] as List).isNotEmpty) {
              rawWList.addAll(wData['data'] as List);
            } else if (wData['withdrawals'] is List && (wData['withdrawals'] as List).isNotEmpty) {
              rawWList.addAll(wData['withdrawals'] as List);
            } else if (wData['categorized'] is Map) {
              final cat = wData['categorized'] as Map;
              if (cat['pending'] is List) rawWList.addAll(cat['pending'] as List);
              if (cat['successful'] is List) rawWList.addAll(cat['successful'] as List);
              if (cat['rejected'] is List) rawWList.addAll(cat['rejected'] as List);
            }

            for (final item in rawWList) {
              final wIdVal = item['withdrawal_id'] ?? item['id'] ?? '';
              final rawAmount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
              final rawStatus = item['stage_status']?.toString() ?? item['status']?.toString() ?? 'PENDING';
              final rawBookName = item['book_name']?.toString() ?? item['book']?.toString() ?? 'Lucky Vault';

              fetched.add(
                RechargeRecordModel(
                  id: 'W${wIdVal.toString()}',
                  bookName: rawBookName,
                  transactionDetails: 'Withdrawal • ₹${rawAmount.toStringAsFixed(0)}',
                  amount: rawAmount,
                  status: rawStatus,
                  date: item['date']?.toString() ?? 'Recent',
                ),
              );
            }
          }
        }
      } catch (_) {}

      // 3. Merge local submitted recharges
      final local = LocalStorageRepositoryImpl().getSubmittedRecharges();
      for (final item in local) {
        if (item is Map) {
          final idStr = (item['id'] ?? '').toString();
          if (idStr.isNotEmpty && !fetched.any((r) => r.id == idStr)) {
            fetched.insert(
              0,
              RechargeRecordModel(
                id: idStr,
                bookName: (item['bookName'] ?? 'Lucky Vault').toString(),
                transactionDetails: 'Recharge • ₹${item['amount']}',
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
      return const _NotificationSkeletonList(isDark: true);
    }

    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, size: 48, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'No status notifications yet.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
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
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF00B2FF)),
                label: Text(
                  'Load More Notifications ($remainingCount remaining)',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00B2FF),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00B2FF)),
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

        Color statusFg = const Color(0xFFFFB800);
        Color statusBg = const Color(0xFF2E2105);
        String statusText = 'PENDING';

        if (st.contains('done') || st.contains('successful') || st.contains('approved') || st.contains('success')) {
          statusFg = const Color(0xFF10B981);
          statusBg = const Color(0xFF052E16);
          statusText = 'APPROVED';
        } else if (st.contains('reject') || st.contains('fail') || st.contains('cancel') || st.contains('decline')) {
          statusFg = const Color(0xFFEF4444);
          statusBg = const Color(0xFF2E080A);
          statusText = 'REJECTED';
        }

        final isWithdrawal = record.id.startsWith('W') || record.transactionDetails.contains('Withdrawal');

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1435),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF0066FF).withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isWithdrawal ? const Color(0xFF8B5CF6) : const Color(0xFFFF6B00)).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isWithdrawal ? Icons.account_balance_wallet_rounded : Icons.flash_on_rounded,
                  color: isWithdrawal ? const Color(0xFF8B5CF6) : const Color(0xFFFF6B00),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${record.bookName} • ₹${record.amount.toStringAsFixed(0)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${record.transactionDetails} • ${record.date}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusFg.withValues(alpha: 0.5), width: 1),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusFg,
                    ),
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


