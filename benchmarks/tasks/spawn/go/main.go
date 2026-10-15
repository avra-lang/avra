// SPAWN COST in Go: goroutines joined one at a time and all at once.
// Prints `spawn_one`/`spawn_alive` ns per task and `spawn_sum`.
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

func oneAtATime(n, rounds int) (float64, int64) {
	best := 0.0
	var sum int64
	for r := 0; r < rounds; r++ {
		t0 := time.Now()
		var s int64
		for i := 0; i < n; i++ {
			done := make(chan int64, 1)
			go func(i int) { done <- int64(i) * int64(i) }(i)
			s += <-done
		}
		spent := float64(time.Since(t0).Nanoseconds())
		if r == 0 || spent < best {
			best = spent
		}
		sum = s
	}
	return best, sum
}

func allAtOnce(n, rounds int) (float64, int64) {
	best := 0.0
	var sum int64
	for r := 0; r < rounds; r++ {
		t0 := time.Now()
		out := make([]int64, n)
		var wg sync.WaitGroup
		wg.Add(n)
		for i := 0; i < n; i++ {
			go func(i int) { out[i] = int64(i) * int64(i); wg.Done() }(i)
		}
		wg.Wait()
		var s int64
		for _, v := range out {
			s += v
		}
		spent := float64(time.Since(t0).Nanoseconds())
		if r == 0 || spent < best {
			best = spent
		}
		sum = s
	}
	return best, sum
}

func main() {
	n := envInt("BENCH_N", 10000)
	rounds := envInt("BENCH_ROUNDS", 5)
	one, sum1 := oneAtATime(n, rounds)
	all, _ := allAtOnce(n, rounds)
	fmt.Printf("spawn_one\t%.3f\tns\t%d\n", one/float64(n), rounds)
	fmt.Printf("spawn_alive\t%.3f\tns\t%d\n", all/float64(n), rounds)
	fmt.Printf("spawn_sum\t%d\tops\t%d\n", sum1, rounds)
}
