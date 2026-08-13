import 'package:flutter/material.dart';

/// A custom high-performance animated shimmering skeleton box container.
class ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Widget? child;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.margin,
    this.padding,
    this.child,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E1B38) : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? const Color(0xFF2D2952) : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [
                baseColor,
                Color.lerp(baseColor, highlightColor, _animation.value)!,
                baseColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Skeleton loading placeholder for Chat messages
class ChatSkeletonLoader extends StatelessWidget {
  const ChatSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: 6,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final isMe = index % 2 == 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe) ...[
                  const ShimmerBox(width: 32, height: 32, borderRadius: 16),
                  const SizedBox(width: 8),
                ],
                ShimmerBox(
                  width: MediaQuery.of(context).size.width * (index % 3 == 0 ? 0.65 : 0.45),
                  height: 48,
                  borderRadius: 16,
                ),
                if (isMe) ...[
                  const SizedBox(width: 8),
                  const ShimmerBox(width: 14, height: 14, borderRadius: 7),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton loading placeholder for Agency Dashboard tiles and metrics
class DashboardSkeletonLoader extends StatelessWidget {
  const DashboardSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat cards skeleton row
          const Row(
            children: [
              Expanded(child: ShimmerBox(height: 72, borderRadius: 16)),
              SizedBox(width: 8),
              Expanded(child: ShimmerBox(height: 72, borderRadius: 16)),
              SizedBox(width: 8),
              Expanded(child: ShimmerBox(height: 72, borderRadius: 16)),
            ],
          ),
          const SizedBox(height: 16),

          // Search bar skeleton
          const ShimmerBox(height: 46, borderRadius: 24),
          const SizedBox(height: 16),

          // Directory item skeletons
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      ShimmerBox(width: 48, height: 48, borderRadius: 24),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(width: 140, height: 16, borderRadius: 4),
                            SizedBox(height: 6),
                            ShimmerBox(width: 190, height: 12, borderRadius: 4),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      ShimmerBox(width: 40, height: 12, borderRadius: 4),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
