import 'package:bloc/bloc.dart';
import '../../../../domain/usecases/get_device_id_usecase.dart';
import '../../../../domain/usecases/save_device_id_usecase.dart';
import 'device_event.dart';
import 'device_state.dart';

class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  final GetDeviceIdUseCase _getDeviceIdUseCase;
  final SaveDeviceIdUseCase _saveDeviceIdUseCase;

  DeviceBloc(this._getDeviceIdUseCase, this._saveDeviceIdUseCase)
      : super(DeviceInitial()) {
    on<DeviceLoadRequested>(_onLoadRequested);
    on<DeviceSaveRequested>(_onSaveRequested);
  }

  Future<void> _onLoadRequested(
    DeviceLoadRequested event,
    Emitter<DeviceState> emit,
  ) async {
    emit(DeviceLoading());
    try {
      final deviceInfo = await _getDeviceIdUseCase();
      emit(DeviceLoaded(deviceInfo));
    } catch (e) {
      emit(DeviceError(e.toString()));
    }
  }

  Future<void> _onSaveRequested(
    DeviceSaveRequested event,
    Emitter<DeviceState> emit,
  ) async {
    try {
      await _saveDeviceIdUseCase(event.info);
      emit(DeviceLoaded(event.info));
    } catch (e) {
      emit(DeviceError(e.toString()));
    }
  }
}
