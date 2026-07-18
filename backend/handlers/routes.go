package handlers

import (
	"wallpaper-backend/config"
	"wallpaper-backend/logger"

	"github.com/gofiber/fiber/v2"
)

// TriggerSync godoc
// @Summary Trigger a manual sync
// @Description Triggers a background Wallhaven sync for all categories. Returns immediately.
// @Tags sync
// @Produce json
// @Success 200 {object} map[string]string
// @Router /sync [post]
func TriggerSync(cfg config.Config) func(*fiber.Ctx) error {
	return func(c *fiber.Ctx) error {
		logger.Log().Info().Msg("Manual sync triggered via API")
		go FetchAndSyncWallpapers(cfg)
		return c.JSON(fiber.Map{
			"status": "sync triggered",
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
			"status": "ok",
		})
	}
}
