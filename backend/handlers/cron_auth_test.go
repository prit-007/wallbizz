package handlers

import (
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"wallpaper-backend/config"

	"github.com/gofiber/fiber/v2"
)

func TestRequireCronSecret_SecretNotConfigured(t *testing.T) {
	app := fiber.New()
	cfg := config.Config{CronSecret: ""}

	v1 := app.Group("/api/v1")
	v1.Use(RequireCronSecret(cfg))
	v1.Get("/sync", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"ok": true})
	})

	req := httptest.NewRequest("GET", "/api/v1/sync", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}

	if resp.StatusCode != http.StatusServiceUnavailable {
		body, _ := io.ReadAll(resp.Body)
		t.Errorf("Expected 503, got %d: %s", resp.StatusCode, string(body))
	}
}

func TestRequireCronSecret_NoAuthHeader(t *testing.T) {
	app := fiber.New()
	cfg := config.Config{CronSecret: "my-secret"}

	v1 := app.Group("/api/v1")
	v1.Use(RequireCronSecret(cfg))
	v1.Get("/sync", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"ok": true})
	})

	req := httptest.NewRequest("GET", "/api/v1/sync", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}

	if resp.StatusCode != http.StatusUnauthorized {
		body, _ := io.ReadAll(resp.Body)
		t.Errorf("Expected 401, got %d: %s", resp.StatusCode, string(body))
	}
}

func TestRequireCronSecret_WrongSecret(t *testing.T) {
	app := fiber.New()
	cfg := config.Config{CronSecret: "my-secret"}

	v1 := app.Group("/api/v1")
	v1.Use(RequireCronSecret(cfg))
	v1.Get("/sync", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"ok": true})
	})

	req := httptest.NewRequest("GET", "/api/v1/sync", nil)
	req.Header.Set("Authorization", "Bearer wrong-secret")
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}

	if resp.StatusCode != http.StatusUnauthorized {
		body, _ := io.ReadAll(resp.Body)
		t.Errorf("Expected 401, got %d: %s", resp.StatusCode, string(body))
	}
}

func TestRequireCronSecret_CorrectSecret(t *testing.T) {
	app := fiber.New()
	cfg := config.Config{CronSecret: "my-secret"}

	v1 := app.Group("/api/v1")
	v1.Use(RequireCronSecret(cfg))
	v1.Get("/sync", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"ok": true})
	})

	req := httptest.NewRequest("GET", "/api/v1/sync", nil)
	req.Header.Set("Authorization", "Bearer my-secret")
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Errorf("Expected 200, got %d: %s", resp.StatusCode, string(body))
	}
}
