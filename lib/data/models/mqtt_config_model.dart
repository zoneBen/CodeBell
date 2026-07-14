import '../../domain/entities/mqtt_config.dart';

class MqttConfigModel extends MqttConfig {
  const MqttConfigModel({
    required super.broker,
    required super.port,
    super.username,
    super.password,
    super.usePublicBroker = true,
  });

  factory MqttConfigModel.fromEntity(MqttConfig entity) {
    return MqttConfigModel(
      broker: entity.broker,
      port: entity.port,
      username: entity.username,
      password: entity.password,
      usePublicBroker: entity.usePublicBroker,
    );
  }

  MqttConfig toEntity() {
    return MqttConfig(
      broker: broker,
      port: port,
      username: username,
      password: password,
      usePublicBroker: usePublicBroker,
    );
  }
}
