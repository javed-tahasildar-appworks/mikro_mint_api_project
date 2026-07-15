package main

import (
	"context"
	"fmt"
	"log"

	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {

	fmt.Println("Hello")
	fmt.Println("World")

	conn, err := pgxpool.New(context.Background(), "postgres://javedtahasildar:admin@localhost:5432/micro_fin_pro_db")
	if err != nil {
		log.Fatalf("Unable to connect: %v", err)
	}
	fmt.Println("✅ Connected successfully")
	conn.Close()

}
