package main

import (
	"log"

	"wallpaper-backend/config"
	"wallpaper-backend/handlers"

	_ "wallpaper-backend/docs"

	"github.com/arsmn/fiber-swagger/v2"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/robfig/cron/v3"
)

// @title Vivek Wallpapers API
// @version 1.0
// @description Backend API for Vivek Wallpapers — syncs from Wallhaven, proxies search, manages wishlists.
// @host localhost:3000
// @BasePath /api/v1
// @schemes http
func main() {
	cfg := config.LoadConfig()

	app := fiber.New()

	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowMethods: "GET,POST,PUT,DELETE,OPTIONS",
		AllowHeaders: "Origin,Content-Type,Accept,Authorization",
	}))

	c := cron.New()
	c.AddFunc("0 2,14 * * *", func() {
		log.Println("Cron triggered: Starting Wallhaven sync...")
		handlers.FetchAndSyncWallpapers(cfg)
	})
	c.Start()
	defer c.Stop()

	log.Println("Cron scheduler started (runs at 2:00 AM and 2:00 PM UTC)")

	// Swagger docs
	app.Get("/swagger/*", swagger.New(swagger.Config{
		URL: "/swagger/doc.json",
	}))

	// Versioned API routes
	v1 := app.Group("/api/v1")
	v1.Post("/sync", handlers.TriggerSync(cfg))
	v1.Get("/search", handlers.SearchProxy(cfg))
	v1.Get("/health", handlers.HealthCheck())

	log.Printf("Server starting on port %s\n", cfg.Port)
	log.Fatal(app.Listen(":" + cfg.Port))
}
