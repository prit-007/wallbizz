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
	"trending":  "",
	"anime":     "q=anime&categories=010",
	"nature":    "q=nature&categories=111&purity=100",
	"cyberpunk": "q=cyberpunk&categories=111&purity=100",
	"space":     "q=space&categories=111&purity=100",
	"desktop":   "ratios=16x9,16x10",
	"mobile":    "ratios=9x16,10x16",
}

var (
	httpClient = &http.Client{Timeout: httpTimeout}
	syncMutex  bool
)

func FetchAndSyncWallpapers(cfg config.Config) {
	if syncMutex {
		logger.Log().Warn().Msg("Sync already in progress, skipping")
		return
	}
	syncMutex = true
	defer func() { syncMutex = false }()

	log := logger.Log()
	started := istNow()
	log.Info().Str("time_ist", started).Int("categories", len(categoryQueryMap)).Msg("Starting Wallhaven sync")

	for category, extraParams := range categoryQueryMap {
		log.Info().Str("category", category).Str("time_ist", istNow()).Msg("Syncing category")
		count := fetchCategory(cfg, category, extraParams)
		if count > 0 {
			log.Info().Str("category", category).Int("count", count).Str("time_ist", istNow()).Msg("Wallpapers synced")
		}
	}

	log.Info().Str("time_ist", istNow()).Msg("All categories synced successfully")

	log.Info().Str("time_ist", istNow()).Msg("Running cleanup of old wallpapers")
	if _, err := CleanupOldWallpapers(cfg); err != nil {
		log.Error().Err(err).Str("time_ist", istNow()).Msg("Cleanup failed after sync")
	} else {
		log.Info().Str("time_ist", istNow()).Msg("Cleanup completed successfully")
	}
}

func fetchCategory(cfg config.Config, category, extraParams string) int {
	log := logger.Log()

	baseParams := fmt.Sprintf("apikey=%s&purity=100&sorting=toplist&topRange=3M", cfg.WallhavenAPIKey)
	if extraParams != "" {
		baseParams += "&" + extraParams
	}

	totalInserted := 0

	for page := 1; page <= 3; page++ {
		url := fmt.Sprintf("%s?%s&page=%d", wallhavenBaseURL, baseParams, page)

		resp, err := httpClient.Get(url)
		if err != nil {
			log.Error().Str("category", category).Int("page", page).Err(err).Msg("Failed to fetch from Wallhaven")
			continue
		}

		if resp.StatusCode != http.StatusOK {
			body, _ := io.ReadAll(resp.Body)
			resp.Body.Close()
			log.Error().Str("category", category).Int("page", page).Int("status", resp.StatusCode).Str("body", string(body)).Msg("Wallhaven returned error")
			continue
		}

		var wallData models.WallhavenResponse
		if err := json.NewDecoder(resp.Body).Decode(&wallData); err != nil {
			resp.Body.Close()
			log.Error().Str("category", category).Int("page", page).Err(err).Msg("Failed to decode Wallhaven response")
			continue
		}
		resp.Body.Close()

		if len(wallData.Data) == 0 {
			log.Debug().Str("category", category).Int("page", page).Msg("No more wallpapers on this page")
			break
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
			log.Error().Str("category", category).Int("page", page).Err(err).Msg("Failed to upsert to Supabase")
			continue
		}

		totalInserted += len(toInsert)
	}

	return totalInserted
}

func upsertToSupabase(cfg config.Config, wallpapers []models.WallpaperInsert) error {
	url := fmt.Sprintf("%s/rest/v1/wallpapers?on_conflict=wallhaven_id", cfg.SupabaseURL)

	body, err := json.Marshal(wallpapers)
	if err != nil {
		return fmt.Errorf("failed to marshal wallpapers: %w", err)
	}

	req, err := http.NewRequest("POST", url, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("apikey", cfg.SupabaseServiceKey)
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
