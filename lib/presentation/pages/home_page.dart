import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/notification_helper.dart';
import '../../domain/entities/notification_history.dart';
import '../../domain/repositories/mqtt_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../bloc/device/device_bloc.dart';
import '../bloc/device/device_state.dart';
import '../bloc/mqtt/mqtt_bloc.dart';
import '../bloc/mqtt/mqtt_event.dart';
import '../bloc/mqtt/mqtt_state.dart';
import '../bloc/notification/notification_bloc.dart';
import '../bloc/notification/notification_event.dart';
import '../bloc/notification/notification_state.dart';
import '../widgets/connection_status_indicator.dart';
import '../widgets/notification_card.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late MqttRepository _mqttRepository;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _mqttRepository = sl();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    _mqttRepository.notificationStream.listen((message) {
      // Show local notification - with error handling
      try {
        NotificationHelper.showNotification(message.title, message.body);
      } catch (e) {
        // Ignore notification errors for now
      }

      final history = NotificationHistory(
        id: message.id,
        title: message.title,
        body: message.body,
        timestamp: message.timestamp,
        taskType: message.data?['taskType'] as String?,
      );

      // Use get_it directly instead of context to avoid provider issues
      try {
        sl<NotificationBloc>().add(NotificationReceived(history));
      } catch (e) {
        // If bloc isn't ready yet, just skip
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AIMSG'),
        actions: [
          BlocBuilder<MqttBloc, MqttState>(
            builder: (context, state) {
              final isConnected = state is MqttConnected;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ConnectionStatusIndicator(isConnected: isConnected),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              if (_deviceId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(deviceId: _deviceId!),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<DeviceBloc, DeviceState>(
        listener: (context, state) async {
          if (state is DeviceLoaded) {
            _deviceId = state.deviceInfo.deviceId;
            final mqttConfig = await sl<SettingsRepository>().getMqttConfig();
            if (context.mounted) {
              context.read<MqttBloc>().add(
                    MqttConnectRequested(
                      broker: mqttConfig.broker,
                      port: mqttConfig.port,
                      deviceId: state.deviceInfo.deviceId,
                    ),
                  );
            }
          }
        },
        builder: (context, deviceState) {
          if (deviceState is DeviceLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (deviceState is DeviceError) {
            return Center(
              child: Text('Error: ${deviceState.message}'),
            );
          }

          return BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, notifState) {
              if (notifState is NotificationLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final notifications =
                  notifState is NotificationLoaded ? notifState.notifications : <NotificationHistory>[];

              if (notifications.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Set up the Claude Code hook to receive notifications',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) => NotificationCard(
                  notification: notifications[index],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
