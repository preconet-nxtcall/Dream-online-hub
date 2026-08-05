import 'package:flutter/material.dart';
import '../../../../models/game/game_card_model.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';

class GameCardWidget extends StatefulWidget {
  final GameCardModel game;
  final VoidCallback onPlay;
  final VoidCallback onChat;

  const GameCardWidget({
    super.key,
    required this.game,
    required this.onPlay,
    required this.onChat,
  });

  @override
  State<GameCardWidget> createState() => _GameCardWidgetState();
}

class _GameCardWidgetState extends State<GameCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRunning = widget.game.isOpen;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                : const Color(0xFFFFD700).withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Section: Avatar Badge, Game Name, Result Pill, Status Chip
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Game Code Logo Box
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2F36),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.game.code,
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  AppSpacing.hGapMd,

                  // Name & Results Box
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.game.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 0.3,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            // Running Open / Closed Status Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isRunning
                                    ? const Color(0xFFE6F7ED)
                                    : const Color(0xFFFFEBEB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.game.status,
                                style: TextStyle(
                                  color: isRunning
                                      ? const Color(0xFF198754)
                                      : const Color(0xFFDC3545),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.vGapXs,
                        // Golden Yellow Result Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                                : const Color(0xFFFFF9E6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.game.result,
                            style: const TextStyle(
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 0.8),

            // Bottom Section: Timings & Actions (Play & Chat)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  // Open Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFFD97706)),
                            const SizedBox(width: 4),
                            Text(
                              'OPEN',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          widget.game.openTime,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Close Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time_filled_rounded, size: 14, color: Color(0xFFDC3545)),
                            const SizedBox(width: 4),
                            Text(
                              'CLOSE',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          widget.game.closeTime,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chat Button (Support / Agency Chat)
                  IconButton(
                    onPressed: widget.onChat,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      padding: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.primary, size: 20),
                    tooltip: 'Chat Support',
                  ),
                  AppSpacing.hGapSm,

                  // Play Button (Dark Gold Pill Button with Gold Border Glow)
                  GestureDetector(
                    onTapDown: (_) => _scaleController.forward(),
                    onTapUp: (_) {
                      _scaleController.reverse();
                      widget.onPlay();
                    },
                    onTapCancel: () => _scaleController.reverse(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2C2F36), Color(0xFF191B1F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Play',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Color(0xFFFFD700),
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
