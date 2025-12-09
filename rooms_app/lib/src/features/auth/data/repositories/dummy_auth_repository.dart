import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rooms/src/features/auth/domain/entities/user.dart';
import 'package:rooms/src/features/auth/domain/repositories/auth_repository.dart';

/// Dummy authentication repository for MVP development
class DummyAuthRepository implements AuthRepository {
  User? _currentUser;
  final _authStateController = StreamController<User?>.broadcast();

  // Hardcoded dummy users for testing
  static final List<User> _dummyUsers = [
    User(
      id: 'user-001',
      hotelId: 'hotel-001',
      name: 'John Owner',
      email: 'owner@rooms.io',
      role: UserRole.owner,
      phone: '+1234567890',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      isActive: true,
    ),
    User(
      id: 'user-002',
      hotelId: 'hotel-001',
      name: 'Jane Manager',
      email: 'manager@rooms.io',
      role: UserRole.manager,
      phone: '+1234567891',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      isActive: true,
    ),
    User(
      id: 'user-003',
      hotelId: 'hotel-001',
      name: 'Bob Staff',
      email: 'staff@rooms.io',
      role: UserRole.staff,
      phone: '+1234567892',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      isActive: true,
    ),
  ];

  // Hardcoded credentials (email: password)
  static const Map<String, String> _credentials = {
    'owner@rooms.io': 'owner123',
    'manager@rooms.io': 'manager123',
    'staff@rooms.io': 'staff123',
  };

  @override
  Future<User> login({required String email, required String password}) async {
    debugPrint('🔍 DummyAuthRepository: Login attempt');
    debugPrint('📧 Email received: $email');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Check credentials
    final expectedPassword = _credentials[email];
    debugPrint(
      '🔑 Expected password for $email: ${expectedPassword != null ? '***' : 'NOT FOUND'}',
    );

    if (expectedPassword == null || expectedPassword != password) {
      debugPrint('❌ Invalid credentials!');
      throw Exception('Invalid email or password');
    }

    debugPrint('✅ Credentials valid!');

    // Find and return user
    final user = _dummyUsers.firstWhere(
      (u) => u.email == email,
      orElse: () {
        debugPrint('❌ User not found in dummy users list');
        throw Exception('User not found');
      },
    );

    debugPrint('✅ User found: ${user.name} (${user.role.displayName})');

    _currentUser = user;
    _authStateController.add(_currentUser);

    debugPrint('✅ Auth state updated, user is now logged in');

    return user;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<User?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _currentUser;
  }

  @override
  Stream<User?> watchAuthState() {
    return _authStateController.stream;
  }

  @override
  Future<bool> isAuthenticated() async {
    return _currentUser != null;
  }

  void dispose() {
    _authStateController.close();
  }
}
