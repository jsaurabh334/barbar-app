package firebase

import (
	"context"
	"log"
	"path/filepath"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

var (
	App           *firebase.App
	MessagingClient *messaging.Client
)

func InitFirebase(serviceAccountPath string) {
	ctx := context.Background()
	
	// If absolute path isn't provided, assume it's relative to project root
	absPath, err := filepath.Abs(serviceAccountPath)
	if err != nil {
		log.Printf("Failed to resolve firebase service account path: %v", err)
		return
	}

	opt := option.WithCredentialsFile(absPath)
	app, err := firebase.NewApp(ctx, nil, opt)
	if err != nil {
		log.Printf("Failed to initialize Firebase Admin SDK: %v\nWarning: Push notifications will not work.", err)
		return
	}

	client, err := app.Messaging(ctx)
	if err != nil {
		log.Printf("Failed to initialize Firebase Messaging Client: %v", err)
		return
	}

	App = app
	MessagingClient = client
	log.Println("Firebase Admin SDK initialized successfully")
}
