import 'package:equatable/equatable.dart';

class MqttConfig extends Equatable {
  final String broker;
  final int port;
  final String? username;
  final String? password;
  final bool usePublicBroker;

  const MqttConfig({
    required this.broker,
    required this.port,
    this.username,
    this.password,
    this.usePublicBroker = true,
  });

  @override
  List<Object?> get props => [
    broker,
    port,
    username,
    password,
    usePublicBroker,
  ];
}
