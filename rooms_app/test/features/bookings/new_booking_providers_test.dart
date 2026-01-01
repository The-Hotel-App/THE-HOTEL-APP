import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rooms/src/features/bookings/presentation/providers/new_booking_providers.dart';

void main() {
  group('NewBookingNotifier', () {
    // Note: roundToNearest15Minutes tests removed - feature deprecated in favor of exact time selection

    group('setDates - check-out after check-in invariant', () {
      /// **Feature: stay-dates-ui-improvement, Property 2: Check-out is always after check-in**
      /// **Validates: Requirements 1.5, 2.5**
      test('Property 2: Check-out is always after check-in date', () {
        final random = Random(42);
        final notifier = NewBookingNotifier();

        // Run 100 iterations with random date combinations
        for (int i = 0; i < 100; i++) {
          final checkInYear = 2024 + random.nextInt(2);
          final checkInMonth = 1 + random.nextInt(12);
          final checkInDay = 1 + random.nextInt(28);
          final checkInHour = random.nextInt(24);
          final checkInMinute = random.nextInt(60);

          final checkOutYear = 2024 + random.nextInt(2);
          final checkOutMonth = 1 + random.nextInt(12);
          final checkOutDay = 1 + random.nextInt(28);
          final checkOutHour = random.nextInt(24);
          final checkOutMinute = random.nextInt(60);

          final checkIn = DateTime(
            checkInYear,
            checkInMonth,
            checkInDay,
            checkInHour,
            checkInMinute,
          );
          final checkOut = DateTime(
            checkOutYear,
            checkOutMonth,
            checkOutDay,
            checkOutHour,
            checkOutMinute,
          );

          notifier.setDates(checkIn, checkOut);

          // Property: check-out date must be after check-in date
          final resultCheckInDate = DateTime(
            notifier.state.checkIn.year,
            notifier.state.checkIn.month,
            notifier.state.checkIn.day,
          );
          final resultCheckOutDate = DateTime(
            notifier.state.checkOut.year,
            notifier.state.checkOut.month,
            notifier.state.checkOut.day,
          );

          expect(
            resultCheckOutDate.isAfter(resultCheckInDate),
            isTrue,
            reason:
                'Check-out date ${notifier.state.checkOut} should be after check-in date ${notifier.state.checkIn}',
          );
        }
      });

      test('auto-adjusts check-out when check-in is set to same day', () {
        final notifier = NewBookingNotifier();
        final sameDay = DateTime(2024, 6, 15, 14, 0);

        notifier.setDates(sameDay, sameDay);

        expect(notifier.state.checkOut.day, 16);
        expect(notifier.state.checkOut.month, 6);
      });

      test('auto-adjusts check-out when check-in is after check-out', () {
        final notifier = NewBookingNotifier();
        final checkIn = DateTime(2024, 6, 20, 14, 0);
        final checkOut = DateTime(2024, 6, 15, 11, 0);

        notifier.setDates(checkIn, checkOut);

        expect(notifier.state.checkOut.day, 21);
        expect(notifier.state.checkOut.hour, 11); // Preserves time
      });
    });

    group('numberOfNights calculation', () {
      /// **Feature: stay-dates-ui-improvement, Property 3: Nights calculation is correct**
      /// **Validates: Requirements 4.4**
      test('Property 3: Nights calculation equals days between dates', () {
        final random = Random(42);

        // Run 100 iterations with random valid date pairs
        for (int i = 0; i < 100; i++) {
          final checkInYear = 2024;
          final checkInMonth =
              1 + random.nextInt(11); // Leave room for checkout
          final checkInDay = 1 + random.nextInt(20);
          final checkInHour = random.nextInt(24);
          final checkInMinute = random.nextInt(60);

          final nightsToAdd = 1 + random.nextInt(30); // 1-30 nights

          final checkIn = DateTime(
            checkInYear,
            checkInMonth,
            checkInDay,
            checkInHour,
            checkInMinute,
          );
          final checkOut = checkIn.add(Duration(days: nightsToAdd));

          final state = NewBookingState(checkIn: checkIn, checkOut: checkOut);

          // Property: numberOfNights should equal the days difference
          expect(
            state.numberOfNights,
            nightsToAdd,
            reason:
                'Nights from $checkIn to $checkOut should be $nightsToAdd, got ${state.numberOfNights}',
          );
        }
      });

      test('calculates 1 night correctly', () {
        final state = NewBookingState(
          checkIn: DateTime(2024, 6, 15, 14, 0),
          checkOut: DateTime(2024, 6, 16, 11, 0),
        );
        expect(state.numberOfNights, 1);
      });

      test('calculates multiple nights correctly', () {
        final state = NewBookingState(
          checkIn: DateTime(2024, 6, 15, 14, 0),
          checkOut: DateTime(2024, 6, 20, 11, 0),
        );
        expect(state.numberOfNights, 5);
      });
    });

    group('setCheckInToNow', () {
      test('sets check-in to current time (exact, no rounding)', () {
        final notifier = NewBookingNotifier();
        final beforeCall = DateTime.now();

        notifier.setCheckInToNow();

        final afterCall = DateTime.now();

        // Check-in should be between before and after calls
        expect(
          notifier.state.checkIn.isAfter(
                beforeCall.subtract(const Duration(seconds: 1)),
              ) ||
              notifier.state.checkIn.isAtSameMomentAs(beforeCall),
          isTrue,
        );
        expect(
          notifier.state.checkIn.isBefore(
                afterCall.add(const Duration(seconds: 1)),
              ) ||
              notifier.state.checkIn.isAtSameMomentAs(afterCall),
          isTrue,
        );
      });

      test('auto-adjusts check-out if it becomes invalid', () {
        final notifier = NewBookingNotifier();
        // Set check-out to a past date
        final pastCheckOut = DateTime.now().subtract(const Duration(days: 5));
        notifier.setDates(
          DateTime.now().subtract(const Duration(days: 10)),
          pastCheckOut,
        );

        notifier.setCheckInToNow();

        // Check-out should be adjusted to tomorrow
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(notifier.state.checkOut.day, tomorrow.day);
      });
    });

    group('setCheckInDate', () {
      test('preserves time when changing date', () {
        final notifier = NewBookingNotifier();
        notifier.setCheckInTime(const TimeOfDay(hour: 15, minute: 30));

        notifier.setCheckInDate(DateTime(2024, 8, 20));

        expect(notifier.state.checkIn.year, 2024);
        expect(notifier.state.checkIn.month, 8);
        expect(notifier.state.checkIn.day, 20);
        expect(notifier.state.checkIn.hour, 15);
        expect(notifier.state.checkIn.minute, 30);
      });
    });

    group('setCheckInTime', () {
      test('preserves date when changing time', () {
        final notifier = NewBookingNotifier();
        final originalDate = notifier.state.checkIn;

        notifier.setCheckInTime(const TimeOfDay(hour: 18, minute: 45));

        expect(notifier.state.checkIn.year, originalDate.year);
        expect(notifier.state.checkIn.month, originalDate.month);
        expect(notifier.state.checkIn.day, originalDate.day);
        expect(notifier.state.checkIn.hour, 18);
        expect(notifier.state.checkIn.minute, 45);
      });
    });

    group('setCheckOutDate', () {
      test('preserves time when changing date', () {
        final notifier = NewBookingNotifier();
        notifier.setCheckOutTime(const TimeOfDay(hour: 12, minute: 0));

        final futureDate = DateTime.now().add(const Duration(days: 10));
        notifier.setCheckOutDate(futureDate);

        expect(notifier.state.checkOut.year, futureDate.year);
        expect(notifier.state.checkOut.month, futureDate.month);
        expect(notifier.state.checkOut.day, futureDate.day);
        expect(notifier.state.checkOut.hour, 12);
        expect(notifier.state.checkOut.minute, 0);
      });

      test('rejects date before check-in', () {
        final notifier = NewBookingNotifier();
        final originalCheckOut = notifier.state.checkOut;

        // Try to set check-out to before check-in
        notifier.setCheckOutDate(
          DateTime.now().subtract(const Duration(days: 5)),
        );

        // Should remain unchanged
        expect(notifier.state.checkOut.day, originalCheckOut.day);
      });
    });

    group('setCheckOutTime', () {
      test('preserves date when changing time', () {
        final notifier = NewBookingNotifier();
        final originalDate = notifier.state.checkOut;

        notifier.setCheckOutTime(const TimeOfDay(hour: 14, minute: 30));

        expect(notifier.state.checkOut.year, originalDate.year);
        expect(notifier.state.checkOut.month, originalDate.month);
        expect(notifier.state.checkOut.day, originalDate.day);
        expect(notifier.state.checkOut.hour, 14);
        expect(notifier.state.checkOut.minute, 30);
      });
    });

    group('default state', () {
      test('check-in defaults to today with current time (no rounding)', () {
        final beforeCreate = DateTime.now();
        final notifier = NewBookingNotifier();
        final afterCreate = DateTime.now();

        expect(notifier.state.checkIn.year, beforeCreate.year);
        expect(notifier.state.checkIn.month, beforeCreate.month);
        expect(notifier.state.checkIn.day, beforeCreate.day);
        // Check that check-in is within reasonable bounds (within 1 second of creation)
        expect(
          notifier.state.checkIn.isAfter(
                beforeCreate.subtract(const Duration(seconds: 1)),
              ) ||
              notifier.state.checkIn.isAtSameMomentAs(beforeCreate),
          isTrue,
        );
        expect(
          notifier.state.checkIn.isBefore(
                afterCreate.add(const Duration(seconds: 1)),
              ) ||
              notifier.state.checkIn.isAtSameMomentAs(afterCreate),
          isTrue,
        );
      });

      test('check-out defaults to tomorrow at 11:00 AM', () {
        final notifier = NewBookingNotifier();
        final tomorrow = DateTime.now().add(const Duration(days: 1));

        expect(notifier.state.checkOut.year, tomorrow.year);
        expect(notifier.state.checkOut.month, tomorrow.month);
        expect(notifier.state.checkOut.day, tomorrow.day);
        expect(notifier.state.checkOut.hour, 11);
        expect(notifier.state.checkOut.minute, 0);
      });
    });
  });
}
