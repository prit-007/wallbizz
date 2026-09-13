package config

import (
	"log"
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

type Config struct {
	Port               string
	SupabaseURL        string
	SupabaseServiceKey string
	WallhavenAPIKey    string
	CronSecret         string
	LogLevel           string
	SyncMaxPages       int
	RetentionDays      int
}

func LoadConfig() Config {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	syncMaxPages := 3
	if v := os.Getenv("SYNC_MAX_PAGES"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 {
			syncMaxPages = n
		}
	}

	retentionDays := 3
	if v := os.Getenv("WALLPAPER_RETENTION_DAYS"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 {
			retentionDays = n
		}
	}

	cfg := Config{
		Port:               getEnv("PORT", "3000"),
		SupabaseURL:        os.Getenv("SUPABASE_URL"),
		SupabaseServiceKey: os.Getenv("SUPABASE_SERVICE_KEY"),
		WallhavenAPIKey:    os.Getenv("WALLHAVEN_API_KEY"),
		CronSecret:         os.Getenv("CRON_SECRET"),
		LogLevel:           getEnv("LOG_LEVEL", "info"),
		SyncMaxPages:       syncMaxPages,
		RetentionDays:      retentionDays,
	}

	cfg.validate()
	return cfg
}

func (cfg Config) validate() {
	if cfg.SupabaseURL == "" {
		log.Fatal("SUPABASE_URL is required but not set")
	}
	if cfg.SupabaseServiceKey == "" {
		log.Fatal("SUPABASE_SERVICE_KEY is required but not set")
	}
	if cfg.WallhavenAPIKey == "" {
		log.Fatal("WALLHAVEN_API_KEY is required but not set")
	}
}

func getEnv(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}
