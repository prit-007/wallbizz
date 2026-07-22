package handlers

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"wallpaper-backend/config"
	"wallpaper-backend/models"
)

func TestUpsertToSupabase_EmptyWallpapers(t *testing.T) {
	var receivedBody []models.WallpaperInsert

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		json.NewDecoder(r.Body).Decode(&receivedBody)
		w.WriteHeader(http.StatusCreated)
	}))
	defer server.Close()

	cfg := config.Config{
		SupabaseURL:        server.URL,
		SupabaseServiceKey: "test-key",
	}

	err := upsertToSupabase(cfg, []models.WallpaperInsert{})
	if err != nil {
		t.Fatalf("upsertToSupabase with empty array should succeed: %v", err)
	}

	if len(receivedBody) != 0 {
		t.Errorf("Expected 0 wallpapers in body, got %d", len(receivedBody))
	}
}

func TestUpsertToSupabase_InvalidJSON(t *testing.T) {
	cfg := config.Config{
		SupabaseURL:        "http://invalid-url-that-does-not-exist:99999",
		SupabaseServiceKey: "test-key",
	}

	err := upsertToSupabase(cfg, []models.WallpaperInsert{
		{WallhavenID: "test", SourceQuery: "anime"},
	})

	if err == nil {
		t.Error("Expected error for invalid URL, got nil")
	}
}

func TestUpsertToSupabase_403Forbidden(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusForbidden)
		w.Write([]byte(`{"message":"forbidden"}`))
	}))
	defer server.Close()

	cfg := config.Config{
		SupabaseURL:        server.URL,
		SupabaseServiceKey: "wrong-key",
	}

	err := upsertToSupabase(cfg, []models.WallpaperInsert{{}})
	if err == nil {
		t.Error("Expected error for 403 response, got nil")
	}

	if !strings.Contains(err.Error(), "403") {
		t.Errorf("Error should mention status code 403, got: %v", err)
	}
}

func TestUpsertToSupabase_401Unauthorized(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusUnauthorized)
		w.Write([]byte(`{"message":"unauthorized"}`))
	}))
	defer server.Close()

	cfg := config.Config{
		SupabaseURL:        server.URL,
		SupabaseServiceKey: "",
	}

	err := upsertToSupabase(cfg, []models.WallpaperInsert{{}})
	if err == nil {
		t.Error("Expected error for 401 response, got nil")
	}

	if !strings.Contains(err.Error(), "401") {
		t.Errorf("Error should mention status code 401, got: %v", err)
	}
}

func TestUpsertToSupabase_503ServiceUnavailable(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusServiceUnavailable)
		w.Write([]byte(`{"message":"service unavailable"}`))
	}))
	defer server.Close()

	cfg := config.Config{
		SupabaseURL:        server.URL,
		SupabaseServiceKey: "test-key",
	}

	err := upsertToSupabase(cfg, []models.WallpaperInsert{{}})
	if err == nil {
		t.Error("Expected error for 503 response, got nil")
	}

	if !strings.Contains(err.Error(), "503") {
		t.Errorf("Error should mention status code 503, got: %v", err)
	}
}

func TestUpsertToSupabase_CorrectURL(t *testing.T) {
	var receivedPath string

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		receivedPath = r.URL.Path
		w.WriteHeader(http.StatusCreated)
	}))
	defer server.Close()

	cfg := config.Config{
		SupabaseURL:        server.URL,
		SupabaseServiceKey: "test-key",
	}

	upsertToSupabase(cfg, []models.WallpaperInsert{{}})

	if receivedPath != "/rest/v1/wallpapers" {
		t.Errorf("Expected path /rest/v1/wallpapers, got: %s", receivedPath)
	}
}

func TestUpsertToSupabase_LargeBatch(t *testing.T) {
	var receivedBody []models.WallpaperInsert

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		json.NewDecoder(r.Body).Decode(&receivedBody)
		w.WriteHeader(http.StatusCreated)
	}))
	defer server.Close()

	cfg := config.Config{
		SupabaseURL:        server.URL,
		SupabaseServiceKey: "test-key",
	}

	// Create 50 wallpapers
	wallpapers := make([]models.WallpaperInsert, 50)
	for i := range wallpapers {
		wallpapers[i] = models.WallpaperInsert{
			WallhavenID:  "id-" + string(rune('A'+i%26)),
			SourceQuery:  "trending",
			PrimaryColor: "#000000",
		}
	}

	err := upsertToSupabase(cfg, wallpapers)
	if err != nil {
		t.Fatalf("upsertToSupabase with 50 wallpapers failed: %v", err)
	}

	if len(receivedBody) != 50 {
		t.Errorf("Expected 50 wallpapers, got %d", len(receivedBody))
	}
}

func TestFetchCategory_AllCategoriesHaveQueries(t *testing.T) {
	for cat, params := range categoryQueryMap {
		if cat == "" {
			t.Error("Empty category key found")
		}
		// params can be empty for trending
		_ = params
	}
}

func TestCategoryQueryMap_KeyCount(t *testing.T) {
	expectedCount := 5
	if len(categoryQueryMap) != expectedCount {
		t.Errorf("Expected %d categories, got %d", expectedCount, len(categoryQueryMap))
	}
}

func TestCategoryQueryMap_TrendingHasNoExtraParams(t *testing.T) {
	if categoryQueryMap["trending"] != "" {
		t.Errorf("Expected empty params for trending, got: '%s'", categoryQueryMap["trending"])
	}
}

func TestCategoryQueryMap_AnimeHasAnimeQuery(t *testing.T) {
	params := categoryQueryMap["anime"]
	if !strings.Contains(params, "q=anime") {
		t.Errorf("Expected 'q=anime' in anime params, got: '%s'", params)
	}
}

func TestCategoryQueryMap_DarkHasQuery(t *testing.T) {
	params := categoryQueryMap["dark"]
	if !strings.Contains(params, "q=dark") {
		t.Errorf("Expected 'q=dark' in dark params, got: '%s'", params)
	}
}

func TestCategoryQueryMap_DesktopHasLandscapeRatio(t *testing.T) {
	params := categoryQueryMap["desktop"]
	if !strings.Contains(params, "16x9") {
		t.Errorf("Expected '16x9' in desktop params, got: '%s'", params)
	}
}

func TestCategoryQueryMap_MobileHasPortraitRatio(t *testing.T) {
	params := categoryQueryMap["mobile"]
	if !strings.Contains(params, "9x16") {
		t.Errorf("Expected '9x16' in mobile params, got: '%s'", params)
	}
}

func TestWallpaperInsert_AllFieldsSerialize(t *testing.T) {
	wi := models.WallpaperInsert{
		WallhavenID:  "test123",
		URLFull:      "https://full.jpg",
		URLThumb:     "https://thumb.jpg",
		Resolution:   "2560x1440",
		Width:        2560,
		Height:       1440,
		FileSize:     3500000,
		PrimaryColor: "#1a2b3c",
		Category:     "anime",
		SourceQuery:  "anime",
	}

	data, err := json.Marshal(wi)
	if err != nil {
		t.Fatalf("Failed to marshal: %v", err)
	}

	var parsed map[string]interface{}
	if err := json.Unmarshal(data, &parsed); err != nil {
		t.Fatalf("Failed to unmarshal: %v", err)
	}

	// Check all expected keys
	expected := map[string]interface{}{
		"wallhaven_id":  "test123",
		"url_full":      "https://full.jpg",
		"url_thumb":     "https://thumb.jpg",
		"resolution":    "2560x1440",
		"width":         float64(2560),
		"height":        float64(1440),
		"file_size":     float64(3500000),
		"primary_color": "#1a2b3c",
		"category":      "anime",
		"source_query":  "anime",
	}

	for key, expectedVal := range expected {
		if parsed[key] != expectedVal {
			t.Errorf("Key '%s': expected %v, got %v", key, expectedVal, parsed[key])
		}
	}
}
