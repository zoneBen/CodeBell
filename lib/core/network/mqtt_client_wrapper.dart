import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../constants/app_constants.dart';
import '../constants/mqtt_topics.dart';
import '../errors/exceptions.dart';
import '../../data/models/notification_message_model.dart';
import '../../domain/entities/notification_message.dart';

class MqttClientWrapper {
  MqttServerClient? _client;
  final StreamController<NotificationMessage> _notificationController =
      StreamController<NotificationMessage>.broadcast();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  final StreamController<String> _logController =
      StreamController<String>.broadcast();

  String? _currentBroker;
  int? _currentPort;
  String? _currentDeviceId;
  String? _username;
  String? _password;
  bool _isAutoReconnecting = false;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage?>>>? _messageSubscription;

  Stream<NotificationMessage> get notificationStream =>
      _notificationController.stream;

  Stream<bool> get connectionStatusStream =>
      _connectionStatusController.stream;

  Stream<String> get logStream => _logController.stream;

  void _log(String message) {
    final timestamp = DateTime.now().toLocal().toString().substring(11, 19);
    final logMessage = '[$timestamp] $message';
    print(logMessage);
    _logController.add(logMessage);
  }

  Future<bool> connect(
    String broker,
    int port,
    String deviceId, {
    String? username,
    String? password,
  }) async {
    _log('Starting connection to $broker:$port...');
    _connectionStatusController.add(false);

    // Save connection details for auto-reconnect
    _currentBroker = broker;
    _currentPort = port;
    _currentDeviceId = deviceId;
    _username = username;
    _password = password;

    final clientId = '${AppConstants.defaultMqttClientIdPrefix}$deviceId';
    _log('Client ID: $clientId');
    _client = MqttServerClient.withPort(broker, clientId, port);

    _client!.logging(on: true);
    _client!.keepAlivePeriod = 30;
    _client!.autoReconnect = true;
    _client!.resubscribeOnAutoReconnect = true;
    _client!.onConnected = () => _onConnected(deviceId);
    _client!.onDisconnected = _onDisconnected;
    _client!.onAutoReconnect = _onAutoReconnect;
    _client!.onAutoReconnected = _onAutoReconnected;
    _client!.onSubscribed = _onSubscribed;
    _client!.onUnsubscribed = _onUnsubscribed;
    _client!.onSubscribeFail = _onSubscribeFail;

    final connMessage = MqttConnectMessage()
        .withWillTopic(MqttTopics.status(deviceId))
        .withWillMessage('offline')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    if (username != null && password != null) {
      connMessage.authenticateAs(username, password);
    }

    _client!.connectionMessage = connMessage;

    try {
      _log('Waiting for connection...');
      await _client!.connect();

      if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
        _log('Connected! Subscribing to topic...');
        await _subscribeToTopic(deviceId);
        _connectionStatusController.add(true);
        return true;
      } else {
        _log('Connection failed - status: ${_client!.connectionStatus?.state}');
        _client!.disconnect();
        return false;
      }
    } catch (e) {
      _log('Connection error: $e');
      _client?.disconnect();
      // Try to auto-reconnect after error
      _scheduleAutoReconnect();
      return false;
    }
  }

  void _onConnected(String deviceId) {
    _log('Connected callback triggered!');
    _isAutoReconnecting = false;
    _connectionStatusController.add(true);
  }

  void _onAutoReconnect() {
    _log('Auto-reconnecting...');
    _isAutoReconnecting = true;
    _connectionStatusController.add(false);
  }

  void _onAutoReconnected() {
    _log('Auto-reconnected!');
    _isAutoReconnecting = false;
    _connectionStatusController.add(true);
    // Re-subscribe - mqtt_client should do this automatically, but just to be safe
    if (_currentDeviceId != null) {
      _subscribeToTopic(_currentDeviceId!);
    }
  }

  void _onDisconnected() {
    _log('Disconnected!');
    _connectionStatusController.add(false);
    // Schedule auto-reconnect if we have connection details
    if (_currentBroker != null && _currentPort != null && _currentDeviceId != null) {
      _scheduleAutoReconnect();
    }
  }

  void _scheduleAutoReconnect() {
    if (_isAutoReconnecting) {
      _log('Already trying to auto-reconnect...');
      return;
    }
    _log('Scheduling auto-reconnect in 5 seconds...');
    Future.delayed(const Duration(seconds: 5), () {
      if (_currentBroker != null && _currentPort != null && _currentDeviceId != null) {
        _log('Trying to auto-reconnect...');
        connect(
          _currentBroker!,
          _currentPort!,
          _currentDeviceId!,
          username: _username,
          password: _password,
        );
      }
    });
  }

  void _onSubscribed(String topic) {
    _log('Successfully subscribed to topic: $topic');
    _log('Setting up message listener...');

    // Cancel any existing subscription first
    _messageSubscription?.cancel();

    _messageSubscription = _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      _log('Received message update from broker!');
      if (c == null || c.isEmpty) {
        _log('  Warning: Empty message list!');
        return;
      }

      final recMess = c[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      _log('  Received raw payload: $payload');

      if (topic.contains('notification')) {
        try {
          _log('  Cleaning payload and parsing...');
          final message = NotificationMessageModel.fromRawJson(payload);
          _log('  Successfully parsed notification: ${message.title}');
          _notificationController.add(message.toEntity());
        } catch (e) {
          _log('  Error parsing message: $e');
          // Try to extract what we can from raw payload
          try {
            final json = jsonDecode(payload.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')) as Map<String, dynamic>;
            _log('  Fallback: extracted JSON keys: ${json.keys}');
          } catch (e2) {
            _log('  Fallback also failed: $e2');
          }
        }
      }
    });

    _log('Message listener is set up and waiting...');
  }

  void _onSubscribeFail(String topic) {
    _log('Failed to subscribe to topic: $topic');
  }

  void _onUnsubscribed(String? topic) {
    _log('Unsubscribed from topic: $topic');
  }

  Future<void> _subscribeToTopic(String deviceId) async {
    if (_client == null ||
        _client!.connectionStatus!.state != MqttConnectionState.connected) {
      throw MqttConnectionException('Not connected');
    }
    final topic = MqttTopics.notification(deviceId);
    _log('Subscribing to: $topic');
    _client!.subscribe(topic, MqttQos.atLeastOnce);
  }

  Future<void> subscribe(String deviceId) => _subscribeToTopic(deviceId);

  Future<void> publishNotification(
    NotificationMessage message,
    String deviceId,
  ) async {
    if (_client == null ||
        _client!.connectionStatus!.state != MqttConnectionState.connected) {
      throw MqttConnectionException('Not connected');
    }

    final builder = MqttClientPayloadBuilder();
    final model = NotificationMessageModel.fromEntity(message);
    builder.addString(jsonEncode(model.toJson()));

    _client!.publishMessage(
      MqttTopics.notification(deviceId),
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }

  Future<void> disconnect() async {
    _log('Disconnecting...');
    if (_client != null) {
      _client!.disconnect();
    }
  }

  void dispose() {
    _notificationController.close();
    _connectionStatusController.close();
    _logController.close();
    _messageSubscription?.cancel();
  }
}
