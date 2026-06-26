package utils

import "github.com/google/uuid"

func GenerateSlug(name string) string {
	result := make([]byte, 0, len(name))
	for _, c := range name {
		if c >= 'a' && c <= 'z' || c >= '0' && c <= '9' {
			result = append(result, byte(c))
		} else if c >= 'A' && c <= 'Z' {
			result = append(result, byte(c+32))
		} else if c == ' ' || c == '-' {
			result = append(result, '-')
		}
	}
	return string(result) + "-" + uuid.New().String()[:8]
}
