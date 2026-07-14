import 'package:flutter/material.dart';
import '../core/di/service_locator.dart';
import '../core/utils/notification_helper.dart';
import '../domain/repositories/mqtt_repository.dart';
import 'pages/home_page.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    _initNotifications();
    _listenToNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      await NotificationHelper.initialize();
    } catch (e) {
      // Continue without notifications if setup fails
    }
  }

  void _listenToNotifications() {
    try {
      final mqttRepository = sl<MqttRepository>();
      mqttRepository.notificationStream.listen((message) {
        NotificationHelper.showNotification(message.title, message.body);
      });
    } catch (e) {
      // Continue if MQTT is not set up yet
    }
  }

  @override
  void dispose() {
    NotificationHelper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIMSG',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
