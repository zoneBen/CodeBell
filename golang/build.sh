#!/bin/bash
echo "Building AIMSG Notifier..."
cd "$(dirname "$0")"
go mod tidy
go build -ldflags "-s -w" -o aimsg-notifier ./cmd/notifier
if [ $? -eq 0 ]; then
    echo "Build successful: aimsg-notifier"
else
    echo "Build failed"
    exit 1
fi
