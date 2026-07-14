import '../entities/mqtt_config.dart';
import '../entities/notification_message.dart';

abstract class MqttRepository {
  Future<bool> connect(MqttConfig config, String deviceId);
  Future<void> disconnect();
  Stream<NotificationMessage> get notificationStream;
  Stream<bool> get connectionStatusStream;
  Future<void> publishNotification(
    NotificationMessage message,
    String deviceId,
  );
}
