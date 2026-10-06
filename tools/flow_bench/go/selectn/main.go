// Select over N sources, one ready per pick. 2 and 8 are static
// `select`s; 64 is `reflect.Select`, the only spelling Go has for it.
package main

import (
	"reflect"
	"time"

	"flowbench/internal/row"
)

func fed(n, picks int) []chan int {
	chs := make([]chan int, n)
	for i := range chs {
		chs[i] = make(chan int)
	}
	go func() {
		for i := 0; i < picks; i++ {
			chs[i%n] <- i
		}
	}()
	return chs
}

func two(picks int) int64 {
	c := fed(2, picks)
	t0 := time.Now()
	for i := 0; i < picks; i++ {
		select {
		case <-c[0]:
		case <-c[1]:
		}
	}
	return time.Since(t0).Nanoseconds()
}

func eight(picks int) int64 {
	c := fed(8, picks)
	t0 := time.Now()
	for i := 0; i < picks; i++ {
		select {
		case <-c[0]:
		case <-c[1]:
		case <-c[2]:
		case <-c[3]:
		case <-c[4]:
		case <-c[5]:
		case <-c[6]:
		case <-c[7]:
		}
	}
	return time.Since(t0).Nanoseconds()
}

func many(n, picks int) int64 {
	c := fed(n, picks)
	cases := make([]reflect.SelectCase, n)
	for i := range cases {
		cases[i] = reflect.SelectCase{Dir: reflect.SelectRecv, Chan: reflect.ValueOf(c[i])}
	}
	t0 := time.Now()
	for i := 0; i < picks; i++ {
		reflect.Select(cases)
	}
	return time.Since(t0).Nanoseconds()
}

func main() {
	n := row.Number("FLOW_N", 1000000)
	row.Say("select_2", two(n), n)
	row.Say("select_8", eight(n), n)
	row.Say("select_64_reflect", many(64, n/10), n/10)
}
