import 'package:flutter/material.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import 'app_buttons.dart';

class AppDialogs {
  /// Confirmation Modal Dialog
  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadii.rLg),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            ElevatedButton(
              style: confirmColor != null
                  ? ElevatedButton.styleFrom(backgroundColor: confirmColor)
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  /// Informational Alert Dialog
  static Future<void> showAlert(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
    IconData? icon,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadii.rLg),
          title: Row(
            children: [
              if (icon != null) ...[
                Icon(icon),
                AppSpacing.hGapSm,
              ],
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          content: Text(message),
          actions: [
            AppPrimaryButton(
              text: buttonText,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  /// Loading Modal Dialog
  static void showLoadingModal(BuildContext context, {String message = 'Please wait...'}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: AppRadii.rLg),
            child: Padding(
              padding: AppSpacing.pAllLg,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  AppSpacing.hGapLg,
                  Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
