import '../../domain/entities/notification_history.dart';
import '../../domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final List<NotificationHistory> _history = [];

  @override
  Future<List<NotificationHistory>> getAll() async {
    return List.unmodifiable(_history..sort((a, b) => b.timestamp.compareTo(a.timestamp)));
  }

  @override
  Future<void> add(NotificationHistory history) async {
    _history.insert(0, history);
  }

  @override
  Future<void> delete(String id) async {
    _history.removeWhere((h) => h.id == id);
  }

  @override
  Future<void> clearAll() async {
    _history.clear();
  }
}
