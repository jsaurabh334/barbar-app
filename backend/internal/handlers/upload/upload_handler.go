package upload

import (
	"fmt"
	"strings"

	"github.com/barbar-app/backend/internal/utils"
	"github.com/barbar-app/backend/internal/services/upload"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type UploadHandler struct {
	svc *upload.UploadService
	baseURL string
}

func NewUploadHandler(svc *upload.UploadService, baseURL string) *UploadHandler {
	return &UploadHandler{svc: svc, baseURL: strings.TrimRight(baseURL, "/")}
}

func (h *UploadHandler) UploadImage(c *gin.Context) {
	subDir := c.DefaultQuery("dir", "images")

	file, err := c.FormFile("file")
	if err != nil {
		utils.BadRequestResponse(c, "No file provided")
		return
	}

	result, err := h.svc.UploadFile(file, subDir)
	if err != nil {
		utils.BadRequestResponse(c, err.Error())
		return
	}

	publicURL := fmt.Sprintf("%s/%s", h.baseURL, result.Path)
	result.URL = publicURL

	utils.CreatedResponse(c, result)
}

func (h *UploadHandler) UploadMultipleImages(c *gin.Context) {
	subDir := c.DefaultQuery("dir", "images")

	form, err := c.MultipartForm()
	if err != nil {
		utils.BadRequestResponse(c, "Invalid multipart form")
		return
	}

	files := form.File["files"]
	if len(files) == 0 {
		utils.BadRequestResponse(c, "No files provided under 'files' key")
		return
	}

	results, err := h.svc.UploadMultiple(files, subDir)
	if err != nil {
		utils.BadRequestResponse(c, err.Error())
		return
	}

	for i := range results {
		results[i].URL = fmt.Sprintf("%s/%s", h.baseURL, results[i].Path)
	}

	utils.CreatedResponse(c, results)
}

func (h *UploadHandler) DeleteUploadedFile(c *gin.Context) {
	path := c.Query("path")
	if path == "" {
		utils.BadRequestResponse(c, "Path query parameter is required")
		return
	}

	if err := h.svc.DeleteFile(path); err != nil {
		utils.InternalErrorResponse(c, "Failed to delete file")
		return
	}

	utils.SuccessResponse(c, gin.H{"message": "File deleted"})
}

func (h *UploadHandler) UploadDoc(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	subDir := fmt.Sprintf("docs/%s", userID.String())

	file, err := c.FormFile("file")
	if err != nil {
		utils.BadRequestResponse(c, "No file provided")
		return
	}

	result, err := h.svc.UploadFile(file, subDir)
	if err != nil {
		utils.BadRequestResponse(c, err.Error())
		return
	}

	result.URL = fmt.Sprintf("%s/%s", h.baseURL, result.Path)
	utils.CreatedResponse(c, result)
}
