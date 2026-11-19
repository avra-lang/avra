// MEMORY PER PARKED TASK in Go: n goroutines block on one channel, the
// resident set is read from the process's own status, then the goroutines
// are released. Prints bytes per parked goroutine.
package main

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"
)

func envInt(name string, fallback int) int {
	if v, err := strconv.Atoi(os.Getenv(name)); err == nil {
		return v
	}
	return fallback
}

func rssBytes() int64 {
	data, err := os.ReadFile("/proc/self/status")
	if err != nil {
		return 0
	}
	for _, line := range strings.Split(string(data), "\n") {
		if strings.HasPrefix(line, "VmRSS:") {
			f := strings.Fields(line)
			if len(f) >= 2 {
				kb, _ := strconv.ParseInt(f[1], 10, 64)
				return kb * 1024
			}
		}
	}
	return 0
}

func main() {
	n := envInt("BENCH_N", 10000)
	release := make(chan struct{})
	var wg sync.WaitGroup
	wg.Add(n)
	before := rssBytes()
	for i := 0; i < n; i++ {
		go func() {
			<-release
			wg.Done()
		}()
	}
	time.Sleep(50 * time.Millisecond)
	after := rssBytes()
	close(release)
	wg.Wait()
	per := int64(0)
	if n > 0 {
		per = (after - before) / int64(n)
	}
	fmt.Printf("parked_bytes\t%d\tbytes\t1\n", per)
	fmt.Printf("parked_n\t%d\tops\t1\n", n)
}
