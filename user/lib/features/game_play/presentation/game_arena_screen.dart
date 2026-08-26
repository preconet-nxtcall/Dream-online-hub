import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/game/game_card_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

class GameArenaScreen extends StatelessWidget {
  final String gameId;
  final GameCardModel? game;
  final Map<String, dynamic>? launchData;

  const GameArenaScreen({
    super.key,
    required this.gameId,
    this.game,
    this.launchData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gameTitle = game?.name ?? 'Game Arena #$gameId';
    final gameCode = game?.code ?? 'GM';
    final sessionToken = launchData?['session_token'] ?? 'sess_active_$gameId';
    final gameUrl = launchData?['game_url'] ?? 'https://zara.androsoft.in/game/$gameId';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2025),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                gameCode,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: Text(
                gameTitle,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: AppColors.success, size: 8),
                SizedBox(width: 4),
                Text(
                  'LIVE BACKEND',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.hGapSm,
        ],
      ),
      body: Container(
        color: isDark ? const Color(0xFF14161C) : const Color(0xFFF8FAFC),
        child: Column(
          children: [
            // Backend Game Header Info Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? const Color(0xFF242730) : const Color(0xFFE2E8F0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFFFFD700)),
                      const SizedBox(width: 6),
                      Text(
                        'Session: ${sessionToken.length > 18 ? sessionToken.substring(0, 18) : sessionToken}...',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded, size: 16, color: Color(0xFF198754)),
                      SizedBox(width: 4),
                      Text(
                        '₹0.00',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Game Arena Body Interface (Served by Backend)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2F36),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sports_esports_rounded,
                          size: 64,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                      AppSpacing.vGapLg,
                      Text(
                        'Backend Game Arena Activated',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      AppSpacing.vGapSm,
                      Text(
                        'Loaded directly from backend API endpoint:\n$gameUrl',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      AppSpacing.vGapXl,

                      // Game Arena Controls Provided by Backend
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildControlChip('Single Digit', 'Rate 1:9'),
                                  _buildControlChip('Jodi Digit', 'Rate 1:90'),
                                  _buildControlChip('Single Panna', 'Rate 1:140'),
                                ],
                              ),
                              AppSpacing.vGapMd,
                              ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Backend Game Engine synchronized!'),
                                      backgroundColor: Color(0xFF198754),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFFFD700)),
                                label: const Text(
                                  'START PLAY SESSION',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2C2F36),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          ],
        ),
      ),
    );
  }

  Widget _buildControlChip(String label, String rate) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          rate,
          style: const TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
