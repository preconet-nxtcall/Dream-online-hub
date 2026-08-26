import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';

class AppSnackBars {
  static void showSuccess(BuildContext context, String message) {
    _showCustomSnackBar(
      context,
      message: message,
      icon: Icons.check_circle_outline,
      backgroundColor: AppColors.success,
    );
  }

  static void showError(BuildContext context, String message) {
    _showCustomSnackBar(
      context,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: AppColors.error,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showCustomSnackBar(
      context,
      message: message,
      icon: Icons.warning_amber_outlined,
      backgroundColor: AppColors.warning,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showCustomSnackBar(
      context,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: AppColors.info,
    );
  }

  static void _showCustomSnackBar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 4,
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.rMd),
        margin: AppSpacing.pAllMd,
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            AppSpacing.hGapMd,
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
