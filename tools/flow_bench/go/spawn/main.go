// Spawn and join: one at a time, then every task alive at once — joined
// through a WaitGroup and a slice, and again through a channel apiece.
package main

import (
	"sync"
	"time"

	"flowbench/internal/row"
)

func spawn(i int) chan int {
	done := make(chan int, 1)
	go func() { done <- i * i }()
	return done
}

func aliveChan(n int) int64 {
	t0 := time.Now()
	all := make([]chan int, n)
	for i := range all {
		all[i] = spawn(i)
	}
	sum := 0
	for _, t := range all {
		sum += <-t
	}
	return time.Since(t0).Nanoseconds()
}

func aliveGroup(n int) int64 {
	t0 := time.Now()
	out := make([]int, n)
	var wg sync.WaitGroup
	wg.Add(n)
	for i := 0; i < n; i++ {
		go func() {
			out[i] = i * i
			wg.Done()
		}()
	}
	wg.Wait()
	return time.Since(t0).Nanoseconds()
}

func least(n int, run func(int) int64) int64 {
	best := run(n)
	for r := 0; r < 4; r++ {
		if w := run(n); w < best {
			best = w
		}
	}
	return best
}

func main() {
	n := row.Number("FLOW_N", 10000)
	run := aliveGroup
	if row.Number("FLOW_CHAN", 0) == 1 {
		run = aliveChan
		row.Say("spawn_alive_cold_chan", run(n), n)
		row.Say("spawn_alive_warm_chan", least(n, run), n)
		return
	}
	cold := run(n)
	t0 := time.Now()
	sum := 0
	for i := 0; i < n; i++ {
		sum += <-spawn(i)
	}
	row.Say("spawn_one", time.Since(t0).Nanoseconds(), n)
	row.Say("spawn_alive_cold", cold, n)
	row.Say("spawn_alive_warm", least(n, run), n)
}
