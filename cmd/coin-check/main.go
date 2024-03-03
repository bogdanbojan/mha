package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/caarlos0/env/v6"
)

type envVars struct {
	Port string `env:"PORT" envDefault:"8080"`

	PriceAPI string `env:"PRICE_API" envDefault:"https://min-api.cryptocompare.com/data/price?fsym=BTC&tsyms=USD"`

	SecondsPoll int `env:"SECONDS_POLL" envDefault:"10"`
	MinutesPoll int `env:"MINUTES_POLL" envDefault:"30"`
}

// service represents the main application.
// TODO: Think about using more channels.
// TODO: Maybe create a factory function for this.
type service struct {
	prices  []float64
	average float64

	log *log.Logger
	envVars
	// TODO: Keep a time window for the average.
	Window time.Time
}

type price struct {
	USD float64 `json:"USD"`
}

// AveragePrice is a Handler functions which responds with the average bitcoin
// price in the last 10 minutes.
func (s *service) AveragePrice(w http.ResponseWriter, r *http.Request) {
	bitcoinPriceAverage := strconv.FormatFloat(s.average, 'f', -1, 64)
	fmt.Fprintf(w, "average bitcoin price: %v \n", bitcoinPriceAverage)
}

// CurrentPrice is a Handler functions which responds with the current bitcoin
// price. The price is updated every 10 seconds.
func (s *service) CurrentPrice(w http.ResponseWriter, r *http.Request) {
	bitcoinPrice := strconv.FormatFloat(s.prices[len(s.prices)-1], 'f', -1, 64)
	fmt.Fprintf(w, "Current bitcoin price: %v \n", bitcoinPrice)
}

func (s *service) Avg() error {
	var sum = float64(0)
	values := s.prices
	if values == nil {
		return fmt.Errorf("no price data")
	}
	n := len(values)
	for _, value := range values {
		sum += value
	}

	s.average = sum / float64(n)
	s.log.Println("Calculated average: ", s.average)
	return nil
}

// CheckAverage polls the bitcoin price every 10 seconds.
func (s *service) CheckAverage() error {
	// TODO: Change this after to time.Minutes!!
	ticker := time.NewTicker(time.Duration(s.MinutesPoll) * time.Second)
	s.log.Println("CheckAverage started at", time.Now())
	defer ticker.Stop()
	for ; true; <-ticker.C {
		s.log.Println("Tick at", time.Now())
		s.Avg()
	}
	return nil

}

// CheckPrice polls the bitcoin price every 10 seconds.
func (s *service) CheckPrice() error {
	ticker := time.NewTicker(time.Duration(s.SecondsPoll) * time.Second)
	s.log.Println("CheckPrice started at", time.Now())
	defer ticker.Stop()
	for ; true; <-ticker.C {
		s.log.Println("Tick at", time.Now())
		resp, err := http.Get(s.PriceAPI)
		if err != nil {
			s.log.Println(err)
			return err
		}
		defer resp.Body.Close()

		b, err := io.ReadAll(resp.Body)
		if err != nil {
			s.log.Println(err)
			return err
		}

		var price price
		err = json.Unmarshal(b, &price)
		if err != nil {
			s.log.Println(err)
			return err
		}
		// TODO: Cap the array.
		s.prices = append(s.prices, price.USD)
		s.log.Println("Appended", price.USD)
	}
	return nil

}

func main() {
	envVars := envVars{}
	if err := env.Parse(&envVars); err != nil {
		log.Fatalf("failed to parse env vars: %v", err)
	}

	log := log.New(os.Stderr, "[coin-check] ", log.LstdFlags)

	s := service{
		envVars: envVars,
		log:     log,
	}

	// TODO: Think about machine limitations.
	go s.CheckPrice()
	go s.CheckAverage()

	http.HandleFunc("/average", s.AveragePrice)
	http.HandleFunc("/current", s.CurrentPrice)

	s.log.Println("Started on port", s.Port)

	err := http.ListenAndServe(":"+s.Port, nil)
	if err != nil {
		s.log.Fatal(err)
	}
}
