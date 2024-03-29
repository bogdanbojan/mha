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

// envVars represents the environment variables of the application.
type envVars struct {
	Port string `env:"PORT" envDefault:"8080"`

	PriceAPI string `env:"PRICE_API" envDefault:"https://min-api.cryptocompare.com/data/price?fsym=BTC&tsyms=USD"`

	SecondsPoll int `env:"SECONDS_POLL" envDefault:"10"`
	MinutesPoll int `env:"MINUTES_POLL" envDefault:"10"`
}

// service represents the main application.
type service struct {
	prices  []float64
	average float64

	log *log.Logger
	envVars
}

type price struct {
	USD float64 `json:"USD"`
}

// averagePrice is a Handler function which responds with the average bitcoin
// price in the last MINUTES_POLL.
func (s *service) averagePrice(w http.ResponseWriter, r *http.Request) {
	bitcoinPriceAverage := strconv.FormatFloat(s.average, 'f', -1, 64)
	fmt.Fprintf(w, "Average bitcoin price: %v \n", bitcoinPriceAverage)
}

// currentPrice is a Handler function which responds with the current bitcoin
// price. The price is updated every SECONDS_POLL.
func (s *service) currentPrice(w http.ResponseWriter, r *http.Request) {
	bitcoinPrice := strconv.FormatFloat(s.prices[len(s.prices)-1], 'f', -1, 64)
	fmt.Fprintf(w, "Current bitcoin price: %v \n", bitcoinPrice)
}

// avg calculates the average coin price based on the values existing in the array.
func (s *service) avg() error {
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

// checkAverage polls the bitcoin price every MINUTES_POLL.
func (s *service) checkAverage() error {
	ticker := time.NewTicker(time.Duration(s.MinutesPoll) * time.Minute)
	s.log.Println("checkAverage started at", time.Now())
	defer ticker.Stop()
	for ; true; <-ticker.C {
		s.log.Println("Tick at", time.Now())
		s.avg()
	}
	return nil

}

// checkPrice polls the bitcoin price every SECONDS_POLL.
func (s *service) checkPrice() error {
	ticker := time.NewTicker(time.Duration(s.SecondsPoll) * time.Second)
	s.log.Println("checkPrice started at", time.Now())
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
		if len(s.prices) == cap(s.prices) {
			// Maintain the cap with a FIFO.
			s.prices = s.prices[1:]
			s.prices = append(s.prices, price.USD)
			s.log.Printf("Appended == %v, \n The price: %v", len(s.prices), price.USD)
		} else {
			s.prices = append(s.prices, price.USD)
			s.log.Printf("Appended < %v, \n The price: %v", len(s.prices), price.USD)
		}
	}
	return nil

}

func main() {
	envVars := envVars{}
	if err := env.Parse(&envVars); err != nil {
		log.Fatalf("failed to parse env vars: %v", err)
	}

	log := log.New(os.Stderr, "[coin-check] ", log.LstdFlags)

	perMin := 60 / envVars.SecondsPoll
	arrCap := envVars.MinutesPoll * perMin

	s := service{
		prices:  make([]float64, 0, arrCap),
		envVars: envVars,
		log:     log,
	}

	go s.checkPrice()
	go s.checkAverage()

	http.HandleFunc("/average", s.averagePrice)
	http.HandleFunc("/current", s.currentPrice)

    s.log.Println("Started on port: ", s.Port)

	err := http.ListenAndServe(":"+s.Port, nil)
	if err != nil {
		s.log.Fatal(err)
	}
}
