package main

import (
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	"aimsg-notifier/internal/config"
	"aimsg-notifier/internal/logparser"
	"aimsg-notifier/internal/models"
	"aimsg-notifier/internal/mqtt"
)

func main() {
	logger := log.New(os.Stderr, "[notifier] ", log.LstdFlags)

	// Log all environment variables for debugging
	logger.Println("=== Starting notifier ===")
	logger.Printf("CLAUDE_DEVICE_ID: %s", os.Getenv("CLAUDE_DEVICE_ID"))
	logger.Printf("CLAUDE_HOOK_EVENT: %s", os.Getenv("CLAUDE_HOOK_EVENT"))
	logger.Printf("CLAUDE_HOOK_MESSAGE: %s", os.Getenv("CLAUDE_HOOK_MESSAGE"))
	logger.Printf("MQTT_USERNAME: %s", os.Getenv("MQTT_USERNAME"))
	logger.Printf("Current working dir: %s", getCWD())

	// Load config
	cfg, err := config.Load()
	if err != nil {
		logger.Fatalf("Configuration error: %v", err)
	}

	logger.Printf("Mode: %s", cfg.Mode)
	logger.Printf("Device ID: %s", cfg.DeviceID)
	logger.Printf("MQTT Broker: %s:%d", cfg.MQTT.Broker, cfg.MQTT.Port)

	// Create MQTT client
	mqttClient := mqtt.NewClient(cfg.MQTT, logger)
	if err := mqttClient.Connect(); err != nil {
		logger.Fatalf("Failed to connect to MQTT: %v", err)
	}
	defer mqttClient.Disconnect()

	// Run in appropriate mode
	switch cfg.Mode {
	case "hook":
		err = runHookMode(cfg, mqttClient, logger)
	case "daemon":
		err = runDaemonMode(cfg, mqttClient, logger)
	default:
		err = fmt.Errorf("unknown mode: %s", cfg.Mode)
	}

	if err != nil {
		logger.Fatalf("Error: %v", err)
	}

	logger.Println("=== Notifier completed ===")
}

func runHookMode(cfg *config.Config, mqttClient *mqtt.Client, logger *log.Logger) error {
	eventType := cfg.HookEvent
	title := config.GetEventTitle(eventType)
	message := cfg.HookMessage
	if message == "" {
		message = fmt.Sprintf("Event: %s", eventType)
	}

	notifyType := config.GetEventType(eventType)
	notification := models.NewNotificationMessage(
		notifyType,
		title,
		message,
		map[string]interface{}{
			"event": eventType,
			"cwd":   getCWD(),
		},
	)

	logger.Printf("Sending hook notification: %s", title)
	return mqttClient.PublishNotification(notification)
}

func runDaemonMode(cfg *config.Config, mqttClient *mqtt.Client, logger *log.Logger) error {
	if cfg.LogFile == "" {
		return fmt.Errorf("log file path is required for daemon mode (use -log flag)")
	}

	// Create event channel
	eventChan := make(chan *models.NotificationMessage, 100)

	// Create and start log parser
	parser := logparser.NewParser(cfg.LogFile, eventChan, logger)
	if err := parser.Start(); err != nil {
		return fmt.Errorf("failed to start log parser: %w", err)
	}
	defer parser.Stop()

	// Forward events to MQTT
	go func() {
		for msg := range eventChan {
			if err := mqttClient.PublishNotification(msg); err != nil {
				logger.Printf("Failed to publish notification: %v", err)
			}
		}
	}()

	logger.Printf("Daemon mode running, monitoring: %s", cfg.LogFile)
	logger.Printf("Listening for events... (Ctrl+C to stop)")

	// Wait for shutdown signal
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	logger.Println("Shutting down...")
	close(eventChan)

	return nil
}

func getCWD() string {
	cwd, _ := os.Getwd()
	return cwd
}
