class MqttTopics {
  static String notification(String deviceId) =>
      'claude/$deviceId/notification';
  static String status(String deviceId) => 'claude/$deviceId/status';
  static String ping(String deviceId) => 'claude/$deviceId/ping';
}
