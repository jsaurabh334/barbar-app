package encryption

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"os"
)

var (
	masterKey []byte
)

func Init() error {
	keyHex := os.Getenv("ENCRYPTION_KEY")
	if keyHex == "" {
		return fmt.Errorf("ENCRYPTION_KEY environment variable is not set")
	}
	key, err := hex.DecodeString(keyHex)
	if err != nil {
		return fmt.Errorf("invalid ENCRYPTION_KEY hex: %w", err)
	}
	if len(key) != 32 {
		return fmt.Errorf("ENCRYPTION_KEY must be 32 bytes (64 hex chars), got %d bytes", len(key))
	}
	masterKey = key
	return nil
}

func Encrypt(plaintext string) (string, error) {
	if masterKey == nil {
		return "", errors.New("encryption not initialized")
	}
	if plaintext == "" {
		return "", nil
	}
	block, err := aes.NewCipher(masterKey)
	if err != nil {
		return "", fmt.Errorf("failed to create cipher: %w", err)
	}
	aesGCM, err := cipher.NewGCM(block)
	if err != nil {
		return "", fmt.Errorf("failed to create GCM: %w", err)
	}
	nonce := make([]byte, aesGCM.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return "", fmt.Errorf("failed to generate nonce: %w", err)
	}
	ciphertext := aesGCM.Seal(nonce, nonce, []byte(plaintext), nil)
	return hex.EncodeToString(ciphertext), nil
}

func Decrypt(cipherHex string) (string, error) {
	if masterKey == nil {
		return "", errors.New("encryption not initialized")
	}
	if cipherHex == "" {
		return "", nil
	}
	ciphertext, err := hex.DecodeString(cipherHex)
	if err != nil {
		return "", fmt.Errorf("invalid ciphertext hex: %w", err)
	}
	block, err := aes.NewCipher(masterKey)
	if err != nil {
		return "", fmt.Errorf("failed to create cipher: %w", err)
	}
	aesGCM, err := cipher.NewGCM(block)
	if err != nil {
		return "", fmt.Errorf("failed to create GCM: %w", err)
	}
	nonceSize := aesGCM.NonceSize()
	if len(ciphertext) < nonceSize {
		return "", errors.New("ciphertext too short")
	}
	nonce, ciphertext := ciphertext[:nonceSize], ciphertext[nonceSize:]
	plaintext, err := aesGCM.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return "", fmt.Errorf("failed to decrypt: %w", err)
	}
	return string(plaintext), nil
}
