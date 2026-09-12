package config

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	Port               string
	SupabaseURL        string
	SupabaseServiceKey string
	WallhavenAPIKey    string
	CronSecret         string
	LogLevel           string
}

func LoadConfig() Config {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	cfg := Config{
		Port:               getEnv("PORT", "3000"),
		SupabaseURL:        os.Getenv("SUPABASE_URL"),
		SupabaseServiceKey: os.Getenv("SUPABASE_SERVICE_KEY"),
		WallhavenAPIKey:    os.Getenv("WALLHAVEN_API_KEY"),
		CronSecret:         os.Getenv("CRON_SECRET"),
		LogLevel:           getEnv("LOG_LEVEL", "info"),
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
