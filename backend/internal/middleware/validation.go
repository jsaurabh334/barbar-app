package middleware

import (
	"github.com/barbar-app/backend/internal/config"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
)

type PaginationParams struct {
	Page      int    `form:"page"`
	PageSize  int    `form:"page_size"`
	SortBy    string `form:"sort_by"`
	SortOrder string `form:"sort_order"`
}

func PaginationMiddleware() gin.HandlerFunc {
	cfg := config.Load()
	defaultPageSize := cfg.App.DefaultPageSize
	maxPageSize := cfg.App.MaxPageSize

	return func(c *gin.Context) {
		var params PaginationParams
		if err := c.ShouldBindQuery(&params); err != nil {
			c.Next()
			return
		}

		if params.Page < 1 {
			params.Page = 1
		}
		if params.PageSize < 1 || params.PageSize > maxPageSize {
			params.PageSize = defaultPageSize
		}
		if params.SortOrder != "asc" && params.SortOrder != "desc" {
			params.SortOrder = "desc"
		}

		c.Set("page", params.Page)
		c.Set("page_size", params.PageSize)
		c.Set("sort_by", params.SortBy)
		c.Set("sort_order", params.SortOrder)

		c.Next()
	}
}

type ValidateFunc func(c *gin.Context) (bool, string)

func ValidateRequest(validators ...ValidateFunc) gin.HandlerFunc {
	return func(c *gin.Context) {
		for _, v := range validators {
			if ok, msg := v(c); !ok {
				utils.BadRequestResponse(c, msg)
				c.Abort()
				return
			}
		}
		c.Next()
	}
}
