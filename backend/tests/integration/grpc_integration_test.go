package integration_test

import (
	"context"
	"log/slog"
	"net"
	"os"
	"testing"
	"time"

	pb "github.com/yourusername/tempconv/backend/gen/tempconv"
	"github.com/yourusername/tempconv/backend/internal/server"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

// startIntegrationServer starts a real gRPC server on a random port and returns a connected client.
func startIntegrationServer(t *testing.T) (pb.TempConverterClient, func()) {
	t.Helper()

	lis, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("failed to listen: %v", err)
	}

	logger := slog.New(slog.NewTextHandler(os.Stderr, nil))
	grpcSrv := grpc.NewServer()
	pb.RegisterTempConverterServer(grpcSrv, server.New(logger))

	go grpcSrv.Serve(lis) //nolint:errcheck

	//nolint:staticcheck
	conn, err := grpc.DialContext(
		context.Background(),
		lis.Addr().String(),
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		t.Fatalf("failed to dial: %v", err)
	}

	client := pb.NewTempConverterClient(conn)
	cleanup := func() {
		conn.Close()
		grpcSrv.GracefulStop()
	}
	return client, cleanup
}

func TestIntegration_CelsiusToFahrenheit(t *testing.T) {
	client, cleanup := startIntegrationServer(t)
	defer cleanup()

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	resp, err := client.CelsiusToFahrenheit(ctx, &pb.ConversionRequest{Value: 100})
	if err != nil {
		t.Fatalf("RPC error: %v", err)
	}
	if resp.Result != 212.0 {
		t.Errorf("expected 212.0°F, got %.6f", resp.Result)
	}
	if resp.Unit != "Fahrenheit" {
		t.Errorf("expected unit Fahrenheit, got %s", resp.Unit)
	}
}

func TestIntegration_FahrenheitToCelsius(t *testing.T) {
	client, cleanup := startIntegrationServer(t)
	defer cleanup()

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	resp, err := client.FahrenheitToCelsius(ctx, &pb.ConversionRequest{Value: 32})
	if err != nil {
		t.Fatalf("RPC error: %v", err)
	}
	if resp.Result != 0.0 {
		t.Errorf("expected 0.0°C, got %.6f", resp.Result)
	}
}

func TestIntegration_ConcurrentRequests(t *testing.T) {
	client, cleanup := startIntegrationServer(t)
	defer cleanup()

	const numRequests = 100
	results := make(chan error, numRequests)

	for i := 0; i < numRequests; i++ {
		go func(idx int) {
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()

			value := float64(idx) - 50 // range -50..49
			resp, err := client.CelsiusToFahrenheit(ctx, &pb.ConversionRequest{Value: value})
			if err != nil {
				results <- err
				return
			}
			// Verify correctness
			want := (value * 9.0 / 5.0) + 32.0
			diff := resp.Result - want
			if diff < -1e-4 || diff > 1e-4 {
				t.Errorf("idx %d: expected %.6f, got %.6f", idx, want, resp.Result)
			}
			results <- nil
		}(i)
	}

	for i := 0; i < numRequests; i++ {
		if err := <-results; err != nil {
			t.Errorf("concurrent request error: %v", err)
		}
	}
}
