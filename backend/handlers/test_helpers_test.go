package handlers

import (
	"wallpaper-backend/config"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
)

func setupTestApp(cfg config.Config) *fiber.App {
	app := fiber.New()
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowMethods: "GET,POST,PUT,DELETE,OPTIONS",
		AllowHeaders: "Origin,Content-Type,Accept,Authorization",
	}))

	v1 := app.Group("/api/v1")
	v1.Post("/sync", TriggerSync(cfg))
	v1.Post("/cleanup", TriggerCleanup(cfg))
	v1.Get("/health", HealthCheck())

	return app
}
