// Bytes per parked task: FLOW_N goroutines blocked on one channel.
package main

import (
	"sync"

	"flowbench/internal/row"
)

func main() {
	n := row.Number("FLOW_N", 1000)
	rss, pte := row.Status("VmRSS:"), row.Status("VmPTE:")
	stop := make(chan struct{})
	var started, done sync.WaitGroup
	started.Add(n)
	done.Add(n)
	for i := 0; i < n; i++ {
		go func() {
			started.Done()
			<-stop
			done.Done()
		}()
	}
	started.Wait()
	row.Say("parked_rss", row.Status("VmRSS:")-rss, n)
	row.Say("parked_pte", row.Status("VmPTE:")-pte, n)
	close(stop)
	done.Wait()
}
