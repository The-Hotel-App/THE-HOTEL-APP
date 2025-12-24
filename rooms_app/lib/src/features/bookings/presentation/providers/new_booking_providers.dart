import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// Get number of nights
  int get numberOfNights {
    return checkOut.difference(checkIn).inDays;
  }

  /// Calculate total from selected rooms
  double calculateTotal() {
    double total = 0;
    for (final room in selectedRooms) {
      total += room.pricePerNight * numberOfNights;
    }
    return total;
  }
}

/// Represents a selected room with its price
class SelectedRoom {
  final String roomId;
  final String roomNumber;
  final String? roomTypeName;
  final double pricePerNight;
  final int floor;

  const SelectedRoom({
    required this.roomId,
    required this.roomNumber,
    this.roomTypeName,
    required this.pricePerNight,
    required this.floor,
  });

  factory SelectedRoom.fromManagedRoom(ManagedRoom room) {
    return SelectedRoom(
      roomId: room.id,
      roomNumber: room.roomNumber,
      roomTypeName: room.roomTypeName,
      pricePerNight: room.pricePerNight ?? 0,
      floor: room.floor,
    );
  }
}

/// Notifier for managing new booking state
class NewBookingNotifier extends StateNotifier<NewBookingState> {
  NewBookingNotifier()
      : super(NewBookingState(
          checkIn: DateTime.now(),
          checkOut: DateTime.now().add(const Duration(days: 1)),
        ));

  void setDates(DateTime checkIn, DateTime checkOut) {
    state = state.copyWith(checkIn: checkIn, checkOut: checkOut);
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
    final newRooms = state.selectedRooms.where((r) => r.roomId != roomId).toList();
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
    final nights = state.numberOfNights;
    for (final room in rooms) {
      total += room.pricePerNight * nights;
    }
    return total;
  }

  void reset() {
    state = NewBookingState(
      checkIn: DateTime.now(),
      checkOut: DateTime.now().add(const Duration(days: 1)),
    );
  }
}

/// Provider for new booking state
final newBookingProvider =
    StateNotifierProvider<NewBookingNotifier, NewBookingState>((ref) {
  return NewBookingNotifier();
});
