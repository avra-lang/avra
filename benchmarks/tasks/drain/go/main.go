// BOUNDED-CHANNEL DRAIN in Go: a producer goroutine pushes n items into a
// buffered channel of capacity cap while this goroutine drains it. Prints
// the per-item cost at two sizes, their ratio, the throughput, the bytes
// moved, and the sum of every item.
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

func drainOnce(n, cap int) (float64, int64) {
	ch := make(chan int64, cap)
	t0 := time.Now()
	go func() {
		for i := 0; i < n; i++ {
			ch <- int64(i)
		}
		close(ch)
	}()
	var s int64
	for v := range ch {
		s += v
	}
	return float64(time.Since(t0).Nanoseconds()), s
}

func least(n, cap, rounds int) (float64, int64) {
	best := 0.0
	var sum int64
	for r := 0; r < rounds; r++ {
		d, s := drainOnce(n, cap)
		if r == 0 || d < best {
			best = d
		}
		sum = s
	}
	return best, sum
}

func main() {
	small := envInt("BENCH_SMALL", 1000)
	n := envInt("BENCH_N", 10000)
	cap := envInt("BENCH_CAP", 64)
	rounds := envInt("BENCH_ROUNDS", 5)
	d1, _ := least(small, cap, rounds)
	d2, sum := least(n, cap, rounds)
	per1 := d1 / float64(small)
	per2 := d2 / float64(n)
	fmt.Printf("drain_1k_ns_per_op\t%.4f\tns\t%d\n", per1, rounds)
	fmt.Printf("drain_10k_ns_per_op\t%.4f\tns\t%d\n", per2, rounds)
	fmt.Printf("drain_scale\t%.4f\tx\t%d\n", per2/per1, rounds)
	fmt.Printf("drain_ops_per_s\t%.0f\tops\t%d\n", float64(n)/(d2/1e9), rounds)
	fmt.Printf("drain_bytes\t%d\tbytes\t%d\n", n*8, rounds)
	fmt.Printf("drain_sum\t%d\tops\t%d\n", sum, rounds)
}
