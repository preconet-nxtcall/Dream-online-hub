import 'package:flutter/material.dart';

class AgencyUserSkeletonTile extends StatefulWidget {
  const AgencyUserSkeletonTile({super.key});

  @override
  State<AgencyUserSkeletonTile> createState() => _AgencyUserSkeletonTileState();
}

class _AgencyUserSkeletonTileState extends State<AgencyUserSkeletonTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _shimmer = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        final baseColor = isDark
            ? const Color(0xFF1E1B3A)
            : const Color(0xFFF1F0FF);
        final shimmerColor = isDark
            ? Color.lerp(const Color(0xFF1E1B3A), const Color(0xFF2D2860), _shimmer.value)!
            : Color.lerp(const Color(0xFFF1F0FF), const Color(0xFFE4E2FF), _shimmer.value)!;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFEBE9FF),
              ),
            ),
            child: Row(
              children: [
                // Avatar skeleton
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 13),
                // Text skeletons
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 120,
                            height: 14,
                            decoration: BoxDecoration(
                              color: shimmerColor,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          Container(
                            width: 50,
                            height: 11,
                            decoration: BoxDecoration(
                              color: shimmerColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: shimmerColor.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
