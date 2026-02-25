package server_test

import (
	"context"
	"log/slog"
	"math"
	"os"
	"testing"

	pb "github.com/yourusername/tempconv/backend/gen/tempconv"
	"github.com/yourusername/tempconv/backend/internal/server"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func newTestServer() *server.TempConverterServer {
	logger := slog.New(slog.NewTextHandler(os.Stderr, nil))
	return server.New(logger)
}

// ---------------------------------------------------------------------------
// CelsiusToFahrenheit tests
// ---------------------------------------------------------------------------

func TestCelsiusToFahrenheit_Freezing(t *testing.T) {
	s := newTestServer()
	resp, err := s.CelsiusToFahrenheit(context.Background(), &pb.ConversionRequest{Value: 0})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if resp.Result != 32.0 {
		t.Errorf("0°C should be 32°F, got %.6f", resp.Result)
	}
	if resp.Unit != "Fahrenheit" {
		t.Errorf("expected unit Fahrenheit, got %s", resp.Unit)
	}
}

func TestCelsiusToFahrenheit_Boiling(t *testing.T) {
	s := newTestServer()
	resp, err := s.CelsiusToFahrenheit(context.Background(), &pb.ConversionRequest{Value: 100})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if resp.Result != 212.0 {
		t.Errorf("100°C should be 212°F, got %.6f", resp.Result)
	}
}

func TestCelsiusToFahrenheit_Negative(t *testing.T) {
	s := newTestServer()
	resp, err := s.CelsiusToFahrenheit(context.Background(), &pb.ConversionRequest{Value: -40})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	// -40°C == -40°F (the crossover point)
	if resp.Result != -40.0 {
		t.Errorf("-40°C should be -40°F, got %.6f", resp.Result)
	}
}

func TestCelsiusToFahrenheit_BodyTemp(t *testing.T) {
	s := newTestServer()
	resp, err := s.CelsiusToFahrenheit(context.Background(), &pb.ConversionRequest{Value: 37})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	want := 98.6
	if math.Abs(resp.Result-want) > 1e-5 {
		t.Errorf("37°C should be ~%.1f°F, got %.6f", want, resp.Result)
	}
}

// ---------------------------------------------------------------------------
// FahrenheitToCelsius tests
// ---------------------------------------------------------------------------

func TestFahrenheitToCelsius_Freezing(t *testing.T) {
	s := newTestServer()
	resp, err := s.FahrenheitToCelsius(context.Background(), &pb.ConversionRequest{Value: 32})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if resp.Result != 0.0 {
		t.Errorf("32°F should be 0°C, got %.6f", resp.Result)
	}
	if resp.Unit != "Celsius" {
		t.Errorf("expected unit Celsius, got %s", resp.Unit)
	}
}

func TestFahrenheitToCelsius_Boiling(t *testing.T) {
	s := newTestServer()
	resp, err := s.FahrenheitToCelsius(context.Background(), &pb.ConversionRequest{Value: 212})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if resp.Result != 100.0 {
		t.Errorf("212°F should be 100°C, got %.6f", resp.Result)
	}
}

func TestFahrenheitToCelsius_Crossover(t *testing.T) {
	s := newTestServer()
	resp, err := s.FahrenheitToCelsius(context.Background(), &pb.ConversionRequest{Value: -40})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if resp.Result != -40.0 {
		t.Errorf("-40°F should be -40°C, got %.6f", resp.Result)
	}
}

// ---------------------------------------------------------------------------
// Round-trip tests
// ---------------------------------------------------------------------------

func TestRoundTrip_CtoFtoC(t *testing.T) {
	s := newTestServer()
	values := []float64{-273.15, -100, -40, 0, 20, 37, 100, 500, 1000}
	for _, v := range values {
		respF, err := s.CelsiusToFahrenheit(context.Background(), &pb.ConversionRequest{Value: v})
		if err != nil {
			t.Fatalf("C->F error for %.2f: %v", v, err)
		}
		respC, err := s.FahrenheitToCelsius(context.Background(), &pb.ConversionRequest{Value: respF.Result})
		if err != nil {
			t.Fatalf("F->C error for %.2f: %v", respF.Result, err)
		}
		if math.Abs(respC.Result-v) > 1e-4 {
			t.Errorf("round-trip failed for %.2f°C: got %.6f°C after round-trip", v, respC.Result)
		}
	}
}

// ---------------------------------------------------------------------------
// Validation tests
// ---------------------------------------------------------------------------

func TestCelsiusToFahrenheit_NaN(t *testing.T) {
	s := newTestServer()
	_, err := s.CelsiusToFahrenheit(context.Background(), &pb.ConversionRequest{Value: math.NaN()})
	if err == nil {
		t.Fatal("expected error for NaN input, got nil")
	}
	st, _ := status.FromError(err)
	if st.Code() != codes.InvalidArgument {
		t.Errorf("expected InvalidArgument, got %v", st.Code())
	}
}

func TestCelsiusToFahrenheit_Inf(t *testing.T) {
	s := newTestServer()
	_, err := s.CelsiusToFahrenheit(context.Background(), &pb.ConversionRequest{Value: math.Inf(1)})
	if err == nil {
		t.Fatal("expected error for +Inf input, got nil")
	}
	st, _ := status.FromError(err)
	if st.Code() != codes.InvalidArgument {
		t.Errorf("expected InvalidArgument, got %v", st.Code())
	}
}

func TestCelsiusToFahrenheit_OutOfRange(t *testing.T) {
	s := newTestServer()
	_, err := s.CelsiusToFahrenheit(context.Background(), &pb.ConversionRequest{Value: 2e9})
	if err == nil {
		t.Fatal("expected error for out-of-range input, got nil")
	}
	st, _ := status.FromError(err)
	if st.Code() != codes.InvalidArgument {
		t.Errorf("expected InvalidArgument, got %v", st.Code())
	}
}
