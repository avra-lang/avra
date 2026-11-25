// A deadline around a wait: the same round trip bare, with one reused
// time.Timer reset around each receive (how a hot loop spells it), and
// with a context made per wait (how a request spells it).
package main

import (
	"context"
	"time"

	"flowbench/internal/row"
)

const (
	bare = iota
	timer
	perWait
)

func rally(n int, how int) int64 {
	ping, pong := make(chan int), make(chan int)
	go func() {
		for v := range ping {
			pong <- v
		}
	}()
	limit := time.NewTimer(time.Hour)
	t0 := time.Now()
	for i := 0; i < n; i++ {
		ping <- i
		switch how {
		case bare:
			<-pong
		case timer:
			limit.Reset(5 * time.Second)
			select {
			case <-pong:
			case <-limit.C:
			}
			limit.Stop()
		case perWait:
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			select {
			case <-pong:
			case <-ctx.Done():
			}
			cancel()
		}
	}
	close(ping)
	return time.Since(t0).Nanoseconds()
}

func main() {
	n := row.Number("FLOW_N", 200000)
	row.Say("deadline_bare", rally(n, bare), n)
	row.Say("deadline_within", rally(n, timer), n)
	row.Say("deadline_within_context", rally(n, perWait), n)
}
