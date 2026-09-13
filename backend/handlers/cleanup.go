package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"wallpaper-backend/config"
	"wallpaper-backend/logger"

	"github.com/gofiber/fiber/v2"
)

func CleanupOldWallpapers(cfg config.Config) (int, error) {
	log := logger.Log()

	protectedIDs, err := fetchProtectedWallpaperIDs(cfg)
	if err != nil {
		log.Error().Err(err).Msg("Failed to fetch protected wallpaper IDs")
		protectedIDs = []string{}
	}

	retentionDays := cfg.RetentionDays
	if retentionDays <= 0 {
		retentionDays = 3
	}
	cutoff := time.Now().UTC().Add(-time.Duration(retentionDays) * 24 * time.Hour)
	cutoffStr := cutoff.Format("2006-01-02T15:04:05")

	url := fmt.Sprintf("%s/rest/v1/wallpapers?created_at=lt.%s", cfg.SupabaseURL, cutoffStr)

	if len(protectedIDs) > 0 {
		url += "&id=not.in.(" + strings.Join(protectedIDs, ",") + ")"
	}

	req, err := http.NewRequest("DELETE", url, nil)
	if err != nil {
		return 0, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("apikey", cfg.SupabaseServiceKey)
	req.Header.Set("Authorization", "Bearer "+cfg.SupabaseServiceKey)
	req.Header.Set("Prefer", "return=minimal")

	resp, err := httpClient.Do(req)
	if err != nil {
		return 0, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNoContent && resp.StatusCode != http.StatusOK {
		respBody, _ := io.ReadAll(resp.Body)
		return 0, fmt.Errorf("supabase returned %d: %s", resp.StatusCode, strings.TrimSpace(string(respBody)))
	}

	log.Info().Str("cutoff", cutoffStr).Int("protected", len(protectedIDs)).Msg("Cleanup completed")
	return len(protectedIDs), nil
}

func fetchProtectedWallpaperIDs(cfg config.Config) ([]string, error) {
	seen := make(map[string]bool)

	if ids, err := fetchIDsFromTable(cfg, "wishlists"); err == nil {
		for _, id := range ids {
			seen[id] = true
		}
	}

	if ids, err := fetchIDsFromTable(cfg, "moodboard_items"); err == nil {
		for _, id := range ids {
			seen[id] = true
		}
	}

	ids := make([]string, 0, len(seen))
	for id := range seen {
		ids = append(ids, id)
	}

	return ids, nil
}

func fetchIDsFromTable(cfg config.Config, table string) ([]string, error) {
	url := fmt.Sprintf("%s/rest/v1/%s?select=wallpaper_id", cfg.SupabaseURL, table)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("apikey", cfg.SupabaseServiceKey)
	req.Header.Set("Authorization", "Bearer "+cfg.SupabaseServiceKey)

	resp, err := httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("%s returned %d", table, resp.StatusCode)
	}

	var rows []struct {
		WallpaperID string `json:"wallpaper_id"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&rows); err != nil {
		return nil, fmt.Errorf("failed to decode %s response: %w", table, err)
	}

	ids := make([]string, 0, len(rows))
	for _, row := range rows {
		if row.WallpaperID != "" {
			ids = append(ids, row.WallpaperID)
		}
	}

	return ids, nil
}

func TriggerCleanup(cfg config.Config) func(*fiber.Ctx) error {
	return func(c *fiber.Ctx) error {
		log := logger.Log()
		now := istNow()
		log.Info().Str("time_ist", now).Msg("Cleanup triggered via API")

		count, err := CleanupOldWallpapers(cfg)
		if err != nil {
			log.Error().Err(err).Str("time_ist", istNow()).Msg("Cleanup failed")
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error":   "cleanup failed",
				"details": err.Error(),
				"skipped": count,
				"time_ist": now,
			})
		}

		return c.JSON(fiber.Map{
			"status":   "cleanup completed",
			"skipped":  count,
			"time_ist": now,
		})
	}
}
