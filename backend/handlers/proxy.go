package handlers

import (
	"fmt"
	"io"
	"net/http"

	"github.com/gofiber/fiber/v2"
)

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

		resp, err := httpClient.Get(imageURL)
		if err != nil {
			return c.Status(http.StatusBadGateway).JSON(fiber.Map{
				"error": fmt.Sprintf("failed to fetch image: %v", err),
			})
		}
		defer resp.Body.Close()

		body, err := io.ReadAll(resp.Body)
		if err != nil {
			return c.Status(http.StatusInternalServerError).JSON(fiber.Map{
				"error": "failed to read image response",
			})
		}

		contentType := resp.Header.Get("Content-Type")
		if contentType == "" {
			contentType = "image/jpeg"
		}

		c.Set("Content-Type", contentType)
		c.Set("Cache-Control", "public, max-age=86400")
		return c.Status(http.StatusOK).Send(body)
	}
}
