import 'package:flutter/material.dart';

class FeaturedGamesGridWidget extends StatelessWidget {
  final Function(String category) onSelectCategory;

  const FeaturedGamesGridWidget({
    super.key,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title with Stacked Cards Icon
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.style_rounded, color: Color(0xFF8B5CF6), size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              'Featured Games & Arenas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Row 1: Rummy Game & Starline
        Row(
          children: [
            Expanded(
              child: _buildFeaturedCard(
                title: 'Rummy Game',
                subtitle: 'Play Now →',
                icon: Icons.style_rounded,
                iconGradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                borderColor: isDark ? const Color(0xFF3B2E63) : const Color(0xFFDDD6FE),
                bgColor: isDark ? const Color(0xFF1A182F) : const Color(0xFFF7F5FF),
                textColor: isDark ? Colors.white : const Color(0xFF1E293B),
                subtitleColor: const Color(0xFF8B5CF6),
                onTap: () => onSelectCategory('Rummy Game'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeaturedCard(
                title: 'Starline',
                subtitle: 'Play Now →',
                icon: Icons.show_chart_rounded,
                iconGradient: const [Color(0xFFF97316), Color(0xFFEA580C)],
                borderColor: isDark ? const Color(0xFF4A341A) : const Color(0xFFFDE68A),
                bgColor: isDark ? const Color(0xFF231C13) : const Color(0xFFFFFBEB),
                textColor: isDark ? Colors.white : const Color(0xFF1E293B),
                subtitleColor: const Color(0xFFF97316),
                onTap: () => onSelectCategory('Starline'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Jackpot & Teen Patti
        Row(
          children: [
            Expanded(
              child: _buildFeaturedCard(
                title: 'Jackpot',
                subtitle: 'Play Now →',
                icon: Icons.military_tech_rounded,
                iconGradient: const [Color(0xFFEAB308), Color(0xFFCA8A04)],
                borderColor: isDark ? const Color(0xFF483E1A) : const Color(0xFFFEF08A),
                bgColor: isDark ? const Color(0xFF221F13) : const Color(0xFFFEFCE8),
                textColor: isDark ? Colors.white : const Color(0xFF1E293B),
                subtitleColor: const Color(0xFFCA8A04),
                onTap: () => onSelectCategory('Jackpot'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeaturedCard(
                title: 'Teen Patti',
                subtitle: 'Play Now →',
                icon: Icons.casino_rounded,
                iconGradient: const [Color(0xFFEC4899), Color(0xFFDB2777)],
                borderColor: isDark ? const Color(0xFF482238) : const Color(0xFFFBCFE8),
                bgColor: isDark ? const Color(0xFF241520) : const Color(0xFFFDF2F8),
                textColor: isDark ? Colors.white : const Color(0xFF1E293B),
                subtitleColor: const Color(0xFFEC4899),
                onTap: () => onSelectCategory('Teen Patti'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturedCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> iconGradient,
    required Color borderColor,
    required Color bgColor,
    required Color textColor,
    required Color subtitleColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: iconGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: iconGradient.first.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: subtitleColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
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
