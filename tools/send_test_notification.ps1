# AIMSG Test Notification Script
# Usage: .\send_test_notification.ps1 -DeviceId "8b32c4ed61f24841" -TaskType "test_task"

param(
    [Parameter(Mandatory=$true)]
    [string]$DeviceId,

    [string]$TaskType = "test_task",

    [string]$Broker = "test.mosquitto.org",

    [int]$Port = 1883
)

$ErrorActionPreference = "Stop"

Write-Host "📡 Sending test notification..." -ForegroundColor Cyan
Write-Host "   Device ID: $DeviceId" -ForegroundColor Gray
Write-Host "   Task Type: $TaskType" -ForegroundColor Gray
Write-Host "   Broker: $Broker`:$Port" -ForegroundColor Gray
Write-Host ""

# Set environment variable and run the Dart script
$env:AIMSG_DEVICE_ID = $DeviceId
$env:AIMSG_BROKER = $Broker
$env:AIMSG_PORT = $Port

dart run (Join-Path $PSScriptRoot "test_notification.dart")
