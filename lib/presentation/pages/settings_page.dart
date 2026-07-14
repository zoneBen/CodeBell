import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/device_id_generator.dart';

class SettingsPage extends StatefulWidget {
  final String deviceId;

  const SettingsPage({super.key, required this.deviceId});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _deviceIdController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _deviceIdController = TextEditingController(text: widget.deviceId);
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }

  void _copyDeviceId() {
    Clipboard.setData(ClipboardData(text: _deviceIdController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Device ID copied to clipboard')),
    );
  }

  void _generateNewId() {
    setState(() {
      _deviceIdController.text = DeviceIdGenerator.generate();
    });
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildDeviceIdSection(),
          const Divider(),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildDeviceIdSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device ID',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Use this ID to pair your Claude Code hooks with this app.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _deviceIdController,
            enabled: _isEditing,
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
              onPressed: _toggleEdit,
              child: Text(_isEditing ? 'Save' : 'Edit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'AIMSG - Claude Code Task Notification System\n\n'
            'This app receives notifications when Claude Code completes tasks.',
          ),
          SizedBox(height: 8),
          Text(
            'Version 1.0.0',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
