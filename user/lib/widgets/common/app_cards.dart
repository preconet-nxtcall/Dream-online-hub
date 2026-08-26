import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';

/// Standard Surface Card
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double? elevation;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      elevation: elevation,
      child: Padding(
        padding: padding ?? AppSpacing.pAllMd,
        child: child,
      ),
    );
  }
}

/// Translucent Frosted Glass Card
class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double blur;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.blur = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: AppRadii.rLg,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? AppSpacing.pAllMd,
          decoration: BoxDecoration(
            color: isDark ? AppColors.glassDark : AppColors.glassLight,
            borderRadius: AppRadii.rLg,
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Interactive Ripple Action Card
class AppActionCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;

  const AppActionCard({
    super.key,
    required this.child,
    required this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: padding ?? AppSpacing.pAllMd,
          child: child,
        ),
      ),
    );
  }
}

/// Status Badge Indicator Card
class AppBadgeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final IconData? icon;

  const AppBadgeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    this.badgeColor = AppColors.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: AppSpacing.pAllSm,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: badgeColor, size: 24),
            ),
            AppSpacing.hGapMd,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                AppSpacing.vGapXs,
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: AppRadii.rSm,
            ),
            child: Text(
              badgeText,
              style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
