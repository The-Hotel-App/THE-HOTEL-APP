import 'package:rooms/src/features/checkin/domain/entities/checkin_data.dart';
import 'package:rooms/src/features/checkin/domain/repositories/checkin_repository.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';

/// Dummy implementation of CheckinRepository for development
class DummyCheckinRepository implements CheckinRepository {
  final List<CheckinData> _checkinHistory = [];

  @override
  Future<void> processCheckin({
    required Room room,
    required CheckinData data,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    _checkinHistory.add(data);
  }

  @override
  Future<bool> validateCheckinData(CheckinData data) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return data.isValid;
  }

  @override
  Future<List<CheckinData>> getCheckinHistory(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_checkinHistory);
  }

  @override
  Future<void> cancelCheckin(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
