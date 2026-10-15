// PING-PONG in Go: two goroutines alternate over two unbuffered channels.
// Prints `pingpong_ns` per round trip and `pingpong_rounds`.
package main

import (
	"fmt"
	"os"
	"strconv"
	"time"
)

func envInt(name string, fallback int) int {
	if v, err := strconv.Atoi(os.Getenv(name)); err == nil {
		return v
	}
	return fallback
}

func rally(n int) float64 {
	ping := make(chan struct{})
	pong := make(chan struct{})
	done := make(chan struct{})
	go func() {
		for i := 0; i < n; i++ {
			<-ping
			pong <- struct{}{}
		}
		close(done)
	}()
	t0 := time.Now()
	for i := 0; i < n; i++ {
		ping <- struct{}{}
		<-pong
	}
	spent := float64(time.Since(t0).Nanoseconds())
	<-done
	return spent
}

func main() {
	n := envInt("BENCH_N", 100000)
	rounds := envInt("BENCH_ROUNDS", 5)
	best := 0.0
	for r := 0; r < rounds; r++ {
		s := rally(n)
		if r == 0 || s < best {
			best = s
		}
	}
	fmt.Printf("pingpong_ns\t%.3f\tns\t%d\n", best/float64(n), rounds)
	fmt.Printf("pingpong_rounds\t%d\tops\t%d\n", n, rounds)
}
