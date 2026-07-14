import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../../../domain/entities/mqtt_config.dart';
import '../../../../domain/usecases/connect_mqtt_usecase.dart';
import '../../../../domain/repositories/mqtt_repository.dart';
import 'mqtt_event.dart';
import 'mqtt_state.dart';

class MqttBloc extends Bloc<MqttEvent, MqttState> {
  final ConnectMqttUseCase _connectUseCase;
  final MqttRepository _mqttRepository;
  StreamSubscription<bool>? _connectionSubscription;
  bool _isConnecting = false;

  MqttBloc(this._connectUseCase, this._mqttRepository) : super(MqttInitial()) {
    on<MqttConnectRequested>(_onConnectRequested);
    on<MqttDisconnectRequested>(_onDisconnectRequested);
  }

  Future<void> _onConnectRequested(
    MqttConnectRequested event,
    Emitter<MqttState> emit,
  ) async {
    if (_isConnecting) {
      return;
    }
    _isConnecting = true;

    // Cancel any existing subscription first
    await _connectionSubscription?.cancel();

    emit(MqttConnecting());
    try {
      // Listen to connection status FIRST before connecting
      _connectionSubscription = _mqttRepository.connectionStatusStream.listen(
        (isConnected) {
          if (!isClosed) {
            if (isConnected) {
              emit(MqttConnected());
            } else {
              emit(MqttDisconnected());
            }
          }
        },
      );

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
