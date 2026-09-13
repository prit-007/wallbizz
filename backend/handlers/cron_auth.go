package handlers

import (
	"wallpaper-backend/config"

	"github.com/gofiber/fiber/v2"
)

func RequireCronSecret(cfg config.Config) func(*fiber.Ctx) error {
	return func(c *fiber.Ctx) error {
		if cfg.CronSecret == "" {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"error": "CRON_SECRET not configured",
			})
		}

		auth := c.Get("Authorization")
		if auth == "Bearer "+cfg.CronSecret {
			return c.Next()
		}

		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "unauthorized",
		})
	}
}
