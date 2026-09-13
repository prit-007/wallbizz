package handlers

import (
	"fmt"
	"net/http"
	"time"

	"wallpaper-backend/config"
	"wallpaper-backend/logger"

	"github.com/gofiber/fiber/v2"
)

var istLocation = func() *time.Location {
	loc, err := time.LoadLocation("Asia/Kolkata")
	if err != nil {
		return time.UTC
	}
	return loc
}()

func istNow() string {
	return time.Now().In(istLocation).Format("2006-01-02 15:04:05 IST")
}

// TriggerSync godoc
// @Summary Trigger a manual sync
// @Description Triggers a background Wallhaven sync for all categories. Returns immediately.
// @Tags sync
// @Produce json
// @Success 200 {object} map[string]string
// @Router /sync [post]
func TriggerSync(cfg config.Config) func(*fiber.Ctx) error {
	return func(c *fiber.Ctx) error {
		now := istNow()
		logger.Log().Info().Str("time_ist", now).Msg("Manual sync triggered via API")
		go FetchAndSyncWallpapers(cfg)
		return c.JSON(fiber.Map{
			"status":   "sync triggered",
			"time_ist": now,
		})
	}
}

// HealthCheck godoc
// @Summary Health check
// @Description Returns server health status and verifies database connectivity.
// @Tags health
// @Produce json
// @Success 200 {object} map[string]string
// @Failure 503 {object} map[string]string
// @Router /health [get]
func HealthCheck() func(*fiber.Ctx) error {
	return func(c *fiber.Ctx) error {
		log := logger.Log()
		log.Debug().Msg("Health check requested")

		dbOk := true
		if err := pingSupabase(); err != nil {
			dbOk = false
			log.Warn().Err(err).Msg("Health check: DB unreachable")
		}

		status := "ok"
		statusCode := http.StatusOK
		if !dbOk {
			status = "degraded"
			statusCode = http.StatusServiceUnavailable
		}

		return c.Status(statusCode).JSON(fiber.Map{
			"status":   status,
			"database": dbOk,
			"time_ist": istNow(),
		})
	}
}

func pingSupabase() error {
	cfg := config.LoadConfig()
	url := fmt.Sprintf("%s/rest/v1/wallpapers?select=id&limit=1", cfg.SupabaseURL)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return err
	}
	req.Header.Set("apikey", cfg.SupabaseServiceKey)
	req.Header.Set("Authorization", "Bearer "+cfg.SupabaseServiceKey)

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		return fmt.Errorf("supabase returned %d", resp.StatusCode)
	}
	return nil
}
