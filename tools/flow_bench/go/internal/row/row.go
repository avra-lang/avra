// Package row is the one output line every flow bench speaks:
// `<key> <total> <count>` — nanoseconds or bytes over how many.
package row

import (
	"fmt"
	"os"
	"strconv"
	"strings"
)

// Say prints one row.
func Say(key string, total int64, count int) { fmt.Printf("%s %d %d\n", key, total, count) }

// Number reads an integer from the environment.
func Number(name string, fallback int) int {
	if v, err := strconv.Atoi(os.Getenv(name)); err == nil {
		return v
	}
	return fallback
}

// Status reads a kB field of /proc/self/status as bytes; 0 where there is none.
func Status(key string) int64 {
	text, err := os.ReadFile("/proc/self/status")
	if err != nil {
		return 0
	}
	for _, line := range strings.Split(string(text), "\n") {
		if strings.HasPrefix(line, key) {
			f := strings.Fields(line)
			if len(f) >= 2 {
				kb, _ := strconv.ParseInt(f[1], 10, 64)
				return kb * 1024
			}
		}
	}
	return 0
}
