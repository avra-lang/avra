// A switch: two goroutines yielding to each other.
package main

import (
	"runtime"
	"sync"
	"time"

	"flowbench/internal/row"
)

func main() {
	n := row.Number("FLOW_N", 1000000)
	var wg sync.WaitGroup
	wg.Add(2)
	t0 := time.Now()
	for g := 0; g < 2; g++ {
		go func() {
			for i := 0; i < n; i++ {
				runtime.Gosched()
			}
			wg.Done()
		}()
	}
	wg.Wait()
	row.Say("switch", time.Since(t0).Nanoseconds(), 2*n)
}
