import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class SnackbarUtils {
  static void showSuccess(BuildContext context, String message) {
    _showSnackbar(
      context: context,
      message: message,
      backgroundColor: AppColors.success,
    );
  }

  static void showError(BuildContext context, String message) {
    _showSnackbar(
      context: context,
      message: message,
      backgroundColor: AppColors.error,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackbar(
      context: context,
      message: message,
      backgroundColor: AppColors.primary,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showSnackbar(
      context: context,
      message: message,
      backgroundColor: AppColors.warning,
    );
  }

  static void _showSnackbar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Clear any existing snackbars first
    scaffoldMessenger.clearSnackBars();
    
    // Show the new snackbar
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}