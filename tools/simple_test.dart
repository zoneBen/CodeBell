#!/usr/bin/env dart

import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:uuid/uuid.dart';

const String deviceId = '8b32c4ed61f24841';
const String broker = 'test.mosquitto.org';
const int port = 1883;

void main() async {
  print('Sending simple test message...');

  final clientId = 'aimsg_simple_test_${DateTime.now().millisecondsSinceEpoch}';
  final client = MqttServerClient.withPort(broker, clientId, port);

  client.keepAlivePeriod = 30;
  final connMessage = MqttConnectMessage().startClean();
  client.connectionMessage = connMessage;

  await client.connect();

  if (client.connectionStatus!.state != MqttConnectionState.connected) {
    print('Connection failed');
    return;
  }

  final messageId = const Uuid().v4();

  // Create a simple map without any special characters
  final message = <String, dynamic>{
    'id': messageId,
    'type': 'task_complete',
    'timestamp': DateTime.now().toUtc().toIso8601String(),
    'title': 'Test Notification',
    'body': 'This is a simple test message',
    'data': {'taskType': 'test_task', 'status': 'success'},
  };

  // Encode to JSON string
  final payload = jsonEncode(message);
  print('Payload: $payload');

  final builder = MqttClientPayloadBuilder();
  builder.addString(payload);

  final topic = 'claude/$deviceId/notification';
  print('Publishing to: $topic');

  client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);

  print('Message sent!');

  await Future.delayed(const Duration(seconds: 1));
  client.disconnect();
}
