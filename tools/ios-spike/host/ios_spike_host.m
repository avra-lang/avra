// The spike's UIKit host: the app's run loop holds the thread, and the
// program runs between its sources (runtime/avra_fiber.h, the host's loop).
// It draws the neutral records frame.av writes, echoes a tap as the node's
// number and seat, and reports what the witness reads. Thrown away after the
// ruling.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include <mach/mach_time.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/sysctl.h>
#include <unistd.h>

void avra_host_attach(void (*loop)(void));
int avra_host_poller(void);
int64_t avra_host_wait_ns(void);
int avra_host_idling(void);
void avra_host_resume(void);
void avra_trap(const char* words);

void avra_spike_tapped(int64_t id, int64_t seat);
void avra_spike_said(int64_t id, int64_t seat, int64_t flag, const char* words);
int64_t avra_spike_sync(int64_t waits);

static double now_ms(void) {
    static mach_timebase_info_data_t tb;
    if (!tb.denom) mach_timebase_info(&tb);
    return (double)mach_absolute_time() * tb.numer / tb.denom / 1e6;
}

// The process's own start, in the clock now_ms reads.
static double started_ms(void) {
    struct kinfo_proc kp;
    size_t len = sizeof kp;
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid() };
    if (sysctl(mib, 4, &kp, &len, NULL, 0) != 0) return now_ms();
    struct timeval tv;
    gettimeofday(&tv, NULL);
    double ago = (tv.tv_sec - kp.kp_proc.p_starttime.tv_sec) * 1e3 + (tv.tv_usec - kp.kp_proc.p_starttime.tv_usec) / 1e3;
    return now_ms() - ago;
}

static void said(NSString* line) {
    printf("spike: %s\n", line.UTF8String);
    fflush(stdout);
}

// ── The run loop's sources ──────────────────────────────────────

static CFFileDescriptorRef g_poller_fd;
static CFRunLoopTimerRef g_deadline;
static CFRunLoopSourceRef g_again;

static void rearmed(void) {
    int64_t wait = avra_host_wait_ns();
    if (wait == 0) {
        CFRunLoopSourceSignal(g_again);
        CFRunLoopWakeUp(CFRunLoopGetMain());
    }
    CFRunLoopTimerSetNextFireDate(g_deadline, wait > 0 ? CFAbsoluteTimeGetCurrent() + wait / 1e9 : CFAbsoluteTimeGetCurrent() + 1e9);
}

// The program resumed from the loop, then the sources armed for its next idle.
static void resumed(void) {
    if (!avra_host_idling()) return;
    avra_host_resume();
    rearmed();
}

static void poller_heard(CFFileDescriptorRef f, CFOptionFlags _flags, void* _info) {
    resumed();
    CFFileDescriptorEnableCallBacks(f, kCFFileDescriptorReadCallBack);
}

static void deadline_passed(CFRunLoopTimerRef _t, void* _info) { resumed(); }

static void again(void* _info) { resumed(); }

// THE SOURCES STAND IN THE COMMON MODES, so a scroll's tracking mode and a
// presented controller's loop still hear the program.
static void sources_armed(void) {
    CFRunLoopRef loop = CFRunLoopGetMain();
    g_poller_fd = CFFileDescriptorCreate(NULL, avra_host_poller(), false, poller_heard, NULL);
    CFFileDescriptorEnableCallBacks(g_poller_fd, kCFFileDescriptorReadCallBack);
    CFRunLoopSourceRef fd = CFFileDescriptorCreateRunLoopSource(NULL, g_poller_fd, 0);
    CFRunLoopAddSource(loop, fd, kCFRunLoopCommonModes);
    g_deadline = CFRunLoopTimerCreate(NULL, CFAbsoluteTimeGetCurrent() + 1e9, 1e9, 0, 0, deadline_passed, NULL);
    CFRunLoopAddTimer(loop, g_deadline, kCFRunLoopCommonModes);
    CFRunLoopSourceContext c = { 0 };
    c.perform = again;
    g_again = CFRunLoopSourceCreate(NULL, 0, &c);
    CFRunLoopAddSource(loop, g_again, kCFRunLoopCommonModes);
}

// ── The tree the records build ──────────────────────────────────

@interface SpikeNode : NSObject
@property(nonatomic) NSInteger nid;
@property(nonatomic, copy) NSString* prim;
@property(nonatomic, copy) NSString* words;
@property(nonatomic, strong) UIView* view;
@property(nonatomic) NSInteger parent;
@property(nonatomic) NSInteger seat;
@property(nonatomic) NSInteger said_seat;
@property(nonatomic) double max;
@property(nonatomic, strong) UIViewController* sheet;
@end
@implementation SpikeNode
@end

static NSMutableDictionary<NSNumber*, SpikeNode*>* g_nodes;
static UIStackView* g_root;
static UIViewController* g_vc;
static NSMutableArray<NSString*>* g_pending;
static NSCountedSet<NSString*>* g_unused;
static double g_first_frame_ms = -1;
static double g_started_ms;

@interface SpikeTarget : NSObject
- (void)tapped:(UIButton*)b;
- (void)typed:(UITextField*)f;
- (void)returned:(UITextField*)f;
- (void)flipped:(UISwitch*)s;
@end

static SpikeTarget* g_target;

// What a page's tag stands for natively: the prim the host draws it as.
static NSString* prim_of(NSString* tag) {
    if ([tag isEqualToString:@"text"]) return @"text";
    if ([tag isEqualToString:@"button"]) return @"button";
    if ([tag isEqualToString:@"a"]) return @"link";
    if ([tag hasPrefix:@"h"] && tag.length == 2 && ![tag isEqualToString:@"hr"]) return @"heading";
    if ([tag isEqualToString:@"input"]) return @"field";
    if ([tag isEqualToString:@"progress"]) return @"progress";
    if ([tag isEqualToString:@"hr"]) return @"divider";
    if ([tag isEqualToString:@"dialog"]) return @"dialog";
    NSArray* boxes = @[ @"div", @"span", @"article", @"ul", @"li", @"form", @"label", @"fieldset", @"legend" ];
    if ([boxes containsObject:tag]) return @"surface";
    return nil;
}

static UIStackView* stack(void) {
    UIStackView* s = [UIStackView new];
    s.axis = UILayoutConstraintAxisVertical;
    s.alignment = UIStackViewAlignmentLeading;
    s.spacing = 8;
    return s;
}

static UILabel* label(UIFontTextStyle style) {
    UILabel* l = [UILabel new];
    l.font = [UIFont preferredFontForTextStyle:style];
    l.numberOfLines = 0;
    l.isAccessibilityElement = YES;
    l.accessibilityTraits = UIAccessibilityTraitStaticText;
    return l;
}

static UIView* made_view(NSString* tag, NSString* prim, NSInteger nid) {
    UIView* v;
    if (!prim) {
        UILabel* l = label(UIFontTextStyleCaption1);
        l.textColor = UIColor.systemRedColor;
        l.text = [NSString stringWithFormat:@"<%@>", tag];
        v = l;
    } else if ([prim isEqualToString:@"button"] || [prim isEqualToString:@"link"]) {
        UIButton* b = [UIButton buttonWithType:UIButtonTypeSystem];
        b.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        b.tag = nid;
        [b addTarget:g_target action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
        b.isAccessibilityElement = YES;
        b.accessibilityTraits = [prim isEqualToString:@"link"] ? UIAccessibilityTraitLink : UIAccessibilityTraitButton;
        v = b;
    } else if ([prim isEqualToString:@"text"]) {
        v = label(UIFontTextStyleBody);
    } else if ([prim isEqualToString:@"heading"]) {
        NSInteger rank = [tag substringFromIndex:1].integerValue;
        UILabel* l = label(rank <= 1 ? UIFontTextStyleLargeTitle : rank == 2 ? UIFontTextStyleTitle2 : UIFontTextStyleTitle3);
        l.accessibilityTraits = UIAccessibilityTraitHeader;
        v = l;
    } else if ([prim isEqualToString:@"field"]) {
        UITextField* f = [UITextField new];
        f.borderStyle = UITextBorderStyleRoundedRect;
        f.tag = nid;
        [f.widthAnchor constraintGreaterThanOrEqualToConstant:200].active = YES;
        [f addTarget:g_target action:@selector(typed:) forControlEvents:UIControlEventEditingChanged];
        [f addTarget:g_target action:@selector(returned:) forControlEvents:UIControlEventEditingDidEndOnExit];
        v = f;
    } else if ([prim isEqualToString:@"progress"]) {
        UIProgressView* p = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [p.widthAnchor constraintEqualToConstant:200].active = YES;
        v = p;
    } else if ([prim isEqualToString:@"divider"]) {
        UIView* d = [UIView new];
        d.backgroundColor = UIColor.separatorColor;
        [d.heightAnchor constraintEqualToConstant:1.0 / UIScreen.mainScreen.scale].active = YES;
        [d.widthAnchor constraintEqualToConstant:300].active = YES;
        v = d;
    } else {
        v = stack();
    }
    v.accessibilityIdentifier = [NSString stringWithFormat:@"avra-%ld", (long)nid];
    return v;
}

// A text run takes its words into what holds it: a button's title, a heading's
// text, or a label of its own in a container.
static void run_shown(SpikeNode* run) {
    SpikeNode* holder = g_nodes[@(run.parent)];
    NSString* p = holder.prim;
    if ([p isEqualToString:@"button"] || [p isEqualToString:@"link"]) {
        [(UIButton*)holder.view setTitle:run.words forState:UIControlStateNormal];
        if (!holder.view.accessibilityLabel.length) holder.view.accessibilityLabel = run.words;
    } else if ([p isEqualToString:@"heading"]) {
        ((UILabel*)holder.view).text = run.words;
        holder.view.accessibilityLabel = run.words;
    } else {
        ((UILabel*)run.view).text = run.words;
        run.view.accessibilityLabel = run.words;
    }
}

static BOOL holds_runs(SpikeNode* holder) {
    NSString* p = holder.prim;
    return [p isEqualToString:@"button"] || [p isEqualToString:@"link"] || [p isEqualToString:@"heading"];
}

static void placed(SpikeNode* n, NSInteger parent, NSInteger after) {
    if (!n) return;
    n.parent = parent;
    SpikeNode* holder = g_nodes[@(parent)];
    if ([n.prim isEqualToString:@"text"] && holder && holds_runs(holder)) {
        if (n.words) run_shown(n);
        return;
    }
    if ([n.prim isEqualToString:@"dialog"]) return;
    UIStackView* into = holder ? (UIStackView*)holder.view : g_root;
    if (![into isKindOfClass:[UIStackView class]]) {
        [g_unused addObject:[NSString stringWithFormat:@"place into %@", holder.prim]];
        return;
    }
    [n.view removeFromSuperview];
    NSUInteger at = 0;
    if (after) {
        NSUInteger i = [into.arrangedSubviews indexOfObject:g_nodes[@(after)].view];
        at = i == NSNotFound ? into.arrangedSubviews.count : i + 1;
    }
    [into insertArrangedSubview:n.view atIndex:at];
    if ([n.prim isEqualToString:@"text"] && n.words) run_shown(n);
}

// A dialog stands as a sheet over the page while it is open.
static void dialog_shown(SpikeNode* n, BOOL open) {
    if (open && !n.sheet) {
        UIViewController* c = [UIViewController new];
        c.view.backgroundColor = UIColor.systemBackgroundColor;
        UIStackView* s = (UIStackView*)n.view;
        s.alignment = UIStackViewAlignmentCenter;
        s.translatesAutoresizingMaskIntoConstraints = NO;
        [c.view addSubview:s];
        [NSLayoutConstraint activateConstraints:@[
            [s.centerXAnchor constraintEqualToAnchor:c.view.centerXAnchor],
            [s.topAnchor constraintEqualToAnchor:c.view.safeAreaLayoutGuide.topAnchor constant:24],
            [s.widthAnchor constraintLessThanOrEqualToAnchor:c.view.widthAnchor constant:-32],
        ]];
        c.sheetPresentationController.detents = @[ UISheetPresentationControllerDetent.mediumDetent ];
        n.sheet = c;
        [g_vc presentViewController:c animated:NO completion:nil];
    } else if (!open && n.sheet) {
        [n.sheet dismissViewControllerAnimated:NO completion:nil];
        [n.view removeFromSuperview];
        n.sheet = nil;
    }
}

static void attr_set(SpikeNode* n, NSString* name, NSString* value) {
    UIView* v = n.view;
    if ([name isEqualToString:@"class"]) {
        if ([v isKindOfClass:[UIStackView class]]) {
            BOOL row = [[value componentsSeparatedByString:@" "] containsObject:@"dir-row"];
            ((UIStackView*)v).axis = row ? UILayoutConstraintAxisHorizontal : UILayoutConstraintAxisVertical;
            ((UIStackView*)v).alignment = row ? UIStackViewAlignmentCenter : UIStackViewAlignmentLeading;
        }
        if ([v isKindOfClass:[UILabel class]] && [value containsString:@"color-muted"]) ((UILabel*)v).textColor = UIColor.secondaryLabelColor;
        [g_unused addObject:@"attr class (styling beyond row/column and muted)"];
    } else if ([name isEqualToString:@"aria-label"]) {
        v.accessibilityLabel = value;
    } else if ([name isEqualToString:@"type"] && [n.prim isEqualToString:@"field"]) {
        if ([value isEqualToString:@"checkbox"]) {
            UISwitch* s = [UISwitch new];
            s.tag = n.nid;
            [s addTarget:g_target action:@selector(flipped:) forControlEvents:UIControlEventValueChanged];
            s.accessibilityIdentifier = v.accessibilityIdentifier;
            n.prim = @"checkbox";
            n.view = s;
        }
    } else if ([name isEqualToString:@"type"]) {
    } else if ([name isEqualToString:@"placeholder"] && [v isKindOfClass:[UITextField class]]) {
        ((UITextField*)v).placeholder = value;
    } else if ([name isEqualToString:@"disabled"] && [v isKindOfClass:[UIControl class]]) {
        ((UIControl*)v).enabled = NO;
    } else if ([name isEqualToString:@"checked"] && [v isKindOfClass:[UISwitch class]]) {
        ((UISwitch*)v).on = YES;
    } else if ([name isEqualToString:@"max"]) {
        n.max = value.doubleValue;
    } else if ([name isEqualToString:@"value"]) {
        if ([v isKindOfClass:[UITextField class]]) ((UITextField*)v).text = value;
        if ([v isKindOfClass:[UIProgressView class]]) ((UIProgressView*)v).progress = n.max > 0 ? value.doubleValue / n.max : 0;
    } else if ([name isEqualToString:@"open"]) {
        dialog_shown(n, YES);
    } else if ([name isEqualToString:@"hidden"]) {
        v.hidden = YES;
    } else {
        [g_unused addObject:[NSString stringWithFormat:@"attr %@", name]];
    }
}

static void attr_dropped(SpikeNode* n, NSString* name) {
    UIView* v = n.view;
    if ([name isEqualToString:@"disabled"] && [v isKindOfClass:[UIControl class]]) ((UIControl*)v).enabled = YES;
    else if ([name isEqualToString:@"checked"] && [v isKindOfClass:[UISwitch class]]) ((UISwitch*)v).on = NO;
    else if ([name isEqualToString:@"open"]) dialog_shown(n, NO);
    else if ([name isEqualToString:@"hidden"]) v.hidden = NO;
    else [g_unused addObject:[NSString stringWithFormat:@"dropattr %@", name]];
}

static NSString* rest(NSArray<NSString*>* w, NSUInteger from) {
    return w.count > from ? [[w subarrayWithRange:NSMakeRange(from, w.count - from)] componentsJoinedByString:@" "] : @"";
}

static void applied(NSString* frame) {
    for (NSString* line in [frame componentsSeparatedByString:@"\n"]) {
        NSArray<NSString*>* w = [line componentsSeparatedByString:@" "];
        if (w.count < 2) continue;
        NSString* op = w[0];
        NSInteger nid = w[1].integerValue;
        SpikeNode* n = g_nodes[@(nid)];
        if ([op isEqualToString:@"create"]) {
            SpikeNode* m = [SpikeNode new];
            m.nid = nid;
            m.prim = prim_of(w[2]) ?: @"unknown";
            m.view = made_view(w[2], prim_of(w[2]), nid);
            g_nodes[@(nid)] = m;
        } else if ([op isEqualToString:@"text"]) {
            n.words = rest(w, 2);
            if (n.parent || n.view.superview) run_shown(n);
        } else if ([op isEqualToString:@"place"]) {
            placed(n, w[2].integerValue, w[3].integerValue);
        } else if ([op isEqualToString:@"remove"]) {
            if (n.sheet) dialog_shown(n, NO);
            [n.view removeFromSuperview];
            [g_nodes removeObjectForKey:@(nid)];
        } else if ([op isEqualToString:@"listen"]) {
            NSString* prim = w.count > 3 ? w[3] : @"";
            if ([prim isEqualToString:@"button"] || [prim isEqualToString:@"link"]) n.seat = w[2].integerValue;
            else if ([prim isEqualToString:@"dialog"]) n.seat = w[2].integerValue;
            else n.said_seat = w[2].integerValue;
        } else if ([op isEqualToString:@"attr"]) {
            attr_set(n, w[2], rest(w, 3));
        } else if ([op isEqualToString:@"dropattr"]) {
            attr_dropped(n, w[2]);
        } else if ([op isEqualToString:@"prop"]) {
            if ([w[2] isEqualToString:@"checked"] && [n.view isKindOfClass:[UISwitch class]]) ((UISwitch*)n.view).on = [w[3] isEqualToString:@"true"];
            else attr_set(n, w[2], rest(w, 3));
        } else if ([op isEqualToString:@"call"]) {
            if ([w[2] isEqualToString:@"showModal"] || [w[2] isEqualToString:@"show"]) dialog_shown(n, YES);
            else if ([w[2] isEqualToString:@"close"]) dialog_shown(n, NO);
            else [g_unused addObject:[NSString stringWithFormat:@"call %@", w[2]]];
        } else {
            [g_unused addObject:op];
        }
    }
}

// THE PROGRAM'S FRAME: drawn at once once the window stands, kept until then.
void avra_spike_frame(const char* records) {
    NSString* frame = [NSString stringWithUTF8String:records];
    if (!g_root) {
        [g_pending addObject:frame];
        return;
    }
    if (NSProcessInfo.processInfo.environment[@"AVRA_SPIKE_FRAMES"]) said([@"frame: " stringByAppendingString:[frame stringByReplacingOccurrencesOfString:@"\n" withString:@" ; "]]);
    applied(frame);
    if (NSProcessInfo.processInfo.environment[@"AVRA_SPIKE_FRAMES"]) {
        for (NSString* u in g_unused) said([NSString stringWithFormat:@"unused: %@ x%lu", u, (unsigned long)[g_unused countForObject:u]]);
        [g_unused removeAllObjects];
    }
    if (g_first_frame_ms < 0) {
        [g_root.window layoutIfNeeded];
        g_first_frame_ms = now_ms() - g_started_ms;
        said([NSString stringWithFormat:@"first frame %.1f ms after the process started", g_first_frame_ms]);
    }
}

// ── What the witness reads: the accessibility tree ──────────────

static void announced(UIView* v, NSMutableArray<NSString*>* out) {
    if (v.isAccessibilityElement && v.accessibilityLabel.length) [out addObject:[NSString stringWithFormat:@"%@%@", (v.accessibilityTraits & UIAccessibilityTraitButton) ? @"button: " : @"label: ", v.accessibilityLabel]];
    for (UIView* c in v.subviews) announced(c, out);
}

static NSArray<NSString*>* a11y_said(void) {
    NSMutableArray* out = [NSMutableArray new];
    announced(g_root, out);
    return out;
}

static UIView* a11y_find(UIView* v, NSString* prefix) {
    if (v.isAccessibilityElement && [v.accessibilityLabel hasPrefix:prefix] && (v.accessibilityTraits & UIAccessibilityTraitButton)) return v;
    for (UIView* c in v.subviews) {
        UIView* f = a11y_find(c, prefix);
        if (f) return f;
    }
    return nil;
}

@implementation SpikeTarget
// A TAP IS HEARD ONLY BETWEEN TURNS: the loop calls this, and the program
// stands idle there by construction; anything else is re-entry.
- (void)tapped:(UIButton*)b {
    if (!avra_host_idling()) avra_trap("a UIKit callback reached the program inside a running turn");
    SpikeNode* n = g_nodes[@(b.tag)];
    avra_spike_tapped(n.nid, n.seat);
    resumed();
}
- (void)typed:(UITextField*)f {
    SpikeNode* n = g_nodes[@(f.tag)];
    avra_spike_said(n.nid, n.said_seat, 0, (f.text ?: @"").UTF8String);
    resumed();
}
- (void)returned:(UITextField*)f {
    [f resignFirstResponder];
}
- (void)flipped:(UISwitch*)s {
    SpikeNode* n = g_nodes[@(s.tag)];
    avra_spike_said(n.nid, n.said_seat, s.on ? 2 : 1, "");
    resumed();
}
@end

// ── The display's frames, and what stalls them ──────────────────

@interface SpikeFrames : NSObject
@property(nonatomic) double last;
@property(nonatomic) double longest;
@property(nonatomic) NSInteger count;
- (void)ticked:(CADisplayLink*)l;
@end
@implementation SpikeFrames
- (void)ticked:(CADisplayLink*)l {
    double t = now_ms();
    if (self.last > 0 && t - self.last > self.longest) self.longest = t - self.last;
    self.last = t;
    self.count++;
}
@end

static SpikeFrames* g_frames;

// ── The witness's script, run on the loop ───────────────────────

static void after(double s, void (^then)(void)) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(s * NSEC_PER_SEC)), dispatch_get_main_queue(), then);
}

static NSInteger g_ticks;
static NSInteger g_ticks_tracking;
static NSInteger g_ticks_alert;
static int g_in_alert;

void avra_spike_tick(int64_t n) {
    g_ticks = n;
    CFStringRef mode = CFRunLoopCopyCurrentMode(CFRunLoopGetMain());
    if (mode && CFEqual(mode, (CFStringRef)UITrackingRunLoopMode)) g_ticks_tracking++;
    if (g_in_alert) g_ticks_alert++;
    if (mode) CFRelease(mode);
}

static UIView* found_kind(UIView* v, Class k) {
    if ([v isKindOfClass:k]) return v;
    for (UIView* c in v.subviews) {
        UIView* f = found_kind(c, k);
        if (f) return f;
    }
    return nil;
}

// The board's script: a task typed and added, then the About dialog opened.
static void board_scripted(void) {
    after(1.5, ^{
        UITextField* f = (UITextField*)found_kind(g_root, [UITextField class]);
        f.text = @"Buy milk";
        [g_target typed:f];
        after(0.5, ^{
            UIButton* add = (UIButton*)a11y_find(g_root, @"Add");
            [add sendActionsForControlEvents:UIControlEventTouchUpInside];
            said([NSString stringWithFormat:@"board after Add: %@", [a11y_said() componentsJoinedByString:@" | "]]);
        });
    });
    after(4.5, ^{
        UIButton* about = (UIButton*)a11y_find(g_root, @"About");
        [about sendActionsForControlEvents:UIControlEventTouchUpInside];
        after(0.5, ^{ said([NSString stringWithFormat:@"board dialog up: %@", g_vc.presentedViewController ? @"yes" : @"no"]); });
    });
}

static void witnessed(UIWindow* w) {
    NSString* press = NSProcessInfo.processInfo.environment[@"AVRA_SPIKE_PRESS"];
    double pause = NSProcessInfo.processInfo.environment[@"AVRA_SPIKE_PAUSE"].doubleValue;
    after(0.5, ^{
        said([NSString stringWithFormat:@"a11y before: %@", [a11y_said() componentsJoinedByString:@" | "]]);
        if (pause > 0) [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:pause]];
        for (int i = 0; i < press.intValue; i++) {
            UIView* b = a11y_find(g_root, @"taps+");
            if (![b accessibilityActivate]) [(UIButton*)b sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
        after(0.3, ^{
            said([NSString stringWithFormat:@"a11y after %d presses: %@", press.intValue, [a11y_said() componentsJoinedByString:@" | "]]);
            if (pause > 0) [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:pause]];
            NSInteger before = g_ticks;
            // a scroll's tracking mode, held for half a second: the program's sources stand in it too
            [[NSRunLoop mainRunLoop] runMode:UITrackingRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
            CFAbsoluteTime until = CFAbsoluteTimeGetCurrent() + 0.5;
            while (CFAbsoluteTimeGetCurrent() < until) [[NSRunLoop mainRunLoop] runMode:UITrackingRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
            said([NSString stringWithFormat:@"ticks in tracking mode: %ld (of %ld over the hold)", (long)g_ticks_tracking, (long)(g_ticks - before)]);
            UIAlertController* a = [UIAlertController alertControllerWithTitle:@"Alert" message:@"held" preferredStyle:UIAlertControllerStyleAlert];
            [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            g_in_alert = 1;
            [w.rootViewController presentViewController:a animated:YES completion:nil];
            after(0.6, ^{
                g_in_alert = 0;
                said([NSString stringWithFormat:@"ticks while an alert stood: %ld", (long)g_ticks_alert]);
                [a dismissViewControllerAnimated:NO completion:nil];
                NSString* sync = NSProcessInfo.processInfo.environment[@"AVRA_SPIKE_SYNC"];
                if (sync) said([NSString stringWithFormat:@"a synchronous answer: %lld", avra_spike_sync(sync.intValue)]);
                said([NSString stringWithFormat:@"display frames %ld, longest gap %.1f ms", (long)g_frames.count, g_frames.longest]);
                said(@"done");
                exit(0);
            });
        });
    });
}

// ── The app ─────────────────────────────────────────────────────

@interface SpikeScene : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, strong) UIWindow* window;
@end

@implementation SpikeScene
- (void)scene:(UIScene*)scene willConnectToSession:(UISceneSession*)session options:(UISceneConnectionOptions*)options {
    UIWindow* w = [[UIWindow alloc] initWithWindowScene:(UIWindowScene*)scene];
    UIViewController* vc = [UIViewController new];
    vc.view.backgroundColor = UIColor.systemBackgroundColor;
    g_root = [UIStackView new];
    g_root.axis = UILayoutConstraintAxisVertical;
    g_root.alignment = UIStackViewAlignmentLeading;
    g_root.translatesAutoresizingMaskIntoConstraints = NO;
    UIScrollView* sv = [UIScrollView new];
    sv.translatesAutoresizingMaskIntoConstraints = NO;
    [vc.view addSubview:sv];
    [sv addSubview:g_root];
    UILayoutGuide* safe = vc.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [sv.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [sv.bottomAnchor constraintEqualToAnchor:vc.view.bottomAnchor],
        [sv.leadingAnchor constraintEqualToAnchor:vc.view.leadingAnchor],
        [sv.trailingAnchor constraintEqualToAnchor:vc.view.trailingAnchor],
        [g_root.topAnchor constraintEqualToAnchor:sv.contentLayoutGuide.topAnchor constant:16],
        [g_root.bottomAnchor constraintEqualToAnchor:sv.contentLayoutGuide.bottomAnchor constant:-16],
        [g_root.leadingAnchor constraintEqualToAnchor:sv.frameLayoutGuide.leadingAnchor constant:16],
        [g_root.trailingAnchor constraintLessThanOrEqualToAnchor:sv.frameLayoutGuide.trailingAnchor constant:-16],
    ]];
    w.rootViewController = vc;
    g_vc = vc;
    self.window = w;
    [w makeKeyAndVisible];
    for (NSString* f in g_pending) avra_spike_frame(f.UTF8String);
    [g_pending removeAllObjects];
    sources_armed();
    g_frames = [SpikeFrames new];
    [[CADisplayLink displayLinkWithTarget:g_frames selector:@selector(ticked:)] addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    resumed();
    if (NSProcessInfo.processInfo.environment[@"AVRA_SPIKE_WITNESS"]) witnessed(w);
    if (NSProcessInfo.processInfo.environment[@"AVRA_SPIKE_BOARD_SCRIPT"]) board_scripted();
}
@end

@interface SpikeApp : UIResponder <UIApplicationDelegate>
@end

@implementation SpikeApp
- (UISceneConfiguration*)application:(UIApplication*)app configurationForConnectingSceneSession:(UISceneSession*)session options:(UISceneConnectionOptions*)options {
    UISceneConfiguration* c = [[UISceneConfiguration alloc] initWithName:@"Default" sessionRole:session.role];
    c.delegateClass = [SpikeScene class];
    return c;
}
@end

static void host_loop(void) {
    @autoreleasepool {
        static char* argv0[] = {"spike", NULL};
        UIApplicationMain(1, argv0, nil, NSStringFromClass([SpikeApp class]));
    }
}

void avra_spike_attach(void) {
    g_started_ms = started_ms();
    g_nodes = [NSMutableDictionary new];
    g_pending = [NSMutableArray new];
    g_unused = [NSCountedSet new];
    g_target = [SpikeTarget new];
    avra_host_attach(host_loop);
}

// An app has no fork, so nothing is prepared for one.
void avra_fork_hook(int (*prepare)(const char** why)) { (void)prepare; }
