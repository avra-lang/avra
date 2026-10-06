// Spawn and join: one at a time, then every task alive at once.
package main

import (
	"time"

	"flowbench/internal/row"
)

func spawn(i int) chan int {
	done := make(chan int, 1)
	go func() { done <- i * i }()
	return done
}

func alive(n int) int64 {
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

func main() {
	n := row.Number("FLOW_N", 10000)
	cold := alive(n)
	t0 := time.Now()
	sum := 0
	for i := 0; i < n; i++ {
		sum += <-spawn(i)
	}
	row.Say("spawn_one", time.Since(t0).Nanoseconds(), n)
	row.Say("spawn_alive_cold", cold, n)
	warm := alive(n)
	for r := 0; r < 4; r++ {
		if w := alive(n); w < warm {
			warm = w
		}
	}
	row.Say("spawn_alive_warm", warm, n)
}
