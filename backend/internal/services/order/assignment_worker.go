package order

import (
	"context"
	"log"
	"time"
)

func (s *OrderService) StartAssignmentWorker(ctx context.Context) {
	ticker := time.NewTicker(30 * time.Second)
	go func() {
		for {
			select {
			case <-ticker.C:
				expired, err := s.ExpireAssignments(ctx)
				if err != nil {
					log.Printf("Assignment expiry check error: %v", err)
				} else if expired > 0 {
					log.Printf("Expired %d stale assignments", expired)
				}
			case <-ctx.Done():
				ticker.Stop()
				return
			}
		}
	}()
}
