package models

// MqttConfig holds MQTT configuration (matches Flutter app design)
type MqttConfig struct {
	Broker          string
	Port            int
	Username        string
	Password        string
	UsePublicBroker bool
	DeviceID        string
}

// DefaultMqttConfig returns default MQTT config
func DefaultMqttConfig() *MqttConfig {
	return &MqttConfig{
		Broker:          "test.mosquitto.org",
		Port:            1883,
		UsePublicBroker: true,
	}
}

// MqttTopics contains topic names (matches Flutter app design)
func NotificationTopic(deviceID string) string {
	return "apps/codebell/" + deviceID + "/notification"
}

func StatusTopic(deviceID string) string {
	return "apps/codebell/" + deviceID + "/status"
}

func PingTopic(deviceID string) string {
	return "apps/codebell/" + deviceID + "/ping"
}

const ClientIDPrefix = "aimsg_"
