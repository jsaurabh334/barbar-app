package models

type CmsPageType string

const (
	CmsPageTypePage CmsPageType = "page"
	CmsPageTypeFAQ  CmsPageType = "faq"
)

type CmsPage struct {
	BaseModel
	Key         string      `gorm:"size:100;uniqueIndex;not null" json:"key"`
	Title       string      `gorm:"size:255;not null" json:"title"`
	Content     string      `gorm:"type:text;not null" json:"content"`
	Type        CmsPageType `gorm:"size:20;not null;default:'page';index" json:"type"`
	SortOrder   int         `gorm:"default:0" json:"sort_order"`
	IsPublished bool        `gorm:"default:true;index" json:"is_published"`
}
