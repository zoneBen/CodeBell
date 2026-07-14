import 'package:equatable/equatable.dart';

class NotificationHistory extends Equatable {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String? taskType;

  const NotificationHistory({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.taskType,
  });

  @override
  List<Object?> get props => [id, title, body, timestamp, taskType];
}
