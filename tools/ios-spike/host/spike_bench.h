// The benchmark's instrument, one definition for the Avra app and its UIKit
// twin: cold start, memory, one toggle's latency and a fling, all read from the
// display link's own timestamps. Spike code.
#pragma once
#import <UIKit/UIKit.h>

// The app's scroll view, and the one action the toggle measure performs.
void bench_attach(UIScrollView* scroll, void (^toggle)(void));
// The first frame of content has been applied to the views.
void bench_first_applied(void);
// The toggle's change has been applied to the views.
void bench_toggle_applied(void);
// Runs the script when AVRA_SPIKE_BENCH is set: memory, toggle, fling, report, exit.
void bench_start(void);
// A named moment on the way to the first frame, for the cold-start timeline.
void bench_mark(const char* name);
