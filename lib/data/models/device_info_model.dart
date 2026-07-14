import '../../domain/entities/device_info.dart';

class DeviceInfoModel extends DeviceInfo {
  const DeviceInfoModel({required super.deviceId});

  factory DeviceInfoModel.fromEntity(DeviceInfo entity) {
    return DeviceInfoModel(deviceId: entity.deviceId);
  }

  DeviceInfo toEntity() {
    return DeviceInfo(deviceId: deviceId);
  }
}
