package logger

import (
	"testing"

	"github.com/rs/zerolog"
)

type testWriter struct {
	entries []string
	level   zerolog.Level
}

func (w *testWriter) Write(p []byte) (n int, err error) {
	w.entries = append(w.entries, string(p))
	return len(p), nil
}

func (w *testWriter) WriteLevel(level zerolog.Level, p []byte) (n int, err error) {
	if level >= w.level {
		w.entries = append(w.entries, string(p))
	}
	return len(p), nil
}

func TestInit_DefaultLevel(t *testing.T) {
	t.Setenv("LOG_LEVEL", "")
	Init()

	l := Log()
	if l == nil {
		t.Fatal("Logger should not be nil after Init()")
	}

	l.Info().Msg("test message")
}

func TestInit_DebugLevel(t *testing.T) {
	w := &testWriter{level: zerolog.DebugLevel}
	InitWithWriter("debug", w)

	l := Log()
	l.Debug().Str("key", "value").Msg("debug test")

	if len(w.entries) == 0 {
		t.Fatal("Expected debug output, got nothing")
	}
}

func TestInit_WarnLevelSuppressesInfo(t *testing.T) {
	w := &testWriter{level: zerolog.WarnLevel}
	InitWithWriter("warn", w)

	l := Log()
	l.Info().Msg("should not appear")

	if len(w.entries) != 0 {
		t.Fatalf("Expected no output at warn level for info message, got: %s", w.entries)
	}
}

func TestLog_ReturnsSingleton(t *testing.T) {
	Init()
	l1 := Log()
	l2 := Log()

	if l1 != l2 {
		t.Fatal("Log() should return the same logger instance")
	}
}

func TestInitWithWriter_InvalidLevel(t *testing.T) {
	w := &testWriter{level: zerolog.InfoLevel}
	InitWithWriter("totally-invalid", w)

	l := Log()
	l.Info().Msg("fallback test")

	if len(w.entries) == 0 {
		t.Fatal("Expected output with default info level fallback")
	}
}
