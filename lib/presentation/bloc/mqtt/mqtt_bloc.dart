import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../../../domain/entities/mqtt_config.dart';
import '../../../../domain/usecases/connect_mqtt_usecase.dart';
import '../../../../domain/repositories/mqtt_repository.dart';
import '../../../../domain/repositories/settings_repository.dart';
import '../../../../core/di/service_locator.dart';
import 'mqtt_event.dart';
import 'mqtt_state.dart';

class MqttBloc extends Bloc<MqttEvent, MqttState> {
  final ConnectMqttUseCase _connectUseCase;
  final MqttRepository _mqttRepository;
  StreamSubscription<bool>? _connectionSubscription;
  bool _isConnecting = false;
  String? _cachedDeviceId;

  MqttBloc(this._connectUseCase, this._mqttRepository) : super(MqttInitial()) {
    on<MqttConnectRequested>(_onConnectRequested);
    on<MqttDisconnectRequested>(_onDisconnectRequested);
    on<MqttAutoReconnectRequested>(_onAutoReconnectRequested);
  }

  Future<void> _setupConnectionListener(Emitter<MqttState> emit) async {
    await _connectionSubscription?.cancel();
    _connectionSubscription = _mqttRepository.connectionStatusStream.listen((
      isConnected,
    ) {
      if (!isClosed) {
        if (isConnected) {
          emit(MqttConnected());
        } else {
          emit(MqttDisconnected());
        }
      }
    });
  }

  Future<void> _onConnectRequested(
    MqttConnectRequested event,
    Emitter<MqttState> emit,
  ) async {
    if (_isConnecting) {
      return;
    }
    _isConnecting = true;
    _cachedDeviceId = event.deviceId;

    emit(MqttConnecting());
    try {
      await _setupConnectionListener(emit);

      final config = MqttConfig(
        broker: event.broker,
        port: event.port,
        username: event.username,
        password: event.password,
      );
      final connected = await _connectUseCase(config, event.deviceId);
      if (!connected) {
        emit(const MqttError('Connection failed'));
      }
    } catch (e) {
      emit(MqttError(e.toString()));
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _onAutoReconnectRequested(
    MqttAutoReconnectRequested event,
    Emitter<MqttState> emit,
  ) async {
    if (_isConnecting || _cachedDeviceId == null) {
      return;
    }
    _isConnecting = true;

    emit(MqttConnecting());
    try {
      await _setupConnectionListener(emit);

      final mqttConfig = await sl<SettingsRepository>().getMqttConfig();
      final config = MqttConfig(
        broker: mqttConfig.broker,
        port: mqttConfig.port,
        username: mqttConfig.username,
        password: mqttConfig.password,
      );
      final connected = await _connectUseCase(config, _cachedDeviceId!);
      if (!connected) {
        emit(MqttDisconnected());
      }
    } catch (e) {
      emit(MqttDisconnected());
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _onDisconnectRequested(
    MqttDisconnectRequested event,
    Emitter<MqttState> emit,
  ) async {
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    await _mqttRepository.disconnect();
    emit(MqttDisconnected());
  }

  @override
  Future<void> close() {
    _connectionSubscription?.cancel();
    return super.close();
  }
}
