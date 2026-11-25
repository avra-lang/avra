// Ping-pong: two goroutines, a round trip over a rendezvous and over a
// buffered channel.
package main

import (
	"time"

	"flowbench/internal/row"
)

func rally(capacity, n int) int64 {
	ping, pong := make(chan int, capacity), make(chan int, capacity)
	go func() {
		for v := range ping {
			pong <- v
		}
		close(pong)
	}()
	t0 := time.Now()
	for i := 0; i < n; i++ {
		ping <- i
		<-pong
	}
	close(ping)
	return time.Since(t0).Nanoseconds()
}

func main() {
	n := row.Number("FLOW_N", 1000000)
	row.Say("pingpong_rendezvous", rally(0, n), n)
	row.Say("pingpong_buffered", rally(1, n), n)
}
