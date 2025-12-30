import 'package:flutter/material.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/utils/tariff_calculator.dart';
import 'package:rooms/src/features/bookings/domain/entities/booking.dart';

/// A popup dialog showing the detailed tariff timeline for a booking room
class TariffTimelinePopup extends StatelessWidget {
  final Booking booking;
  final BookingRoom room;
  final TariffResult currentResult;
  final TariffResult expectedResult;

  const TariffTimelinePopup({
    super.key,
    required this.booking,
    required this.room,
    required this.currentResult,
    required this.expectedResult,
  });

  static Future<void> show(
    BuildContext context, {
    required Booking booking,
    required BookingRoom room,
    required TariffResult currentResult,
    required TariffResult expectedResult,
  }) {
    // Debug logging
    final now = DateTime.now();
    final elapsed = now.difference(booking.checkIn);
    AppLogger.info('=== TARIFF TIMELINE DEBUG ===', tag: 'TariffTimeline');
    AppLogger.info('Check-in: ${booking.checkIn}, isUtc: ${booking.checkIn.isUtc}', tag: 'TariffTimeline');
    AppLogger.info('Now: $now', tag: 'TariffTimeline');
    AppLogger.info('Elapsed: ${elapsed.inMinutes} minutes', tag: 'TariffTimeline');
    AppLogger.info('Tariff duration: ${room.tariffDurationHours}h', tag: 'TariffTimeline');
    AppLogger.info('Current cycles: ${currentResult.cycles}', tag: 'TariffTimeline');
    AppLogger.info('Current status: ${currentResult.status}', tag: 'TariffTimeline');
    AppLogger.info('============================', tag: 'TariffTimeline');

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TariffTimelinePopup(
        booking: booking,
        room: room,
        currentResult: currentResult,
        expectedResult: expectedResult,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final elapsed = now.difference(booking.checkIn);
    final elapsedMinutes = elapsed.inMinutes.clamp(0, 999999);
    final tariffMinutes = room.tariffDurationHours * 60;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _getStatusColor(currentResult.status),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          room.roomNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Room ${room.roomNumber} - Tariff Details',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (room.roomTypeName != null)
                            Text(
                              room.roomTypeName!,
                              style: TextStyle(color: AppColors.grey600, fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Card
                      _buildStatusCard(elapsedMinutes, tariffMinutes),
                      const SizedBox(height: 20),
                      // Time Details
                      _buildTimeDetails(now, elapsed),
                      const SizedBox(height: 20),
                      // Cycle Progress
                      _buildCycleProgress(elapsedMinutes, tariffMinutes),
                      const SizedBox(height: 20),
                      // Pricing
                      _buildPricing(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(int elapsedMinutes, int tariffMinutes) {
    final statusColor = _getStatusColor(currentResult.status);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(_getStatusIcon(currentResult.status), color: statusColor, size: 32),
          const SizedBox(height: 8),
          Text(
            currentResult.statusMessage,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDetails(DateTime now, Duration elapsed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildTimeRow('Check-in', booking.checkIn, Icons.login, AppColors.success),
          const Divider(height: 20),
          _buildTimeRow('Current Time', now, Icons.access_time, AppColors.info),
          const Divider(height: 20),
          Row(
            children: [
              Icon(Icons.timelapse, color: AppColors.warning, size: 20),
              const SizedBox(width: 12),
              const Text('Time Elapsed', style: TextStyle(fontSize: 13)),
              const Spacer(),
              Text(
                _formatElapsed(elapsed),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, DateTime time, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13)),
        const Spacer(),
        Text(
          _formatDateTime(time),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildCycleProgress(int elapsedMinutes, int tariffMinutes) {
    final completedCycles = currentResult.cycles - 1;
    final totalCyclesToShow = currentResult.cycles + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tariff Cycles',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(currentResult.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Cycle ${currentResult.cycles}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Cycle bars
        ...List.generate(totalCyclesToShow, (index) {
          final cycleNum = index + 1;
          final isCompleted = cycleNum <= completedCycles;
          final isCurrent = cycleNum == currentResult.cycles;
          
          final cycleStartTime = booking.checkIn.add(Duration(hours: (cycleNum - 1) * room.tariffDurationHours));
          final cycleEndTime = booking.checkIn.add(Duration(hours: cycleNum * room.tariffDurationHours));
          
          // Calculate fill for current cycle
          double fillPercent = 0;
          if (isCompleted) {
            fillPercent = 1.0;
          } else if (isCurrent) {
            final cycleStartMinutes = (cycleNum - 1) * tariffMinutes;
            final minutesIntoCycle = elapsedMinutes - cycleStartMinutes;
            fillPercent = (minutesIntoCycle / tariffMinutes).clamp(0.0, 1.0);
          }

          return _buildCycleBar(
            cycleNum: cycleNum,
            startTime: cycleStartTime,
            endTime: cycleEndTime,
            fillPercent: fillPercent,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
          );
        }),
      ],
    );
  }

  Widget _buildCycleBar({
    required int cycleNum,
    required DateTime startTime,
    required DateTime endTime,
    required double fillPercent,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    Color barColor;
    if (isCompleted) {
      barColor = AppColors.success;
    } else if (isCurrent) {
      barColor = _getStatusColor(currentResult.status);
    } else {
      barColor = AppColors.grey300;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Cycle $cycleNum',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? barColor : AppColors.grey600,
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NOW',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                '${_formatTimeOnly(startTime)} - ${_formatTimeOnly(endTime)}',
                style: TextStyle(fontSize: 11, color: AppColors.grey500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fillPercent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                if (isCompleted || isCurrent)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Text(
                        '₹${room.tariffAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: fillPercent > 0.7 ? Colors.white : AppColors.grey600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricing() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tariff Rate', style: TextStyle(fontSize: 13)),
              Text(
                '₹${room.tariffAmount.toStringAsFixed(0)} / ${room.tariffDurationHours}h',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grace Period', style: TextStyle(fontSize: 13)),
              Text(
                '${room.gracePeriodHours}h',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Total (${currentResult.cycles} ${currentResult.cycles == 1 ? 'cycle' : 'cycles'})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                '₹${currentResult.totalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _getStatusColor(currentResult.status),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TariffStatus status) {
    switch (status) {
      case TariffStatus.withinTariff:
        return AppColors.success;
      case TariffStatus.inGracePeriod:
        return AppColors.warning;
      case TariffStatus.nextTariffApplied:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(TariffStatus status) {
    switch (status) {
      case TariffStatus.withinTariff:
        return Icons.check_circle;
      case TariffStatus.inGracePeriod:
        return Icons.schedule;
      case TariffStatus.nextTariffApplied:
        return Icons.warning_amber;
    }
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dt.month - 1];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day $month, $hour:$minute $amPm';
  }

  String _formatTimeOnly(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }

  String _formatElapsed(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
