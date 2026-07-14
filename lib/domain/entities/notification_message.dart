import 'package:equatable/equatable.dart';

class NotificationMessage extends Equatable {
  final String id;
  final String type;
  final DateTime timestamp;
  final String title;
  final String body;
  final Map<String, dynamic>? data;

  const NotificationMessage({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.title,
    required this.body,
    this.data,
  });

  @override
  List<Object?> get props => [id, type, timestamp, title, body, data];
}
