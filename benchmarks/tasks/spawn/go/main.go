// SPAWN COST in Go: goroutines joined one at a time and all at once —
// user-space tasks the runtime schedules, never OS threads. Prints
// `spawn_fiber`/`spawn_fiber_alive` ns per task and `spawn_sum`; then
// `spawn_alive_cold`, the first all-at-once round alone, and the same
// all-at-once joined through a channel apiece, cold and warm.
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

func allAtOnce(n, rounds int) (float64, float64, int64) {
	best, first := 0.0, 0.0
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
		if r == 0 {
			first = spent
		}
		if r == 0 || spent < best {
			best = spent
		}
		sum = s
	}
	return first, best, sum
}

// allByChannel creates n goroutines alive at once and joins each through a channel of its own.
func allByChannel(n, rounds int) (float64, float64) {
	best, first := 0.0, 0.0
	for r := 0; r < rounds; r++ {
		t0 := time.Now()
		all := make([]chan int64, n)
		for i := range all {
			done := make(chan int64, 1)
			go func(i int) { done <- int64(i) * int64(i) }(i)
			all[i] = done
		}
		var s int64
		for _, d := range all {
			s += <-d
		}
		spent := float64(time.Since(t0).Nanoseconds())
		if r == 0 {
			first = spent
		}
		if r == 0 || spent < best {
			best = spent
		}
	}
	return first, best
}

func main() {
	n := envInt("BENCH_N", 10000)
	rounds := envInt("BENCH_ROUNDS", 5)
	one, sum1 := oneAtATime(n, rounds)
	cold, all, _ := allAtOnce(n, rounds)
	chanCold, chanWarm := allByChannel(n, rounds)
	fmt.Printf("spawn_fiber\t%.3f\tns\t%d\n", one/float64(n), rounds)
	fmt.Printf("spawn_fiber_alive\t%.3f\tns\t%d\n", all/float64(n), rounds)
	fmt.Printf("spawn_sum\t%d\tops\t%d\n", sum1, rounds)
	fmt.Printf("spawn_alive_cold\t%.3f\tns\t1\n", cold/float64(n))
	fmt.Printf("spawn_alive_chan_cold\t%.3f\tns\t1\n", chanCold/float64(n))
	fmt.Printf("spawn_alive_chan_warm\t%.3f\tns\t%d\n", chanWarm/float64(n), rounds)
}
