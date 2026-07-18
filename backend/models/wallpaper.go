package models

// WallhavenResponse is the top-level response from /api/v1/search
type WallhavenResponse struct {
	Data []WallhavenImage `json:"data"`
	Meta struct {
		CurrentPage int `json:"current_page"`
		LastPage    int `json:"last_page"`
		PerPage     int `json:"per_page"`
		Total       int `json:"total"`
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
