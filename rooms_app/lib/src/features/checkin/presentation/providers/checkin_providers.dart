import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/features/customers/domain/entities/customer.dart';

/// Check-in state for the wizard
class CheckinState {
  final Customer? customer;
  final int guestCount;
  final DateTime checkIn;
  final DateTime checkOut;
  final double totalAmount;
  final double paidAmount;
  final String? notes;

  const CheckinState({
    this.customer,
    this.guestCount = 1,
    required this.checkIn,
    required this.checkOut,
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.notes,
  });

  CheckinState copyWith({
    Customer? customer,
    int? guestCount,
    DateTime? checkIn,
    DateTime? checkOut,
    double? totalAmount,
    double? paidAmount,
    String? notes,
  }) {
    return CheckinState(
      customer: customer ?? this.customer,
      guestCount: guestCount ?? this.guestCount,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      notes: notes ?? this.notes,
    );
  }

  int get stayDuration => checkOut.difference(checkIn).inDays;
}

/// Provider for check-in state
final checkinStateProvider =
    StateNotifierProvider<CheckinNotifier, CheckinState>((ref) {
      return CheckinNotifier();
    });

class CheckinNotifier extends StateNotifier<CheckinState> {
  CheckinNotifier()
    : super(
        CheckinState(
          checkIn: DateTime.now(),
          checkOut: DateTime.now().add(const Duration(days: 1)),
        ),
      );

  void setCustomer(Customer customer) {
    state = state.copyWith(customer: customer);
  }

  void setGuestCount(int count) {
    state = state.copyWith(guestCount: count);
  }

  void setDates(DateTime checkIn, DateTime checkOut) {
    state = state.copyWith(checkIn: checkIn, checkOut: checkOut);
  }

  void setPayment(double total, double paid) {
    state = state.copyWith(totalAmount: total, paidAmount: paid);
  }

  void setNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  void reset() {
    state = CheckinState(
      checkIn: DateTime.now(),
      checkOut: DateTime.now().add(const Duration(days: 1)),
    );
  }
}
