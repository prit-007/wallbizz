package handlers

import (
	"fmt"
	"net/http"
	"net/url"
	"strings"

	"github.com/gofiber/fiber/v2"
)

var allowedImageHosts = []string{
	"w.wallhaven.cc",
	"th.wallhaven.cc",
}

func isAllowedImageHost(host string) bool {
	for _, allowed := range allowedImageHosts {
		if host == allowed {
			return true
		}
	}
	return false
}

// ProxyImage godoc
// @Summary Proxy an image from Wallhaven CDN
// @Description Proxies image requests to Wallhaven's CDN (w.wallhaven.cc, th.wallhaven.cc) to bypass CORS restrictions on Flutter web.
// @Tags proxy
// @Produce image/*
// @Param url query string true "Full image URL to proxy"
// @Success 200 {file} binary
// @Failure 400 {object} map[string]string
// @Failure 502 {object} map[string]string
// @Router /proxy-image [get]
func ProxyImage() func(*fiber.Ctx) error {
	return func(c *fiber.Ctx) error {
		imageURL := c.Query("url")
		if imageURL == "" {
			return c.Status(http.StatusBadRequest).JSON(fiber.Map{"error": "url parameter is required"})
		}

		parsed, err := url.Parse(imageURL)
		if err != nil || (parsed.Scheme != "http" && parsed.Scheme != "https") {
			return c.Status(http.StatusBadRequest).JSON(fiber.Map{"error": "invalid url"})
		}

		if !isAllowedImageHost(parsed.Host) {
			return c.Status(http.StatusForbidden).JSON(fiber.Map{
				"error": fmt.Sprintf("host not allowed: %s", parsed.Host),
			})
		}

		resp, err := httpClient.Get(imageURL)
		if err != nil {
			return c.Status(http.StatusBadGateway).JSON(fiber.Map{
				"error": fmt.Sprintf("failed to fetch image: %v", err),
			})
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			return c.Status(http.StatusBadGateway).JSON(fiber.Map{
				"error": fmt.Sprintf("upstream returned status %d", resp.StatusCode),
			})
		}

		contentType := resp.Header.Get("Content-Type")
		if contentType == "" {
			contentType = "image/jpeg"
		}

		// Only proxy image content types
		if !strings.HasPrefix(contentType, "image/") {
			return c.Status(http.StatusBadGateway).JSON(fiber.Map{
				"error": "response is not an image",
			})
		}

		c.Set("Content-Type", contentType)
		c.Set("Cache-Control", "public, max-age=86400")
		if contentLength := resp.Header.Get("Content-Length"); contentLength != "" {
			c.Set("Content-Length", contentLength)
		}
		return c.SendStream(resp.Body)
	}
}
