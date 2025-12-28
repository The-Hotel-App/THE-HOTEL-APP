import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/utils/tariff_calculator.dart';
import 'package:rooms/src/features/customers/domain/entities/customer.dart';
import 'package:rooms/src/features/rooms/data/repositories/rooms_repository.dart';

/// Payment mode enum
enum PaymentMode {
  cash,
  upi,
  card,
  bankTransfer,
  other;

  String get displayName {
    switch (this) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.upi:
        return 'UPI/QR';
      case PaymentMode.card:
        return 'Card';
      case PaymentMode.bankTransfer:
        return 'Bank Transfer';
      case PaymentMode.other:
        return 'Other';
    }
  }

  String get dbValue {
    switch (this) {
      case PaymentMode.cash:
        return 'cash';
      case PaymentMode.upi:
        return 'upi';
      case PaymentMode.card:
        return 'card';
      case PaymentMode.bankTransfer:
        return 'bank_transfer';
      case PaymentMode.other:
        return 'other';
    }
  }
}

/// State for the new booking flow
class NewBookingState {
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestCount;
  final List<Customer?> guests; // List of guests (null if not filled yet)
  final List<SelectedRoom> selectedRooms;
  final double totalAmount;
  final double paidAmount;
  final PaymentMode paymentMode;
  final String? notes;

  const NewBookingState({
    required this.checkIn,
    required this.checkOut,
    this.guestCount = 1,
    this.guests = const [],
    this.selectedRooms = const [],
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.paymentMode = PaymentMode.cash,
    this.notes,
  });

  NewBookingState copyWith({
    DateTime? checkIn,
    DateTime? checkOut,
    int? guestCount,
    List<Customer?>? guests,
    List<SelectedRoom>? selectedRooms,
    double? totalAmount,
    double? paidAmount,
    PaymentMode? paymentMode,
    String? notes,
  }) {
    return NewBookingState(
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      guestCount: guestCount ?? this.guestCount,
      guests: guests ?? this.guests,
      selectedRooms: selectedRooms ?? this.selectedRooms,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentMode: paymentMode ?? this.paymentMode,
      notes: notes ?? this.notes,
    );
  }

  /// Check if all guests have been filled
  bool get allGuestsFilled {
    if (guests.length != guestCount) return false;
    return guests.every((g) => g != null);
  }

  /// Check if rooms have been selected
  bool get hasRoomsSelected => selectedRooms.isNotEmpty;

  /// Get number of nights (based on calendar days, not hours)
  int get numberOfNights {
    final checkInDate = DateTime(checkIn.year, checkIn.month, checkIn.day);
    final checkOutDate = DateTime(checkOut.year, checkOut.month, checkOut.day);
    return checkOutDate.difference(checkInDate).inDays;
  }

  /// Get stay duration
  Duration get stayDuration => checkOut.difference(checkIn);

  /// Get formatted stay duration (e.g., "1d 5h 30m")
  String get formattedDuration => TariffCalculator.formatDuration(stayDuration);

  /// Calculate total from selected rooms using tariff-based pricing
  double calculateTotal() {
    double total = 0;
    for (final room in selectedRooms) {
      final result = TariffCalculator.calculate(
        checkIn: checkIn,
        checkOut: checkOut,
        tariffDurationHours: room.tariffDurationHours,
        tariffAmount: room.tariffAmount,
        gracePeriodHours: room.gracePeriodHours,
      );
      total += result.totalAmount;
    }
    return total;
  }
}

/// Represents a selected room with its price and tariff info
class SelectedRoom {
  final String roomId;
  final String roomNumber;
  final String? roomTypeName;
  final double pricePerNight;
  final int floor;

  // Tariff-based pricing fields
  final int tariffDurationHours;
  final double tariffAmount;
  final double gracePeriodHours;

  const SelectedRoom({
    required this.roomId,
    required this.roomNumber,
    this.roomTypeName,
    required this.pricePerNight,
    required this.floor,
    this.tariffDurationHours = 24,
    this.tariffAmount = 0,
    this.gracePeriodHours = 2,
  });

  factory SelectedRoom.fromManagedRoom(ManagedRoom room) {
    return SelectedRoom(
      roomId: room.id,
      roomNumber: room.roomNumber,
      roomTypeName: room.roomTypeName,
      pricePerNight: room.pricePerNight ?? 0,
      floor: room.floor,
      tariffDurationHours: room.tariffDurationHours,
      tariffAmount: room.tariffAmount > 0
          ? room.tariffAmount
          : (room.pricePerNight ?? 0),
      gracePeriodHours: room.gracePeriodHours,
    );
  }

  /// Get tariff display string (e.g., "₹2500 per 24h")
  String get tariffDisplayString =>
      '₹${tariffAmount.toStringAsFixed(0)} per ${tariffDurationHours}h';
}

/// Notifier for managing new booking state
class NewBookingNotifier extends StateNotifier<NewBookingState> {
  /// Default checkout time (11:00 AM)
  static const TimeOfDay defaultCheckOutTime = TimeOfDay(hour: 11, minute: 0);

  NewBookingNotifier()
    : super(
        NewBookingState(
          checkIn: DateTime.now(),
          checkOut: _createDefaultCheckOut(),
        ),
      );

  /// Creates default checkout: 24 hours from now
  static DateTime _createDefaultCheckOut() {
    return DateTime.now().add(const Duration(hours: 24));
  }

  /// Kept for backward compatibility - now returns exact time
  @Deprecated('Use DateTime.now() directly for exact time')
  static DateTime roundToNearest15Minutes(DateTime dateTime) {
    return dateTime;
  }

  void setDates(DateTime checkIn, DateTime checkOut) {
    // Enforce invariant: check-out must be after check-in
    DateTime adjustedCheckOut = checkOut;
    if (checkOut.isBefore(checkIn) ||
        checkOut.isAtSameMomentAs(checkIn) ||
        (checkOut.year == checkIn.year &&
            checkOut.month == checkIn.month &&
            checkOut.day == checkIn.day)) {
      // Auto-adjust check-out to next day, preserving time
      adjustedCheckOut = DateTime(
        checkIn.year,
        checkIn.month,
        checkIn.day + 1,
        checkOut.hour,
        checkOut.minute,
      );
    }
    state = state.copyWith(checkIn: checkIn, checkOut: adjustedCheckOut);
  }

  /// Sets check-in to current time (exact, no rounding)
  void setCheckInToNow() {
    final now = DateTime.now();
    DateTime checkOut = state.checkOut;

    // Auto-adjust check-out if it becomes invalid
    if (checkOut.isBefore(now) ||
        checkOut.isAtSameMomentAs(now) ||
        (checkOut.year == now.year &&
            checkOut.month == now.month &&
            checkOut.day == now.day)) {
      checkOut = DateTime(
        now.year,
        now.month,
        now.day + 1,
        state.checkOut.hour,
        state.checkOut.minute,
      );
    }

    state = state.copyWith(checkIn: now, checkOut: checkOut);
  }

  /// Sets check-in date while preserving the time
  void setCheckInDate(DateTime date) {
    final newCheckIn = DateTime(
      date.year,
      date.month,
      date.day,
      state.checkIn.hour,
      state.checkIn.minute,
    );
    setDates(newCheckIn, state.checkOut);
  }

  /// Sets check-in time while preserving the date
  void setCheckInTime(TimeOfDay time) {
    final newCheckIn = DateTime(
      state.checkIn.year,
      state.checkIn.month,
      state.checkIn.day,
      time.hour,
      time.minute,
    );
    state = state.copyWith(checkIn: newCheckIn);
  }

  /// Sets check-out date while preserving the time
  void setCheckOutDate(DateTime date) {
    final newCheckOut = DateTime(
      date.year,
      date.month,
      date.day,
      state.checkOut.hour,
      state.checkOut.minute,
    );
    // Only update if the new date is valid (on or after check-in date)
    final checkInDate = DateTime(
      state.checkIn.year,
      state.checkIn.month,
      state.checkIn.day,
    );
    final newCheckOutDate = DateTime(date.year, date.month, date.day);
    if (!newCheckOutDate.isBefore(checkInDate) &&
        !newCheckOutDate.isAtSameMomentAs(checkInDate)) {
      state = state.copyWith(checkOut: newCheckOut);
    }
  }

  /// Sets check-out time while preserving the date
  void setCheckOutTime(TimeOfDay time) {
    final newCheckOut = DateTime(
      state.checkOut.year,
      state.checkOut.month,
      state.checkOut.day,
      time.hour,
      time.minute,
    );
    state = state.copyWith(checkOut: newCheckOut);
  }

  void setGuestCount(int count) {
    // Adjust guests list when count changes
    List<Customer?> newGuests = List.from(state.guests);

    if (count > newGuests.length) {
      // Add null placeholders for new guests
      while (newGuests.length < count) {
        newGuests.add(null);
      }
    } else if (count < newGuests.length) {
      // Remove extra guests
      newGuests = newGuests.sublist(0, count);
    }

    state = state.copyWith(guestCount: count, guests: newGuests);
  }

  void setGuest(int index, Customer guest) {
    List<Customer?> newGuests = List.from(state.guests);

    // Ensure list is long enough
    while (newGuests.length <= index) {
      newGuests.add(null);
    }

    newGuests[index] = guest;
    state = state.copyWith(guests: newGuests);
  }

  void addRoom(SelectedRoom room) {
    // Check if room already selected
    if (state.selectedRooms.any((r) => r.roomId == room.roomId)) {
      return;
    }

    final newRooms = [...state.selectedRooms, room];
    state = state.copyWith(
      selectedRooms: newRooms,
      totalAmount: _calculateTotal(newRooms),
    );
  }

  void removeRoom(String roomId) {
    final newRooms = state.selectedRooms
        .where((r) => r.roomId != roomId)
        .toList();
    state = state.copyWith(
      selectedRooms: newRooms,
      totalAmount: _calculateTotal(newRooms),
    );
  }

  void clearRooms() {
    state = state.copyWith(selectedRooms: [], totalAmount: 0);
  }

  void setPaidAmount(double amount) {
    state = state.copyWith(paidAmount: amount);
  }

  void setPaymentMode(PaymentMode mode) {
    state = state.copyWith(paymentMode: mode);
  }

  void setNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  double _calculateTotal(List<SelectedRoom> rooms) {
    double total = 0;
    for (final room in rooms) {
      final result = TariffCalculator.calculate(
        checkIn: state.checkIn,
        checkOut: state.checkOut,
        tariffDurationHours: room.tariffDurationHours,
        tariffAmount: room.tariffAmount,
        gracePeriodHours: room.gracePeriodHours,
      );
      total += result.totalAmount;
    }
    return total;
  }

  void reset() {
    state = NewBookingState(
      checkIn: DateTime.now(),
      checkOut: _createDefaultCheckOut(),
    );
  }
}

/// Provider for new booking state
final newBookingProvider =
    StateNotifierProvider<NewBookingNotifier, NewBookingState>((ref) {
      return NewBookingNotifier();
    });
