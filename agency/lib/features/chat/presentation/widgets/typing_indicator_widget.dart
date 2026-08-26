import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class TypingIndicatorWidget extends StatefulWidget {
  final String agencyName;
  final Color accentColor;

  const TypingIndicatorWidget({
    super.key,
    required this.agencyName,
    this.accentColor = AppColors.primary,
  });

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accentColor;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 64, 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1B3A) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : const Color(0xFFE8E7FF),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mini avatar
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.7)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent_rounded,
                    size: 12, color: Colors.white),
              ),
              const SizedBox(width: 10),

              // Animated dots
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Row(
                    children: List.generate(3, (index) {
                      final delay = index * 0.25;
                      final t = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
                      final bounce = (t < 0.5 ? t * 2 : (1 - t) * 2);

                      return Transform.translate(
                        offset: Offset(0, -4 * bounce),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.5 + 0.5 * bounce),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                'typing...',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black38,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
