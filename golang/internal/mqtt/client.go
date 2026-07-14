package mqtt

import (
	"fmt"
	"log"
	"time"

	"aimsg-notifier/internal/models"
	mqtt "github.com/eclipse/paho.mqtt.golang"
)

// Client handles MQTT communication
type Client struct {
	client mqtt.Client
	config *models.MqttConfig
	logger *log.Logger
}

// NewClient creates a new MQTT client
func NewClient(config *models.MqttConfig, logger *log.Logger) *Client {
	return &Client{
		config: config,
		logger: logger,
	}
}

// Connect connects to the MQTT broker
func (c *Client) Connect() error {
	opts := mqtt.NewClientOptions()
	brokerURL := fmt.Sprintf("tcp://%s:%d", c.config.Broker, c.config.Port)
	opts.AddBroker(brokerURL)
	opts.SetClientID(models.ClientIDPrefix + c.config.DeviceID + "_notifier")
	opts.SetKeepAlive(30 * time.Second)
	opts.SetAutoReconnect(true)
	opts.SetCleanSession(true)

	if c.config.Username != "" && c.config.Password != "" {
		opts.SetUsername(c.config.Username)
		opts.SetPassword(c.config.Password)
	}

	opts.SetWill(
		models.StatusTopic(c.config.DeviceID),
		"offline",
		1,
		false,
	)

	opts.SetOnConnectHandler(c.onConnect)
	opts.SetConnectionLostHandler(c.onConnectionLost)
	opts.SetReconnectingHandler(c.onReconnecting)

	c.client = mqtt.NewClient(opts)

	c.logger.Printf("Connecting to MQTT broker at %s...", brokerURL)
	if token := c.client.Connect(); token.Wait() && token.Error() != nil {
		return fmt.Errorf("failed to connect: %w", token.Error())
	}

	c.logger.Println("Connected to MQTT broker successfully")
	return nil
}

func (c *Client) onConnect(client mqtt.Client) {
	c.logger.Println("MQTT connection established")
	// Publish online status
	c.publishStatus("online")
}

func (c *Client) onConnectionLost(client mqtt.Client, err error) {
	c.logger.Printf("MQTT connection lost: %v", err)
}

func (c *Client) onReconnecting(client mqtt.Client, opts *mqtt.ClientOptions) {
	c.logger.Println("MQTT reconnecting...")
}

func (c *Client) publishStatus(status string) {
	topic := models.StatusTopic(c.config.DeviceID)
	token := c.client.Publish(topic, 1, false, status)
	token.Wait()
}

// PublishNotification sends a notification via MQTT
func (c *Client) PublishNotification(msg *models.NotificationMessage) error {
	if c.client == nil || !c.client.IsConnected() {
		return fmt.Errorf("not connected to MQTT broker")
	}

	payload, err := msg.ToJSON()
	if err != nil {
		return fmt.Errorf("failed to marshal message: %w", err)
	}

	topic := models.NotificationTopic(c.config.DeviceID)
	c.logger.Printf("Publishing notification to %s: %s", topic, msg.Title)
	c.logger.Printf("Payload: %s", string(payload))

	token := c.client.Publish(topic, 1, false, payload)
	if token.Wait() && token.Error() != nil {
		return fmt.Errorf("failed to publish: %w", token.Error())
	}

	return nil
}

// Disconnect disconnects from the MQTT broker
func (c *Client) Disconnect() {
	if c.client != nil && c.client.IsConnected() {
		c.publishStatus("offline")
		c.client.Disconnect(250)
		c.logger.Println("Disconnected from MQTT broker")
	}
}

// IsConnected checks if connected to broker
func (c *Client) IsConnected() bool {
	return c.client != nil && c.client.IsConnected()
}
