import '../entities/device_info.dart';
import '../entities/mqtt_config.dart';

abstract class SettingsRepository {
  Future<DeviceInfo> getDeviceInfo();
  Future<void> saveDeviceInfo(DeviceInfo info);
  Future<MqttConfig> getMqttConfig();
  Future<void> saveMqttConfig(MqttConfig config);
}
