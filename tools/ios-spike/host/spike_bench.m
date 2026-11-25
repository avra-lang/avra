// The benchmark's instrument: see spike_bench.h.
#import "spike_bench.h"
#import <QuartzCore/QuartzCore.h>
#include <mach/mach.h>
#include <sys/sysctl.h>
#include <unistd.h>

static double bench_now_s(void) { return CACurrentMediaTime(); }

// The process's own start, on the clock CACurrentMediaTime reads.
static double started_s(void) {
    struct kinfo_proc kp;
    size_t len = sizeof kp;
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid() };
    if (sysctl(mib, 4, &kp, &len, NULL, 0) != 0) return bench_now_s();
    struct timeval tv;
    gettimeofday(&tv, NULL);
    double ago = (tv.tv_sec - kp.kp_proc.p_starttime.tv_sec) + (tv.tv_usec - kp.kp_proc.p_starttime.tv_usec) / 1e6;
    return bench_now_s() - ago;
}

static double footprint_mb(void) {
    task_vm_info_data_t info;
    mach_msg_type_number_t n = TASK_VM_INFO_COUNT;
    if (task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&info, &n) != KERN_SUCCESS) return -1;
    return info.phys_footprint / 1048576.0;
}

static void say(NSString* line) {
    printf("bench: %s\n", line.UTF8String);
    fflush(stdout);
}

@interface BenchLink : NSObject
@property(nonatomic) double started;
@property(nonatomic) double first_applied;
@property(nonatomic) double first_drawn;
@property(nonatomic) double toggle_asked;
@property(nonatomic) double toggle_applied;
@property(nonatomic) double toggle_drawn;
@property(nonatomic) BOOL flinging;
@property(nonatomic) double fling_from;
@property(nonatomic) BOOL slow;
@property(nonatomic) CGFloat slow_from_y;
@property(nonatomic) double fling_last;
@property(nonatomic) NSInteger fling_frames;
@property(nonatomic) double fling_longest;
@property(nonatomic) NSInteger over16;
@property(nonatomic) NSInteger over8;
@property(nonatomic, weak) UIScrollView* scroll;
@property(nonatomic, copy) void (^toggle)(void);
- (void)ticked:(CADisplayLink*)l;
@end

static BenchLink* g_bench;
static const double fling_s = 3.0;

@implementation BenchLink
- (void)ticked:(CADisplayLink*)l {
    double t = l.timestamp;
    double shown = MAX(l.targetTimestamp, bench_now_s());
    if (self.first_applied > 0 && self.first_drawn == 0) self.first_drawn = shown;
    if (self.toggle_applied > 0 && self.toggle_drawn == 0) self.toggle_drawn = shown;
    if (!self.flinging) return;
    if (self.fling_last > 0) {
        double gap = (t - self.fling_last) * 1000;
        if (gap > self.fling_longest) self.fling_longest = gap;
        if (gap > 16.7) self.over16++;
        if (gap > 8.4) self.over8++;
    }
    self.fling_last = t;
    self.fling_frames++;
    double k = MIN(1.0, (t - self.fling_from) / fling_s);
    UIScrollView* s = self.scroll;
    CGFloat bottom = MAX(0, s.contentSize.height - s.bounds.size.height);
    if (self.slow) s.contentOffset = CGPointMake(0, MAX(0, self.slow_from_y - 4000 * k));
    else s.contentOffset = CGPointMake(0, bottom * k);
    if (k >= 1.0) self.flinging = NO;
}
@end

void bench_attach(UIScrollView* scroll, void (^toggle)(void)) {
    if (!g_bench) g_bench = [BenchLink new];
    g_bench.started = started_s();
    g_bench.scroll = scroll;
    g_bench.toggle = toggle;
    CADisplayLink* link = [CADisplayLink displayLinkWithTarget:g_bench selector:@selector(ticked:)];
    link.preferredFrameRateRange = CAFrameRateRangeMake(60, 120, 120);
    [link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}

void bench_first_applied(void) {
    if (g_bench && g_bench.first_applied == 0) g_bench.first_applied = bench_now_s();
}

void bench_toggle_applied(void) {
    if (g_bench && g_bench.toggle_asked > 0 && g_bench.toggle_applied == 0) g_bench.toggle_applied = bench_now_s();
}

static void later(double s, void (^then)(void)) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(s * NSEC_PER_SEC)), dispatch_get_main_queue(), then);
}

// The script, once the first frame is drawn: memory, a toggle, a fling, the report.
static void flung(void) {
    if (g_bench.toggle_drawn > 0)
        say([NSString stringWithFormat:@"toggle to frame drawn: %.2f ms (applied at %.2f ms)", (g_bench.toggle_drawn - g_bench.toggle_asked) * 1000, (g_bench.toggle_applied - g_bench.toggle_asked) * 1000]);
    else say(@"toggle: never applied within 30 s");
    g_bench.fling_from = bench_now_s();
    g_bench.flinging = YES;
    later(fling_s + 1, ^{
        say([NSString stringWithFormat:@"fling: %ld frames in %.1f s, longest gap %.1f ms, gaps over 16.7 ms %ld, over 8.3 ms %ld",
            (long)g_bench.fling_frames, fling_s, g_bench.fling_longest, (long)g_bench.over16, (long)g_bench.over8]);
        say([NSString stringWithFormat:@"memory after the fling: %.1f MB", footprint_mb()]);
        say(@"slow scroll begins");
        g_bench.fling_frames = 0;
        g_bench.fling_longest = 0;
        g_bench.over16 = g_bench.over8 = 0;
        g_bench.fling_last = 0;
        g_bench.slow = YES;
        g_bench.slow_from_y = g_bench.scroll.contentOffset.y;
        g_bench.fling_from = bench_now_s();
        g_bench.flinging = YES;
        later(fling_s + 1, ^{
            say([NSString stringWithFormat:@"slow scroll: %ld frames in %.1f s, longest gap %.1f ms, gaps over 16.7 ms %ld",
                (long)g_bench.fling_frames, fling_s, g_bench.fling_longest, (long)g_bench.over16]);
            say(@"done");
            exit(0);
        });
    });
}

// The toggle's frame, waited for up to 30 s, then a breath before the fling.
static void toggled_wait(void) {
    if (g_bench.toggle_drawn > 0 || bench_now_s() - g_bench.toggle_asked > 30) { later(0.5, ^{ flung(); }); return; }
    later(0.05, ^{ toggled_wait(); });
}

// The script, once the first frame is drawn: memory, a toggle, a fling, the report.
static void scripted(void) {
    say([NSString stringWithFormat:@"cold start to first frame drawn: %.1f ms", (g_bench.first_drawn - g_bench.started) * 1000]);
    later(1, ^{
        say([NSString stringWithFormat:@"memory after first frame: %.1f MB", footprint_mb()]);
        g_bench.toggle_asked = bench_now_s();
        g_bench.toggle();
        toggled_wait();
    });
}

static void awaited(void) {
    if (g_bench.first_drawn > 0) { scripted(); return; }
    later(0.1, ^{ awaited(); });
}

void bench_start(void) {
    if (!NSProcessInfo.processInfo.environment[@"AVRA_SPIKE_BENCH"]) return;
    awaited();
}
