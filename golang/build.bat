@echo off
echo Building AIMSG Notifier...
cd /d "%~dp0"
go mod tidy
if errorlevel 1 (
    echo Failed to download dependencies
    exit /b 1
)
go build -ldflags "-s -w" -o aimsg-notifier.exe ./cmd/notifier
if errorlevel 1 (
    echo Build failed
    exit /b 1
)
echo Build successful: aimsg-notifier.exe
echo.
echo To use, set CLAUDE_DEVICE_ID environment variable and configure in Claude Code settings.
