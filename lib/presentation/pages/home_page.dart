import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/notification_helper.dart';
import '../../domain/entities/notification_history.dart';
import '../../domain/repositories/mqtt_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../bloc/device/device_bloc.dart';
import '../bloc/device/device_event.dart';
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

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late MqttRepository _mqttRepository;
  String? _deviceId;
  bool _hasAttemptedAutoConnect = false;

  @override
  void initState() {
    super.initState();
    _mqttRepository = sl();
    _listenToNotifications();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tryAutoReconnect();
    }
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

  Future<void> _connectWithDeviceId(String deviceId) async {
    final mqttConfig = await sl<SettingsRepository>().getMqttConfig();
    if (!mounted) return;
    context.read<MqttBloc>().add(
      MqttConnectRequested(
        broker: mqttConfig.broker,
        port: mqttConfig.port,
        deviceId: deviceId,
        username: mqttConfig.username,
        password: mqttConfig.password,
      ),
    );
  }

  Future<void> _tryAutoReconnect() async {
    if (_deviceId == null) return;
    final currentState = context.read<MqttBloc>().state;
    if (currentState is! MqttConnected && currentState is! MqttConnecting) {
      context.read<MqttBloc>().add(MqttAutoReconnectRequested());
    }
  }

  Future<void> _reconnect() async {
    if (_deviceId == null) return;
    final mqttBloc = context.read<MqttBloc>();
    final mqttConfig = await sl<SettingsRepository>().getMqttConfig();
    if (!mounted) return;
    mqttBloc.add(MqttDisconnectRequested());
    mqttBloc.add(
      MqttConnectRequested(
        broker: mqttConfig.broker,
        port: mqttConfig.port,
        deviceId: _deviceId!,
        username: mqttConfig.username,
        password: mqttConfig.password,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('码哨'),
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
      body: Column(
        children: [
          _buildConnectionStatusBar(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusBar() {
    return BlocBuilder<MqttBloc, MqttState>(
      builder: (context, state) {
        String statusText = '未连接';
        Color statusColor = Colors.red;
        bool showReconnect = false;

        if (state is MqttConnecting) {
          statusText = '连接中...';
          statusColor = Colors.orange;
        } else if (state is MqttConnected) {
          statusText = '已连接';
          statusColor = Colors.green;
        } else if (state is MqttError) {
          statusText = '连接错误';
          showReconnect = true;
        } else if (state is MqttDisconnected) {
          statusText = '已断开';
          showReconnect = true;
        }

        return Container(
          width: double.infinity,
          color: statusColor.withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.circle, size: 10, color: statusColor),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(color: statusColor, fontSize: 14),
              ),
              const Spacer(),
              if (showReconnect && _deviceId != null)
                TextButton(onPressed: _reconnect, child: const Text('重新连接')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return BlocConsumer<DeviceBloc, DeviceState>(
      listener: (context, state) {
        if (state is DeviceLoaded) {
          _deviceId = state.deviceInfo.deviceId;
          if (!_hasAttemptedAutoConnect) {
            _hasAttemptedAutoConnect = true;
            _connectWithDeviceId(state.deviceInfo.deviceId);
          }
        }
      },
      builder: (context, deviceState) {
        if (deviceState is DeviceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (deviceState is DeviceError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('加载设备错误: ${deviceState.message}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<DeviceBloc>().add(DeviceLoadRequested());
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        return BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, notifState) {
            if (notifState is NotificationLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = notifState is NotificationLoaded
                ? notifState.notifications
                : <NotificationHistory>[];

            if (notifications.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '暂无通知',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '设置 Claude Code hook 以接收通知',
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
              itemBuilder: (context, index) =>
                  NotificationCard(notification: notifications[index]),
            );
          },
        );
      },
    );
  }
}
