package models

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// NotificationMessage represents a notification message (matches Flutter app design)
type NotificationMessage struct {
	ID        string                 `json:"id"`
	Type      string                 `json:"type"`
	Timestamp time.Time              `json:"timestamp"`
	Title     string                 `json:"title"`
	Body      string                 `json:"body"`
	Data      map[string]interface{} `json:"data,omitempty"`
}

// NewNotificationMessage creates a new notification message
func NewNotificationMessage(notifyType, title, body string, data map[string]interface{}) *NotificationMessage {
	return &NotificationMessage{
		ID:        uuid.NewString(),
		Type:      notifyType,
		Timestamp: time.Now().UTC().Truncate(time.Millisecond),
		Title:     title,
		Body:      body,
		Data:      data,
	}
}

// ToJSON converts the message to JSON
func (m *NotificationMessage) ToJSON() ([]byte, error) {
	return json.Marshal(m)
}

// FromJSON parses JSON into a notification message
func FromJSON(data []byte) (*NotificationMessage, error) {
	var msg NotificationMessage
	err := json.Unmarshal(data, &msg)
	if err != nil {
		return nil, err
	}
	return &msg, nil
}

// TaskComplete creates a task complete notification
func TaskComplete(taskName, details string) *NotificationMessage {
	return NewNotificationMessage(
		"task_complete",
		"Task Complete",
		taskName,
		map[string]interface{}{"details": details},
	)
}

// TaskStuck creates a task stuck notification
func TaskStuck(taskName, reason string) *NotificationMessage {
	return NewNotificationMessage(
		"task_stuck",
		"Task Stuck",
		taskName,
		map[string]interface{}{"reason": reason},
	)
}

// HookEvent creates a hook event notification
func HookEvent(eventName, description string) *NotificationMessage {
	return NewNotificationMessage(
		"hook_event",
		"Hook Event",
		eventName,
		map[string]interface{}{"description": description},
	)
}
