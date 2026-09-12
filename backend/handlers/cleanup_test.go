package handlers

import (
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"wallpaper-backend/config"
)

func TestCleanupOldWallpapers_DeletesOldEntries(t *testing.T) {
	var deleteReq *http.Request
	var deleteBody string

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		deleteReq = r
		body, _ := io.ReadAll(r.Body)
		deleteBody = string(body)
		w.WriteHeader(http.StatusNoContent)
	}))
	defer server.Close()

	cfg := config.Config{
		SupabaseURL:        server.URL,
		SupabaseServiceKey: "test-key",
	}

	count, err := CleanupOldWallpapers(cfg)
	if err != nil {
		t.Fatalf("CleanupOldWallpapers failed: %v", err)
	}

	if count < 0 {
		t.Errorf("Count should be non-negative, got %d", count)
	}

	if deleteReq == nil {
		t.Fatal("Expected a DELETE request to be made")
	}

	if deleteReq.Method != "DELETE" {
		t.Errorf("Expected DELETE method, got %s", deleteReq.Method)
	}

	if deleteReq.Header.Get("Authorization") != "Bearer test-key" {
		t.Errorf("Wrong Authorization header: %s", deleteReq.Header.Get("Authorization"))
	}

	_ = deleteBody
}

func TestCleanupOldWallpapers_SendsCorrectURL(t *testing.T) {
	var receivedPath string
	var receivedQuery string

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		receivedPath = r.URL.Path
		receivedQuery = r.URL.RawQuery
		w.WriteHeader(http.StatusNoContent)
	}))
	defer server.Close()

	cfg := config.Config{
		SupabaseURL:        server.URL,
		SupabaseServiceKey: "test-key",
	}

	CleanupOldWallpapers(cfg)

	if receivedPath != "/rest/v1/wallpapers" {
		t.Errorf("Expected path /rest/v1/wallpapers, got: %s", receivedPath)
	}

	if !strings.Contains(receivedQuery, "created_at=lt.") {
		t.Errorf("Expected query to contain created_at=lt., got: %s", receivedQuery)
	}

	cutoff := time.Now().UTC().Add(-3 * 24 * time.Hour).Format("2006-01-02T15:04:05")
	if !strings.Contains(receivedQuery, cutoff[:10]) {
		t.Errorf("Expected query to contain cutoff date %s, got: %s", cutoff[:10], receivedQuery)
	}
}

func TestCleanupOldWallpapers_ExcludesProtectedWallpapers(t *testing.T) {
	var deleteQuery string

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == "GET" {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusOK)
			w.Write([]byte(`[{"wallpaper_id":"aaa-111"},{"wallpaper_id":"bbb-222"}]`))
			return
		}
		deleteQuery = r.URL.RawQuery
		w.WriteHeader(http.StatusNoContent)
	}))
	defer server.Close()

	cfg := config.Config{
		SupabaseURL:        server.URL,
		SupabaseServiceKey: "test-key",
	}

	CleanupOldWallpapers(cfg)

	if !strings.Contains(deleteQuery, "aaa-111") || !strings.Contains(deleteQuery, "bbb-222") {
		t.Errorf("Expected query to exclude protected wallpapers aaa-111 and bbb-222, got: %s", deleteQuery)
	}
}

func TestCleanupOldWallpapers_MoodboardProtection(t *testing.T) {
	var getRequests []string
	var deleteQuery string

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		getRequests = append(getRequests, r.URL.Path)
		if r.Method == "GET" {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusOK)
			if strings.Contains(r.URL.Path, "wishlists") {
				w.Write([]byte(`[{"wallpaper_id":"wish-111"}]`))
			} else if strings.Contains(r.URL.Path, "moodboard_items") {
				w.Write([]byte(`[{"wallpaper_id":"mood-222"}]`))
			} else {
				w.Write([]byte(`[]`))
			}
			return
		}
		deleteQuery = r.URL.RawQuery
		w.WriteHeader(http.StatusNoContent)
	}))
	defer server.Close()

	cfg := config.Config{
		SupabaseURL:        server.URL,
		SupabaseServiceKey: "test-key",
	}

	count, err := CleanupOldWallpapers(cfg)
	if err != nil {
		t.Fatalf("CleanupOldWallpapers failed: %v", err)
	}

	if count != 2 {
		t.Errorf("Expected 2 protected IDs, got %d", count)
	}

	if !strings.Contains(deleteQuery, "wish-111") {
		t.Error("Delete query should exclude wishlisted wallpaper wish-111")
	}
	if !strings.Contains(deleteQuery, "mood-222") {
		t.Error("Delete query should exclude moodboard wallpaper mood-222")
	}

	hasWishlistReq := false
	hasMoodboardReq := false
	for _, path := range getRequests {
		if strings.Contains(path, "wishlists") {
			hasWishlistReq = true
		}
		if strings.Contains(path, "moodboard_items") {
			hasMoodboardReq = true
		}
	}
	if !hasWishlistReq {
		t.Error("Expected a GET request to wishlists table")
	}
	if !hasMoodboardReq {
		t.Error("Expected a GET request to moodboard_items table")
	}
}

func TestCleanupOldWallpapers_SendsPreferHeader(t *testing.T) {
	var receivedHeaders http.Header

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		receivedHeaders = r.Header
		w.WriteHeader(http.StatusNoContent)
	}))
	defer server.Close()

	cfg := config.Config{
		SupabaseURL:        server.URL,
		SupabaseServiceKey: "test-key",
	}

	CleanupOldWallpapers(cfg)

	if receivedHeaders.Get("Prefer") != "return=minimal" {
		t.Errorf("Expected Prefer header 'return=minimal', got: %s", receivedHeaders.Get("Prefer"))
	}
}

func TestCleanupOldWallpapers_HandlesNoProtected(t *testing.T) {
	var receivedQuery string

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		receivedQuery = r.URL.RawQuery
		w.WriteHeader(http.StatusNoContent)
	}))
	defer server.Close()

	cfg := config.Config{
		SupabaseURL:        server.URL,
		SupabaseServiceKey: "test-key",
	}

	count, err := CleanupOldWallpapers(cfg)
	if err != nil {
		t.Fatalf("CleanupOldWallpapers failed: %v", err)
	}

	if count < 0 {
		t.Errorf("Count should be non-negative, got %d", count)
	}

	_ = receivedQuery
}

func TestCleanupOldWallpapers_HandlesSupabaseError(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(`{"message":"internal error"}`))
	}))
	defer server.Close()

	cfg := config.Config{
		SupabaseURL:        server.URL,
		SupabaseServiceKey: "test-key",
	}

	_, err := CleanupOldWallpapers(cfg)
	if err == nil {
		t.Error("Expected error for 500 response, got nil")
	}
}

func TestCleanupOldWallpapers_HandlesNetworkError(t *testing.T) {
	cfg := config.Config{
		SupabaseURL:        "http://localhost:1",
		SupabaseServiceKey: "test-key",
	}

	_, err := CleanupOldWallpapers(cfg)
	if err == nil {
		t.Error("Expected error for connection refused, got nil")
	}
}

func TestCleanupOldWallpapers_HandlesEmptyProtectedIDs(t *testing.T) {
	var receivedQuery string

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		receivedQuery = r.URL.RawQuery
		w.WriteHeader(http.StatusNoContent)
	}))
	defer server.Close()

	cfg := config.Config{
		SupabaseURL:        server.URL,
		SupabaseServiceKey: "test-key",
	}

	count, err := CleanupOldWallpapers(cfg)
	if err != nil {
		t.Fatalf("CleanupOldWallpapers failed: %v", err)
	}

	if count < 0 {
		t.Errorf("Count should be non-negative, got %d", count)
	}

	_ = receivedQuery
}

func TestCleanupRoute_ReturnsJSON(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	}))
	defer server.Close()

	cfg := config.Config{
		SupabaseURL:        server.URL,
		SupabaseServiceKey: "test-key",
	}

	app := setupTestApp(cfg)
	req := httptest.NewRequest("POST", "/api/v1/cleanup", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Failed to make request: %v", err)
	}

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status 200, got %d", resp.StatusCode)
	}

	body, _ := io.ReadAll(resp.Body)
	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		t.Fatalf("Failed to unmarshal response: %v", err)
	}

	if _, ok := result["status"]; !ok {
		t.Error("Response should have 'status' field")
	}
}

func TestCleanupRoute_HandlesCleanupError(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(`{"message":"error"}`))
	}))
	defer server.Close()

	cfg := config.Config{
		SupabaseURL:        server.URL,
		SupabaseServiceKey: "test-key",
	}

	app := setupTestApp(cfg)
	req := httptest.NewRequest("POST", "/api/v1/cleanup", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Failed to make request: %v", err)
	}

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status 200 even on cleanup error, got %d", resp.StatusCode)
	}
}
