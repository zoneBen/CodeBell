# AIMSG - Claude Code Task Notification System

A cross-platform Flutter app that receives notifications when Claude Code completes tasks, using MQTT for communication.

## Features

- MQTT-based real-time notifications
- Cross-platform support (iOS, Android, Windows, macOS, Linux)
- Device pairing via unique ID
- Local notifications with sound and vibration
- Notification history
- Custom MQTT broker configuration

## Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Run the App

```bash
# For mobile
flutter run

# For desktop
flutter run -d windows
flutter run -d macos
flutter run -d linux
```

### 3. Get Your Device ID

Open the app, go to Settings, and copy your Device ID.

### 4. Set Up Claude Code Hook

```bash
cd tools
dart pub get
```

Set up environment variables:

```bash
export AIMSG_DEVICE_ID="your_device_id_from_app"
export AIMSG_BROKER="test.mosquitto.org"  # optional
export AIMSG_PORT="1883"  # optional
```

Test the hook:

```bash
dart run claude_hook.dart test_task
```

### 5. Configure Claude Code Hooks

Add this to your Claude Code settings:

```json
{
  "hooks": {
    "postToolUse": [
      {
        "description": "Send notification on task complete",
        "command": "dart",
        "args": [
          "path/to/aimsg/tools/claude_hook.dart",
          "{{toolName}}"
        ],
        "env": {
          "AIMSG_DEVICE_ID": "your_device_id_from_app"
        }
      }
    ]
  }
}
```

## Architecture

### Project Structure

```
lib/
├── core/              # Core utilities and constants
├── domain/            # Entities, repositories, use cases
├── data/              # Data sources and implementations
└── presentation/      # UI and state management
```

### MQTT Topics

- `claude/{deviceId}/notification` - Notification messages
- `claude/{deviceId}/status` - Device status updates

### Message Format

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

## MQTT Broker

### Default (Quick Start)

Uses public broker `test.mosquitto.org:1883` - great for testing, not recommended for production.

### Self-Hosted (Recommended)

- Mosquitto
- EMQX
- VerneMQ

Set custom broker in app Settings or via environment variables.

## Troubleshooting

### Notifications not showing up

1. Check if app is connected to MQTT broker (green indicator in app)
2. Verify Device ID matches between hook and app
3. Check if notifications are enabled in system settings
4. Try sending a test notification via the hook script

### MQTT connection issues

1. Verify broker is reachable
2. Check if port is open
3. Try a different network (some block public MQTT)

## Development

### Generate Code

```bash
dart pub run build_runner watch
```

### Run Tests

```bash
flutter test
```

## License

MIT
