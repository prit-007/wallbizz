package handlers

import (
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"wallpaper-backend/config"
	"wallpaper-backend/models"
)

func setupSearchTestServers(t *testing.T) (wallhaven *httptest.Server, supabase *httptest.Server, cfg config.Config) {
	t.Helper()

	wallhaven = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !strings.Contains(r.URL.String(), "apikey=test-wh-key") {
			t.Errorf("Wallhaven request missing apikey, got URL: %s", r.URL.String())
		}
		resp := models.WallhavenResponse{
			Data: []models.WallhavenImage{
				{ID: "abc123", Path: "https://w.wallhaven.cc/full/ab/abc123.jpg", Resolution: "1920x1080", DimensionX: 1920, DimensionY: 1080, FileSize: 1000000, Category: "general", Colors: []string{"#111111"}},
				{ID: "def456", Path: "https://w.wallhaven.cc/full/de/def456.jpg", Resolution: "2560x1440", DimensionX: 2560, DimensionY: 1440, FileSize: 2000000, Category: "anime", Colors: []string{"#222222"}},
			},
		}
		resp.Meta.CurrentPage = 1
		resp.Meta.LastPage = 10
		resp.Meta.PerPage = 24
		resp.Meta.Total = 240
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(resp)
	}))

	supabase = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if strings.Contains(authHeader, "valid-token") {
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]interface{}{
				"id":    "user-123",
				"email": "test@example.com",
			})
		} else {
			w.WriteHeader(http.StatusUnauthorized)
			json.NewEncoder(w).Encode(map[string]string{"msg": "invalid token"})
		}
	}))

	cfg = config.Config{
		WallhavenAPIKey:    "test-wh-key",
		SupabaseURL:        supabase.URL,
		SupabaseServiceKey: "test-service-key",
	}

	return
}

func TestSearchProxy_ValidJWT(t *testing.T) {
	wallhaven, supabase, cfg := setupSearchTestServers(t)
	defer wallhaven.Close()
	defer supabase.Close()

	app := setupSearchApp(cfg, wallhaven.URL)

	req := httptest.NewRequest("GET", "/api/v1/search?q=nature", nil)
	req.Header.Set("Authorization", "Bearer valid-token")
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Expected 200, got %d: %s", resp.StatusCode, string(body))
	}

	var wallData models.WallhavenResponse
	json.NewDecoder(resp.Body).Decode(&wallData)

	if len(wallData.Data) != 2 {
		t.Fatalf("Expected 2 wallpapers, got %d", len(wallData.Data))
	}
	if wallData.Data[0].ID != "abc123" {
		t.Errorf("Expected first wallpaper ID abc123, got %s", wallData.Data[0].ID)
	}
	if wallData.Meta.LastPage != 10 {
		t.Errorf("Expected last_page 10, got %d", wallData.Meta.LastPage)
	}
}

func TestSearchProxy_MissingAuth(t *testing.T) {
	wallhaven, supabase, cfg := setupSearchTestServers(t)
	defer wallhaven.Close()
	defer supabase.Close()

	app := setupSearchApp(cfg, wallhaven.URL)

	req := httptest.NewRequest("GET", "/api/v1/search?q=nature", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Errorf("Expected 200 (unauthenticated SFW allowed), got %d: %s", resp.StatusCode, string(body))
	}
}

func TestSearchProxy_InvalidJWT(t *testing.T) {
	wallhaven, supabase, cfg := setupSearchTestServers(t)
	defer wallhaven.Close()
	defer supabase.Close()

	app := setupSearchApp(cfg, wallhaven.URL)

	req := httptest.NewRequest("GET", "/api/v1/search?q=nature", nil)
	req.Header.Set("Authorization", "Bearer bad-token")
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Errorf("Expected 200 (proxy continues despite invalid JWT), got %d: %s", resp.StatusCode, string(body))
	}

	var wallData models.WallhavenResponse
	json.NewDecoder(resp.Body).Decode(&wallData)
	if len(wallData.Data) == 0 {
		t.Error("Expected wallpapers despite invalid JWT")
	}
}

func TestSearchProxy_QueryParamsForwarded(t *testing.T) {
	var receivedQuery string

	wallhaven := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		receivedQuery = r.URL.RawQuery
		resp := models.WallhavenResponse{Data: []models.WallhavenImage{}}
		resp.Meta.CurrentPage = 1
		resp.Meta.LastPage = 0
		resp.Meta.PerPage = 24
		resp.Meta.Total = 0
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(resp)
	}))
	defer wallhaven.Close()

	supabase := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{"id": "user-1"})
	}))
	defer supabase.Close()

	cfg := config.Config{
		WallhavenAPIKey:    "test-wh-key",
		SupabaseURL:        supabase.URL,
		SupabaseServiceKey: "test-key",
	}
	app := setupSearchApp(cfg, wallhaven.URL)

	req := httptest.NewRequest("GET", "/api/v1/search?q=nature+dark&sorting=toplist&topRange=3M&purity=111&ratios=16x9&categories=010&page=2", nil)
	req.Header.Set("Authorization", "Bearer valid-token")
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("Expected 200, got %d", resp.StatusCode)
	}

	if !strings.Contains(receivedQuery, "q=nature+dark") {
		t.Errorf("Missing q param in forwarded request: %s", receivedQuery)
	}
	if !strings.Contains(receivedQuery, "sorting=toplist") {
		t.Errorf("Missing sorting param: %s", receivedQuery)
	}
	if !strings.Contains(receivedQuery, "topRange=3M") {
		t.Errorf("Missing topRange param: %s", receivedQuery)
	}
	if !strings.Contains(receivedQuery, "purity=111") {
		t.Errorf("Missing purity param: %s", receivedQuery)
	}
	if !strings.Contains(receivedQuery, "ratios=16x9") {
		t.Errorf("Missing ratios param: %s", receivedQuery)
	}
	if !strings.Contains(receivedQuery, "categories=010") {
		t.Errorf("Missing categories param: %s", receivedQuery)
	}
	if !strings.Contains(receivedQuery, "page=2") {
		t.Errorf("Missing page param: %s", receivedQuery)
	}
	if !strings.Contains(receivedQuery, "apikey=test-wh-key") {
		t.Errorf("Missing apikey in forwarded request: %s", receivedQuery)
	}
}

func TestSearchProxy_EmptyQuery(t *testing.T) {
	wallhaven := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		resp := models.WallhavenResponse{Data: []models.WallhavenImage{}}
		resp.Meta.CurrentPage = 1
		resp.Meta.LastPage = 0
		resp.Meta.PerPage = 24
		resp.Meta.Total = 0
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(resp)
	}))
	defer wallhaven.Close()

	supabase := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{"id": "user-1"})
	}))
	defer supabase.Close()

	cfg := config.Config{
		WallhavenAPIKey:    "test-wh-key",
		SupabaseURL:        supabase.URL,
		SupabaseServiceKey: "test-key",
	}
	app := setupSearchApp(cfg, wallhaven.URL)

	req := httptest.NewRequest("GET", "/api/v1/search", nil)
	req.Header.Set("Authorization", "Bearer valid-token")
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Errorf("Expected 200 for empty query, got %d: %s", resp.StatusCode, string(body))
	}
}

func TestSearchProxy_WallhavenError(t *testing.T) {
	wallhaven := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusTooManyRequests)
		w.Write([]byte(`{"error":"rate limited"}`))
	}))
	defer wallhaven.Close()

	supabase := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{"id": "user-1"})
	}))
	defer supabase.Close()

	cfg := config.Config{
		WallhavenAPIKey:    "test-wh-key",
		SupabaseURL:        supabase.URL,
		SupabaseServiceKey: "test-key",
	}
	app := setupSearchApp(cfg, wallhaven.URL)

	req := httptest.NewRequest("GET", "/api/v1/search?q=nature", nil)
	req.Header.Set("Authorization", "Bearer valid-token")
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}
	if resp.StatusCode != http.StatusTooManyRequests {
		body, _ := io.ReadAll(resp.Body)
		t.Errorf("Expected 429, got %d: %s", resp.StatusCode, string(body))
	}
}

func TestSearchProxy_SupabaseDown(t *testing.T) {
	wallhaven := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		resp := models.WallhavenResponse{Data: []models.WallhavenImage{}}
		resp.Meta.CurrentPage = 1
		resp.Meta.LastPage = 0
		resp.Meta.PerPage = 24
		resp.Meta.Total = 0
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(resp)
	}))
	defer wallhaven.Close()

	cfg := config.Config{
		WallhavenAPIKey:    "test-wh-key",
		SupabaseURL:        "http://localhost:1",
		SupabaseServiceKey: "test-key",
	}
	app := setupSearchApp(cfg, wallhaven.URL)

	req := httptest.NewRequest("GET", "/api/v1/search?q=nature", nil)
	req.Header.Set("Authorization", "Bearer valid-token")
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Errorf("Expected 200 (proxy continues despite Supabase down), got %d: %s", resp.StatusCode, string(body))
	}
}

func TestSearchProxy_NoResults(t *testing.T) {
	wallhaven := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		resp := models.WallhavenResponse{Data: []models.WallhavenImage{}}
		resp.Meta.CurrentPage = 1
		resp.Meta.LastPage = 0
		resp.Meta.PerPage = 24
		resp.Meta.Total = 0
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(resp)
	}))
	defer wallhaven.Close()

	supabase := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{"id": "user-1"})
	}))
	defer supabase.Close()

	cfg := config.Config{
		WallhavenAPIKey:    "test-wh-key",
		SupabaseURL:        supabase.URL,
		SupabaseServiceKey: "test-key",
	}
	app := setupSearchApp(cfg, wallhaven.URL)

	req := httptest.NewRequest("GET", "/api/v1/search?q=xyznonexistent", nil)
	req.Header.Set("Authorization", "Bearer valid-token")
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}
	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected 200 for no results, got %d", resp.StatusCode)
	}

	var wallData models.WallhavenResponse
	json.NewDecoder(resp.Body).Decode(&wallData)
	if len(wallData.Data) != 0 {
		t.Errorf("Expected 0 results, got %d", len(wallData.Data))
	}
}
