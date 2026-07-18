package models

import (
	"encoding/json"
	"testing"
)

func TestWallhavenResponse_Parse(t *testing.T) {
	jsonData := `{
		"data": [
			{
				"id": "94x38z",
				"path": "https://w.wallhaven.cc/full/94/wallhaven-94x38z.jpg",
				"resolution": "6742x3534",
				"file_size": 5070446,
				"dimension_x": 6742,
				"dimension_y": 3534,
				"category": "anime",
				"colors": ["#000000", "#abbcda", "#424153"],
				"thumbs": {
					"large": "https://th.wallhaven.cc/lg/94/94x38z.jpg",
					"original": "https://th.wallhaven.cc/orig/94/94x38z.jpg",
					"small": "https://th.wallhaven.cc/small/94/94x38z.jpg"
				}
			}
		],
		"meta": {
			"current_page": 1,
			"last_page": 36,
			"per_page": 24,
			"total": 848
		}
	}`

	var resp WallhavenResponse
	if err := json.Unmarshal([]byte(jsonData), &resp); err != nil {
		t.Fatalf("Failed to unmarshal WallhavenResponse: %v", err)
	}

	if len(resp.Data) != 1 {
		t.Fatalf("Expected 1 image, got %d", len(resp.Data))
	}

	img := resp.Data[0]

	tests := []struct {
		name     string
		got      interface{}
		expected interface{}
	}{
		{"ID", img.ID, "94x38z"},
		{"Path", img.Path, "https://w.wallhaven.cc/full/94/wallhaven-94x38z.jpg"},
		{"Resolution", img.Resolution, "6742x3534"},
		{"FileSize", img.FileSize, int64(5070446)},
		{"DimensionX", img.DimensionX, 6742},
		{"DimensionY", img.DimensionY, 3534},
		{"Category", img.Category, "anime"},
		{"Colors count", len(img.Colors), 3},
		{"First color", img.Colors[0], "#000000"},
		{"Thumb original", img.Thumbs.Original, "https://th.wallhaven.cc/orig/94/94x38z.jpg"},
		{"Meta total", int(resp.Meta.Total), 848},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if tt.got != tt.expected {
				t.Errorf("Got %v, expected %v", tt.got, tt.expected)
			}
		})
	}
}

func TestWallhavenResponse_EmptyData(t *testing.T) {
	jsonData := `{"data": [], "meta": {"current_page": 1, "last_page": 0, "per_page": 24, "total": 0}}`

	var resp WallhavenResponse
	if err := json.Unmarshal([]byte(jsonData), &resp); err != nil {
		t.Fatalf("Failed to unmarshal: %v", err)
	}

	if len(resp.Data) != 0 {
		t.Errorf("Expected empty data, got %d items", len(resp.Data))
	}
}

func TestWallhavenResponse_NoColors(t *testing.T) {
	jsonData := `{
		"data": [{
			"id": "abc123",
			"path": "https://example.com/image.jpg",
			"resolution": "1920x1080",
			"file_size": 1000000,
			"dimension_x": 1920,
			"dimension_y": 1080,
			"category": "general",
			"colors": [],
			"thumbs": {"large": "", "original": "", "small": ""}
		}],
		"meta": {"current_page": 1, "last_page": 1, "per_page": 24, "total": 1}
	}`

	var resp WallhavenResponse
	if err := json.Unmarshal([]byte(jsonData), &resp); err != nil {
		t.Fatalf("Failed to unmarshal: %v", err)
	}

	if len(resp.Data[0].Colors) != 0 {
		t.Errorf("Expected empty colors, got %d", len(resp.Data[0].Colors))
	}
}

func TestWallpaperInsert_Fields(t *testing.T) {
	wi := WallpaperInsert{
		WallhavenID:  "94x38z",
		URLFull:      "https://w.wallhaven.cc/full/94/wallhaven-94x38z.jpg",
		URLThumb:     "https://th.wallhaven.cc/orig/94/94x38z.jpg",
		Resolution:   "6742x3534",
		Width:        6742,
		Height:       3534,
		FileSize:     5070446,
		PrimaryColor: "#000000",
		Category:     "anime",
		SourceQuery:  "anime",
	}

	// Verify JSON serialization matches Supabase column names
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
