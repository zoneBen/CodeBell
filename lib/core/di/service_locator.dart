import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/mqtt_client_wrapper.dart';
import '../../data/datasources/local_storage_datasource.dart';
import '../../data/datasources/mqtt_datasource.dart';
import '../../data/repositories/mqtt_repository_impl.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/mqtt_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/usecases/connect_mqtt_usecase.dart';
import '../../domain/usecases/get_device_id_usecase.dart';
import '../../domain/usecases/save_device_id_usecase.dart';
import '../../domain/usecases/get_notification_history_usecase.dart';
import '../../presentation/bloc/device/device_bloc.dart';
import '../../presentation/bloc/mqtt/mqtt_bloc.dart';
import '../../presentation/bloc/notification/notification_bloc.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // Core
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => MqttClientWrapper());

  // Data sources
  sl.registerLazySingleton(() => LocalStorageDataSource(prefs));
  sl.registerLazySingleton(() => MqttDataSource(sl()));

  // Repositories
  sl.registerLazySingleton<MqttRepository>(() => MqttRepositoryImpl(sl()));
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<HistoryRepository>(() => HistoryRepositoryImpl());

  // Use cases
  sl.registerFactory(() => ConnectMqttUseCase(sl()));
  sl.registerFactory(() => GetDeviceIdUseCase(sl()));
  sl.registerFactory(() => SaveDeviceIdUseCase(sl()));
  sl.registerFactory(() => GetNotificationHistoryUseCase(sl()));

  // Blocs (LazySingleton - single instance for app)
  sl.registerLazySingleton(() => DeviceBloc(sl(), sl()));
  sl.registerLazySingleton(() => MqttBloc(sl(), sl()));
  sl.registerLazySingleton(() => NotificationBloc(sl(), sl()));
}
