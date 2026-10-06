// Select over N sources, one ready per pick. 2 and 8 are static
// `select`s; 64 is spelled three ways — a static 64-case `select`,
// `reflect.Select`, and one forwarder per source into one channel, which
// is how a Go program waits on many.
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

func sixtyFour(picks int) int64 {
	c := fed(64, picks)
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
		case <-c[8]:
		case <-c[9]:
		case <-c[10]:
		case <-c[11]:
		case <-c[12]:
		case <-c[13]:
		case <-c[14]:
		case <-c[15]:
		case <-c[16]:
		case <-c[17]:
		case <-c[18]:
		case <-c[19]:
		case <-c[20]:
		case <-c[21]:
		case <-c[22]:
		case <-c[23]:
		case <-c[24]:
		case <-c[25]:
		case <-c[26]:
		case <-c[27]:
		case <-c[28]:
		case <-c[29]:
		case <-c[30]:
		case <-c[31]:
		case <-c[32]:
		case <-c[33]:
		case <-c[34]:
		case <-c[35]:
		case <-c[36]:
		case <-c[37]:
		case <-c[38]:
		case <-c[39]:
		case <-c[40]:
		case <-c[41]:
		case <-c[42]:
		case <-c[43]:
		case <-c[44]:
		case <-c[45]:
		case <-c[46]:
		case <-c[47]:
		case <-c[48]:
		case <-c[49]:
		case <-c[50]:
		case <-c[51]:
		case <-c[52]:
		case <-c[53]:
		case <-c[54]:
		case <-c[55]:
		case <-c[56]:
		case <-c[57]:
		case <-c[58]:
		case <-c[59]:
		case <-c[60]:
		case <-c[61]:
		case <-c[62]:
		case <-c[63]:
		}
	}
	return time.Since(t0).Nanoseconds()
}

func merged(n, picks int) int64 {
	c := fed(n, picks)
	one := make(chan int)
	for i := range c {
		go func() {
			for v := range c[i] {
				one <- v
			}
		}()
	}
	t0 := time.Now()
	for i := 0; i < picks; i++ {
		<-one
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
	row.Say("select_64_static", sixtyFour(n/10), n/10)
	row.Say("select_64_reflect", many(64, n/10), n/10)
	row.Say("select_64_merged", merged(64, n), n)
}
