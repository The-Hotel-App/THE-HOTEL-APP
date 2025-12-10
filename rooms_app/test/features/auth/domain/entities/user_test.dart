import 'package:flutter_test/flutter_test.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart';

void main() {
  group('UserRole', () {
    test('displayName returns correct values', () {
      expect(UserRole.owner.displayName, 'Owner');
      expect(UserRole.manager.displayName, 'Manager');
      expect(UserRole.staff.displayName, 'Staff');
      expect(UserRole.kitchenManager.displayName, 'Kitchen Manager');
    });

    test('dbValue returns correct snake_case values', () {
      expect(UserRole.owner.dbValue, 'owner');
      expect(UserRole.manager.dbValue, 'manager');
      expect(UserRole.staff.dbValue, 'staff');
      expect(UserRole.kitchenManager.dbValue, 'kitchen_manager');
    });

    test('fromString parses correctly', () {
      expect(UserRole.fromString('owner'), UserRole.owner);
      expect(UserRole.fromString('manager'), UserRole.manager);
      expect(UserRole.fromString('staff'), UserRole.staff);
      expect(UserRole.fromString('kitchen_manager'), UserRole.kitchenManager);
    });

    test('fromString throws on invalid value', () {
      expect(
        () => UserRole.fromString('invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });

    group('permissions', () {
      test('owner has full permissions', () {
        expect(UserRole.owner.canEditPastBookings, true);
        expect(UserRole.owner.canManageStaff, true);
        expect(UserRole.owner.canViewMoneyDetails, true);
        expect(UserRole.owner.canManageRoomTypes, true);
        expect(UserRole.owner.canEditRooms, true);
      });

      test('manager has operational permissions', () {
        expect(UserRole.manager.canEditCurrentBookings, true);
        expect(UserRole.manager.canEditPastBookings, false);
        expect(UserRole.manager.canManageStaff, false);
        expect(UserRole.manager.canViewMoneyDetails, false);
      });

      test('staff has limited permissions', () {
        expect(UserRole.staff.canCreateBookings, true);
        expect(UserRole.staff.canEditCurrentBookings, false);
        expect(UserRole.staff.canManageStaff, false);
      });

      test('kitchenManager cannot access rooms', () {
        expect(UserRole.kitchenManager.canAccessRooms, false);
        expect(UserRole.kitchenManager.canViewFoodOrders, true);
        expect(UserRole.kitchenManager.canManageFoodOrders, true);
      });
    });
  });

  group('User', () {
    test('creates user from JSON', () {
      final json = {
        'id': 'test-id',
        'name': 'Test User',
        'email': 'test@example.com',
        'phone': '+91 9876543210',
        'created_at': '2024-01-01T00:00:00.000Z',
        'is_active': true,
        'has_biometric': false,
      };

      final user = User.fromJson(json);

      expect(user.id, 'test-id');
      expect(user.name, 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.phone, '+91 9876543210');
      expect(user.isActive, true);
      expect(user.hasBiometric, false);
    });

    test('copyWith creates modified copy', () {
      final user = User(
        id: 'test-id',
        name: 'Original Name',
        email: 'test@example.com',
        createdAt: DateTime(2024, 1, 1),
      );

      final modifiedUser = user.copyWith(name: 'New Name');

      expect(modifiedUser.id, user.id);
      expect(modifiedUser.name, 'New Name');
      expect(modifiedUser.email, user.email);
    });
  });

  group('UserHotel', () {
    test('creates UserHotel from JSON', () {
      final json = {
        'hotel_id': 'hotel-123',
        'hotel_name': 'Test Hotel',
        'user_role': 'owner',
        'is_owner': true,
      };

      final userHotel = UserHotel.fromJson(json);

      expect(userHotel.hotelId, 'hotel-123');
      expect(userHotel.hotelName, 'Test Hotel');
      expect(userHotel.role, UserRole.owner);
      expect(userHotel.isOwner, true);
    });
  });
}
