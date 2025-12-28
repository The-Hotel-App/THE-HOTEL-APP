// ignore_for_file: dangling_library_doc_comments
/// Tariff-based pricing calculator for hotel bookings
///
/// Each room type has:
/// - tariffDurationHours: Fixed billing period (e.g., 24 for service apartment)
/// - tariffAmount: Price for one tariff cycle
/// - gracePeriodHours: Extra time allowed before next tariff applies


/// Status of the current stay relative to tariff
enum TariffStatus {
  /// Within the tariff duration - normal billing
  withinTariff,

  /// Exceeded tariff but within grace period - warning state
  inGracePeriod,

  /// Exceeded grace period - next tariff cycle applied
  nextTariffApplied,
}

/// Result of tariff calculation
class TariffResult {
  /// Number of tariff cycles to charge
  final int cycles;

  /// Total amount to charge (cycles × tariffAmount)
  final double totalAmount;

  /// Actual stay duration
  final Duration stayDuration;

  /// Current tariff status
  final TariffStatus status;

  /// Time remaining in grace period (if in grace)
  final Duration gracePeriodRemaining;

  /// Time until tariff ends (if within tariff)
  final Duration tariffTimeRemaining;

  /// Hours into current tariff cycle
  final double hoursIntoCurrentCycle;

  const TariffResult({
    required this.cycles,
    required this.totalAmount,
    required this.stayDuration,
    required this.status,
    required this.gracePeriodRemaining,
    required this.tariffTimeRemaining,
    required this.hoursIntoCurrentCycle,
  });

  /// Human-readable status message
  String get statusMessage {
    switch (status) {
      case TariffStatus.withinTariff:
        final hours = tariffTimeRemaining.inHours;
        final minutes = tariffTimeRemaining.inMinutes % 60;
        if (hours > 0) {
          return '${hours}h ${minutes}m remaining in tariff';
        }
        return '${minutes}m remaining in tariff';
      case TariffStatus.inGracePeriod:
        final minutes = gracePeriodRemaining.inMinutes;
        if (minutes > 60) {
          return '⚠️ Grace period - ${minutes ~/ 60}h ${minutes % 60}m before next tariff';
        }
        return '⚠️ Grace period - ${minutes}m before next tariff';
      case TariffStatus.nextTariffApplied:
        return '$cycles tariff ${cycles == 1 ? 'cycle' : 'cycles'} applied';
    }
  }

  /// Short status for badges
  String get shortStatus {
    switch (status) {
      case TariffStatus.withinTariff:
        return 'Within tariff';
      case TariffStatus.inGracePeriod:
        return 'Grace period';
      case TariffStatus.nextTariffApplied:
        return '$cycles cycles';
    }
  }

  /// Formatted stay duration (e.g., "1d 5h 30m" or "5h 30m")
  String get formattedDuration {
    final days = stayDuration.inDays;
    final hours = stayDuration.inHours % 24;
    final minutes = stayDuration.inMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

/// Utility class for tariff-based pricing calculations
class TariffCalculator {
  /// Calculate tariff result for a given stay
  ///
  /// Parameters:
  /// - checkIn: Check-in DateTime
  /// - checkOut: Check-out DateTime
  /// - tariffDurationHours: Fixed billing period in hours
  /// - tariffAmount: Price for one tariff cycle
  /// - gracePeriodHours: Extra hours allowed before next tariff
  static TariffResult calculate({
    required DateTime checkIn,
    required DateTime checkOut,
    required int tariffDurationHours,
    required double tariffAmount,
    required double gracePeriodHours,
  }) {
    final stayDuration = checkOut.difference(checkIn);
    final stayMinutes = stayDuration.inMinutes;
    final stayHours = stayMinutes / 60.0;

    final tariffMinutes = tariffDurationHours * 60;
    final graceMinutes = (gracePeriodHours * 60).round();
    final tariffWithGraceMinutes = tariffMinutes + graceMinutes;

    // Calculate number of tariff cycles needed
    int cycles = 1;
    int minutesAccountedFor = tariffWithGraceMinutes;

    while (stayMinutes > minutesAccountedFor) {
      cycles++;
      minutesAccountedFor +=
          tariffMinutes; // Each additional cycle adds tariff duration
    }

    // Determine status based on position within current cycle
    TariffStatus status;
    Duration gracePeriodRemaining = Duration.zero;
    Duration tariffTimeRemaining = Duration.zero;
    double hoursIntoCurrentCycle = 0;

    if (stayMinutes <= tariffMinutes) {
      // Within first tariff period
      status = TariffStatus.withinTariff;
      tariffTimeRemaining = Duration(minutes: tariffMinutes - stayMinutes);
      hoursIntoCurrentCycle = stayHours;
    } else if (stayMinutes <= tariffWithGraceMinutes) {
      // First tariff exceeded, but within grace
      status = TariffStatus.inGracePeriod;
      gracePeriodRemaining = Duration(
        minutes: tariffWithGraceMinutes - stayMinutes,
      );
      hoursIntoCurrentCycle = stayHours - tariffDurationHours;
    } else {
      // Grace exceeded - additional tariffs applied
      status = TariffStatus.nextTariffApplied;

      // Calculate position within current (non-first) cycle
      final minutesAfterFirst = stayMinutes - tariffWithGraceMinutes;
      final cyclesAfterFirst = (minutesAfterFirst / tariffMinutes).ceil();
      final minutesIntoCurrentCycle =
          minutesAfterFirst - ((cyclesAfterFirst - 1) * tariffMinutes);
      hoursIntoCurrentCycle = minutesIntoCurrentCycle / 60.0;

      // Time remaining in current cycle
      if (minutesIntoCurrentCycle < tariffMinutes) {
        tariffTimeRemaining = Duration(
          minutes: tariffMinutes - minutesIntoCurrentCycle,
        );
      }
    }

    return TariffResult(
      cycles: cycles,
      totalAmount: cycles * tariffAmount,
      stayDuration: stayDuration,
      status: status,
      gracePeriodRemaining: gracePeriodRemaining,
      tariffTimeRemaining: tariffTimeRemaining,
      hoursIntoCurrentCycle: hoursIntoCurrentCycle,
    );
  }

  /// Calculate the additional charge for extending a stay
  static TariffResult calculateExtension({
    required DateTime checkIn,
    required DateTime currentCheckOut,
    required DateTime newCheckOut,
    required int tariffDurationHours,
    required double tariffAmount,
    required double gracePeriodHours,
  }) {
    final currentResult = calculate(
      checkIn: checkIn,
      checkOut: currentCheckOut,
      tariffDurationHours: tariffDurationHours,
      tariffAmount: tariffAmount,
      gracePeriodHours: gracePeriodHours,
    );

    final newResult = calculate(
      checkIn: checkIn,
      checkOut: newCheckOut,
      tariffDurationHours: tariffDurationHours,
      tariffAmount: tariffAmount,
      gracePeriodHours: gracePeriodHours,
    );

    return TariffResult(
      cycles: newResult.cycles - currentResult.cycles,
      totalAmount: newResult.totalAmount - currentResult.totalAmount,
      stayDuration: newCheckOut.difference(currentCheckOut),
      status: newResult.status,
      gracePeriodRemaining: newResult.gracePeriodRemaining,
      tariffTimeRemaining: newResult.tariffTimeRemaining,
      hoursIntoCurrentCycle: newResult.hoursIntoCurrentCycle,
    );
  }

  /// Format duration as human-readable string
  static String formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
