import '../../../../domain/entities/notification_history.dart';

abstract class NotificationEvent {}

class NotificationLoadRequested extends NotificationEvent {}

class NotificationReceived extends NotificationEvent {
  final NotificationHistory history;

  NotificationReceived(this.history);
}

class NotificationClearAllRequested extends NotificationEvent {}
