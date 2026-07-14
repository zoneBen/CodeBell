import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../domain/entities/notification_message.dart';

class NotificationMessageModel extends NotificationMessage {
  const NotificationMessageModel({
    required super.id,
    required super.type,
    required super.timestamp,
    required super.title,
    required super.body,
    super.data,
  });

  factory NotificationMessageModel.fromJson(Map<String, dynamic> json) {
    return NotificationMessageModel(
      id: json['id'] as String? ?? const Uuid().v4(),
      type: json['type'] as String? ?? 'task_complete',
      timestamp: DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toUtc().toIso8601String()),
      title: json['title'] as String? ?? 'Task Complete',
      body: json['body'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  /// Create from raw JSON string, cleaning control characters
  factory NotificationMessageModel.fromRawJson(String rawJson) {
    // Clean control characters except for tab, newline, carriage return
    final cleanJson = rawJson.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    return NotificationMessageModel.fromJson(jsonDecode(cleanJson) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'title': title,
      'body': body,
      'data': data,
    };
  }

  factory NotificationMessageModel.fromEntity(NotificationMessage entity) {
    return NotificationMessageModel(
      id: entity.id,
      type: entity.type,
      timestamp: entity.timestamp,
      title: entity.title,
      body: entity.body,
      data: entity.data,
    );
  }

  NotificationMessage toEntity() {
    return NotificationMessage(
      id: id,
      type: type,
      timestamp: timestamp,
      title: title,
      body: body,
      data: data,
    );
  }
}
