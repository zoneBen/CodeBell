import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/service_locator.dart';
import 'core/utils/notification_helper.dart';
import 'presentation/bloc/device/device_bloc.dart';
import 'presentation/bloc/device/device_event.dart';
import 'presentation/bloc/mqtt/mqtt_bloc.dart';
import 'presentation/bloc/notification/notification_bloc.dart';
import 'presentation/bloc/notification/notification_event.dart';
import 'presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initServiceLocator();
  await NotificationHelper.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIMSG',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<DeviceBloc>.value(
            value: sl<DeviceBloc>()..add(DeviceLoadRequested()),
          ),
          BlocProvider<MqttBloc>.value(value: sl<MqttBloc>()),
          BlocProvider<NotificationBloc>.value(
            value: sl<NotificationBloc>()..add(NotificationLoadRequested()),
          ),
        ],
        child: const HomePage(),
      ),
    );
  }
}
