import 'package:flutter/material.dart';
import 'package:rooms/src/core/constants/app_colors.dart';

/// Dialog type for different visual styles
enum CustomDialogType {
  /// Standard dialog with primary button
  standard,

  /// Confirmation dialog (typically for delete/remove actions)
  confirmation,

  /// Destructive dialog with red accent
  destructive,

  /// Success dialog with green accent
  success,

  /// Warning dialog with yellow/amber accent
  warning,

  /// Info dialog with blue accent
  info,
}

/// A highly customizable, reusable dialog widget that matches the app theme.
///
/// This dialog is designed to replace all AlertDialog instances in the app
/// with a consistent, themed look and feel.
///
/// Features:
/// - Multiple dialog types (standard, confirmation, destructive, success, warning, info)
/// - Support for icons
/// - Customizable buttons (primary, secondary, tertiary)
/// - Form support with auto-validation
/// - Loading state support
/// - Dismissible control
class CustomDialog extends StatelessWidget {
  /// Dialog title
  final String title;

  /// Dialog content - can be a widget or simple text
  final Widget content;

  /// Optional icon to display above the title
  final IconData? icon;

  /// Icon color (defaults based on dialog type)
  final Color? iconColor;

  /// Dialog type for visual styling
  final CustomDialogType type;

  /// Primary button text
  final String? primaryButtonText;

  /// Primary button callback
  final VoidCallback? onPrimaryPressed;

  /// Whether primary button is in loading state
  final bool isPrimaryLoading;

  /// Whether primary button should be disabled
  final bool isPrimaryDisabled;

  /// Secondary button text (typically "Cancel")
  final String? secondaryButtonText;

  /// Secondary button callback
  final VoidCallback? onSecondaryPressed;

  /// Tertiary button text (for 3-button dialogs)
  final String? tertiaryButtonText;

  /// Tertiary button callback
  final VoidCallback? onTertiaryPressed;

  /// Whether dialog can be dismissed by tapping outside
  final bool isDismissible;

  /// Custom primary button color
  final Color? primaryButtonColor;

  /// Maximum width of the dialog
  final double maxWidth;

  const CustomDialog({
    super.key,
    required this.title,
    required this.content,
    this.icon,
    this.iconColor,
    this.type = CustomDialogType.standard,
    this.primaryButtonText,
    this.onPrimaryPressed,
    this.isPrimaryLoading = false,
    this.isPrimaryDisabled = false,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.tertiaryButtonText,
    this.onTertiaryPressed,
    this.isDismissible = true,
    this.primaryButtonColor,
    this.maxWidth = 400,
  });

  /// Get the accent color based on dialog type
  Color _getAccentColor() {
    if (iconColor != null) return iconColor!;

    switch (type) {
      case CustomDialogType.standard:
        return AppColors.black;
      case CustomDialogType.confirmation:
        return AppColors.black;
      case CustomDialogType.destructive:
        return AppColors.error;
      case CustomDialogType.success:
        return AppColors.success;
      case CustomDialogType.warning:
        return AppColors.warning;
      case CustomDialogType.info:
        return AppColors.info;
    }
  }

  /// Get the primary button color based on dialog type
  Color _getPrimaryButtonColor() {
    if (primaryButtonColor != null) return primaryButtonColor!;

    switch (type) {
      case CustomDialogType.standard:
        return AppColors.black;
      case CustomDialogType.confirmation:
        return AppColors.black;
      case CustomDialogType.destructive:
        return AppColors.error;
      case CustomDialogType.success:
        return AppColors.success;
      case CustomDialogType.warning:
        return AppColors.warning;
      case CustomDialogType.info:
        return AppColors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor();
    final buttonColor = _getPrimaryButtonColor();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.white,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon (if provided)
            if (icon != null) ...[
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 28),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Content
            DefaultTextStyle(
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              child: content,
            ),
            const SizedBox(height: 24),

            // Buttons
            _buildButtons(context, buttonColor),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context, Color buttonColor) {
    final hasSecondary = secondaryButtonText != null;
    final hasTertiary = tertiaryButtonText != null;

    // If no buttons specified, add a default "OK" button
    if (primaryButtonText == null && !hasSecondary && !hasTertiary) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('OK'),
        ),
      );
    }

    // Build primary button widget
    Widget? primaryButton;
    if (primaryButtonText != null) {
      primaryButton = Expanded(
        child: ElevatedButton(
          onPressed: isPrimaryLoading || isPrimaryDisabled
              ? null
              : onPrimaryPressed ?? () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: buttonColor.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isPrimaryLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                )
              : Text(primaryButtonText!),
        ),
      );
    }

    // Build secondary button widget
    Widget? secondaryButton;
    if (hasSecondary) {
      secondaryButton = Expanded(
        child: OutlinedButton(
          onPressed: onSecondaryPressed ?? () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: AppColors.grey300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(secondaryButtonText!),
        ),
      );
    }

    // Build tertiary button widget
    Widget? tertiaryButton;
    if (hasTertiary) {
      tertiaryButton = Expanded(
        child: TextButton(
          onPressed: onTertiaryPressed ?? () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.grey500,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(tertiaryButtonText!),
        ),
      );
    }

    // Arrange buttons horizontally (left-right fashion)
    // Order: Tertiary (if any) | Secondary (if any) | Primary
    final buttons = <Widget>[];

    if (tertiaryButton != null) {
      buttons.add(tertiaryButton);
      if (secondaryButton != null || primaryButton != null) {
        buttons.add(const SizedBox(width: 12));
      }
    }

    if (secondaryButton != null) {
      buttons.add(secondaryButton);
      if (primaryButton != null) {
        buttons.add(const SizedBox(width: 12));
      }
    }

    if (primaryButton != null) {
      buttons.add(primaryButton);
    }

    return Row(children: buttons);
  }

  // ============== STATIC CONVENIENCE METHODS ==============

  /// Show a standard custom dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    IconData? icon,
    Color? iconColor,
    CustomDialogType type = CustomDialogType.standard,
    String? primaryButtonText,
    VoidCallback? onPrimaryPressed,
    bool isPrimaryLoading = false,
    bool isPrimaryDisabled = false,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    String? tertiaryButtonText,
    VoidCallback? onTertiaryPressed,
    bool isDismissible = true,
    Color? primaryButtonColor,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => CustomDialog(
        title: title,
        content: content,
        icon: icon,
        iconColor: iconColor,
        type: type,
        primaryButtonText: primaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        isPrimaryLoading: isPrimaryLoading,
        isPrimaryDisabled: isPrimaryDisabled,
        secondaryButtonText: secondaryButtonText,
        onSecondaryPressed: onSecondaryPressed,
        tertiaryButtonText: tertiaryButtonText,
        onTertiaryPressed: onTertiaryPressed,
        isDismissible: isDismissible,
        primaryButtonColor: primaryButtonColor,
      ),
    );
  }

  /// Show a confirmation dialog (e.g., for delete actions)
  /// Returns true if confirmed, false or null otherwise
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => CustomDialog(
        title: title,
        content: Text(message),
        icon:
            icon ??
            (isDestructive ? Icons.warning_amber_rounded : Icons.help_outline),
        type: isDestructive
            ? CustomDialogType.destructive
            : CustomDialogType.confirmation,
        primaryButtonText: confirmText,
        onPrimaryPressed: () => Navigator.of(context).pop(true),
        secondaryButtonText: cancelText,
        onSecondaryPressed: () => Navigator.of(context).pop(false),
      ),
    );
  }

  /// Show an info/alert dialog with just a message and "OK" button
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    IconData? icon,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => CustomDialog(
        title: title,
        content: Text(message),
        icon: icon ?? Icons.info_outline,
        type: CustomDialogType.info,
        primaryButtonText: buttonText,
        onPrimaryPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// Show an error dialog
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => CustomDialog(
        title: title,
        content: Text(message),
        icon: Icons.error_outline,
        type: CustomDialogType.destructive,
        primaryButtonText: buttonText,
        onPrimaryPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// Show a success dialog
  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => CustomDialog(
        title: title,
        content: Text(message),
        icon: Icons.check_circle_outline,
        type: CustomDialogType.success,
        primaryButtonText: buttonText,
        onPrimaryPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// Show a warning dialog
  static Future<void> showWarning({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => CustomDialog(
        title: title,
        content: Text(message),
        icon: Icons.warning_amber_rounded,
        type: CustomDialogType.warning,
        primaryButtonText: buttonText,
        onPrimaryPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

/// A form-based custom dialog that supports form validation
/// and state management for forms within dialogs.
class CustomFormDialog extends StatefulWidget {
  final String title;
  final Widget Function(BuildContext context, GlobalKey<FormState> formKey)
  formBuilder;
  final Future<void> Function() onSubmit;
  final String submitButtonText;
  final String cancelButtonText;
  final IconData? icon;
  final CustomDialogType type;

  const CustomFormDialog({
    super.key,
    required this.title,
    required this.formBuilder,
    required this.onSubmit,
    this.submitButtonText = 'Submit',
    this.cancelButtonText = 'Cancel',
    this.icon,
    this.type = CustomDialogType.standard,
  });

  @override
  State<CustomFormDialog> createState() => _CustomFormDialogState();

  /// Show a form dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget Function(BuildContext context, GlobalKey<FormState> formKey)
    formBuilder,
    required Future<void> Function() onSubmit,
    String submitButtonText = 'Submit',
    String cancelButtonText = 'Cancel',
    IconData? icon,
    CustomDialogType type = CustomDialogType.standard,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomFormDialog(
        title: title,
        formBuilder: formBuilder,
        onSubmit: onSubmit,
        submitButtonText: submitButtonText,
        cancelButtonText: cancelButtonText,
        icon: icon,
        type: type,
      ),
    );
  }
}

class _CustomFormDialogState extends State<CustomFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: widget.title,
      icon: widget.icon,
      type: widget.type,
      content: widget.formBuilder(context, _formKey),
      primaryButtonText: widget.submitButtonText,
      onPrimaryPressed: _handleSubmit,
      isPrimaryLoading: _isSubmitting,
      secondaryButtonText: widget.cancelButtonText,
      onSecondaryPressed: () => Navigator.pop(context),
      isDismissible: !_isSubmitting,
    );
  }
}
