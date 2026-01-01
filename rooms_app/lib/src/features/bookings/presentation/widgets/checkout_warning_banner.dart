import 'package:flutter/material.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/utils/tariff_calculator.dart';
import 'package:rooms/src/features/bookings/domain/entities/booking.dart';

/// Banner widget that displays checkout warnings based on tariff status
/// Shows different states: within tariff, grace period, or exceeded
class CheckoutWarningBanner extends StatelessWidget {
  final Booking booking;
  final int tariffDurationHours;
  final double tariffAmount;
  final double gracePeriodHours;
  final VoidCallback? onCheckOut;
  final VoidCallback? onExtendStay;

  const CheckoutWarningBanner({
    super.key,
    required this.booking,
    required this.tariffDurationHours,
    required this.tariffAmount,
    required this.gracePeriodHours,
    this.onCheckOut,
    this.onExtendStay,
  });

  @override
  Widget build(BuildContext context) {
    // Only show for checked-in bookings
    if (booking.status != BookingStatus.checkedIn) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final result = TariffCalculator.calculate(
      checkIn: booking.checkIn,
      checkOut: now, // Calculate based on current time
      tariffDurationHours: tariffDurationHours,
      tariffAmount: tariffAmount,
      gracePeriodHours: gracePeriodHours,
    );

    return _buildBanner(context, result);
  }

  Widget _buildBanner(BuildContext context, TariffResult result) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String title;
    String subtitle;

    switch (result.status) {
      case TariffStatus.withinTariff:
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        icon = Icons.check_circle_outline;
        title = 'Within Tariff Period';
        subtitle = result.statusMessage;
        break;
      case TariffStatus.inGracePeriod:
        backgroundColor = AppColors.warning.withValues(alpha: 0.15);
        textColor = AppColors.warning;
        icon = Icons.warning_amber_rounded;
        title = 'Grace Period Active';
        subtitle = result.statusMessage;
        break;
      case TariffStatus.nextTariffApplied:
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        icon = Icons.error_outline;
        title = 'Additional Tariff Applied';
        subtitle =
            '${result.cycles} tariff cycles (₹${result.totalAmount.toStringAsFixed(0)})';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onCheckOut != null || onExtendStay != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onExtendStay != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onExtendStay,
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('Extend Stay'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(
                          color: textColor.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                if (onCheckOut != null && onExtendStay != null)
                  const SizedBox(width: 12),
                if (onCheckOut != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onCheckOut,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Check Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: textColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact version of the warning banner for list items
class CheckoutWarningChip extends StatelessWidget {
  final DateTime checkIn;
  final int tariffDurationHours;
  final double tariffAmount;
  final double gracePeriodHours;

  const CheckoutWarningChip({
    super.key,
    required this.checkIn,
    required this.tariffDurationHours,
    required this.tariffAmount,
    required this.gracePeriodHours,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final result = TariffCalculator.calculate(
      checkIn: checkIn,
      checkOut: now,
      tariffDurationHours: tariffDurationHours,
      tariffAmount: tariffAmount,
      gracePeriodHours: gracePeriodHours,
    );

    Color backgroundColor;
    Color textColor;
    String label;

    switch (result.status) {
      case TariffStatus.withinTariff:
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        label = result.tariffTimeRemaining.inHours > 0
            ? '${result.tariffTimeRemaining.inHours}h left'
            : '${result.tariffTimeRemaining.inMinutes}m left';
        break;
      case TariffStatus.inGracePeriod:
        backgroundColor = AppColors.warning.withValues(alpha: 0.15);
        textColor = AppColors.warning;
        label = 'Grace: ${result.gracePeriodRemaining.inMinutes}m';
        break;
      case TariffStatus.nextTariffApplied:
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        label = '+${result.cycles - 1} tariff';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
