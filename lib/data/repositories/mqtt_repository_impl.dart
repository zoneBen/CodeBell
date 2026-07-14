import '../../domain/entities/mqtt_config.dart';
import '../../domain/entities/notification_message.dart';
import '../../domain/repositories/mqtt_repository.dart';
import '../datasources/mqtt_datasource.dart';

class MqttRepositoryImpl implements MqttRepository {
  final MqttDataSource _dataSource;

  MqttRepositoryImpl(this._dataSource);

  @override
  Future<bool> connect(MqttConfig config, String deviceId) {
    return _dataSource.connect(config, deviceId);
  }

  @override
  Future<void> disconnect() {
    return _dataSource.disconnect();
  }

  @override
  Stream<NotificationMessage> get notificationStream =>
      _dataSource.notificationStream;

  @override
  Stream<bool> get connectionStatusStream =>
      _dataSource.connectionStatusStream;

  @override
  Future<void> publishNotification(
    NotificationMessage message,
    String deviceId,
  ) {
    return _dataSource.publishNotification(message, deviceId);
  }
}
