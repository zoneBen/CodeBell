import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/errors/exceptions.dart';

class LocalStorageDataSource {
  final SharedPreferences _prefs;

  LocalStorageDataSource(this._prefs);

  Future<String?> getDeviceId() async {
    try {
      return _prefs.getString(StorageKeys.deviceId);
    } catch (e) {
      throw StorageException('Failed to get device ID: $e');
    }
  }

  Future<void> saveDeviceId(String deviceId) async {
    try {
      await _prefs.setString(StorageKeys.deviceId, deviceId);
    } catch (e) {
      throw StorageException('Failed to save device ID: $e');
    }
  }

  Future<String?> getMqttBroker() async {
    try {
      return _prefs.getString(StorageKeys.mqttBroker);
    } catch (e) {
      throw StorageException('Failed to get MQTT broker: $e');
    }
  }

  Future<void> saveMqttBroker(String broker) async {
    try {
      await _prefs.setString(StorageKeys.mqttBroker, broker);
    } catch (e) {
      throw StorageException('Failed to save MQTT broker: $e');
    }
  }

  Future<int?> getMqttPort() async {
    try {
      return _prefs.getInt(StorageKeys.mqttPort);
    } catch (e) {
      throw StorageException('Failed to get MQTT port: $e');
    }
  }

  Future<void> saveMqttPort(int port) async {
    try {
      await _prefs.setInt(StorageKeys.mqttPort, port);
    } catch (e) {
      throw StorageException('Failed to save MQTT port: $e');
    }
  }

  Future<bool?> getUsePublicBroker() async {
    try {
      return _prefs.getBool(StorageKeys.usePublicBroker);
    } catch (e) {
      throw StorageException('Failed to get use public broker flag: $e');
    }
  }

  Future<void> saveUsePublicBroker(bool usePublic) async {
    try {
      await _prefs.setBool(StorageKeys.usePublicBroker, usePublic);
    } catch (e) {
      throw StorageException('Failed to save use public broker flag: $e');
    }
  }
}
