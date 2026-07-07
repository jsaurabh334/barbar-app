package main

import (
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"image/png"
	"log"
	"os"
	"path/filepath"
)

var shopViews = map[int][]string{
	1:  {"exterior", "interior", "chair", "reception", "service"},
	2:  {"exterior", "interior", "reception", "wash-area", "haircut"},
	3:  {"exterior", "chair", "spa-room", "reception", "product-display"},
	4:  {"exterior", "interior", "chair", "waiting-area", "service"},
	5:  {"exterior", "chair", "reception", "service", "product-display"},
	6:  {"exterior", "interior", "spa-room", "chair", "reception"},
	7:  {"exterior", "chair", "reception", "haircut", "wash-area"},
	8:  {"exterior", "interior", "chair", "waiting-area", "service"},
	9:  {"exterior", "reception", "chair", "styling-area", "product-display"},
	10: {"exterior", "interior", "beard-station", "chair", "reception"},
	11: {"exterior", "chair", "reception", "service", "waiting-area"},
	12: {"exterior", "interior", "chair", "reception", "spa-room"},
	13: {"exterior", "chair", "reception", "service", "haircut"},
	14: {"exterior", "interior", "vip-room", "spa-room", "reception"},
	15: {"exterior", "chair", "reception", "service", "product-display"},
}

var viewColors = map[string]color.RGBA{
	"exterior":       {0x2E, 0xCC, 0x71, 0xFF},
	"interior":       {0x34, 0x98, 0xDB, 0xFF},
	"chair":          {0xE7, 0x4C, 0x3C, 0xFF},
	"reception":      {0xF3, 0x9C, 0x12, 0xFF},
	"service":        {0x9B, 0x59, 0xB6, 0xFF},
	"wash-area":      {0x1A, 0xBC, 0x9C, 0xFF},
	"haircut":        {0xE9, 0x1E, 0x63, 0xFF},
	"spa-room":       {0x00, 0xBC, 0xA0, 0xFF},
	"product-display": {0x8E, 0x44, 0xAD, 0xFF},
	"waiting-area":   {0x27, 0xAE, 0x60, 0xFF},
	"styling-area":   {0x29, 0x80, 0xB9, 0xFF},
	"beard-station":  {0xD3, 0x54, 0x00, 0xFF},
	"vip-room":       {0x8E, 0x44, 0xAD, 0xFF},
}

func generateDemoImages(outputDir string, shopNames []string) {
	const width, height = 800, 600

	for shopID := 1; shopID <= len(shopNames); shopID++ {
		views, ok := shopViews[shopID]
		if !ok {
			views = shopViews[1]
		}

		for _, view := range views {
			clr, ok := viewColors[view]
			if !ok {
				clr = color.RGBA{0x95, 0xA5, 0xA6, 0xFF}
			}

			img := createLabeledImage(width, height, clr, shopNames[shopID-1], view)
			filename := fmt.Sprintf("%s/shop%d-%s.png", outputDir, shopID, view)
			savePNG(img, filename)
			log.Printf("  Generated: shop%d-%s.png", shopID, view)
		}
	}
	log.Printf("Total images generated: %d", countImages(shopNames))
}

func createLabeledImage(w, h int, bgColor color.RGBA, shopName, view string) *image.RGBA {
	img := image.NewRGBA(image.Rect(0, 0, w, h))
	draw.Draw(img, img.Bounds(), &image.Uniform{bgColor}, image.Point{}, draw.Src)

	// Draw a darker stripe at the bottom for text
	stripeColor := color.RGBA{0, 0, 0, 100}
	for y := h - 80; y < h; y++ {
		for x := 0; x < w; x++ {
			img.Set(x, y, stripeColor)
		}
	}

	// Draw a semi-transparent overlay in center
	overlayColor := color.RGBA{0, 0, 0, 40}
	overlayRect := image.Rect(w/4, h/3, 3*w/4, 2*h/3)
	draw.Draw(img, overlayRect, &image.Uniform{overlayColor}, image.Point{}, draw.Src)

	// Add placeholder text using basic font
	// Draw simple rectangles as "image" placeholders
	drawPlaceholderRects(img, w, h)

	return img
}

func drawPlaceholderRects(img *image.RGBA, w, h int) {
	// Draw a few decorative rectangles to simulate furniture/scenery
	rects := []struct {
		x, y, rw, rh int
		clr          color.RGBA
	}{
		{w/2 - 150, h/4, 120, 180, color.RGBA{255, 255, 255, 60}},
		{w/2 + 30, h/4, 120, 180, color.RGBA{255, 255, 255, 40}},
		{w/2 - 100, h/4 + 200, 200, 30, color.RGBA{255, 255, 255, 30}},
	}

	for _, r := range rects {
		for y := r.y; y < r.y+r.rh && y < h; y++ {
			for x := r.x; x < r.x+r.rw && x < w; x++ {
				img.Set(x, y, r.clr)
			}
		}
	}
}

func savePNG(img image.Image, filename string) {
	_ = os.MkdirAll(filepath.Dir(filename), 0755)
	f, err := os.Create(filename)
	if err != nil {
		log.Fatalf("Failed to create image %s: %v", filename, err)
	}
	defer f.Close()
	if err := png.Encode(f, img); err != nil {
		log.Fatalf("Failed to encode image %s: %v", filename, err)
	}
}

func countImages(names []string) int {
	count := 0
	for shopID := 1; shopID <= len(names); shopID++ {
		views, ok := shopViews[shopID]
		if !ok {
			views = shopViews[1]
		}
		count += len(views)
	}
	return count
}


