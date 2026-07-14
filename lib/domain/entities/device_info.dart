import 'package:equatable/equatable.dart';

class DeviceInfo extends Equatable {
  final String deviceId;

  const DeviceInfo({required this.deviceId});

  @override
  List<Object?> get props => [deviceId];
}
