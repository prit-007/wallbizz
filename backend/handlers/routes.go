package handlers

import (
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
			"status": "sync triggered",
			"time_ist": now,
		})
	}
}

// HealthCheck godoc
// @Summary Health check
// @Description Returns server health status.
// @Tags health
// @Produce json
// @Success 200 {object} map[string]string
// @Router /health [get]
func HealthCheck() func(*fiber.Ctx) error {
	return func(c *fiber.Ctx) error {
		logger.Log().Debug().Msg("Health check requested")
		return c.JSON(fiber.Map{
			"status":   "ok",
			"time_ist": istNow(),
		})
	}
}
