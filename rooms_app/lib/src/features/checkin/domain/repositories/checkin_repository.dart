import 'package:rooms/src/features/checkin/domain/entities/checkin_data.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';

/// Abstract repository for check-in operations
abstract class CheckinRepository {
  /// Process check-in for a room
  Future<void> processCheckin({required Room room, required CheckinData data});

  /// Validate check-in data before processing
  Future<bool> validateCheckinData(CheckinData data);

  /// Get check-in history for a room
  Future<List<CheckinData>> getCheckinHistory(String roomId);

  /// Cancel ongoing check-in
  Future<void> cancelCheckin(String roomId);
}
