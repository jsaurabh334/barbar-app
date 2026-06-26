package notification

import (
	"bytes"
	"fmt"
	"log"
	"net/smtp"
	"text/template"
	"time"

	"github.com/barbar-app/backend/internal/config"
)

type EmailService struct {
	cfg *config.SMTPConfig
}

func NewEmailService(cfg *config.SMTPConfig) *EmailService {
	return &EmailService{cfg: cfg}
}

func (s *EmailService) Send(to, subject, body string) error {
	if s.cfg.Password == "" {
		log.Printf("[EMAIL DEV MODE] To: %s, Subject: %s, Body: %s", to, subject, body)
		return nil
	}

	from := s.cfg.From
	addr := fmt.Sprintf("%s:%d", s.cfg.Host, s.cfg.Port)

	msg := buildMIMEMessage(from, to, subject, body)
	return smtp.SendMail(addr, smtp.PlainAuth("", s.cfg.Username, s.cfg.Password, s.cfg.Host), from, []string{to}, []byte(msg))
}

func (s *EmailService) SendWithTemplate(to, subject, tmpl string, data interface{}) error {
	t, err := template.New("email").Parse(tmpl)
	if err != nil {
		return err
	}

	var body bytes.Buffer
	if err := t.Execute(&body, data); err != nil {
		return err
	}

	return s.Send(to, subject, body.String())
}

func buildMIMEMessage(from, to, subject, body string) string {
	headers := make(map[string]string)
	headers["From"] = from
	headers["To"] = to
	headers["Subject"] = subject
	headers["MIME-Version"] = "1.0"
	headers["Content-Type"] = "text/html; charset=UTF-8"
	headers["Date"] = time.Now().Format(time.RFC1123Z)

	msg := ""
	for k, v := range headers {
		msg += fmt.Sprintf("%s: %s\r\n", k, v)
	}
	msg += "\r\n" + body
	return msg
}

func (s *EmailService) SendOTPEmail(to, otp string) error {
	subject := "Your OTP for Barbar App"
	body := fmt.Sprintf(`<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="font-family: Arial, sans-serif; background: #f4f4f4; padding: 20px;">
<div style="max-width: 480px; margin: 0 auto; background: #fff; border-radius: 8px; padding: 24px;">
<h2 style="color: #333;">Barbar App</h2>
<p>Your one-time password is:</p>
<div style="font-size: 32px; font-weight: bold; text-align: center; padding: 16px; background: #f8f8f8; border-radius: 6px; letter-spacing: 8px;">%s</div>
<p style="color: #666; font-size: 13px;">This OTP is valid for 5 minutes.</p>
<p style="color: #666; font-size: 13px;">If you did not request this, please ignore this email.</p>
</div>
</body>
</html>`, otp)
	return s.Send(to, subject, body)
}

func (s *EmailService) SendPasswordReset(to, otp string) error {
	subject := "Password Reset Request - Barbar App"
	body := fmt.Sprintf(`<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="font-family: Arial, sans-serif; background: #f4f4f4; padding: 20px;">
<div style="max-width: 480px; margin: 0 auto; background: #fff; border-radius: 8px; padding: 24px;">
<h2 style="color: #333;">Barbar App</h2>
<p>You requested a password reset. Use this OTP:</p>
<div style="font-size: 32px; font-weight: bold; text-align: center; padding: 16px; background: #f8f8f8; border-radius: 6px; letter-spacing: 8px;">%s</div>
<p style="color: #666; font-size: 13px;">This OTP is valid for 5 minutes.</p>
</div>
</body>
</html>`, otp)
	return s.Send(to, subject, body)
}

func (s *EmailService) SendBookingConfirmation(to, customerName, shopName string, scheduledTime time.Time) error {
	subject := "Booking Confirmed - Barbar App"
	body := fmt.Sprintf(`<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="font-family: Arial, sans-serif; background: #f4f4f4; padding: 20px;">
<div style="max-width: 480px; margin: 0 auto; background: #fff; border-radius: 8px; padding: 24px;">
<h2 style="color: #333;">Booking Confirmed!</h2>
<p>Hi %s,</p>
<p>Your booking at <strong>%s</strong> is confirmed for:</p>
<div style="font-size: 18px; font-weight: bold; padding: 12px; background: #e8f5e9; border-radius: 6px;">%s</div>
<p style="color: #666; font-size: 13px;">Please arrive on time. You can track your queue position in the app.</p>
</div>
</body>
</html>`, customerName, shopName, scheduledTime.Format("Mon, Jan 2 at 3:04 PM"))
	return s.Send(to, subject, body)
}
