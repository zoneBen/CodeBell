# AIMSG Notifier (Go)

Go实现的推送程序，用于替换原有的Python程序。与Flutter应用保持一致的MQTT配置。

## 功能

- **Hook模式**: 通过环境变量接收Claude Code hooks事件并推送通知
- **Daemon模式**: 监控日志文件并推送通知
- 与Flutter应用完全兼容的MQTT协议

## 编译

```bash
cd golang
go mod tidy
go build -o aimsg-notifier.exe ./cmd/notifier
```

## 使用方式

### 1. 生成Device ID

首先在Flutter应用中获取或生成一个16位的Device ID。

### 2. 配置Claude Code hooks

编辑 `C:\Users\mrcong\.claude\settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "CLAUDE_DEVICE_ID=你的设备ID CLAUDE_HOOK_EVENT=task_start C:\\path\\to\\aimsg-notifier.exe"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "CLAUDE_DEVICE_ID=你的设备ID CLAUDE_HOOK_EVENT=confirm_required C:\\path\\to\\aimsg-notifier.exe"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "CLAUDE_DEVICE_ID=你的设备ID CLAUDE_HOOK_EVENT=step_done C:\\path\\to\\aimsg-notifier.exe"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "CLAUDE_DEVICE_ID=你的设备ID CLAUDE_HOOK_EVENT=needs_attention C:\\path\\to\\aimsg-notifier.exe"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "CLAUDE_DEVICE_ID=你的设备ID CLAUDE_HOOK_EVENT=task_finished C:\\path\\to\\aimsg-notifier.exe"
          }
        ]
      }
    ]
  }
}
```

### 3. 环境变量

- `CLAUDE_DEVICE_ID`: 设备ID（必需，16位字母数字）
- `CLAUDE_HOOK_EVENT`: Hook事件类型
- `CLAUDE_HOOK_MESSAGE`: 自定义消息（可选）
- `MQTT_USERNAME`: MQTT用户名（可选）
- `MQTT_PASSWORD`: MQTT密码（可选）

### 4. 命令行参数

```bash
# Hook模式（通过环境变量）
set CLAUDE_DEVICE_ID=abc123def4567890
set CLAUDE_HOOK_EVENT=task_finished
aimsg-notifier.exe

# 或通过命令行参数
aimsg-notifier.exe -device abc123def4567890 -mode hook -hook-event task_finished

# Daemon模式（监控日志文件）
aimsg-notifier.exe -device abc123def4567890 -mode daemon -log C:\path\to\claudecode-log.txt

# 自定义MQTT broker
aimsg-notifier.exe -device abc123def4567890 -broker mqtt.example.com -port 1883
```

## Hook事件类型

| 事件 | 标题 | 类型 |
|-----|------|-----|
| `task_start` | Task Started | task_start |
| `step_done` | Step Completed | task_complete |
| `task_finished` | Task Finished | task_complete |
| `confirm_required` | Confirmation Needed | alert |
| `needs_attention` | Needs Attention | alert |
| `error` | Error Occurred | error |

## MQTT Topics

与Flutter应用保持一致：

- 通知: `apps/codebell/{deviceId}/notification`
- 状态: `apps/codebell/{deviceId}/status`
- Ping: `apps/codebell/{deviceId}/ping`

## 消息格式

```json
{
  "id": "uuid",
  "type": "task_complete",
  "timestamp": "2024-01-01T00:00:00Z",
  "title": "Task Complete",
  "body": "task details",
  "data": {
    "event": "task_finished",
    "cwd": "/path/to/workdir"
  }
}
```

