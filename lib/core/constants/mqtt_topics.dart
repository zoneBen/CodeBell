class MqttTopics {
  static String notification(String deviceId) =>
      'apps/codebell/$deviceId/notification';
  static String status(String deviceId) => 'apps/codebell/$deviceId/status';
  static String ping(String deviceId) => 'apps/codebell/$deviceId/ping';
}
