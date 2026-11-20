// Cancel of a tree of tasks: fan-out 10, four levels (11110 tasks),
// each parked on its own child context; the root is cancelled and
// every task is joined.
package main

import (
	"context"
	"sync"
	"time"

	"flowbench/internal/row"
)

func grow(ctx context.Context, depth int, started, done *sync.WaitGroup, count *int) {
	*count++
	started.Add(1)
	done.Add(1)
	mine, cancel := context.WithCancel(ctx)
	if depth > 0 {
		for i := 0; i < 10; i++ {
			grow(mine, depth-1, started, done, count)
		}
	}
	go func() {
		started.Done()
		<-mine.Done()
		cancel()
		done.Done()
	}()
}

func main() {
	var started, done sync.WaitGroup
	root, cancel := context.WithCancel(context.Background())
	count := 0
	grow(root, 4, &started, &done, &count)
	started.Wait()
	t0 := time.Now()
	cancel()
	done.Wait()
	row.Say("cancel_tree", time.Since(t0).Nanoseconds(), count)
}
