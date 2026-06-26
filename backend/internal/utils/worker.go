package utils

import (
	"fmt"
	"log"
	"sync"
	"time"
)

type Job struct {
	ID       string
	Type     string
	Payload  interface{}
	Retries  int
	MaxRetries int
	Execute  func(interface{}) error
}

type WorkerPool struct {
	workers   int
	jobQueue  chan Job
	quit      chan struct{}
	wg        sync.WaitGroup
	mu        sync.Mutex
	running   map[string]bool
}

var DefaultPool *WorkerPool

func NewWorkerPool(workers int, queueSize int) *WorkerPool {
	pool := &WorkerPool{
		workers:  workers,
		jobQueue: make(chan Job, queueSize),
		quit:     make(chan struct{}),
		running:  make(map[string]bool),
	}
	pool.Start()
	DefaultPool = pool
	return pool
}

func (p *WorkerPool) Start() {
	for i := 0; i < p.workers; i++ {
		p.wg.Add(1)
		go p.worker(i)
	}
	log.Printf("Worker pool started with %d workers", p.workers)
}

func (p *WorkerPool) worker(id int) {
	defer p.wg.Done()
	for {
		select {
		case job := <-p.jobQueue:
			p.processJob(id, job)
		case <-p.quit:
			return
		}
	}
}

func (p *WorkerPool) processJob(workerID int, job Job) {
	defer func() {
		p.mu.Lock()
		delete(p.running, job.ID)
		p.mu.Unlock()
		if r := recover(); r != nil {
			log.Printf("Worker %d recovered from panic: %v", workerID, r)
		}
	}()

	for attempt := 0; attempt <= job.MaxRetries; attempt++ {
		err := job.Execute(job.Payload)
		if err == nil {
			return
		}
		log.Printf("Job %s failed (attempt %d/%d): %v", job.ID, attempt+1, job.MaxRetries+1, err)
		if attempt < job.MaxRetries {
			time.Sleep(time.Duration(attempt+1) * time.Second)
		}
	}
}

func (p *WorkerPool) Submit(job Job) {
	job.MaxRetries = 3
	job.ID = generateJobID()
	p.mu.Lock()
	p.running[job.ID] = true
	p.mu.Unlock()
	p.jobQueue <- job
}

func (p *WorkerPool) SubmitNamed(name string, fn func(interface{}) error, payload interface{}) {
	p.Submit(Job{
		Type:    name,
		Payload: payload,
		Execute: fn,
	})
}

func (p *WorkerPool) Shutdown() {
	close(p.quit)
	p.wg.Wait()
}

var jobCounter int64
var jobMu sync.Mutex

func generateJobID() string {
	jobMu.Lock()
	defer jobMu.Unlock()
	jobCounter++
	return fmt.Sprintf("job-%d", jobCounter)
}

type NotificationPayload struct {
	UserID string `json:"user_id"`
	Title  string `json:"title"`
	Body   string `json:"body"`
	Type   string `json:"type"`
}

type EmailPayload struct {
	To      string `json:"to"`
	Subject string `json:"subject"`
	Body    string `json:"body"`
}

type SMSPayload struct {
	Phone   string `json:"phone"`
	Message string `json:"message"`
}

type WebhookPayload struct {
	URL     string      `json:"url"`
	Event   string      `json:"event"`
	Payload interface{} `json:"payload"`
}
