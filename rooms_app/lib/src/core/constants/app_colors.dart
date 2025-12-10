import 'package:flutter/material.dart';

/// Color palette for the app - designed for low-literacy, high-contrast UI
class AppColors {
  AppColors._();

  // Primary Brand Colors (Professional Black & White)
  static const Color primary = Color(0xFF000000); // Black
  static const Color primaryDark = Color(0xFF1A1A1A);
  static const Color primaryLight = Color(0xFF333333);
  static const Color accent = Color(0xFFFFFFFF); // White accent

  // Room Status Colors (High Contrast)
  static const Color roomFree = Color(0xFF4CAF50); // Green
  static const Color roomOccupied = Color(0xFFE53935); // Red
  static const Color roomCleaning = Color(0xFFFF9800); // Orange
  static const Color roomMaintenance = Color(0xFFFF9800); // Orange
  static const Color roomOutOfService = Color(0xFF757575); // Grey

  // Secondary Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textHint = Color(0xFF9E9E9E);

  // Background Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color cardBackground = Color(0xFFF8F9FA);
}

/// Helper class to get room status color
class RoomStatusColors {
  static Color getColor(String status) {
    switch (status.toLowerCase()) {
      case 'free':
      case 'vacant':
        return AppColors.roomFree;
      case 'occupied':
        return AppColors.roomOccupied;
      case 'cleaning':
        return AppColors.roomCleaning;
      case 'maintenance':
        return AppColors.roomMaintenance;
      case 'out_of_service':
      case 'blocked':
        return AppColors.roomOutOfService;
      default:
        return AppColors.grey400;
    }
  }

  static String getLabel(String status) {
    switch (status.toLowerCase()) {
      case 'free':
      case 'vacant':
        return 'Free';
      case 'occupied':
        return 'Occupied';
      case 'cleaning':
        return 'Cleaning';
      case 'maintenance':
        return 'Maintenance';
      case 'out_of_service':
      case 'blocked':
        return 'Out of Service';
      default:
        return 'Unknown';
    }
  }
}
