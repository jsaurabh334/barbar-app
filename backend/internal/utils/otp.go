package utils

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"fmt"
	"math/big"
	"os"
)

var otpPepper = func() string {
	if p := os.Getenv("OTP_PEPPER"); p != "" {
		return p
	}
	return "barbar-otp-pepper-v1"
}()

// GenerateOTP returns a cryptographically secure numeric OTP of the given length.
func GenerateOTP(length int) string {
	if length <= 0 {
		length = 6
	}
	max := new(big.Int).Exp(big.NewInt(10), big.NewInt(int64(length)), nil)
	n, err := rand.Int(rand.Reader, max)
	if err != nil {
		// Fall back to the zero-padded low bits on entropy failure (should not happen).
		return fmt.Sprintf("%0*d", length, 0)
	}
	return fmt.Sprintf("%0*d", length, n.Int64())
}

// HashOTP returns the HMAC-SHA256 digest of an OTP using the shared pepper.
func HashOTP(otp string) string {
	mac := hmac.New(sha256.New, []byte(otpPepper))
	mac.Write([]byte(otp))
	return hex.EncodeToString(mac.Sum(nil))
}

// VerifyOTP performs a constant-time comparison between the stored hash and the
// hash of the supplied code.
func VerifyOTP(hash, code string) bool {
	if hash == "" || code == "" {
		return false
	}
	return subtle.ConstantTimeCompare([]byte(hash), []byte(HashOTP(code))) == 1
}
