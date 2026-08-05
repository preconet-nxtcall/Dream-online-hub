import 'package:flutter/material.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';

/// M3 Circular Loading Spinner
class AppLoadingSpinner extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLoadingSpinner({
    super.key,
    this.size = 36.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 3.0,
          valueColor: AlwaysStoppedAnimation<Color>(color ?? theme.colorScheme.primary),
        ),
      ),
    );
  }
}

/// Fullscreen Loading Translucent Shield
class AppLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: Card(
                child: Padding(
                  padding: AppSpacing.pAllLg,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppLoadingSpinner(),
                      if (message != null) ...[
                        AppSpacing.vGapMd,
                        Text(message!, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Skeleton Placeholder Shimmer Box Loader
class AppSkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const AppSkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<AppSkeletonLoader> createState() => _AppSkeletonLoaderState();
}

class _AppSkeletonLoaderState extends State<AppSkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: _animation.value),
            borderRadius: widget.borderRadius ?? AppRadii.rMd,
          ),
        );
      },
    );
  }
}
