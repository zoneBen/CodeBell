abstract class MqttEvent {}

class MqttConnectRequested extends MqttEvent {
  final String broker;
  final int port;
  final String deviceId;
  final String? username;
  final String? password;

  MqttConnectRequested({
    required this.broker,
    required this.port,
    required this.deviceId,
    this.username,
    this.password,
  });
}

class MqttAutoReconnectRequested extends MqttEvent {}

class MqttDisconnectRequested extends MqttEvent {}
