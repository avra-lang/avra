// Ten thousand tasks alive AND parked: each has yielded once before any
// is joined. Cold first, then the least of five.
package main

import (
	"runtime"
	"sync"
	"time"

	"flowbench/internal/row"
)

func parked(n int) int64 {
	t0 := time.Now()
	var wg sync.WaitGroup
	wg.Add(n)
	for i := 0; i < n; i++ {
		go func() {
			runtime.Gosched()
			wg.Done()
		}()
	}
	wg.Wait()
	return time.Since(t0).Nanoseconds()
}

func main() {
	n := row.Number("FLOW_N", 10000)
	row.Say("spawn_parked_cold", parked(n), n)
	best := parked(n)
	for r := 0; r < 4; r++ {
		if w := parked(n); w < best {
			best = w
		}
	}
	row.Say("spawn_parked_warm", best, n)
}
