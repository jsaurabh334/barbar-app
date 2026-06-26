package upload

import (
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
)

var allowedMIMETypes = map[string]string{
	"image/jpeg":       ".jpg",
	"image/png":        ".png",
	"image/webp":       ".webp",
	"image/gif":        ".gif",
	"application/pdf":  ".pdf",
	"text/csv":         ".csv",
	"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": ".xlsx",
}

type UploadService struct {
	BasePath string
	MaxSize  int64
}

type UploadResult struct {
	URL        string `json:"url"`
	Path       string `json:"path"`
	FileName   string `json:"file_name"`
	Size       int64  `json:"size"`
	MIMEType   string `json:"mime_type"`
	Extension  string `json:"extension"`
}

type UploadOption func(*UploadService)

func WithBasePath(path string) UploadOption {
	return func(s *UploadService) {
		s.BasePath = path
	}
}

func WithMaxSize(maxSize int64) UploadOption {
	return func(s *UploadService) {
		s.MaxSize = maxSize
	}
}

func NewUploadService(opts ...UploadOption) *UploadService {
	s := &UploadService{
		BasePath: "uploads",
		MaxSize:  10 * 1024 * 1024, // 10MB default
	}
	for _, opt := range opts {
		opt(s)
	}
	return s
}

func (s *UploadService) UploadFile(file *multipart.FileHeader, subDir string) (*UploadResult, error) {
	if file.Size > s.MaxSize {
		return nil, fmt.Errorf("file size %d exceeds maximum %d", file.Size, s.MaxSize)
	}

	src, err := file.Open()
	if err != nil {
		return nil, fmt.Errorf("failed to open file: %w", err)
	}
	defer src.Close()

	buf := make([]byte, 512)
	if _, err := src.Read(buf); err != nil {
		return nil, fmt.Errorf("failed to read file header: %w", err)
	}
	src.Seek(0, io.SeekStart)

	mimeType := http.DetectContentType(buf)
	ext, allowed := allowedMIMETypes[mimeType]
	if !allowed {
		if file.Filename != "" {
			origExt := strings.ToLower(filepath.Ext(file.Filename))
			if origExt == ".jpg" || origExt == ".jpeg" || origExt == ".png" || origExt == ".pdf" {
				ext = origExt
			} else {
				return nil, fmt.Errorf("file type %s is not allowed", mimeType)
			}
		} else {
			return nil, fmt.Errorf("file type %s is not allowed", mimeType)
		}
	}

	uploadDir := filepath.Join(s.BasePath, subDir)
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create upload directory: %w", err)
	}

	fileName := fmt.Sprintf("%s_%s%s", time.Now().Format("20060102150405"), uuid.New().String()[:8], ext)
	filePath := filepath.Join(uploadDir, fileName)

	dst, err := os.Create(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to create file: %w", err)
	}
	defer dst.Close()

	written, err := io.Copy(dst, src)
	if err != nil {
		return nil, fmt.Errorf("failed to write file: %w", err)
	}

	return &UploadResult{
		URL:       filePath,
		Path:      filePath,
		FileName:  fileName,
		Size:      written,
		MIMEType:  mimeType,
		Extension: ext,
	}, nil
}

func (s *UploadService) UploadMultiple(files []*multipart.FileHeader, subDir string) ([]*UploadResult, error) {
	results := make([]*UploadResult, 0, len(files))
	for _, file := range files {
		result, err := s.UploadFile(file, subDir)
		if err != nil {
			return nil, fmt.Errorf("failed to upload %s: %w", file.Filename, err)
		}
		results = append(results, result)
	}
	return results, nil
}

func (s *UploadService) DeleteFile(path string) error {
	return os.Remove(path)
}
