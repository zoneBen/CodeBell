import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/device_id_generator.dart';
import '../../domain/entities/device_info.dart';
import '../../domain/entities/mqtt_config.dart';
import '../../domain/repositories/settings_repository.dart';
import '../bloc/mqtt/mqtt_bloc.dart';
import '../bloc/mqtt/mqtt_event.dart';
import '../bloc/device/device_bloc.dart';
import '../bloc/device/device_state.dart';

class SettingsPage extends StatefulWidget {
  final String deviceId;

  const SettingsPage({super.key, required this.deviceId});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _deviceIdController;
  late final TextEditingController _brokerController;
  late final TextEditingController _portController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  bool _isEditingDeviceId = false;
  bool _usePublicBroker = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _deviceIdController = TextEditingController(text: widget.deviceId);
    _brokerController = TextEditingController();
    _portController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _brokerController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final config = await sl<SettingsRepository>().getMqttConfig();
    if (mounted) {
      setState(() {
        _usePublicBroker = config.usePublicBroker;
        _brokerController.text = config.broker;
        _portController.text = config.port.toString();
        _usernameController.text = config.username ?? '';
        _passwordController.text = config.password ?? '';
        _isLoading = false;
      });
    }
  }

  void _copyDeviceId() {
    Clipboard.setData(ClipboardData(text: _deviceIdController.text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('设备ID已复制到剪贴板')));
  }

  void _generateNewId() {
    setState(() {
      _deviceIdController.text = DeviceIdGenerator.generate();
    });
  }

  void _toggleEditDeviceId() {
    setState(() {
      _isEditingDeviceId = !_isEditingDeviceId;
    });
    if (!_isEditingDeviceId) {
      _saveDeviceId();
    }
  }

  Future<void> _saveDeviceId() async {
    final repo = sl<SettingsRepository>();
    await repo.saveDeviceInfo(DeviceInfo(deviceId: _deviceIdController.text));
  }

  Future<void> _saveSettings() async {
    final repo = sl<SettingsRepository>();

    int? port;
    try {
      port = int.parse(_portController.text);
    } catch (e) {
      port = null;
    }

    final config = MqttConfig(
      broker: _brokerController.text,
      port: port ?? 1883,
      username: _usernameController.text.isEmpty
          ? null
          : _usernameController.text,
      password: _passwordController.text.isEmpty
          ? null
          : _passwordController.text,
      usePublicBroker: _usePublicBroker,
    );

    await repo.saveMqttConfig(config);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('设置已保存')));

      // Reconnect with new settings
      final deviceState = context.read<DeviceBloc>().state;
      if (deviceState is DeviceLoaded && mounted) {
        context.read<MqttBloc>().add(MqttDisconnectRequested());
        context.read<MqttBloc>().add(
          MqttConnectRequested(
            broker: config.broker,
            port: config.port,
            deviceId: deviceState.deviceInfo.deviceId,
            username: config.username,
            password: config.password,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDeviceIdSection(),
                const SizedBox(height: 16),
                _buildMqttSettingsSection(),
                const SizedBox(height: 16),
                _buildAboutSection(),
              ],
            ),
    );
  }

  Widget _buildDeviceIdSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '设备ID',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '使用此ID将您的 Claude Code hooks 与此应用配对。',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _deviceIdController,
              enabled: _isEditingDeviceId,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: _copyDeviceId,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _generateNewId,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _toggleEditDeviceId,
                child: Text(_isEditingDeviceId ? '保存' : '编辑'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMqttSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MQTT 设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('使用公共服务器'),
              value: _usePublicBroker,
              onChanged: (value) {
                setState(() {
                  _usePublicBroker = value;
                });
              },
            ),
            if (!_usePublicBroker) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _brokerController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '服务器',
                  hintText: '例如：mqtt.example.com',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '端口',
                  hintText: '例如：1883',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '用户名',
                  hintText: '用户名（可选）',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '密码',
                  hintText: '密码（可选）',
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('保存设置'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '关于',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '码哨 - Claude Code 任务通知系统\n\n当 Claude Code 完成任务时，此应用会接收通知。',
            ),
            const SizedBox(height: 8),
            const Text('版本 1.0.0', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
