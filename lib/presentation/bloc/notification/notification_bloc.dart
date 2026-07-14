import 'package:bloc/bloc.dart';
import '../../../../domain/usecases/get_notification_history_usecase.dart';
import '../../../../domain/repositories/history_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationHistoryUseCase _getHistoryUseCase;
  final HistoryRepository _historyRepository;

  NotificationBloc(this._getHistoryUseCase, this._historyRepository)
    : super(NotificationInitial()) {
    on<NotificationLoadRequested>(_onLoadRequested);
    on<NotificationReceived>(_onNotificationReceived);
    on<NotificationClearAllRequested>(_onClearAllRequested);
  }

  Future<void> _onLoadRequested(
    NotificationLoadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    try {
      final notifications = await _getHistoryUseCase();
      emit(NotificationLoaded(notifications));
    } catch (e) {
      emit(const NotificationLoaded([]));
    }
  }

  Future<void> _onNotificationReceived(
    NotificationReceived event,
    Emitter<NotificationState> emit,
  ) async {
    await _historyRepository.add(event.history);
    final notifications = await _getHistoryUseCase();
    emit(NotificationLoaded(notifications));
  }

  Future<void> _onClearAllRequested(
    NotificationClearAllRequested event,
    Emitter<NotificationState> emit,
  ) async {
    await _historyRepository.clearAll();
    emit(const NotificationLoaded([]));
  }
}
