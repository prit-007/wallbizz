package handlers

import (
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"

	"wallpaper-backend/config"
	"wallpaper-backend/logger"

	"github.com/gofiber/fiber/v2"
)

// SearchProxy godoc
// @Summary Search Wallhaven via proxy
// @Description Proxies search requests to Wallhaven. Auth is optional — if a valid JWT is provided it will be verified, otherwise the request is proxied without auth (SFW only).
// @Tags search
// @Accept json
// @Produce json
// @Param Authorization header string false "Bearer <JWT>"
// @Param q query string false "Search query"
// @Param categories query string false "Category filter (e.g. 010, 100, 111)"
// @Param purity query string false "Purity filter (100=SFW, 110=Sketchy, 111=NSFW)"
// @Param sorting query string false "Sort order (toplist, date, favorites, etc.)"
// @Param topRange query string false "Time range for toplist (1M, 3M, 6M, 1Y)"
// @Param ratios query string false "Aspect ratio filter (e.g. 16x9, 9x16)"
// @Param page query int false "Page number"
// @Success 200 {object} models.WallhavenResponse
// @Failure 401 {object} models.ErrorResponse
// @Failure 502 {object} models.ErrorResponse
// @Router /search [get]
func SearchProxy(cfg config.Config) func(*fiber.Ctx) error {
	return searchProxyHandler(cfg, wallhavenBaseURL)
}

func searchProxyHandler(cfg config.Config, wallhavenBase string) func(*fiber.Ctx) error {
	return func(c *fiber.Ctx) error {
		log := logger.Log()

		authHeader := c.Get("Authorization")
		if authHeader != "" && strings.HasPrefix(authHeader, "Bearer ") {
			token := strings.TrimPrefix(authHeader, "Bearer ")
			if err := verifySupabaseToken(cfg, token); err != nil {
				log.Warn().Err(err).Msg("Invalid JWT token — continuing without auth")
			}
		} else {
			log.Debug().Str("path", c.Path()).Msg("Search request without authorization (SFW proxy)")
		}

		query := c.Request().URI().QueryString()

		// Input validation: only allow known query parameters
		allowedParams := map[string]bool{
			"q": true, "categories": true, "purity": true, "sorting": true,
			"topRange": true, "ratios": true, "page": true, "seed": true,
		}
		parsedQuery, _ := url.ParseQuery(string(query))
		for key := range parsedQuery {
			if !allowedParams[key] {
				return c.Status(http.StatusBadRequest).JSON(fiber.Map{
					"error": fmt.Sprintf("disallowed query parameter: %s", key),
				})
			}
		}

		wallhavenURL := fmt.Sprintf("%s?apikey=%s", wallhavenBase, cfg.WallhavenAPIKey)
		if len(query) > 0 {
			wallhavenURL += "&" + string(query)
		}

		log.Info().Str("query", string(query)).Msg("Search proxy request")

		resp, err := httpClient.Get(wallhavenURL)
		if err != nil {
			log.Error().Err(err).Msg("Failed to reach Wallhaven")
			return c.Status(http.StatusBadGateway).JSON(fiber.Map{"error": "failed to reach wallhaven"})
		}
		defer resp.Body.Close()

		body, err := io.ReadAll(resp.Body)
		if err != nil {
			log.Error().Err(err).Msg("Failed to read Wallhaven response")
			return c.Status(http.StatusInternalServerError).JSON(fiber.Map{"error": "failed to read response"})
		}

		c.Set("Content-Type", "application/json")
		return c.Status(resp.StatusCode).Send(body)
	}
}

func verifySupabaseToken(cfg config.Config, token string) error {
	log := logger.Log()

	url := fmt.Sprintf("%s/auth/v1/user", cfg.SupabaseURL)
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("apikey", cfg.SupabaseServiceKey)

	resp, err := httpClient.Do(req)
	if err != nil {
		log.Error().Err(err).Msg("Supabase token verification request failed")
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("supabase returned %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}

	return nil
}

func setupSearchApp(cfg config.Config, mockWallhavenURL string) *fiber.App {
	app := fiber.New()
	v1 := app.Group("/api/v1")
	v1.Get("/search", searchProxyHandler(cfg, mockWallhavenURL))
	return app
}
