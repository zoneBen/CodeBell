import 'package:equatable/equatable.dart';
import '../../../../domain/entities/device_info.dart';

abstract class DeviceState extends Equatable {
  const DeviceState();

  @override
  List<Object?> get props => [];
}

class DeviceInitial extends DeviceState {}

class DeviceLoading extends DeviceState {}

class DeviceLoaded extends DeviceState {
  final DeviceInfo deviceInfo;

  const DeviceLoaded(this.deviceInfo);

  @override
  List<Object?> get props => [deviceInfo];
}

class DeviceError extends DeviceState {
  final String message;

  const DeviceError(this.message);

  @override
  List<Object?> get props => [message];
}
