package notification

import (
	"bytes"
	"log"
	"text/template"

	"github.com/barbar-app/backend/internal/models"
	"gorm.io/gorm"
)

type TemplateService interface {
	GetTemplate(eventType models.NotificationType, lang string) (models.NotificationTemplate, bool)
	Compile(text string, data map[string]any) string
	Reload() error
}

type templateService struct {
	db        *gorm.DB
	templates map[models.NotificationType]map[string]models.NotificationTemplate
}

func NewTemplateService(db *gorm.DB) TemplateService {
	ts := &templateService{
		db:        db,
		templates: make(map[models.NotificationType]map[string]models.NotificationTemplate),
	}
	ts.Reload()
	return ts
}

func (s *templateService) Reload() error {
	var tmpls []models.NotificationTemplate
	if err := s.db.Where("is_active = ?", true).Find(&tmpls).Error; err != nil {
		log.Printf("TemplateService: failed to load templates: %v", err)
		return err
	}

	newMap := make(map[models.NotificationType]map[string]models.NotificationTemplate)
	for _, t := range tmpls {
		if newMap[t.Type] == nil {
			newMap[t.Type] = make(map[string]models.NotificationTemplate)
		}
		newMap[t.Type][t.Language] = t
	}
	s.templates = newMap
	log.Printf("TemplateService: loaded %d templates", len(tmpls))
	return nil
}

func (s *templateService) GetTemplate(eventType models.NotificationType, lang string) (models.NotificationTemplate, bool) {
	if s.templates[eventType] == nil {
		return models.NotificationTemplate{}, false
	}
	
	if lang == "" {
		lang = "en"
	}

	tmpl, ok := s.templates[eventType][lang]
	if ok {
		return tmpl, true
	}

	// Fallback to English if the requested language is not found
	tmpl, ok = s.templates[eventType]["en"]
	return tmpl, ok
}

func (s *templateService) Compile(text string, data map[string]any) string {
	if text == "" {
		return ""
	}
	
	tmpl, err := template.New("tmpl").Parse(text)
	if err != nil {
		log.Printf("TemplateService: failed to parse template: %v", err)
		return text
	}

	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, data); err != nil {
		log.Printf("TemplateService: failed to execute template: %v", err)
		return text
	}

	return buf.String()
}
