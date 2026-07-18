package config

import (
	"os"
	"testing"
)

func TestGetEnv_ReturnsValue(t *testing.T) {
	os.Setenv("TEST_GETENV_EXISTS", "hello")
	defer os.Unsetenv("TEST_GETENV_EXISTS")

	val := getEnv("TEST_GETENV_EXISTS", "fallback")
	if val != "hello" {
		t.Errorf("Expected 'hello', got '%s'", val)
	}
}

func TestGetEnv_ReturnsFallback(t *testing.T) {
	os.Unsetenv("TEST_GETENV_MISSING")

	val := getEnv("TEST_GETENV_MISSING", "fallback")
	if val != "fallback" {
		t.Errorf("Expected 'fallback', got '%s'", val)
	}
}

func TestGetEnv_EmptyStringReturnsFallback(t *testing.T) {
	os.Setenv("TEST_GETENV_EMPTY", "")
	defer os.Unsetenv("TEST_GETENV_EMPTY")

	val := getEnv("TEST_GETENV_EMPTY", "fallback")
	if val != "fallback" {
		t.Errorf("Expected 'fallback' for empty string, got '%s'", val)
	}
}

func TestGetEnv_PortDefault(t *testing.T) {
	os.Unsetenv("PORT")
	val := getEnv("PORT", "3000")
	if val != "3000" {
		t.Errorf("Expected default port '3000', got '%s'", val)
	}
}

func TestGetEnv_PortCustom(t *testing.T) {
	os.Setenv("PORT", "8080")
	defer os.Unsetenv("PORT")
	val := getEnv("PORT", "3000")
	if val != "8080" {
		t.Errorf("Expected custom port '8080', got '%s'", val)
	}
}

func TestConfig_Fields(t *testing.T) {
	cfg := Config{
		Port:               "3000",
		SupabaseURL:        "https://test.supabase.co",
		SupabaseServiceKey: "test-key",
		WallhavenAPIKey:    "test-wh-key",
	}

	if cfg.Port != "3000" {
		t.Errorf("Wrong Port: %s", cfg.Port)
	}
	if cfg.SupabaseURL != "https://test.supabase.co" {
		t.Errorf("Wrong SupabaseURL: %s", cfg.SupabaseURL)
	}
	if cfg.SupabaseServiceKey != "test-key" {
		t.Errorf("Wrong SupabaseServiceKey: %s", cfg.SupabaseServiceKey)
	}
	if cfg.WallhavenAPIKey != "test-wh-key" {
		t.Errorf("Wrong WallhavenAPIKey: %s", cfg.WallhavenAPIKey)
	}
}
