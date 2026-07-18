package models

import (
	"encoding/json"
	"strconv"
)

// FlexInt accepts both JSON number and string when unmarshaling
type FlexInt int

func (f *FlexInt) UnmarshalJSON(data []byte) error {
	if len(data) == 0 {
		return nil
	}
	// Try number first
	if data[0] != '"' {
		var i int
		if err := json.Unmarshal(data, &i); err == nil {
			*f = FlexInt(i)
			return nil
		}
	}
	// Try string
	var s string
	if err := json.Unmarshal(data, &s); err != nil {
		return err
	}
	n, err := strconv.Atoi(s)
	if err != nil {
		return err
	}
	*f = FlexInt(n)
	return nil
}

// WallhavenResponse is the top-level response from /api/v1/search
type WallhavenResponse struct {
	Data []WallhavenImage `json:"data"`
	Meta struct {
		CurrentPage FlexInt `json:"current_page"`
		LastPage    FlexInt `json:"last_page"`
		PerPage     FlexInt `json:"per_page"`
		Total       FlexInt `json:"total"`
	} `json:"meta"`
}

// WallhavenImage represents a single wallpaper from the Wallhaven API
type WallhavenImage struct {
	ID         string   `json:"id"`
	Path       string   `json:"path"`
	Resolution string   `json:"resolution"`
	FileSize   int64    `json:"file_size"`
	DimensionX int      `json:"dimension_x"`
	DimensionY int      `json:"dimension_y"`
	Category   string   `json:"category"`
	Colors     []string `json:"colors"`
	Thumbs     struct {
		Large    string `json:"large"`
		Original string `json:"original"`
		Small    string `json:"small"`
	} `json:"thumbs"`
}

// WallpaperInsert maps directly to the Supabase wallpapers table columns
type WallpaperInsert struct {
	WallhavenID  string `json:"wallhaven_id"`
	URLFull      string `json:"url_full"`
	URLThumb     string `json:"url_thumb"`
	Resolution   string `json:"resolution"`
	Width        int    `json:"width"`
	Height       int    `json:"height"`
	FileSize     int64  `json:"file_size"`
	PrimaryColor string `json:"primary_color"`
	Category     string `json:"category"`
	SourceQuery  string `json:"source_query"`
}

// HealthResponse is the response for the health check endpoint
type HealthResponse struct {
	Status string `json:"status" example:"ok"`
}

// SyncResponse is the response for the manual sync trigger endpoint
type SyncResponse struct {
	Status string `json:"status" example:"sync triggered"`
}

// ErrorResponse is a generic error response
type ErrorResponse struct {
	Error string `json:"error" example:"something went wrong"`
}
