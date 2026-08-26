import 'package:flutter/material.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';

class AppBottomOption {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? textColor;

  AppBottomOption({
    required this.title,
    required this.icon,
    required this.onTap,
    this.textColor,
  });
}

class AppBottomSheets {
  /// Custom Bottom Modal Sheet
  static Future<T?> showModalSheet<T>(
    BuildContext context, {
    required Widget child,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: AppSpacing.pAllLg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child,
              ],
            ),
          ),
        );
      },
    );
  }

  /// Action Tile Option Bottom Sheet
  static Future<void> showActionSheet(
    BuildContext context, {
    required String title,
    required List<AppBottomOption> options,
  }) {
    return showModalSheet(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          AppSpacing.vGapMd,
          ...options.map(
            (option) => ListTile(
              leading: Icon(option.icon, color: option.textColor),
              title: Text(
                option.title,
                style: option.textColor != null ? TextStyle(color: option.textColor) : null,
              ),
              onTap: () {
                Navigator.of(context).pop();
                option.onTap();
              },
            ),
          ),
        ],
      ),
    );
  }
}
