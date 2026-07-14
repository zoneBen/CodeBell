import '../../core/network/mqtt_client_wrapper.dart';
import '../../domain/entities/mqtt_config.dart';
import '../../domain/entities/notification_message.dart';

class MqttDataSource {
  final MqttClientWrapper _client;

  MqttDataSource(this._client);

  Future<bool> connect(MqttConfig config, String deviceId) async {
    return await _client.connect(
      config.broker,
      config.port,
      deviceId,
      username: config.username,
      password: config.password,
    );
  }

  Future<void> disconnect() => _client.disconnect();

  Stream<NotificationMessage> get notificationStream =>
      _client.notificationStream;

  Stream<bool> get connectionStatusStream => _client.connectionStatusStream;

  Future<void> publishNotification(
    NotificationMessage message,
    String deviceId,
  ) =>
      _client.publishNotification(message, deviceId);
}
