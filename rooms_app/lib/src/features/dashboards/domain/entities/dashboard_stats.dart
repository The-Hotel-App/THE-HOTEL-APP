/// Dashboard statistics entity
class DashboardStats {
  final int totalRooms;
  final int freeRooms;
  final int occupiedRooms;
  final int cleaningRooms;
  final int maintenanceRooms;
  final double occupancyRate;
  final double todayRevenue;
  final int todayCheckins;
  final int todayCheckouts;
  final int pendingBookings;

  const DashboardStats({
    required this.totalRooms,
    required this.freeRooms,
    required this.occupiedRooms,
    required this.cleaningRooms,
    required this.maintenanceRooms,
    required this.occupancyRate,
    required this.todayRevenue,
    required this.todayCheckins,
    required this.todayCheckouts,
    required this.pendingBookings,
  });

  factory DashboardStats.empty() {
    return const DashboardStats(
      totalRooms: 0,
      freeRooms: 0,
      occupiedRooms: 0,
      cleaningRooms: 0,
      maintenanceRooms: 0,
      occupancyRate: 0,
      todayRevenue: 0,
      todayCheckins: 0,
      todayCheckouts: 0,
      pendingBookings: 0,
    );
  }

  DashboardStats copyWith({
    int? totalRooms,
    int? freeRooms,
    int? occupiedRooms,
    int? cleaningRooms,
    int? maintenanceRooms,
    double? occupancyRate,
    double? todayRevenue,
    int? todayCheckins,
    int? todayCheckouts,
    int? pendingBookings,
  }) {
    return DashboardStats(
      totalRooms: totalRooms ?? this.totalRooms,
      freeRooms: freeRooms ?? this.freeRooms,
      occupiedRooms: occupiedRooms ?? this.occupiedRooms,
      cleaningRooms: cleaningRooms ?? this.cleaningRooms,
      maintenanceRooms: maintenanceRooms ?? this.maintenanceRooms,
      occupancyRate: occupancyRate ?? this.occupancyRate,
      todayRevenue: todayRevenue ?? this.todayRevenue,
      todayCheckins: todayCheckins ?? this.todayCheckins,
      todayCheckouts: todayCheckouts ?? this.todayCheckouts,
      pendingBookings: pendingBookings ?? this.pendingBookings,
    );
  }
}
