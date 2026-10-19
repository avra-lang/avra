// FAN-IN in Go: n_producers goroutines push values into one buffered
// channel while this goroutine drains it until the senders close it.
// Prints the per-value cost and the received/dropped counts.
package main

import (
	"fmt"
	"os"
	"strconv"
	"sync"
	"time"
)

func envInt(name string, fallback int) int {
	if v, err := strconv.Atoi(os.Getenv(name)); err == nil {
		return v
	}
	return fallback
}

func faninOnce(producers, per, cap int) (float64, int64, int64) {
	ch := make(chan int64, cap)
	var wg sync.WaitGroup
	wg.Add(producers)
	t0 := time.Now()
	for p := 0; p < producers; p++ {
		go func(p int) {
			for j := 0; j < per; j++ {
				ch <- int64(p*per + j)
			}
			wg.Done()
		}(p)
	}
	go func() { wg.Wait(); close(ch) }()
	var s, got int64
	for v := range ch {
		s += v
		got++
	}
	return float64(time.Since(t0).Nanoseconds()), s, got
}

func main() {
	producers := envInt("BENCH_PRODUCERS", 8)
	per := envInt("BENCH_PER", 6250)
	cap := envInt("BENCH_CAP", 64)
	rounds := envInt("BENCH_ROUNDS", 5)
	total := producers * per
	best := 0.0
	var got int64
	for r := 0; r < rounds; r++ {
		d, _, g := faninOnce(producers, per, cap)
		if r == 0 || d < best {
			best = d
		}
		got = g
	}
	fmt.Printf("fanin_ns_per_op\t%.4f\tns\t%d\n", best/float64(total), rounds)
	fmt.Printf("fanin_received\t%d\tops\t%d\n", got, rounds)
	fmt.Printf("fanin_dropped\t%d\tops\t%d\n", int64(total)-got, rounds)
}
