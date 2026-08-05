import 'package:flutter/material.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';

/// Primary Filled Button
class AppPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const AppPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: backgroundColor != null
          ? ElevatedButton.styleFrom(backgroundColor: backgroundColor)
          : null,
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: textColor),
                  AppSpacing.hGapSm,
                ],
                Text(
                  text,
                  style: textColor != null ? TextStyle(color: textColor) : null,
                ),
              ],
            ),
    );
  }
}

/// Secondary Tonal Button
class AppSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  const AppSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        foregroundColor: theme.colorScheme.onSurfaceVariant,
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            AppSpacing.hGapSm,
          ],
          Text(text),
        ],
      ),
    );
  }
}

/// Outlined Button
class AppOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  const AppOutlineButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            AppSpacing.hGapSm,
          ],
          Text(text),
        ],
      ),
    );
  }
}

/// Clean Text Link Button
class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;

  const AppTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: color != null ? TextStyle(color: color) : null,
      ),
    );
  }
}

/// Styled Icon Button
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
      borderRadius: AppRadii.rMd,
      child: InkWell(
        borderRadius: AppRadii.rMd,
        onTap: onPressed,
        child: Padding(
          padding: AppSpacing.pAllSm,
          child: Icon(
            icon,
            size: size,
            color: iconColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
