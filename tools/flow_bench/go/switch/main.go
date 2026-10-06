// An explicit yield: two goroutines calling Gosched, which goes through
// the global run queue. A Go program hands off through channels; the
// round trip rows are that comparison.
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
	row.Say("yield_switch", time.Since(t0).Nanoseconds(), 2*n)
}
