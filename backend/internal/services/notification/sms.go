package notification

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/barbar-app/backend/internal/config"
)

type SMSService struct {
	cfg *config.SMSConfig
}

func NewSMSService(cfg *config.SMSConfig) *SMSService {
	return &SMSService{cfg: cfg}
}

func (s *SMSService) Send(phone, message string) error {
	if s.cfg.AccountSID == "" || s.cfg.AuthToken == "" {
		log.Printf("[SMS DEV MODE] To: %s, Message: %s", phone, message)
		return nil
	}

	return s.sendViaTwilio(phone, message)
}

func (s *SMSService) sendViaTwilio(phone, message string) error {
	accountSID := s.cfg.AccountSID
	authToken := s.cfg.AuthToken
	from := s.cfg.FromNumber

	phone = ensureInternational(phone)

	reqBody := url.Values{}
	reqBody.Set("From", from)
	reqBody.Set("To", phone)
	reqBody.Set("Body", message)

	apiURL := fmt.Sprintf("https://api.twilio.com/2010-04-01/Accounts/%s/Messages.json", accountSID)
	req, err := http.NewRequest("POST", apiURL, bytes.NewBufferString(reqBody.Encode()))
	if err != nil {
		return err
	}
	req.SetBasicAuth(accountSID, authToken)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		var twilioErr struct {
			Message string `json:"message"`
			Code    int    `json:"code"`
		}
		json.NewDecoder(resp.Body).Decode(&twilioErr)
		return fmt.Errorf("twilio error (code %d): %s", twilioErr.Code, twilioErr.Message)
	}

	return nil
}

func (s *SMSService) SendOTP(phone, otp string) error {
	return s.Send(phone, fmt.Sprintf("Your Barbar App OTP is: %s. Valid for 5 minutes.", otp))
}

func ensureInternational(phone string) string {
	phone = strings.TrimSpace(phone)
	phone = strings.TrimPrefix(phone, "+")
	if !strings.HasPrefix(phone, "00") {
		phone = "+" + phone
	}
	return phone
}
