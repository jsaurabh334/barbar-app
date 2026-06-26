package utils

import (
    "net/http"
    "strconv"

    "github.com/barbar-app/backend/internal/config"
    "github.com/gin-gonic/gin"
)

// Status constants used in API responses
const (
    StatusSuccess = "success"
    StatusCreated = "created"
    StatusError   = "error"
)

// Response is the generic API response wrapper
type Response struct {
    Status  string      `json:"status"`
    Message string      `json:"message,omitempty"`
    Data    interface{} `json:"data,omitempty"`
    Error   string      `json:"error,omitempty"`
    Meta    *APIMeta    `json:"meta,omitempty"`
}

// APIMeta provides pagination/meta information
type APIMeta struct {
    Page    int   `json:"page,omitempty"`
    Limit   int   `json:"limit,omitempty"`
    Total   int64 `json:"total,omitempty"`
    Version string `json:"version,omitempty"`
}

func SuccessResponse(c *gin.Context, data interface{}) {
    c.JSON(http.StatusOK, Response{Status: StatusSuccess, Data: data})
}

func CreatedResponse(c *gin.Context, data interface{}) {
    c.JSON(http.StatusCreated, Response{Status: StatusCreated, Data: data})
}

func PaginatedResponse(c *gin.Context, data interface{}, page, pageSize int, total int64) {
    meta := &APIMeta{Page: page, Limit: pageSize, Total: total}
    c.JSON(http.StatusOK, Response{Status: StatusSuccess, Data: data, Meta: meta})
}

func ErrorResponse(c *gin.Context, status int, message string) {
    c.JSON(status, Response{Status: StatusError, Error: message})
}

func BadRequestResponse(c *gin.Context, message string) {
    ErrorResponse(c, http.StatusBadRequest, message)
}

func NotFoundResponse(c *gin.Context, message string) {
    ErrorResponse(c, http.StatusNotFound, message)
}

func UnauthorizedResponse(c *gin.Context, message string) {
    ErrorResponse(c, http.StatusUnauthorized, message)
}

func ForbiddenResponse(c *gin.Context, message string) {
    ErrorResponse(c, http.StatusForbidden, message)
}

func InternalErrorResponse(c *gin.Context, message string) {
    ErrorResponse(c, http.StatusInternalServerError, message)
}

func ValidationErrorResponse(c *gin.Context, errors interface{}) {
    c.JSON(http.StatusUnprocessableEntity, gin.H{"success": false, "errors": errors})
}

func GetPageParams(c *gin.Context) (int, int) {
    cfg := config.Load()
    page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
    if page < 1 {
        page = 1
    }
    pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", strconv.Itoa(cfg.App.DefaultPageSize)))
    if pageSize < 1 {
        pageSize = cfg.App.DefaultPageSize
    }
    if pageSize > cfg.App.MaxPageSize {
        pageSize = cfg.App.MaxPageSize
    }
    return page, pageSize
}
