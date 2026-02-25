// Package server implements the TempConverter gRPC service.
package server

import (
	"context"
	"fmt"
	"log/slog"
	"math"

	pb "github.com/yourusername/tempconv/backend/gen/tempconv"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

const (
	maxTemperatureValue = 1e9  // Sanity cap for input values
	minTemperatureValue = -1e9 // Sanity cap for input values
)

// TempConverterServer implements pb.TempConverterServer.
type TempConverterServer struct {
	pb.UnimplementedTempConverterServer
	logger *slog.Logger
}

// New creates a new TempConverterServer.
func New(logger *slog.Logger) *TempConverterServer {
	return &TempConverterServer{logger: logger}
}

// CelsiusToFahrenheit converts a Celsius temperature to Fahrenheit.
// Formula: (°C × 9/5) + 32 = °F
func (s *TempConverterServer) CelsiusToFahrenheit(
	ctx context.Context, req *pb.ConversionRequest,
) (*pb.ConversionResponse, error) {
	if err := validateInput(req.GetValue()); err != nil {
		return nil, err
	}

	celsius := req.GetValue()
	fahrenheit := (celsius * 9.0 / 5.0) + 32.0
	fahrenheit = roundTo6Decimals(fahrenheit)

	s.logger.InfoContext(ctx, "CelsiusToFahrenheit",
		"input_celsius", celsius,
		"output_fahrenheit", fahrenheit,
	)

	return &pb.ConversionResponse{
		Result:  fahrenheit,
		Unit:    "Fahrenheit",
		Formula: fmt.Sprintf("(%.4f °C × 9/5) + 32 = %.6f °F", celsius, fahrenheit),
	}, nil
}

// FahrenheitToCelsius converts a Fahrenheit temperature to Celsius.
// Formula: (°F − 32) × 5/9 = °C
func (s *TempConverterServer) FahrenheitToCelsius(
	ctx context.Context, req *pb.ConversionRequest,
) (*pb.ConversionResponse, error) {
	if err := validateInput(req.GetValue()); err != nil {
		return nil, err
	}

	fahrenheit := req.GetValue()
	celsius := (fahrenheit - 32.0) * 5.0 / 9.0
	celsius = roundTo6Decimals(celsius)

	s.logger.InfoContext(ctx, "FahrenheitToCelsius",
		"input_fahrenheit", fahrenheit,
		"output_celsius", celsius,
	)

	return &pb.ConversionResponse{
		Result:  celsius,
		Unit:    "Celsius",
		Formula: fmt.Sprintf("(%.4f °F − 32) × 5/9 = %.6f °C", fahrenheit, celsius),
	}, nil
}

// validateInput checks that the temperature value is within acceptable bounds.
func validateInput(v float64) error {
	if math.IsNaN(v) || math.IsInf(v, 0) {
		return status.Errorf(codes.InvalidArgument, "temperature value must be a finite number")
	}
	if v < minTemperatureValue || v > maxTemperatureValue {
		return status.Errorf(codes.InvalidArgument,
			"temperature value %.2f is out of acceptable range [%.0f, %.0f]",
			v, minTemperatureValue, maxTemperatureValue,
		)
	}
	return nil
}

// roundTo6Decimals rounds a float64 to 6 decimal places.
func roundTo6Decimals(v float64) float64 {
	return math.Round(v*1_000_000) / 1_000_000
}
