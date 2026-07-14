import '../../../../domain/entities/device_info.dart';

abstract class DeviceEvent {}

class DeviceLoadRequested extends DeviceEvent {}

class DeviceSaveRequested extends DeviceEvent {
  final DeviceInfo info;

  DeviceSaveRequested(this.info);
}
