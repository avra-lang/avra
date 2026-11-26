// Fan-in: N producers, one consumer; the time for FLOW_N items.
package main

import (
	"fmt"
	"time"

	"flowbench/internal/row"
)

func fanin(producers, items int) int64 {
	ch := make(chan int, 64)
	each := items / producers
	t0 := time.Now()
	for p := 0; p < producers; p++ {
		go func() {
			for i := 0; i < each; i++ {
				ch <- i
			}
		}()
	}
	for i := 0; i < each*producers; i++ {
		<-ch
	}
	return time.Since(t0).Nanoseconds()
}

func main() {
	n := row.Number("FLOW_N", 1048576)
	for _, p := range []int{1, 8, 64, 1024} {
		row.Say(fmt.Sprintf("fanin_%d", p), fanin(p, n), n/p*p)
	}
}
