import 'package:flutter/material.dart';
import 'package:rooms/src/core/constants/app_colors.dart';

/// Clean, reusable dialog widget for the app
/// Designed for low-literacy users with clear actions
class AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String? primaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;
  final bool isDismissible;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.primaryButtonText,
    this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.isDismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            content,
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (primaryButtonText != null)
                  ElevatedButton(
                    onPressed:
                        onPrimaryPressed ?? () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    child: Text(primaryButtonText!),
                  ),
                if (secondaryButtonText != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed:
                        onSecondaryPressed ?? () => Navigator.of(context).pop(),
                    child: Text(
                      secondaryButtonText!,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show the dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    String? primaryButtonText,
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    bool isDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => AppDialog(
        title: title,
        content: content,
        primaryButtonText: primaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        secondaryButtonText: secondaryButtonText,
        onSecondaryPressed: onSecondaryPressed,
        isDismissible: isDismissible,
      ),
    );
  }
}
