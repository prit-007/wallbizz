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

func TestCategoryQueryMap_ContainsAllCategories(t *testing.T) {
	expected := []string{"trending", "anime", "dark", "desktop", "mobile"}

	for _, cat := range expected {
		if _, ok := categoryQueryMap[cat]; !ok {
			t.Errorf("Missing category in categoryQueryMap: %s", cat)
		}
	}

	if len(categoryQueryMap) != len(expected) {
		t.Errorf("categoryQueryMap has %d entries, expected %d", len(categoryQueryMap), len(expected))
	}
}

func TestCategoryQueryMap_QueryParams(t *testing.T) {
	tests := []struct {
		category    string
		shouldHave  []string
		shouldNot   []string
	}{
		{"trending", nil, []string{"q=", "ratios="}},
		{"anime", []string{"q=anime", "categories=010"}, nil},
		{"dark", []string{"q=dark", "categories=111", "purity=100"}, nil},
		{"desktop", []string{"ratios=16x9"}, nil},
		{"mobile", []string{"ratios=9x16"}, nil},
	}

	for _, tt := range tests {
		t.Run(tt.category, func(t *testing.T) {
			params, ok := categoryQueryMap[tt.category]
			if !ok {
				t.Fatalf("Category %s not found", tt.category)
			}
			for _, s := range tt.shouldHave {
				if !strings.Contains(params, s) {
					t.Errorf("Category %s params '%s' should contain '%s'", tt.category, params, s)
				}
			}
			for _, s := range tt.shouldNot {
				if strings.Contains(params, s) {
					t.Errorf("Category %s params '%s' should NOT contain '%s'", tt.category, params, s)
				}
			}
		})
	}
}

func TestUpsertToSupabase_SendsCorrectHeaders(t *testing.T) {
	var receivedHeaders http.Header
	var receivedBody []models.WallpaperInsert

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		receivedHeaders = r.Header

		if r.Method != "POST" {
			t.Errorf("Expected POST, got %s", r.Method)
		}

		if r.Header.Get("Authorization") == "" {
			t.Error("Missing Authorization header")
		}

		if r.Header.Get("Prefer") != "resolution=merge-duplicates" {
			t.Errorf("Missing or wrong Prefer header: %s", r.Header.Get("Prefer"))
		}

		json.NewDecoder(r.Body).Decode(&receivedBody)
		w.WriteHeader(http.StatusCreated)
	}))
	defer server.Close()

	cfg := config.Config{
		SupabaseURL:        server.URL,
		SupabaseServiceKey: "test-key",
	}

	wallpapers := []models.WallpaperInsert{
		{
			WallhavenID:  "abc123",
			URLFull:      "https://example.com/full.jpg",
			URLThumb:     "https://example.com/thumb.jpg",
			Resolution:   "1920x1080",
			Width:        1920,
			Height:       1080,
			FileSize:     1000000,
			PrimaryColor: "#FF0000",
			Category:     "anime",
			SourceQuery:  "anime",
		},
	}

	err := upsertToSupabase(cfg, wallpapers)
	if err != nil {
		t.Fatalf("upsertToSupabase failed: %v", err)
	}

	if receivedHeaders.Get("Authorization") != "Bearer test-key" {
		t.Errorf("Wrong Authorization header: %s", receivedHeaders.Get("Authorization"))
	}

	if receivedHeaders.Get("Content-Type") != "application/json" {
		t.Errorf("Wrong Content-Type: %s", receivedHeaders.Get("Content-Type"))
	}

	if len(receivedBody) != 1 {
		t.Fatalf("Expected 1 wallpaper in body, got %d", len(receivedBody))
	}

	if receivedBody[0].WallhavenID != "abc123" {
		t.Errorf("Wrong wallhaven_id: %s", receivedBody[0].WallhavenID)
	}

	if receivedBody[0].Width != 1920 || receivedBody[0].Height != 1080 {
		t.Errorf("Wrong dimensions: %dx%d", receivedBody[0].Width, receivedBody[0].Height)
	}
}

func TestUpsertToSupabase_MultipleWallpapers(t *testing.T) {
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

	wallpapers := []models.WallpaperInsert{
		{WallhavenID: "aaa", SourceQuery: "anime"},
		{WallhavenID: "bbb", SourceQuery: "anime"},
		{WallhavenID: "ccc", SourceQuery: "anime"},
	}

	err := upsertToSupabase(cfg, wallpapers)
	if err != nil {
		t.Fatalf("upsertToSupabase failed: %v", err)
	}

	if len(receivedBody) != 3 {
		t.Fatalf("Expected 3 wallpapers, got %d", len(receivedBody))
	}
}

func TestUpsertToSupabase_HandlesError(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(`{"message":"internal error"}`))
	}))
	defer server.Close()

	cfg := config.Config{
		SupabaseURL:        server.URL,
		SupabaseServiceKey: "test-key",
	}

	err := upsertToSupabase(cfg, []models.WallpaperInsert{{}})
	if err == nil {
		t.Error("Expected error for 500 response, got nil")
	}

	if !strings.Contains(err.Error(), "500") {
		t.Errorf("Error should mention status code 500, got: %v", err)
	}
}

func TestUpsertToSupabase_HandlesNetworkError(t *testing.T) {
	cfg := config.Config{
		SupabaseURL:        "http://localhost:1",
		SupabaseServiceKey: "test-key",
	}

	err := upsertToSupabase(cfg, []models.WallpaperInsert{{}})
	if err == nil {
		t.Error("Expected error for connection refused, got nil")
	}
}

func TestWallpaperInsert_JSONKeys(t *testing.T) {
	wi := models.WallpaperInsert{
		WallhavenID:  "94x38z",
		URLFull:      "https://w.wallhaven.cc/full.jpg",
		URLThumb:     "https://th.wallhaven.cc/thumb.jpg",
		Resolution:   "6742x3534",
		Width:        6742,
		Height:       3534,
		FileSize:     5070446,
		PrimaryColor: "#000000",
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

	expectedKeys := []string{
		"wallhaven_id", "url_full", "url_thumb", "resolution",
		"width", "height", "file_size", "primary_color",
		"category", "source_query",
	}

	for _, key := range expectedKeys {
		if _, ok := parsed[key]; !ok {
			t.Errorf("Missing expected JSON key: %s", key)
		}
	}
}
