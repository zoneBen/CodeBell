import '../entities/notification_history.dart';
import '../repositories/history_repository.dart';

class GetNotificationHistoryUseCase {
  final HistoryRepository repository;

  GetNotificationHistoryUseCase(this.repository);

  Future<List<NotificationHistory>> call() {
    return repository.getAll();
  }
}
