package logparser

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"

	"aimsg-notifier/internal/models"
	"github.com/fsnotify/fsnotify"
)

// LogEvent represents a parsed log event
type LogEvent struct {
	Event string                 `json:"event"`
	Data  map[string]interface{} `json:"data"`
	Meta  struct {
		Timestamp string `json:"timestamp"`
		Hostname  string `json:"hostname"`
		User      string `json:"user"`
		Cwd       string `json:"cwd"`
	} `json:"_meta"`
}

// Parser monitors and parses the log file
type Parser struct {
	filePath     string
	lastOffset   int64
	watcher      *fsnotify.Watcher
	eventChan    chan<- *models.NotificationMessage
	logger       *log.Logger
	lastActivity time.Time
	stuckTimer   *time.Timer
	stuckTimeout time.Duration
}

// NewParser creates a new log parser
func NewParser(filePath string, eventChan chan<- *models.NotificationMessage, logger *log.Logger) *Parser {
	return &Parser{
		filePath:     filePath,
		eventChan:    eventChan,
		logger:       logger,
		stuckTimeout: 5 * time.Minute,
	}
}

// Start starts monitoring the log file
func (p *Parser) Start() error {
	var err error
	p.watcher, err = fsnotify.NewWatcher()
	if err != nil {
		return fmt.Errorf("failed to create watcher: %w", err)
	}

	// Seek to end of file first
	file, err := os.Open(p.filePath)
	if err != nil {
		if os.IsNotExist(err) {
			p.logger.Printf("Log file does not exist yet: %s", p.filePath)
			p.lastOffset = 0
		} else {
			return fmt.Errorf("failed to open log file: %w", err)
		}
	} else {
		stat, err := file.Stat()
		if err == nil {
			p.lastOffset = stat.Size()
		}
		file.Close()
	}

	go p.watchLoop()

	// Add the file or its directory to watcher
	if err := p.addWatch(); err != nil {
		return err
	}

	// Start stuck detector
	p.resetStuckTimer()

	return nil
}

func (p *Parser) addWatch() error {
	// Check if file exists
	if _, err := os.Stat(p.filePath); err == nil {
		// File exists, watch it
		return p.watcher.Add(p.filePath)
	}

	// File doesn't exist, watch directory instead
	dir := p.filePath
	if idx := strings.LastIndex(p.filePath, string(os.PathSeparator)); idx >= 0 {
		dir = p.filePath[:idx]
	} else {
		dir = "."
	}

	p.logger.Printf("Watching directory for file creation: %s", dir)
	return p.watcher.Add(dir)
}

func (p *Parser) watchLoop() {
	for {
		select {
		case event, ok := <-p.watcher.Events:
			if !ok {
				return
			}
			p.handleEvent(event)
		case err, ok := <-p.watcher.Errors:
			if !ok {
				return
			}
			p.logger.Printf("Watcher error: %v", err)
		}
	}
}

func (p *Parser) handleEvent(event fsnotify.Event) {
	// Check if this is our file
	if !strings.HasSuffix(event.Name, p.filePath) && event.Name != p.filePath {
		// If file was just created, add it to watcher
		if event.Op&fsnotify.Create == fsnotify.Create && strings.HasSuffix(event.Name, filepathBase(p.filePath)) {
			p.logger.Printf("Log file created: %s", event.Name)
			p.watcher.Remove(filepathDir(p.filePath))
			p.watcher.Add(event.Name)
			p.lastOffset = 0
		}
		return
	}

	if event.Op&fsnotify.Write == fsnotify.Write {
		p.parseNewContent()
		p.resetStuckTimer()
	}
}

func (p *Parser) parseNewContent() {
	file, err := os.Open(p.filePath)
	if err != nil {
		p.logger.Printf("Failed to open log file: %v", err)
		return
	}
	defer file.Close()

	// Seek to last known position
	_, err = file.Seek(p.lastOffset, io.SeekStart)
	if err != nil {
		p.logger.Printf("Failed to seek in log file: %v", err)
		// Reset offset and try again
		p.lastOffset = 0
		return
	}

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		p.parseLine(line)
	}

	if err := scanner.Err(); err != nil {
		p.logger.Printf("Error scanning log file: %v", err)
	}

	// Update offset
	p.lastOffset, _ = file.Seek(0, io.SeekCurrent)
}

func (p *Parser) parseLine(line string) {
	// Skip empty lines
	line = strings.TrimSpace(line)
	if line == "" {
		return
	}

	// Check if line contains JSON event
	if strings.HasPrefix(line, "{") {
		p.parseJSONEvent(line)
		return
	}

	// Check for other patterns
	p.checkKeywords(line)
}

func (p *Parser) parseJSONEvent(line string) {
	var event LogEvent
	if err := json.Unmarshal([]byte(line), &event); err != nil {
		return
	}

	// Process different event types
	switch event.Event {
	case "step_done":
		p.sendNotification(models.TaskComplete(
			"Step completed",
			fmt.Sprintf("Step done in %s", event.Meta.Cwd),
		))
	case "task_complete":
		p.sendNotification(models.TaskComplete(
			"Task completed",
			fmt.Sprintf("Task finished in %s", event.Meta.Cwd),
		))
	case "task_start":
		p.sendNotification(models.NewNotificationMessage(
			"task_start",
			"Task Started",
			fmt.Sprintf("New task started in %s", event.Meta.Cwd),
			map[string]interface{}{"cwd": event.Meta.Cwd},
		))
	case "error":
		p.sendNotification(models.NewNotificationMessage(
			"error",
			"Error Occurred",
			fmt.Sprintf("An error was detected"),
			map[string]interface{}{"raw": event.Data},
		))
	}
}

func (p *Parser) checkKeywords(line string) {
	lowerLine := strings.ToLower(line)

	keywords := map[string]func(string){
		"done": func(line string) {
			p.sendNotification(models.TaskComplete("Task Done", extractLastPart(line)))
		},
		"complete": func(line string) {
			p.sendNotification(models.TaskComplete("Task Complete", extractLastPart(line)))
		},
		"finish": func(line string) {
			p.sendNotification(models.TaskComplete("Task Finished", extractLastPart(line)))
		},
		"error": func(line string) {
			p.sendNotification(models.NewNotificationMessage(
				"error",
				"Error Detected",
				extractLastPart(line),
				map[string]interface{}{"line": line},
			))
		},
		"fail": func(line string) {
			p.sendNotification(models.NewNotificationMessage(
				"failure",
				"Task Failed",
				extractLastPart(line),
				map[string]interface{}{"line": line},
			))
		},
		"hook": func(line string) {
			p.sendNotification(models.HookEvent("Hook Activity", extractLastPart(line)))
		},
	}

	for keyword, handler := range keywords {
		if strings.Contains(lowerLine, keyword) {
			handler(line)
			return
		}
	}
}

func (p *Parser) sendNotification(msg *models.NotificationMessage) {
	select {
	case p.eventChan <- msg:
	default:
		p.logger.Println("Event channel full, dropping notification")
	}
}

func (p *Parser) resetStuckTimer() {
	p.lastActivity = time.Now()
	if p.stuckTimer != nil {
		p.stuckTimer.Stop()
	}
	p.stuckTimer = time.AfterFunc(p.stuckTimeout, p.checkStuck)
}

func (p *Parser) checkStuck() {
	if time.Since(p.lastActivity) >= p.stuckTimeout {
		p.sendNotification(models.TaskStuck(
			"No activity detected",
			fmt.Sprintf("No log activity for %v", p.stuckTimeout),
		))
	}
}

// Stop stops the log parser
func (p *Parser) Stop() {
	if p.stuckTimer != nil {
		p.stuckTimer.Stop()
	}
	if p.watcher != nil {
		p.watcher.Close()
	}
}

func filepathBase(path string) string {
	return filepath.Base(path)
}

func filepathDir(path string) string {
	return filepath.Dir(path)
}

func extractLastPart(line string) string {
	if len(line) > 100 {
		return line[len(line)-100:]
	}
	return line
}
