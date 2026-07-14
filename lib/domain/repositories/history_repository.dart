import '../entities/notification_history.dart';

abstract class HistoryRepository {
  Future<List<NotificationHistory>> getAll();
  Future<void> add(NotificationHistory history);
  Future<void> delete(String id);
  Future<void> clearAll();
}
