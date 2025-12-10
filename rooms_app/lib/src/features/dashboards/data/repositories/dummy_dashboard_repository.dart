import 'dart:async';

import 'package:rooms/src/features/dashboards/domain/entities/dashboard_stats.dart';
import 'package:rooms/src/features/dashboards/domain/repositories/dashboard_repository.dart';

/// Dummy implementation of DashboardRepository for development
class DummyDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardStats> getStats(String hotelId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Return mock stats
    return const DashboardStats(
      totalRooms: 20,
      freeRooms: 8,
      occupiedRooms: 10,
      cleaningRooms: 1,
      maintenanceRooms: 1,
      occupancyRate: 0.50,
      todayRevenue: 25000,
      todayCheckins: 3,
      todayCheckouts: 2,
      pendingBookings: 5,
    );
  }

  @override
  Future<double> getRevenue({
    required String hotelId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 150000.0; // Mock revenue
  }

  @override
  Stream<DashboardStats> watchStats(String hotelId) {
    return Stream.periodic(const Duration(seconds: 30), (_) {
      return const DashboardStats(
        totalRooms: 20,
        freeRooms: 8,
        occupiedRooms: 10,
        cleaningRooms: 1,
        maintenanceRooms: 1,
        occupancyRate: 0.50,
        todayRevenue: 25000,
        todayCheckins: 3,
        todayCheckouts: 2,
        pendingBookings: 5,
      );
    });
  }
}
