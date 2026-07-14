#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:uuid/uuid.dart';

const String deviceId = '8b32c4ed61f24841';
const String broker = 'test.mosquitto.org';
const int port = 1883;

void main() async {
  print('📡 Connecting to MQTT broker...');
  print('   Broker: $broker:$port');
  print('   Device ID: $deviceId');
  print('');

  final clientId = 'aimsg_test_${DateTime.now().millisecondsSinceEpoch}';
  final client = MqttServerClient.withPort(broker, clientId, port);

  client.logging(on: true);
  client.keepAlivePeriod = 30;

  final connMessage = MqttConnectMessage()
      .startClean()
      .withWillQos(MqttQos.atLeastOnce);

  client.connectionMessage = connMessage;

  try {
    await client.connect();
    print('✅ Connected successfully!');
  } catch (e) {
    print('❌ Connection failed: $e');
    client.disconnect();
    return;
  }

  if (client.connectionStatus!.state != MqttConnectionState.connected) {
    print('❌ Not connected');
    client.disconnect();
    return;
  }

  // Create notification message
  final messageId = const Uuid().v4();
  final payload = jsonEncode({
    'id': messageId,
    'type': 'task_complete',
    'timestamp': DateTime.now().toUtc().toIso8601String(),
    'title': '✅ Claude Code Task Complete!',
    'body': 'Your test task has finished successfully!',
    'data': {
      'taskType': 'test_task',
      'status': 'success',
    },
  });

  final builder = MqttClientPayloadBuilder();
  builder.addString(payload);

  final topic = 'claude/$deviceId/notification';
  print('');
  print('📤 Publishing to: $topic');
  print('📄 Message: $payload');
  print('');

  client.publishMessage(
    topic,
    MqttQos.atLeastOnce,
    builder.payload!,
  );

  print('✅ Notification sent!');
  print('');
  print('💡 If you have the AIMSG app running with this device ID,');
  print('   you should receive a notification shortly!');

  await Future.delayed(const Duration(seconds: 2));
  client.disconnect();
  print('');
  print('👋 Disconnected');
}
