package db

import (
	"context"
	"fmt"
	"log"
	"time"

	"microfinpro/internal/config"

	"github.com/jackc/pgx/v5/pgxpool"
)

func ConnectPostgres(cfg *config.Config) *pgxpool.Pool {
	dsn := fmt.Sprintf(
		"postgres://%s:%s@%s:%s/%s?sslmode=%s",
		cfg.DBUser, cfg.DBPassword, cfg.DBHost, cfg.DBPort, cfg.DBName, cfg.DBSSLMode,
	)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		log.Fatalf("❌ Unable to connect to database: %v", err)
	}

	if err := pool.Ping(ctx); err != nil {
		log.Fatalf("❌ Unable to ping database: %v", err)
	}

	log.Println("✅ Connected to PostgreSQL database successfully")
	return pool
}
