package main

import (
	"log"
	"net/http"
	"os"

	"github.com/caarlos0/env/v6"
)

// envVars represents the environment variables of the application.
type envVars struct {
	Port string `env:"PORT" envDefault:"8081"`
}

// service represents the main application.
type service struct {
	log *log.Logger
	envVars
}

// ok is a Handler function which responds with an OK Status.
func (s *service) ok(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	s.log.Println("Served request succesfully")
}

func main() {
	envVars := envVars{}
	if err := env.Parse(&envVars); err != nil {
		log.Fatalf("failed to parse env vars: %v", err)
	}
	log := log.New(os.Stderr, "[ok] ", log.LstdFlags)

	s := service{
		envVars: envVars,
		log:     log,
	}

	http.HandleFunc("/ok", s.ok)
	s.log.Println("Started on port", s.Port)

	err := http.ListenAndServe(":"+s.Port, nil)
	if err != nil {
		s.log.Fatal(err)
	}
}
