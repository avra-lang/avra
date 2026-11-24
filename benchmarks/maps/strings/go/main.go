// STRING-KEYED MAP in Go: map[string]int (Swiss tables since Go 1.24).
// Prints build, hit, miss, walk and remove per operation at three sizes,
// the sum of one pass of hits and the entries left after removing all.
package main

import (
	"fmt"
	"os"
	"strconv"
	"time"
)

func envInt(name string, fallback int) int {
	if v, err := strconv.Atoi(os.Getenv(name)); err == nil {
		return v
	}
	return fallback
}

var sum, left int

func oneSize(n, ops, rounds int, tag string) {
	hit := make([]string, n)
	miss := make([]string, n)
	for i := 0; i < n; i++ {
		hit[i] = "key" + strconv.Itoa(i)
		miss[i] = "nokey" + strconv.Itoa(i)
	}
	reps := ops / n
	if reps < 1 {
		reps = 1
	}
	best := [5]float64{1e300, 1e300, 1e300, 1e300, 1e300}
	sink := 0
	for r := 0; r < rounds; r++ {
		t := time.Now()
		ms := make([]map[string]int, reps)
		for q := 0; q < reps; q++ {
			m := map[string]int{}
			for i, k := range hit {
				m[k] = i
			}
			ms[q] = m
		}
		best[0] = min(best[0], float64(time.Since(t).Nanoseconds()))
		m := ms[0]
		t = time.Now()
		s := 0
		for q := 0; q < reps; q++ {
			for _, k := range hit {
				s += m[k]
			}
		}
		best[1] = min(best[1], float64(time.Since(t).Nanoseconds()))
		if n == 100000 {
			sum = s / reps
		}
		t = time.Now()
		for q := 0; q < reps; q++ {
			for _, k := range miss {
				if _, ok := m[k]; ok {
					sink++
				}
			}
		}
		best[2] = min(best[2], float64(time.Since(t).Nanoseconds()))
		t = time.Now()
		for q := 0; q < reps; q++ {
			for _, v := range m {
				sink += v
			}
		}
		best[3] = min(best[3], float64(time.Since(t).Nanoseconds()))
		t = time.Now()
		for _, m := range ms {
			for _, k := range hit {
				delete(m, k)
			}
		}
		best[4] = min(best[4], float64(time.Since(t).Nanoseconds()))
		if n == 100000 {
			left = len(ms[0])
		}
	}
	per := float64(reps * n)
	for i, op := range []string{"build", "hit", "miss", "walk", "remove"} {
		fmt.Printf("maps_%s_%s_ns_per_op\t%.1f\tns\t%d\n", op, tag, best[i]/per, rounds)
	}
	if sink == -1 {
		fmt.Println("# sink")
	}
}

func main() {
	ops := envInt("BENCH_OPS", 100000)
	rounds := envInt("BENCH_ROUNDS", 5)
	oneSize(8, ops, rounds, "8")
	oneSize(1000, ops, rounds, "1k")
	oneSize(100000, ops, rounds, "100k")
	fmt.Printf("maps_hit_sum\t%d\tops\t%d\n", sum, rounds)
	fmt.Printf("maps_left\t%d\tops\t%d\n", left, rounds)
}
