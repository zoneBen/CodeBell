import '../entities/mqtt_config.dart';
import '../repositories/mqtt_repository.dart';

class ConnectMqttUseCase {
  final MqttRepository repository;

  ConnectMqttUseCase(this.repository);

  Future<bool> call(MqttConfig config, String deviceId) {
    return repository.connect(config, deviceId);
  }
}
