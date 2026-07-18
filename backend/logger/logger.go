package logger

import (
	"os"
	"time"

	"github.com/rs/zerolog"
)

var log *zerolog.Logger

// Init initializes the global zerolog logger.
// Reads LOG_LEVEL from env (default: "info").
func Init() {
	levelStr := os.Getenv("LOG_LEVEL")
	if levelStr == "" {
		levelStr = "info"
	}

	level, err := zerolog.ParseLevel(levelStr)
	if err != nil {
		level = zerolog.InfoLevel
	}

	output := zerolog.ConsoleWriter{
		Out:        os.Stdout,
		TimeFormat: time.RFC3339,
	}

	logger := zerolog.New(output).
		Level(level).
		With().
		Timestamp().
		Logger()

	log = &logger

	zerolog.SetGlobalLevel(level)
}

// InitWithWriter initializes the logger with a custom writer (useful for testing).
func InitWithWriter(level string, w zerolog.LevelWriter) {
	lvl, err := zerolog.ParseLevel(level)
	if err != nil {
		lvl = zerolog.InfoLevel
	}

	logger := zerolog.New(w).
		Level(lvl).
		With().
		Timestamp().
		Logger()

	log = &logger
	zerolog.SetGlobalLevel(lvl)
}

// Log returns the global logger instance.
func Log() *zerolog.Logger {
	if log == nil {
		Init()
	}
	return log
}
