import 'package:rooms/src/features/dashboards/domain/entities/dashboard_stats.dart';

/// Abstract repository for dashboard data
abstract class DashboardRepository {
  /// Get current dashboard statistics
  Future<DashboardStats> getStats(String hotelId);

  /// Get revenue for a date range
  Future<double> getRevenue({
    required String hotelId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Stream of real-time stats updates
  Stream<DashboardStats> watchStats(String hotelId);
}
