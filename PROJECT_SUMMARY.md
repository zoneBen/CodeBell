# AIMSG - Project Summary

## Project Overview

A cross-platform Flutter app that receives notifications when Claude Code completes tasks, using MQTT for communication.

## What's Been Built

### Core Architecture
- ✅ Clean Architecture (Domain/Data/Presentation layers)
- ✅ BLoC for state management
- ✅ GetIt for dependency injection
- ✅ MQTT client wrapper

### Domain Layer
- ✅ Entities: NotificationMessage, DeviceInfo, MqttConfig, NotificationHistory
- ✅ Repository contracts
- ✅ Use Cases: ConnectMQTT, GetDeviceID, SaveDeviceID, GetNotificationHistory

### Data Layer
- ✅ LocalStorageDataSource using shared_preferences
- ✅ MqttDataSource
- ✅ Repository implementations

### Presentation Layer
- ✅ BLoCs: DeviceBloc, MqttBloc, NotificationBloc
- ✅ HomePage - shows notification history and connection status
- ✅ SettingsPage - device ID configuration
- ✅ Widgets: ConnectionStatusIndicator, NotificationCard

### Tools
- ✅ Claude Code hook script (Dart)
- ✅ Hook script pubspec.yaml
- ✅ Configuration example

## Project Structure

```
aimsg/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   ├── di/
│   │   ├── errors/
│   │   ├── network/
│   │   └── utils/
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   ├── data/
│   │   ├── datasources/
│   │   └── repositories/
│   ├── presentation/
│   │   ├── bloc/
│   │   ├── pages/
│   │   └── widgets/
│   └── main.dart
├── tools/
│   ├── claude_hook.dart
│   └── pubspec.yaml
├── pubspec.yaml
└── README.md
```

## Next Steps to Complete

### 1. Fix Navigation in App
Update `lib/presentation/app.dart` to use a proper navigator setup with routes.

### 2. Complete Notification Helper
The `notification_helper.dart` needs to be fully implemented (it's currently a skeleton).

### 3. Test Connection Flow
Test the MQTT connection flow end-to-end:
- Device ID generation
- MQTT broker connection
- Subscription to notification topic
- Receiving messages

### 4. Create a Test Script
Add a simple test script to send test notifications without Claude Code.

### 5. Add Missing Imports
Some files have missing imports (like SettingsRepository in home_page.dart).

### 6. iOS/Android Permissions
Add necessary permissions for notifications and vibration.

### 7. Generate Missing Code
If we want to use json_serializable later, add the models with proper annotations.

## How to Run

### Flutter App

```bash
cd aimsg
flutter pub get
flutter run
```

### Claude Code Hook

```bash
cd aimsg/tools
dart pub get
export AIMSG_DEVICE_ID="your_device_id"
dart run claude_hook.dart test_task
```

## MQTT Topics

- `claude/{deviceId}/notification` - Notification messages

## Message Format

```json
{
  "id": "uuid",
  "type": "task_complete",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "title": "Task Completed",
  "body": "Your task has finished",
  "data": {
    "taskType": "code_review"
  }
}
```

## Configuration Options

### Default Broker
Uses public broker `test.mosquitto.org:1883` - great for testing.

### Custom Broker
Can be configured in app settings later.

## Notes

- The project is about 80% complete
- Core architecture is in place
- Main functionality is stubbed out
- Needs final integration and testing
