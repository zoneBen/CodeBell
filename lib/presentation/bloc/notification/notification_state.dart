import 'package:equatable/equatable.dart';
import '../../../../domain/entities/notification_history.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationHistory> notifications;

  const NotificationLoaded(this.notifications);

  @override
  List<Object?> get props => [notifications];
}
