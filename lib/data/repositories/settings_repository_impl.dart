import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/device_id_generator.dart';
import '../../domain/entities/device_info.dart';
import '../../domain/entities/mqtt_config.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local_storage_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final LocalStorageDataSource _dataSource;

  SettingsRepositoryImpl(this._dataSource);

  @override
  Future<DeviceInfo> getDeviceInfo() async {
    try {
      final deviceId = await _dataSource.getDeviceId();
      if (deviceId == null) {
        final newDeviceId = DeviceIdGenerator.generate();
        await _dataSource.saveDeviceId(newDeviceId);
        return DeviceInfo(deviceId: newDeviceId);
      }
      return DeviceInfo(deviceId: deviceId);
    } on StorageException {
      rethrow;
    }
  }

  @override
  Future<void> saveDeviceInfo(DeviceInfo info) async {
    try {
      await _dataSource.saveDeviceId(info.deviceId);
    } on StorageException {
      rethrow;
    }
  }

  @override
  Future<MqttConfig> getMqttConfig() async {
    try {
      final usePublicBroker = await _dataSource.getUsePublicBroker() ?? true;
      if (usePublicBroker) {
        return const MqttConfig(
          broker: AppConstants.defaultMqttBroker,
          port: AppConstants.defaultMqttPort,
          usePublicBroker: true,
        );
      }

      final broker = await _dataSource.getMqttBroker();
      final port = await _dataSource.getMqttPort();

      if (broker == null || port == null) {
        return const MqttConfig(
          broker: AppConstants.defaultMqttBroker,
          port: AppConstants.defaultMqttPort,
          usePublicBroker: true,
        );
      }

      return MqttConfig(broker: broker, port: port, usePublicBroker: false);
    } on StorageException {
      rethrow;
    }
  }

  @override
  Future<void> saveMqttConfig(MqttConfig config) async {
    try {
      await _dataSource.saveUsePublicBroker(config.usePublicBroker);
      if (!config.usePublicBroker) {
        await _dataSource.saveMqttBroker(config.broker);
        await _dataSource.saveMqttPort(config.port);
      }
    } on StorageException {
      rethrow;
    }
  }
}
