import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/game/game_card_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/game_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/common/app_logout_dialog.dart';
import '../../profile/presentation/user_profile_screen.dart';
import 'widgets/banner_carousel_widget.dart';
import 'widgets/game_card_widget.dart';
import 'widgets/quick_category_widget.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().fetchGames();
    });
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

  void _onOpenChat([String? gameName]) {
    context.push(
      '/chat/agency_support',
      extra: gameName != null ? {'gameName': gameName} : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF04020A) : const Color(0xFFF5F4FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF04020A),
            border: const Border(
              bottom: BorderSide(
                color: Color(0xFF7C3AED),
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  // Star Logo Icon + Title
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0E0921),
                      border: Border.all(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.star_rounded, color: Color(0xFFFFC700), size: 24),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'GOLDEN ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        TextSpan(
                          text: '888',
                          style: TextStyle(
                            color: Color(0xFFFFC700),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // Wallet Chip (matching screenshot: purple wallet icon + purple ₹0 text)
                  InkWell(
                    onTap: () => setState(() => _currentNavIndex = 1),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E0722),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF6B39CF),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B39CF).withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Color(0xFF9061F9),
                            size: 19,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '₹0',
                            style: TextStyle(
                              color: Color(0xFF9061F9),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Profile Icon Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _currentNavIndex = 3),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
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
                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
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
          ),
        ),
      ),
      body: SafeArea(
        child: _currentNavIndex == 3
            ? const UserProfileScreen()
            : RefreshIndicator(
                onRefresh: () => gameProvider.fetchGames(),
                color: const Color(0xFFFFD700),
                child: _currentNavIndex == 0
                    ? _buildHomeBody(gameProvider, isDark)
                    : _currentNavIndex == 1
                        ? _buildWalletBody(authProvider, isDark)
                        : _buildHistoryBody(isDark),
              ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0A091A),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
              blurRadius: 20,
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
            },
            selectedItemColor: const Color(0xFFA78BFA),
            unselectedItemColor: const Color(0xFF94A3B8),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded, color: Color(0xFFA78BFA)),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFA78BFA)),
                label: 'Wallet',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history_rounded, color: Color(0xFFA78BFA)),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded, color: Color(0xFFA78BFA)),
                label: 'Profile',
              ),
            ],
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

    return ListView(
      padding: AppSpacing.pAllMd,
      children: [
        // Hero Banner Carousel
        const BannerCarouselWidget(),

        // Starline & Jackpot Games Section
        QuickCategoryWidget(
          onSelectCategory: (category) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Selected $category Market'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        AppSpacing.vGapLg,

        // Main Markets Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Main Markets',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${provider.games.length} Live Games',
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

        // Game Cards List
        ...provider.games.map(
          (game) => GameCardWidget(
            game: game,
            onPlay: () => _onPlayGame(game),
            onChat: () => _onOpenChat(game.name),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletBody(AuthProvider authProvider, bool isDark) {
    final userName = authProvider.currentUser?.name;
    return ListView(
      padding: AppSpacing.pAllMd,
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: AppSpacing.pAllLg,
            child: Column(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, size: 48, color: Color(0xFFFFD700)),
                AppSpacing.vGapSm,
                Text(
                  userName != null && userName.isNotEmpty
                      ? 'Available Balance ($userName)'
                      : 'Available Balance',
                  style: const TextStyle(color: Colors.grey),
                ),
                AppSpacing.vGapXs,
                const Text('₹0.00', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                AppSpacing.vGapLg,
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                        label: const Text('Add Cash'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF198754),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    AppSpacing.hGapMd,
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.arrow_upward),
                        label: const Text('Withdraw'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C2F36),
                          foregroundColor: const Color(0xFFFFD700),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryBody(bool isDark) {
    return ListView(
      padding: AppSpacing.pAllMd,
      children: [
        const Text('Bid & Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        AppSpacing.vGapMd,
        Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey[400]),
                AppSpacing.vGapMd,
                Text('No transaction history found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              ],
            ),
          ),
        ),
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
                children: ['Single Digit', 'Jodi Digit', 'Single Panna'].map((type) {
                  final isSelected = _selectedMarketType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMarketType = type),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2C2F36)
                              : (isDark ? Colors.grey[800] : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          type,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFFFFD700) : (isDark ? Colors.white : Colors.black87),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
                children: _pointOptions.map((pts) {
                  final isSelected = _selectedPoints == pts;
                  return Expanded(
                    child: ChoiceChip(
                      label: Text('₹${pts.toInt()}'),
                      selected: isSelected,
                      selectedColor: const Color(0xFFFFD700),
                      onSelected: (val) {
                        if (val) setState(() => _selectedPoints = pts);
                      },
                    ),
                  );
                }).toList(),
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

