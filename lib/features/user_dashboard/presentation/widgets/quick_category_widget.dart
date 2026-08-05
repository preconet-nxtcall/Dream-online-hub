import 'package:flutter/material.dart';
import '../../../../theme/app_spacing.dart';

class QuickCategoryWidget extends StatelessWidget {
  final Function(String category) onSelectCategory;

  const QuickCategoryWidget({
    super.key,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.style_rounded, color: Color(0xFF8B5CF6), size: 22),
                AppSpacing.hGapSm,
                Text(
                  'Featured Games & Arenas',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ],
        ),
        AppSpacing.vGapMd,

        // Top Row: Rummy Game & Starline Game
        Row(
          children: [
            Expanded(
              child: _buildQuickCategoryCard(
                context,
                title: 'Rummy Game',
                subtitle: 'Play Now →',
                icon: Icons.style_rounded,
                gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                borderColor: const Color(0xFFDDD6FE),
                bgColor: isDark ? const Color(0xFF242338) : const Color(0xFFF5F3FF),
                isDark: isDark,
                onTap: () => onSelectCategory('Rummy Game'),
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: _buildQuickCategoryCard(
                context,
                title: 'Starline',
                subtitle: 'Play Now →',
                icon: Icons.show_chart_rounded,
                gradientColors: const [Color(0xFFF97316), Color(0xFFEA580C)],
                borderColor: const Color(0xFFFDE68A),
                bgColor: isDark ? const Color(0xFF2C221D) : const Color(0xFFFFFBEB),
                isDark: isDark,
                onTap: () => onSelectCategory('Starline'),
              ),
            ),
          ],
        ),
        AppSpacing.vGapMd,

        // Bottom Row: Jackpot & Teen Patti
        Row(
          children: [
            Expanded(
              child: _buildQuickCategoryCard(
                context,
                title: 'Jackpot',
                subtitle: 'Play Now →',
                icon: Icons.military_tech_rounded,
                gradientColors: const [Color(0xFFEAB308), Color(0xFFCA8A04)],
                borderColor: const Color(0xFFFEF08A),
                bgColor: isDark ? const Color(0xFF2A2719) : const Color(0xFFFEFCE8),
                isDark: isDark,
                onTap: () => onSelectCategory('Jackpot'),
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: _buildQuickCategoryCard(
                context,
                title: 'Teen Patti',
                subtitle: 'Play Now →',
                icon: Icons.casino_rounded,
                gradientColors: const [Color(0xFFEC4899), Color(0xFFDB2777)],
                borderColor: const Color(0xFFFBCFE8),
                bgColor: isDark ? const Color(0xFF2D1F29) : const Color(0xFFFDF2F8),
                isDark: isDark,
                onTap: () => onSelectCategory('Teen Patti'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required Color borderColor,
    required Color bgColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: gradientColors.first,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
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
