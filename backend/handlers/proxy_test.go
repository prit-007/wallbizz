package handlers

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gofiber/fiber/v2"
)

func TestIsAllowedImageHost_Allowed(t *testing.T) {
	tests := []struct {
		host string
		want bool
	}{
		{"w.wallhaven.cc", true},
		{"th.wallhaven.cc", true},
	}
	for _, tt := range tests {
		if got := isAllowedImageHost(tt.host); got != tt.want {
			t.Errorf("isAllowedImageHost(%q) = %v, want %v", tt.host, got, tt.want)
		}
	}
}

func TestIsAllowedImageHost_Disallowed(t *testing.T) {
	tests := []struct {
		host string
	}{
		{"evil.com"},
		{"wallhaven.cc"},
		{"w.wallhaven.cc.evil.com"},
		{"th.wallhaven.cc.malicious.net"},
	}
	for _, tt := range tests {
		if got := isAllowedImageHost(tt.host); got {
			t.Errorf("isAllowedImageHost(%q) = true, want false", tt.host)
		}
	}
}

func TestIsAllowedImageHost_Empty(t *testing.T) {
	if got := isAllowedImageHost(""); got {
		t.Errorf("isAllowedImageHost(\"\") = true, want false")
	}
}

func TestProxyImage_MissingURL(t *testing.T) {
	app := fiber.New()
	app.Get("/proxy-image", ProxyImage())

	req := httptest.NewRequest("GET", "/proxy-image", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}

	if resp.StatusCode != http.StatusBadRequest {
		body, _ := io.ReadAll(resp.Body)
		t.Errorf("Expected 400, got %d: %s", resp.StatusCode, string(body))
	}
}

func TestProxyImage_InvalidURL(t *testing.T) {
	app := fiber.New()
	app.Get("/proxy-image", ProxyImage())

	req := httptest.NewRequest("GET", "/proxy-image?url=not-a-url", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}

	if resp.StatusCode != http.StatusBadRequest {
		body, _ := io.ReadAll(resp.Body)
		t.Errorf("Expected 400, got %d: %s", resp.StatusCode, string(body))
	}
}

func TestProxyImage_DisallowedHost(t *testing.T) {
	app := fiber.New()
	app.Get("/proxy-image", ProxyImage())

	req := httptest.NewRequest("GET", "/proxy-image?url=https://evil.com/image.jpg", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}

	if resp.StatusCode != http.StatusForbidden {
		body, _ := io.ReadAll(resp.Body)
		t.Errorf("Expected 403, got %d: %s", resp.StatusCode, string(body))
	}
}

func TestProxyImage_UpstreamFailure(t *testing.T) {
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("internal error"))
	}))
	defer upstream.Close()

	original := allowedImageHosts
	allowedImageHosts = []string{"w.wallhaven.cc", "th.wallhaven.cc", strings.TrimPrefix(upstream.URL, "http://")}
	defer func() { allowedImageHosts = original }()

	app := fiber.New()
	app.Get("/proxy-image", ProxyImage())

	req := httptest.NewRequest("GET", "/proxy-image?url="+upstream.URL+"/full/ab/test.jpg", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}

	if resp.StatusCode != http.StatusBadGateway {
		body, _ := io.ReadAll(resp.Body)
		t.Errorf("Expected 502, got %d: %s", resp.StatusCode, string(body))
	}
}

func TestProxyImage_NonImageResponse(t *testing.T) {
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/html")
		w.Write([]byte("<html><body>not an image</body></html>"))
	}))
	defer upstream.Close()

	original := allowedImageHosts
	allowedImageHosts = []string{"w.wallhaven.cc", "th.wallhaven.cc", strings.TrimPrefix(upstream.URL, "http://")}
	defer func() { allowedImageHosts = original }()

	app := fiber.New()
	app.Get("/proxy-image", ProxyImage())

	req := httptest.NewRequest("GET", "/proxy-image?url="+upstream.URL+"/full/ab/test.html", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}

	if resp.StatusCode != http.StatusBadGateway {
		body, _ := io.ReadAll(resp.Body)
		t.Errorf("Expected 502, got %d: %s", resp.StatusCode, string(body))
	}
}

type fakeTransport struct{}

func (f *fakeTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	return &http.Response{
		StatusCode: http.StatusOK,
		Header:     http.Header{"Content-Type": {"image/jpeg"}, "Content-Length": {"6"}},
		Body:       io.NopCloser(strings.NewReader("\xff\xd8\xff\xe0\x00\x10")),
	}, nil
}

func TestProxyImage_Success(t *testing.T) {
	originalClient := httpClient
	originalHosts := allowedImageHosts

	httpClient = &http.Client{Transport: &fakeTransport{}}
	allowedImageHosts = []string{"w.wallhaven.cc", "th.wallhaven.cc"}
	defer func() {
		httpClient = originalClient
		allowedImageHosts = originalHosts
	}()

	app := fiber.New()
	app.Get("/proxy-image", ProxyImage())

	req := httptest.NewRequest("GET", "/proxy-image?url=https://w.wallhaven.cc/full/ab/test.jpg", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Expected 200, got %d: %s", resp.StatusCode, string(body))
	}

	ct := resp.Header.Get("Content-Type")
	if ct != "image/jpeg" {
		t.Errorf("Expected Content-Type image/jpeg, got %s", ct)
	}

	body, _ := io.ReadAll(resp.Body)
	if len(body) != 6 {
		t.Errorf("Expected body length 6, got %d", len(body))
	}

	cc := resp.Header.Get("Cache-Control")
	if cc != "public, max-age=86400" {
		t.Errorf("Expected Cache-Control 'public, max-age=86400', got %s", cc)
	}
}
