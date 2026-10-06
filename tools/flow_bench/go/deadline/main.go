// A deadline around a wait: the same round trip bare, then with a
// five-second context around each receive.
package main

import (
	"context"
	"time"

	"flowbench/internal/row"
)

func rally(n int, bounded bool) int64 {
	ping, pong := make(chan int), make(chan int)
	go func() {
		for v := range ping {
			pong <- v
		}
	}()
	t0 := time.Now()
	for i := 0; i < n; i++ {
		ping <- i
		if !bounded {
			<-pong
			continue
		}
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		select {
		case <-pong:
		case <-ctx.Done():
		}
		cancel()
	}
	close(ping)
	return time.Since(t0).Nanoseconds()
}

func main() {
	n := row.Number("FLOW_N", 200000)
	row.Say("deadline_bare", rally(n, false), n)
	row.Say("deadline_within", rally(n, true), n)
}
