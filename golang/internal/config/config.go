package config

import (
	"flag"
	"fmt"
	"os"
	"strings"

	"aimsg-notifier/internal/models"
)

// Config holds all configuration
type Config struct {
	DeviceID    string
	MQTT        *models.MqttConfig
	LogFile     string
	Mode        string // "daemon" or "hook"
	HookEvent   string // Event type when in hook mode
	HookMessage string // Optional message for hook mode
}

// Load loads configuration from flags and environment
func Load() (*Config, error) {
	cfg := &Config{
		MQTT: models.DefaultMqttConfig(),
	}

	// Flags
	flag.StringVar(&cfg.DeviceID, "device", "", "Device ID (required)")
	flag.StringVar(&cfg.MQTT.Broker, "broker", cfg.MQTT.Broker, "MQTT broker address")
	flag.IntVar(&cfg.MQTT.Port, "port", cfg.MQTT.Port, "MQTT broker port")
	flag.StringVar(&cfg.MQTT.Username, "user", "", "MQTT username (optional)")
	flag.StringVar(&cfg.MQTT.Password, "pass", "", "MQTT password (optional)")
	flag.StringVar(&cfg.LogFile, "log", "", "Log file to monitor (daemon mode)")
	flag.StringVar(&cfg.Mode, "mode", "daemon", "Mode: daemon or hook")
	flag.StringVar(&cfg.HookMessage, "msg", "", "Custom message for hook mode")

	flag.Parse()

	// Check environment variables
	if cfg.DeviceID == "" {
		cfg.DeviceID = os.Getenv("CLAUDE_DEVICE_ID")
	}
	if cfg.MQTT.Username == "" {
		cfg.MQTT.Username = os.Getenv("MQTT_USERNAME")
	}
	if cfg.MQTT.Password == "" {
		cfg.MQTT.Password = os.Getenv("MQTT_PASSWORD")
	}
	if cfg.HookEvent == "" {
		cfg.HookEvent = os.Getenv("CLAUDE_HOOK_EVENT")
	}
	if cfg.HookMessage == "" {
		cfg.HookMessage = os.Getenv("CLAUDE_HOOK_MESSAGE")
	}

	// Validate
	if cfg.DeviceID == "" {
		return nil, fmt.Errorf("device ID is required (use -device flag or CLAUDE_DEVICE_ID env)")
	}
	if !isValidDeviceID(cfg.DeviceID) {
		return nil, fmt.Errorf("device ID must be 16 alphanumeric characters")
	}

	cfg.MQTT.DeviceID = cfg.DeviceID

	// Set mode based on whether hook event is present
	if cfg.HookEvent != "" && cfg.Mode == "daemon" {
		cfg.Mode = "hook"
	}

	return cfg, nil
}

func isValidDeviceID(id string) bool {
	if len(id) != 16 {
		return false
	}
	for _, c := range id {
		if !((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')) {
			return false
		}
	}
	return true
}

// GetEventTitle maps hook events to friendly titles
func GetEventTitle(event string) string {
	titles := map[string]string{
		"task_start":       "Task Started",
		"step_done":        "Step Completed",
		"task_finished":    "Task Finished",
		"confirm_required": "Confirmation Needed",
		"needs_attention":  "Needs Attention",
		"error":            "Error Occurred",
	}
	if title, ok := titles[event]; ok {
		return title
	}
	return strings.Title(strings.ReplaceAll(event, "_", " "))
}

// GetEventType determines notification type from hook event
func GetEventType(event string) string {
	types := map[string]string{
		"task_start":       "task_start",
		"step_done":        "task_complete",
		"task_finished":    "task_complete",
		"confirm_required": "alert",
		"needs_attention":  "alert",
		"error":            "error",
	}
	if t, ok := types[event]; ok {
		return t
	}
	return "hook_event"
}
