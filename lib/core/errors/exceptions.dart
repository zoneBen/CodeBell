class MqttConnectionException implements Exception {
  final String message;

  MqttConnectionException(this.message);

  @override
  String toString() => 'MqttConnectionException: $message';
}

class MqttPublishException implements Exception {
  final String message;

  MqttPublishException(this.message);

  @override
  String toString() => 'MqttPublishException: $message';
}

class StorageException implements Exception {
  final String message;

  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
