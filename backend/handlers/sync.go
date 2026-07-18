package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"wallpaper-backend/config"
	"wallpaper-backend/logger"
	"wallpaper-backend/models"
)

const (
	httpTimeout      = 30 * time.Second
	wallhavenBaseURL = "https://wallhaven.cc/api/v1/search"
)

var categoryQueryMap = map[string]string{
	"trending": "",
	"anime":    "q=anime&categories=010",
	"amoled":   "q=amoled+black",
	"desktop":  "ratios=16x9,16x10",
	"mobile":   "ratios=9x16,10x16",
}

var httpClient = &http.Client{Timeout: httpTimeout}

func FetchAndSyncWallpapers(cfg config.Config) {
	log := logger.Log()
	log.Info().Int("categories", len(categoryQueryMap)).Msg("Starting Wallhaven sync")

	for category, extraParams := range categoryQueryMap {
		log.Info().Str("category", category).Msg("Syncing category")
		count := fetchCategory(cfg, category, extraParams)
		if count > 0 {
			log.Info().Str("category", category).Int("count", count).Msg("Wallpapers synced")
		}
	}

	log.Info().Msg("All categories synced successfully")
}

func fetchCategory(cfg config.Config, category, extraParams string) int {
	log := logger.Log()

	params := fmt.Sprintf("?apikey=%s&purity=100&sorting=toplist&topRange=3M", cfg.WallhavenAPIKey)
	if extraParams != "" {
		params += "&" + extraParams
	}
	url := wallhavenBaseURL + params

	resp, err := httpClient.Get(url)
	if err != nil {
		log.Error().Str("category", category).Err(err).Msg("Failed to fetch from Wallhaven")
		return 0
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		log.Error().Str("category", category).Int("status", resp.StatusCode).Str("body", string(body)).Msg("Wallhaven returned error")
		return 0
	}

	var wallData models.WallhavenResponse
	if err := json.NewDecoder(resp.Body).Decode(&wallData); err != nil {
		log.Error().Str("category", category).Err(err).Msg("Failed to decode Wallhaven response")
		return 0
	}

	if len(wallData.Data) == 0 {
		log.Warn().Str("category", category).Msg("No wallpapers returned")
		return 0
	}

	toInsert := make([]models.WallpaperInsert, 0, len(wallData.Data))
	for _, item := range wallData.Data {
		primaryColor := "#000000"
		if len(item.Colors) > 0 {
			primaryColor = item.Colors[0]
		}

		toInsert = append(toInsert, models.WallpaperInsert{
			WallhavenID:  item.ID,
			URLFull:      item.Path,
			URLThumb:     item.Thumbs.Original,
			Resolution:   item.Resolution,
			Width:        item.DimensionX,
			Height:       item.DimensionY,
			FileSize:     item.FileSize,
			PrimaryColor: primaryColor,
			Category:     item.Category,
			SourceQuery:  category,
		})
	}

	if err := upsertToSupabase(cfg, toInsert); err != nil {
		log.Error().Str("category", category).Err(err).Msg("Failed to upsert to Supabase")
		return 0
	}

	return len(toInsert)
}

func upsertToSupabase(cfg config.Config, wallpapers []models.WallpaperInsert) error {
	url := fmt.Sprintf("%s/rest/v1/wallpapers", cfg.SupabaseURL)

	body, err := json.Marshal(wallpapers)
	if err != nil {
		return fmt.Errorf("failed to marshal wallpapers: %w", err)
	}

	req, err := http.NewRequest("POST", url, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+cfg.SupabaseServiceKey)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Prefer", "resolution=merge-duplicates")

	resp, err := httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusOK {
		respBody, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("supabase returned %d: %s", resp.StatusCode, strings.TrimSpace(string(respBody)))
	}

	return nil
}
