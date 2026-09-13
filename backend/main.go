package main

import (
	"context"
	"os"
	"os/signal"
	"syscall"
	"time"

	"wallpaper-backend/config"
	"wallpaper-backend/handlers"
	"wallpaper-backend/logger"

	_ "wallpaper-backend/docs"

	"github.com/arsmn/fiber-swagger/v2"
	"github.com/gofiber/contrib/fiberzerolog"
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

	logger.Init()
	log := logger.Log()

	app := fiber.New(fiber.Config{
		DisableStartupMessage: true,
	})

	app.Use(cors.New(cors.Config{
		AllowOrigins: "https://*.vercel.app,https://*.onrender.com,http://localhost:*",
		AllowMethods: "GET,POST,PUT,DELETE,OPTIONS",
		AllowHeaders: "Origin,Content-Type,Accept,Authorization",
	}))

	app.Use(fiberzerolog.New(fiberzerolog.Config{
		Logger: log,
	}))

	c := cron.New()
	c.AddFunc("0 2,14 * * *", func() {
		log.Info().Msg("Cron triggered: Starting Wallhaven sync")
		handlers.FetchAndSyncWallpapers(cfg)
	})
	c.Start()

	log.Info().Msg("Cron scheduler started (runs at 2:00 AM and 2:00 PM UTC)")

	app.Get("/swagger/*", swagger.New(swagger.Config{
		URL: "/swagger/doc.json",
	}))

	v1 := app.Group("/api/v1")
	v1.Post("/sync", handlers.RequireCronSecret(cfg), handlers.TriggerSync(cfg))
	v1.Post("/cleanup", handlers.RequireCronSecret(cfg), handlers.TriggerCleanup(cfg))
	v1.Get("/search", handlers.SearchProxy(cfg))
	v1.Get("/proxy-image", handlers.ProxyImage())
	v1.Get("/health", handlers.HealthCheck())

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		log.Info().Str("port", cfg.Port).Msg("Server starting")
		if err := app.Listen(":" + cfg.Port); err != nil {
			log.Fatal().Err(err).Msg("Server failed to start")
		}
	}()

	sig := <-quit
	log.Warn().Str("signal", sig.String()).Msg("Shutdown signal received")

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	log.Info().Msg("Stopping cron scheduler...")
	c.Stop()

	log.Info().Msg("Waiting for in-flight sync to complete...")
	handlers.WaitForSync()

	log.Info().Msg("Shutting down Fiber server...")
	if err := app.ShutdownWithContext(ctx); err != nil {
		log.Error().Err(err).Msg("Fiber shutdown error")
	}

	log.Info().Msg("Server stopped gracefully")
}
