#!/usr/bin/env dart

/// Claude Code Task Completion Hook
///
/// This script sends an MQTT notification when a Claude Code task completes.
/// Configure it in your ~/.claude/settings.json as a PostToolUse hook.
///
/// Usage: dart run claude_hook.dart --device-id="YOUR_DEVICE_ID"
///
/// Environment variable: AIMSG_DEVICE_ID (alternative to --device-id)
/// Optional: AIMSG_BROKER (default: test.mosquitto.org)
/// Optional: AIMSG_PORT (default: 1883)

import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:uuid/uuid.dart';

void main(List<String> args) async {
  // Parse device ID from args or environment
  String? deviceId;
  String? broker;
  int? port;
  String taskType = 'unknown_task';

  for (var i = 0; i < args.length; i++) {
    if (args[i].startsWith('--device-id=') || args[i].startsWith('-d=')) {
      deviceId = args[i].split('=')[1];
    } else if (args[i] == '--device-id' || args[i] == '-d') {
      if (i + 1 < args.length) {
        deviceId = args[i + 1];
        i++;
      }
    } else if (args[i].startsWith('--broker=')) {
      broker = args[i].split('=')[1];
    } else if (args[i] == '--broker') {
      if (i + 1 < args.length) {
        broker = args[i + 1];
        i++;
      }
    } else if (args[i].startsWith('--port=')) {
      port = int.tryParse(args[i].split('=')[1]);
    } else if (args[i] == '--port') {
      if (i + 1 < args.length) {
        port = int.tryParse(args[i + 1]);
        i++;
      }
    } else if (!args[i].startsWith('-')) {
      taskType = args[i];
    }
  }

  // Fall back to environment variables
  deviceId ??= Platform.environment['AIMSG_DEVICE_ID'];
  broker ??= Platform.environment['AIMSG_BROKER'] ?? 'test.mosquitto.org';
  port ??= int.tryParse(Platform.environment['AIMSG_PORT'] ?? '') ?? 1883;

  if (deviceId == null || deviceId.isEmpty) {
    print(
      'Error: Device ID is required. Use --device-id or set AIMSG_DEVICE_ID environment variable.',
    );
    print('');
    print(
      'Your device ID can be found in the AIMSG Flutter app: 8b32c4ed61f24841',
    );
    print('');
    print(
      'Usage: dart run claude_hook.dart --device-id="8b32c4ed61f24841" [task_type]',
    );
    exit(1);
  }

  // Send notification
  await sendNotification(broker, port, deviceId, taskType);
}

Future<void> sendNotification(
  String broker,
  int port,
  String deviceId,
  String taskType,
) async {
  final clientId = 'aimsg_hook_${DateTime.now().millisecondsSinceEpoch}';
  final client = MqttServerClient.withPort(broker, clientId, port);

  client.logging(on: false);
  client.keepAlivePeriod = 30;

  final connMessage = MqttConnectMessage().startClean().withWillQos(
    MqttQos.atLeastOnce,
  );

  client.connectionMessage = connMessage;

  try {
    await client.connect();
  } catch (e) {
    print('Error connecting to MQTT broker: $e');
    client.disconnect();
    return;
  }

  if (client.connectionStatus!.state != MqttConnectionState.connected) {
    print('Error: Failed to connect to MQTT broker');
    client.disconnect();
    return;
  }

  final messageId = const Uuid().v4();
  final payload = jsonEncode({
    'id': messageId,
    'type': 'task_complete',
    'timestamp': DateTime.now().toUtc().toIso8601String(),
    'title': '✅ Claude Code Task Complete',
    'body': 'Your task has finished: $taskType',
    'data': {'taskType': taskType},
  });

  final builder = MqttClientPayloadBuilder();
  builder.addString(payload);

  final topic = 'claude/$deviceId/notification';
  client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);

  print('Notification sent to device $deviceId');

  await Future.delayed(const Duration(milliseconds: 500));
  client.disconnect();
}
