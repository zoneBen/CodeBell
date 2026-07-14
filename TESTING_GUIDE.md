# 🧪 AIMSG 测试指南

## 快速开始

### 1️⃣ 启动 Flutter 应用

在项目根目录下运行：

```bash
flutter run
```

或者直接运行已构建的版本：
```
build\windows\x64\runner\Debug\aimsg.exe
```

### 2️⃣ 获取设备 ID

应用启动后：
- 点击右上角设置图标 ⚙️
- 复制显示的设备 ID（应该是 `8b32c4ed61f24841`）

### 3️⃣ 发送测试通知

打开一个新的终端窗口，进入 `tools` 目录：

#### 方式一：使用 PowerShell 脚本（推荐）
```powershell
cd tools
.\send_test_notification.ps1 -DeviceId "8b32c4ed61f24841" -TaskType "my_test_task"
```

#### 方式二：使用 Dart 测试脚本
```bash
cd tools
dart run test_notification.dart
```

#### 方式三：使用 Claude Code Hook
```bash
cd tools
$env:AIMSG_DEVICE_ID="8b32c4ed61f24841"
dart run claude_hook.dart "my_test_task"
```

## 预期结果

如果一切正常工作：

✅ **在 Flutter 应用中**：
- 连接状态显示为绿色 "Connected"
- 通知列表中显示新收到的通知
- 显示通知标题 "✅ Claude Code Task Complete!"
- 显示通知内容

✅ **系统通知**（如果已配置）：
- Windows / Android / iOS 会弹出系统通知
- （注：可能需要额外的平台配置）

## 故障排查

### 问题：应用显示 "Disconnected"

- 检查网络连接
- 确认 `test.mosquitto.org` 可访问
- 尝试更换网络环境

### 问题：收不到通知

- 确认设备 ID 匹配
- 检查应用是否在前台运行
- 尝试重新启动应用
- 再次发送测试通知

### 问题：MQTT 连接超时

公共 broker 有时不稳定，可以尝试：
- 稍后重试
- 或自建 MQTT broker（如 Mosquitto, EMQX）

## 配置 Claude Code

要在 Claude Code 中实际使用：

1. 在 Claude Code 设置中配置 hook
2. 设置环境变量 `AIMSG_DEVICE_ID`
3. 完成任务后会自动发送通知

示例配置（添加到 Claude Code settings）：
```json
{
  "hooks": {
    "postToolUse": [
      {
        "command": "dart",
        "args": ["D:\\works\\flutter\\aimsg\\tools\\claude_hook.dart", "{{toolName}}"],
        "env": {
          "AIMSG_DEVICE_ID": "8b32c4ed61f24841"
        }
      }
    ]
  }
}
```
