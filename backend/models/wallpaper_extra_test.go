package models

import (
	"encoding/json"
	"testing"
)

func TestWallhavenResponse_MultipleImages(t *testing.T) {
	jsonData := `{
		"data": [
			{"id": "aaa111", "path": "https://example.com/1.jpg", "resolution": "1920x1080", "file_size": 1000000, "dimension_x": 1920, "dimension_y": 1080, "category": "general", "colors": ["#ff0000"], "thumbs": {"large": "", "original": "", "small": ""}},
			{"id": "bbb222", "path": "https://example.com/2.jpg", "resolution": "3840x2160", "file_size": 2000000, "dimension_x": 3840, "dimension_y": 2160, "category": "anime", "colors": ["#00ff00", "#0000ff"], "thumbs": {"large": "", "original": "", "small": ""}},
			{"id": "ccc333", "path": "https://example.com/3.jpg", "resolution": "1080x1920", "file_size": 500000, "dimension_x": 1080, "dimension_y": 1920, "category": "general", "colors": [], "thumbs": {"large": "", "original": "", "small": ""}}
		],
		"meta": {"current_page": 1, "last_page": 5, "per_page": 3, "total": 15}
	}`

	var resp WallhavenResponse
	if err := json.Unmarshal([]byte(jsonData), &resp); err != nil {
		t.Fatalf("Failed to unmarshal: %v", err)
	}

	if len(resp.Data) != 3 {
		t.Fatalf("Expected 3 images, got %d", len(resp.Data))
	}

	if resp.Data[0].ID != "aaa111" {
		t.Errorf("Wrong first ID: %s", resp.Data[0].ID)
	}
	if resp.Data[2].ID != "ccc333" {
		t.Errorf("Wrong third ID: %s", resp.Data[2].ID)
	}

	if resp.Meta.Total != 15 {
		t.Errorf("Wrong meta total: %d", resp.Meta.Total)
	}
	if resp.Meta.LastPage != 5 {
		t.Errorf("Wrong meta last_page: %d", resp.Meta.LastPage)
	}
	if resp.Meta.PerPage != 3 {
		t.Errorf("Wrong meta per_page: %d", resp.Meta.PerPage)
	}
}

func TestWallhavenResponse_MissingThumbs(t *testing.T) {
	jsonData := `{
		"data": [{"id": "x", "path": "p", "resolution": "r", "file_size": 0, "dimension_x": 0, "dimension_y": 0, "category": "general", "colors": ["#000000"], "thumbs": {}}],
		"meta": {"current_page": 1, "last_page": 1, "per_page": 24, "total": 1}
	}`

	var resp WallhavenResponse
	if err := json.Unmarshal([]byte(jsonData), &resp); err != nil {
		t.Fatalf("Failed to unmarshal: %v", err)
	}

	// Missing thumb fields should be zero-value strings
	if resp.Data[0].Thumbs.Large != "" {
		t.Errorf("Expected empty Large thumb, got: %s", resp.Data[0].Thumbs.Large)
	}
}

func TestWallhavenResponse_ZeroDimensions(t *testing.T) {
	jsonData := `{
		"data": [{"id": "z", "path": "", "resolution": "0x0", "file_size": 0, "dimension_x": 0, "dimension_y": 0, "category": "", "colors": [], "thumbs": {"large": "", "original": "", "small": ""}}],
		"meta": {"current_page": 1, "last_page": 1, "per_page": 24, "total": 1}
	}`

	var resp WallhavenResponse
	if err := json.Unmarshal([]byte(jsonData), &resp); err != nil {
		t.Fatalf("Failed to unmarshal: %v", err)
	}

	if resp.Data[0].DimensionX != 0 {
		t.Errorf("Expected 0 DimensionX, got %d", resp.Data[0].DimensionX)
	}
	if resp.Data[0].DimensionY != 0 {
		t.Errorf("Expected 0 DimensionY, got %d", resp.Data[0].DimensionY)
	}
}

func TestWallpaperInsert_EmptyValues(t *testing.T) {
	wi := WallpaperInsert{}
	data, err := json.Marshal(wi)
	if err != nil {
		t.Fatalf("Failed to marshal: %v", err)
	}

	var parsed map[string]interface{}
	if err := json.Unmarshal(data, &parsed); err != nil {
		t.Fatalf("Failed to unmarshal: %v", err)
	}

	// All fields should be present even with zero values
	expectedKeys := []string{
		"wallhaven_id", "url_full", "url_thumb", "resolution",
		"width", "height", "file_size", "primary_color",
		"category", "source_query",
	}

	for _, key := range expectedKeys {
		if _, ok := parsed[key]; !ok {
			t.Errorf("Missing key in empty WallpaperInsert: %s", key)
		}
	}

	// String fields should be empty
	if parsed["wallhaven_id"] != "" {
		t.Errorf("Expected empty wallhaven_id, got: %v", parsed["wallhaven_id"])
	}
	// Int fields should be 0
	if parsed["width"] != float64(0) {
		t.Errorf("Expected 0 width, got: %v", parsed["width"])
	}
}

func TestWallpaperInsert_LargeValues(t *testing.T) {
	wi := WallpaperInsert{
		WallhavenID:  "99999z",
		URLFull:      "https://w.wallhaven.cc/full/99/wallhaven-99999z.jpg",
		URLThumb:     "https://th.wallhaven.cc/orig/99/99999z.jpg",
		Resolution:   "7680x4320",
		Width:        7680,
		Height:       4320,
		FileSize:     2147483647,
		PrimaryColor: "#ffffff",
		Category:     "general",
		SourceQuery:  "trending",
	}

	data, err := json.Marshal(wi)
	if err != nil {
		t.Fatalf("Failed to marshal: %v", err)
	}

	var parsed map[string]interface{}
	if err := json.Unmarshal(data, &parsed); err != nil {
		t.Fatalf("Failed to unmarshal: %v", err)
	}

	if parsed["resolution"] != "7680x4320" {
		t.Errorf("Wrong resolution: %v", parsed["resolution"])
	}
	if parsed["file_size"] != float64(2147483647) {
		t.Errorf("Wrong file_size: %v", parsed["file_size"])
	}
}

func TestWallpaperInsert_SpecialCharactersInColor(t *testing.T) {
	wi := WallpaperInsert{
		WallhavenID:  "test",
		PrimaryColor: "#a1b2c3",
	}

	data, _ := json.Marshal(wi)
	var parsed map[string]interface{}
	json.Unmarshal(data, &parsed)

	if parsed["primary_color"] != "#a1b2c3" {
		t.Errorf("Wrong primary_color: %v", parsed["primary_color"])
	}
}

func TestWallhavenResponse_OnlyRequiredFields(t *testing.T) {
	jsonData := `{
		"data": [{"id": "minimal", "path": "", "resolution": "", "file_size": 0, "dimension_x": 0, "dimension_y": 0, "category": "", "colors": null, "thumbs": null}],
		"meta": {"current_page": 1, "last_page": 1, "per_page": 24, "total": 1}
	}`

	var resp WallhavenResponse
	if err := json.Unmarshal([]byte(jsonData), &resp); err != nil {
		t.Fatalf("Failed to unmarshal: %v", err)
	}

	if resp.Data[0].ID != "minimal" {
		t.Errorf("Wrong ID: %s", resp.Data[0].ID)
	}
}
