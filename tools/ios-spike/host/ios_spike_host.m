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
#include "avra_facts.gen.h"
#include "spike_bench.m"

void avra_host_attach(void (*loop)(void));
int avra_host_poller(void);
int64_t avra_host_wait_ns(void);
int avra_host_idling(void);
void avra_host_resume(void);
void avra_trap(const char* words);

void avra_spike_tapped(int64_t id, int64_t seat);
void avra_spike_resized(void);
void avra_spike_scrolled(int64_t from, int64_t to, int64_t extent);
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

// One element: its prim, the view it stands as, the control inside that view
// that speaks, the label a control composes beside itself, and the title a
// container composes above its children.
@interface SpikeNode : NSObject
@property(nonatomic) NSInteger nid;
@property(nonatomic, copy) NSString* prim;
@property(nonatomic, strong) UIView* view;
@property(nonatomic, strong) UIView* control;
@property(nonatomic, strong) UILabel* label;
@property(nonatomic, strong) UILabel* title;
@property(nonatomic) NSInteger parent;
@property(nonatomic) NSInteger seat;
@property(nonatomic) NSInteger said_seat;
@property(nonatomic) double max;
@property(nonatomic) double amount;
@property(nonatomic, strong) UIViewController* sheet;
@property(nonatomic, strong) UIColor* ink;
@property(nonatomic) CGFloat pad_start;
@property(nonatomic) CGFloat pad_top;
@property(nonatomic, strong) NSMutableDictionary<NSString*, NSString*>* facts;
@property(nonatomic, strong) NSMutableSet<NSString*>* fresh;
@property(nonatomic, strong) NSMutableArray<SpikeNode*>* kid_nodes;
@end
@implementation SpikeNode
@end

static NSMutableDictionary<NSNumber*, SpikeNode*>* g_nodes;
static UIView* g_root;
static UIScrollView* g_scroll;
static CGFloat g_width;
static UIViewController* g_vc;
static NSMutableArray<NSString*>* g_pending;
static NSCountedSet<NSString*>* g_unused;
static double g_first_frame_ms = -1;
static double g_apply_s;
static NSInteger g_measures;
static CGFloat g_row_h;
static UIColor* placeholder_rows(void);
static NSInteger g_reused;
static double g_parse_s;
static double g_pair_s;
static NSInteger g_rows_reused;
static NSMutableDictionary<NSString*, NSNumber*>* g_op_s;
static double g_measure_s;
static BOOL g_toggling;
static double g_started_ms;

@interface SpikeTarget : NSObject
- (void)tapped:(UIButton*)b;
- (void)typed:(UITextField*)f;
- (void)returned:(UITextField*)f;
- (void)flipped:(UISwitch*)s;
@end

static SpikeTarget* g_target;

static UIStackView* stack(UILayoutConstraintAxis axis) {
    UIStackView* s = [UIStackView new];
    s.axis = axis;
    s.alignment = axis == UILayoutConstraintAxisHorizontal ? UIStackViewAlignmentCenter : UIStackViewAlignmentLeading;
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

static BOOL is(SpikeNode* n, NSString* prim) { return [n.prim isEqualToString:prim]; }

static BOOL is_any(SpikeNode* n, NSArray<NSString*>* prims) { return [prims containsObject:n.prim]; }

// The view a prim stands as: the platform's own control, composed with its
// label where the control has one.
static void made(SpikeNode* n) {
    NSString* p = n.prim;
    if ([p isEqualToString:@"button"] || [p isEqualToString:@"link"]) {
        UIButtonConfiguration* cfg = [UIButtonConfiguration plainButtonConfiguration];
        cfg.contentInsets = NSDirectionalEdgeInsetsMake(6, 12, 6, 12);
        UIButton* b = [UIButton buttonWithConfiguration:cfg primaryAction:nil];
        b.tag = n.nid;
        [b addTarget:g_target action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
        b.isAccessibilityElement = YES;
        b.accessibilityTraits = [p isEqualToString:@"link"] ? UIAccessibilityTraitLink : UIAccessibilityTraitButton;
        n.view = n.control = b;
    } else if ([p isEqualToString:@"text"]) {
        n.view = n.label = label(UIFontTextStyleBody);
    } else if ([p isEqualToString:@"heading"]) {
        n.view = n.label = label(UIFontTextStyleTitle2);
        n.label.accessibilityTraits = UIAccessibilityTraitHeader;
    } else if ([p isEqualToString:@"field"]) {
        UITextField* f = [UITextField new];
        f.borderStyle = UITextBorderStyleRoundedRect;
        f.tag = n.nid;
        [f.widthAnchor constraintGreaterThanOrEqualToConstant:200].active = YES;
        [f addTarget:g_target action:@selector(typed:) forControlEvents:UIControlEventEditingChanged];
        [f addTarget:g_target action:@selector(returned:) forControlEvents:UIControlEventEditingDidEndOnExit];
        UIStackView* s = stack(UILayoutConstraintAxisVertical);
        n.label = label(UIFontTextStyleBody);
        [s addArrangedSubview:n.label];
        [s addArrangedSubview:f];
        n.control = f;
        n.view = s;
    } else if ([p isEqualToString:@"switch"] || [p isEqualToString:@"checkbox"]) {
        UISwitch* w = [UISwitch new];
        w.tag = n.nid;
        [w addTarget:g_target action:@selector(flipped:) forControlEvents:UIControlEventValueChanged];
        w.isAccessibilityElement = YES;
        UIStackView* s = stack(UILayoutConstraintAxisHorizontal);
        n.label = label(UIFontTextStyleBody);
        [s addArrangedSubview:w];
        [s addArrangedSubview:n.label];
        n.control = w;
        n.view = s;
    } else if ([p isEqualToString:@"progress"] || [p isEqualToString:@"slider"]) {
        UIView* c;
        if ([p isEqualToString:@"progress"]) c = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        else c = [UISlider new];
        [c.widthAnchor constraintEqualToConstant:200].active = YES;
        UIStackView* s = stack(UILayoutConstraintAxisVertical);
        n.label = label(UIFontTextStyleBody);
        [s addArrangedSubview:n.label];
        [s addArrangedSubview:c];
        n.control = c;
        n.view = s;
    } else if ([p isEqualToString:@"divider"]) {
        UIView* d = [UIView new];
        d.backgroundColor = UIColor.separatorColor;
        [d.heightAnchor constraintEqualToConstant:1.0 / UIScreen.mainScreen.scale].active = YES;
        [d.widthAnchor constraintEqualToConstant:300].active = YES;
        n.view = d;
    } else if ([p isEqualToString:@"spinner"]) {
        UIActivityIndicatorView* a = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        [a startAnimating];
        n.view = a;
    } else if ([p isEqualToString:@"image"] || [p isEqualToString:@"icon"]) {
        n.view = n.label = label(UIFontTextStyleCaption1);
        n.label.text = @"▢";
    } else if ([p isEqualToString:@"key"]) {
        n.view = [UIView new];
        n.view.hidden = YES;
    } else if ([@[ @"row", @"column", @"surface", @"list", @"item", @"card", @"form", @"fieldset", @"alert", @"dialog" ] containsObject:p]) {
        n.view = [UIView new];
    } else {
        UILabel* l = label(UIFontTextStyleCaption1);
        l.textColor = UIColor.systemRedColor;
        l.text = [NSString stringWithFormat:@"<%@>", p];
        n.view = l;
    }
    n.view.accessibilityIdentifier = [NSString stringWithFormat:@"avra-%ld", (long)n.nid];
}

// A container's title stands above its children.
static void titled(SpikeNode* n, NSString* words) {
    if (n.control || n.label) return;
    if (!n.title) {
        n.title = label(is(n, @"card") ? UIFontTextStyleTitle3 : UIFontTextStyleHeadline);
        [n.view addSubview:n.title];
    }
    n.title.text = words;
    n.title.accessibilityLabel = words;
}

// What a control shows as its words: a button's title, a label's text, a
// container's title.
static void worded(SpikeNode* n, NSString* words) {
    if ([n.control isKindOfClass:[UIButton class]]) {
        [(UIButton*)n.control setTitle:words forState:UIControlStateNormal];
        n.control.accessibilityLabel = words;
    } else if (n.label) {
        n.label.text = words;
        n.label.accessibilityLabel = words;
        if (n.control) n.control.accessibilityLabel = words;
    } else {
        titled(n, words);
    }
}

static UIColor* tone_colour(NSString* tone) {
    NSDictionary<NSString*, UIColor*>* by = @{
        @"canvas" : UIColor.systemBackgroundColor,
        @"surface" : UIColor.secondarySystemBackgroundColor,
        @"surface-raised" : UIColor.tertiarySystemBackgroundColor,
        @"surface-sunk" : UIColor.tertiarySystemFillColor,
        @"accent" : UIColor.tintColor,
        @"neutral" : UIColor.systemGray5Color,
        @"danger" : UIColor.systemRedColor,
        @"success" : UIColor.systemGreenColor,
        @"warning" : UIColor.systemOrangeColor,
    };
    return by[tone];
}

static UIColor* ink_colour(NSString* ink) {
    NSDictionary<NSString*, UIColor*>* by = @{
        @"text" : UIColor.labelColor,
        @"muted" : UIColor.secondaryLabelColor,
        @"accent" : UIColor.tintColor,
        @"danger" : UIColor.systemRedColor,
        @"success" : UIColor.systemGreenColor,
        @"warning" : UIColor.systemOrangeColor,
    };
    return by[ink];
}

// A spacing step in points.
static CGFloat step(NSString* z) {
    NSDictionary<NSString*, NSNumber*>* by = @{ @"none" : @0, @"xs" : @4, @"s" : @8, @"m" : @16, @"l" : @32, @"xl" : @48 };
    return by[z] ? by[z].doubleValue : 8;
}

static void padded(SpikeNode* n, int code, NSString* z) {
    if (code == AVRA_FACT_pad_start) n.pad_start = step(z);
    if (code == AVRA_FACT_pad_top) n.pad_top = step(z);
    if (![n.view isKindOfClass:[UIStackView class]]) return;
    UIStackView* s = (UIStackView*)n.view;
    s.layoutMarginsRelativeArrangement = YES;
    NSDirectionalEdgeInsets m = s.directionalLayoutMargins;
    CGFloat p = step(z);
    if (code == AVRA_FACT_pad_start) m.leading = p;
    if (code == AVRA_FACT_pad_end) m.trailing = p;
    if (code == AVRA_FACT_pad_top) m.top = p;
    if (code == AVRA_FACT_pad_bottom) m.bottom = p;
    s.directionalLayoutMargins = m;
}

static void progressed(SpikeNode* n) {
    if ([n.control isKindOfClass:[UIProgressView class]]) ((UIProgressView*)n.control).progress = n.max > 0 ? n.amount / n.max : 0;
    if ([n.control isKindOfClass:[UISlider class]]) {
        ((UISlider*)n.control).maximumValue = n.max;
        ((UISlider*)n.control).value = n.amount;
    }
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

// The theme's mode: the device's own, or the one the program holds.
static void moded(NSString* mode) {
    UIUserInterfaceStyle s = [mode isEqualToString:@"dark"] ? UIUserInterfaceStyleDark : [mode isEqualToString:@"light"] ? UIUserInterfaceStyleLight : UIUserInterfaceStyleUnspecified;
    g_vc.view.window.overrideUserInterfaceStyle = s;
}

// One fact, by its code. A fact under an interaction is the host's control
// state to draw, and is carried only.
static void fact_set(SpikeNode* n, int code, NSString* under, NSString* kind, NSString* value) {
    if (![under isEqualToString:@"-"]) { [g_unused addObject:[NSString stringWithFormat:@"fact %d under %@", code, under]]; return; }
    BOOL on = [kind isEqualToString:@"f"] && [value isEqualToString:@"1"];
    UIView* v = n.view;
    switch (code) {
    case AVRA_FACT_words: worded(n, value); break;
    case AVRA_FACT_label:
        if (is_any(n, @[ @"card", @"fieldset", @"dialog", @"column", @"surface", @"form", @"list", @"item", @"row", @"alert" ])) titled(n, value);
        else worded(n, value);
        break;
    case AVRA_FACT_rank:
        if (n.label) n.label.font = [UIFont preferredFontForTextStyle:value.integerValue <= 1 ? UIFontTextStyleLargeTitle : value.integerValue == 2 ? UIFontTextStyleTitle2 : UIFontTextStyleTitle3];
        break;
    case AVRA_FACT_value:
        if ([n.control isKindOfClass:[UITextField class]]) ((UITextField*)n.control).text = value;
        break;
    case AVRA_FACT_amount: n.amount = value.doubleValue; progressed(n); break;
    case AVRA_FACT_max: n.max = value.doubleValue; progressed(n); break;
    case AVRA_FACT_placeholder:
        if ([n.control isKindOfClass:[UITextField class]]) ((UITextField*)n.control).placeholder = value;
        break;
    case AVRA_FACT_disabled:
        if ([n.control isKindOfClass:[UIControl class]]) ((UIControl*)n.control).enabled = !on;
        break;
    case AVRA_FACT_checked:
        if ([n.control isKindOfClass:[UISwitch class]]) ((UISwitch*)n.control).on = on;
        break;
    case AVRA_FACT_masked:
        if ([n.control isKindOfClass:[UITextField class]]) ((UITextField*)n.control).secureTextEntry = on;
        break;
    case AVRA_FACT_open: dialog_shown(n, on); break;
    case AVRA_FACT_name: (n.control ?: v).accessibilityLabel = value; break;
    case AVRA_FACT_title:
        if (!n.control && !n.label) titled(n, value);
        else [g_unused addObject:@"fact title on a control"];
        break;
    case AVRA_FACT_fill: {
        UIColor* c = tone_colour(value);
        v.backgroundColor = c;
        break;
    }
    case AVRA_FACT_ink: {
        UIColor* c = ink_colour(value);
        n.ink = c;
        if (n.label) n.label.textColor = c;
        if ([n.control isKindOfClass:[UIButton class]]) [(UIButton*)n.control setTitleColor:c forState:UIControlStateNormal];
        break;
    }
    case AVRA_FACT_radius: {
        NSDictionary<NSString*, NSNumber*>* by = @{ @"xs" : @4, @"s" : @6, @"m" : @10, @"l" : @16, @"xl" : @24 };
        v.layer.cornerRadius = by[value] ? by[value].doubleValue : 8;
        v.layer.cornerCurve = kCACornerCurveContinuous;
        v.clipsToBounds = YES;
        break;
    }
    case AVRA_FACT_gap:
        if ([v isKindOfClass:[UIStackView class]]) ((UIStackView*)v).spacing = step(value);
        break;
    case AVRA_FACT_pad_start: case AVRA_FACT_pad_end: case AVRA_FACT_pad_top: case AVRA_FACT_pad_bottom: padded(n, code, value); break;
    case AVRA_FACT_direction:
        if ([v isKindOfClass:[UIStackView class]]) {
            BOOL row = [value isEqualToString:@"row"];
            ((UIStackView*)v).axis = row ? UILayoutConstraintAxisHorizontal : UILayoutConstraintAxisVertical;
            ((UIStackView*)v).alignment = row ? UIStackViewAlignmentCenter : UIStackViewAlignmentLeading;
        }
        break;
    case AVRA_FACT_mode: moded(value); break;
    case AVRA_FACT_skipped_rows:
        if (g_row_h > 0 && v.backgroundColor != placeholder_rows()) v.backgroundColor = placeholder_rows();
        break;
    case AVRA_FACT_align: case AVRA_FACT_distribute: case AVRA_FACT_wrap: case AVRA_FACT_width: case AVRA_FACT_height: case AVRA_FACT_grow: case AVRA_FACT_order:
    case AVRA_FACT_margin_start: case AVRA_FACT_margin_end: case AVRA_FACT_margin_top: case AVRA_FACT_margin_bottom: break;
    default: [g_unused addObject:[NSString stringWithFormat:@"fact %d", code]];
    }
}

// A fact gone: the control as it stands without it.
static void fact_dropped(SpikeNode* n, int code) {
    switch (code) {
    case AVRA_FACT_disabled:
        if ([n.control isKindOfClass:[UIControl class]]) ((UIControl*)n.control).enabled = YES;
        break;
    case AVRA_FACT_checked:
        if ([n.control isKindOfClass:[UISwitch class]]) ((UISwitch*)n.control).on = NO;
        break;
    case AVRA_FACT_open: dialog_shown(n, NO); break;
    case AVRA_FACT_fill: n.view.backgroundColor = nil; break;
    case AVRA_FACT_value:
        if ([n.control isKindOfClass:[UITextField class]]) ((UITextField*)n.control).text = @"";
        break;
    default: [g_unused addObject:[NSString stringWithFormat:@"drop %d", code]];
    }
}

// An element goes into its parent's view; the solver's `rect` says where.
static void placed(SpikeNode* n, NSInteger parent, NSInteger after) {
    if (!n) return;
    SpikeNode* was = g_nodes[@(n.parent)];
    if (was) [was.kid_nodes removeObject:n];
    n.parent = parent;
    SpikeNode* into = g_nodes[@(parent)];
    if (into) {
        if (!into.kid_nodes) into.kid_nodes = [NSMutableArray new];
        if (![into.kid_nodes containsObject:n]) [into.kid_nodes addObject:n];
    }
    if (is(n, @"dialog")) return;
    SpikeNode* holder = g_nodes[@(parent)];
    if (holder && holder.control) {
        [g_unused addObject:[NSString stringWithFormat:@"a child placed in %@", holder.prim]];
        return;
    }
    UIView* into_view = holder ? holder.view : g_root;
    n.view.hidden = NO;
    if (n.view.superview == into_view) return;
    [n.view removeFromSuperview];
    [into_view addSubview:n.view];
}

// The solver's box for an element, relative to its parent's; a container's
// title stands at the top of its own content.
static void framed(SpikeNode* n, CGFloat x, CGFloat y, CGFloat w, CGFloat h) {
    if (!n) return;
    if (is(n, @"dialog") && n.sheet) {
        n.view.frame = CGRectMake(16, 24, w, h);
        return;
    }
    n.view.frame = CGRectMake(x, y, w, h);
    if (n.title) {
        CGSize s = [n.title sizeThatFits:CGSizeMake(w, CGFLOAT_MAX)];
        n.title.frame = CGRectMake(n.pad_start, n.pad_top, w - 2 * n.pad_start, s.height);
    }
}

// THE WINDOW: the rows of the first windowed list the scroll view shows,
// with an overscan above and below, at the height the solver gave a row.
static CGFloat g_row_h;
static CGFloat g_list_top;
static NSInteger g_win_from = -1;
static NSInteger g_win_to = -1;
static const NSInteger overscan = 3;

static void list_found(void) {
    for (SpikeNode* n in g_nodes.allValues) {
        if (!is(n, @"list")) continue;
        g_list_top = [n.view convertRect:n.view.bounds toView:g_root].origin.y;
        for (UIView* k in n.view.subviews)
            if (k.subviews.count > 0 && k.frame.size.height > 0) { g_row_h = k.frame.size.height; return; }
    }
}

static BOOL g_win_pending;
static CGFloat g_last_y;
static double g_last_t;
static NSInteger g_scroll_seq;

// A new window only when the rows on screen near the edge of the one standing,
// reaching ahead of the scroll by what it will travel before the next paint.
static void window_asked(void) {
    if (g_row_h <= 0 || g_win_pending || !g_deadline) return;
    CGFloat y = g_scroll.contentOffset.y - 16 - g_list_top;
    double now = CACurrentMediaTime();
    double v = g_last_t > 0 && now > g_last_t ? (y - g_last_y) / (now - g_last_t) / g_row_h : 0;
    g_last_y = y;
    g_last_t = now;
    NSInteger top = MAX(0, (NSInteger)floor(y / g_row_h));
    NSInteger bottom = top + (NSInteger)ceil(g_scroll.bounds.size.height / g_row_h);
    const NSInteger margin = 1;
    if (g_win_from >= 0 && top - margin >= g_win_from && bottom + margin <= g_win_to) return;
    // too fast for any row to be read: the placeholders carry the scroll, and
    // the rows come when it slows (the scroll's own end asks again)
    if (fabs(v) > 1000) return;
    NSInteger lead = MIN(40, (NSInteger)ceil(fabs(v) * 0.15));
    NSInteger from = MAX(0, top - overscan - (v < 0 ? lead : 0));
    NSInteger to = bottom + overscan + (v > 0 ? lead : 0);
    if (from == g_win_from && to == g_win_to) return;
    if (!avra_host_idling()) return;
    g_win_from = from;
    g_win_to = to;
    g_win_pending = YES;
    avra_spike_scrolled(from, to, (int64_t)llround(g_row_h));
    resumed();
}

// What a spacer shows while its rows are on the way: one placeholder row,
// repeated at the remembered row height.
static UIColor* placeholder_rows(void) {
    static UIColor* c;
    static CGFloat for_h;
    if (c && for_h == g_row_h) return c;
    for_h = g_row_h;
    UIGraphicsImageRenderer* r = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(1000, g_row_h)];
    UIImage* row = [r imageWithActions:^(UIGraphicsImageRendererContext* ctx) {
        [UIColor.tertiarySystemFillColor setFill];
        CGFloat mid = g_row_h / 2;
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, mid - 15, 51, 30) cornerRadius:15] fill];
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(60, mid - 7, 90, 14) cornerRadius:7] fill];
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(162, mid - 12, 70, 24) cornerRadius:6] fill];
    }];
    c = [UIColor colorWithPatternImage:row];
    return c;
}

@interface SpikeScrollWatch : NSObject <UIScrollViewDelegate>
@end
@implementation SpikeScrollWatch
- (void)scrollViewDidScroll:(UIScrollView*)s {
    window_asked();
    NSInteger seq = ++g_scroll_seq;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (seq != g_scroll_seq) return;
        g_last_t = 0;
        window_asked();
    });
}
- (void)scrollViewDidEndDecelerating:(UIScrollView*)s { g_last_t = 0; window_asked(); }
- (void)scrollViewDidEndDragging:(UIScrollView*)s willDecelerate:(BOOL)d { if (!d) { g_last_t = 0; window_asked(); } }
@end
static SpikeScrollWatch* g_scroll_watch;

// A paint reached the views: what it cost the host, and the instrument told.
static void painted(void) {
    if (g_win_pending) {
        g_win_pending = NO;
        dispatch_async(dispatch_get_main_queue(), ^{ window_asked(); });
    }
    if (NSProcessInfo.processInfo.environment[@"AVRA_SPIKE_BENCH"])
    {
        double l0 = CACurrentMediaTime();
        [g_scroll layoutIfNeeded];
        double layout_s = CACurrentMediaTime() - l0;
        NSMutableString* ops = [NSMutableString new];
        for (NSString* k in g_op_s) [ops appendFormat:@" %@_us=%.0f", k, g_op_s[k].doubleValue * 1e6];
        if (NSProcessInfo.processInfo.environment[@"AVRA_SPIKE_BENCH"])
            said([NSString stringWithFormat:@"host apply_us=%.0f measures=%ld measure_us=%.0f reused=%ld rows_reused=%ld pair_us=%.0f parse_us=%.0f layout_us=%.0f%@", g_apply_s * 1e6, (long)g_measures, g_measure_s * 1e6, (long)g_reused, (long)g_rows_reused, g_pair_s * 1e6, g_parse_s * 1e6, layout_s * 1e6, ops]);
        g_rows_reused = 0;
        g_pair_s = 0;
        [g_op_s removeAllObjects];
        g_parse_s = 0;
    }
    g_reused = 0;
    g_apply_s = 0;
    g_measures = 0;
    g_measure_s = 0;
    bench_first_applied();
    if (g_toggling) { g_toggling = NO; bench_toggle_applied(); }
    if (g_row_h <= 0) {
        list_found();
        if (g_row_h > 0) dispatch_async(dispatch_get_main_queue(), ^{ window_asked(); });
    }
}

// THE POOL: a removed element's view, and every view under it, waits by its
// prim for the next create of that prim, as a table's cells wait for reuse.
static NSMutableDictionary<NSString*, NSMutableArray<SpikeNode*>*>* g_pool;
// The first window: the rows the screen shows at UIKit's standard row height, and
// the overscan this target keeps.
int64_t avra_spike_visible_rows(void) {
    return (int64_t)ceil(UIScreen.mainScreen.bounds.size.height / 44.0) + overscan;
}

// A pooled element as a fresh one of its prim: everything a fact could have set, unset.
static void reset(SpikeNode* n) {
    UIView* v = n.view;
    v.backgroundColor = nil;
    v.layer.cornerRadius = 0;
    v.hidden = NO;
    v.accessibilityLabel = nil;
    if (n.title) { [n.title removeFromSuperview]; n.title = nil; }
    if (n.label) { n.label.text = nil; n.label.textColor = UIColor.labelColor; n.label.accessibilityLabel = nil; }
    if ([n.control isKindOfClass:[UIButton class]]) [(UIButton*)n.control setTitle:nil forState:UIControlStateNormal];
    if ([n.control isKindOfClass:[UIControl class]]) ((UIControl*)n.control).enabled = YES;
    if ([n.control isKindOfClass:[UISwitch class]]) ((UISwitch*)n.control).on = NO;
    if ([n.control isKindOfClass:[UITextField class]]) { ((UITextField*)n.control).text = nil; ((UITextField*)n.control).placeholder = nil; }
    n.control.accessibilityLabel = nil;
    n.ink = nil;
    n.pad_start = n.pad_top = 0;
    n.seat = n.said_seat = 0;
    n.max = n.amount = 0;
    n.parent = 0;
    [n.kid_nodes removeAllObjects];
    [n.facts removeAllObjects];
    n.fresh = nil;
}

// An element of `prim` numbered `nid`: from the pool when one waits, else made.
static SpikeNode* taken(NSString* prim, NSInteger nid) {
    SpikeNode* n = [g_pool[prim] lastObject];
    if (n) {
        [g_pool[prim] removeLastObject];
        reset(n);
        g_reused++;
    } else {
        n = [SpikeNode new];
        n.prim = prim;
        made(n);
    }
    n.nid = nid;
    n.view.tag = nid;
    n.control.tag = nid;
    n.view.accessibilityIdentifier = [NSString stringWithFormat:@"avra-%ld", (long)nid];
    return n;
}

// A subtree's shape: its prim and its children's shapes in order.
static NSString* shape_of(SpikeNode* n) {
    if (n.kid_nodes.count == 0) return n.prim;
    NSMutableArray* parts = [NSMutableArray new];
    for (SpikeNode* k in n.kid_nodes) [parts addObject:shape_of(k)];
    return [NSString stringWithFormat:@"%@(%@)", n.prim, [parts componentsJoinedByString:@";"]];
}

// THE ROW POOL: a removed subtree waits whole, hidden where it stood, keyed by
// its shape, for a create of the same shape — as a table's cell is reused whole.
static NSMutableDictionary<NSString*, NSMutableArray<SpikeNode*>*>* g_rows;

// What the pools keep: a window move's worth, no more; the rest is released.
static const NSUInteger row_pool_cap = 8;
static const NSUInteger view_pool_cap = 32;

// Every node of a subtree, in order: the root, then each child's subtree.
static void preorder(SpikeNode* n, NSMutableArray<SpikeNode*>* out) {
    if (!n) return;
    [out addObject:n];
    for (SpikeNode* k in n.kid_nodes) preorder(k, out);
}

// `n` leaves the page: a subtree for the row pool, a single element for its prim's.
static void pooled(SpikeNode* n) {
    if (!n) return;
    if (n.sheet) dialog_shown(n, NO);
    n.view.hidden = YES;
    if (n.kid_nodes.count > 0) {
        NSString* shape = shape_of(n);
        NSMutableArray<SpikeNode*>* all = [NSMutableArray new];
        preorder(n, all);
        for (SpikeNode* m in all) [g_nodes removeObjectForKey:@(m.nid)];
        if (!g_rows) g_rows = [NSMutableDictionary new];
        if (!g_rows[shape]) g_rows[shape] = [NSMutableArray new];
        if (g_rows[shape].count >= row_pool_cap) { [n.view removeFromSuperview]; return; }
        [g_rows[shape] addObject:n];
        return;
    }
    [g_nodes removeObjectForKey:@(n.nid)];
    if (!g_pool) g_pool = [NSMutableDictionary new];
    if (!g_pool[n.prim]) g_pool[n.prim] = [NSMutableArray new];
    if (g_pool[n.prim].count >= view_pool_cap) { [n.view removeFromSuperview]; return; }
    [g_pool[n.prim] addObject:n];
}

// THE PAIRING, read from a frame before it is applied: each subtree it creates
// is matched by shape to a pooled one, whose nodes take the new numbers in
// order. Answers the numbers whose create and inner place the pairing carries.
static NSMutableSet<NSNumber*>* paired(NSArray<NSArray<NSString*>*>* records, NSMutableSet<NSNumber*>* roots) {
    NSMutableDictionary<NSNumber*, NSString*>* made_prim = [NSMutableDictionary new];
    NSMutableDictionary<NSNumber*, NSNumber*>* parent_of = [NSMutableDictionary new];
    NSMutableDictionary<NSNumber*, NSMutableArray<NSNumber*>*>* kids_of = [NSMutableDictionary new];
    NSMutableArray<NSNumber*>* order = [NSMutableArray new];
    for (NSArray<NSString*>* w in records) {
        if ([w[0] isEqualToString:@"create"]) {
            made_prim[@([w[1] integerValue])] = w[2];
            [order addObject:@([w[1] integerValue])];
        } else if ([w[0] isEqualToString:@"place"]) {
            NSNumber* id = @([w[1] integerValue]);
            NSNumber* parent = @([w[2] integerValue]);
            parent_of[id] = parent;
            if (made_prim[parent]) {
                if (!kids_of[parent]) kids_of[parent] = [NSMutableArray new];
                [kids_of[parent] addObject:id];
            }
        }
    }
    NSMutableSet<NSNumber*>* carried = [NSMutableSet new];
    NSString* (^__block shape)(NSNumber*) = nil;
    __block __weak NSString* (^weak_shape)(NSNumber*);
    weak_shape = shape = ^NSString*(NSNumber* id) {
        NSArray* ks = kids_of[id];
        if (ks.count == 0) return made_prim[id];
        NSMutableArray* parts = [NSMutableArray new];
        for (NSNumber* k in ks) [parts addObject:weak_shape(k)];
        return [NSString stringWithFormat:@"%@(%@)", made_prim[id], [parts componentsJoinedByString:@";"]];
    };
    void (^__block flat)(NSNumber*, NSMutableArray*) = nil;
    __block __weak void (^weak_flat)(NSNumber*, NSMutableArray*);
    weak_flat = flat = ^(NSNumber* id, NSMutableArray* out) {
        [out addObject:id];
        for (NSNumber* k in kids_of[id]) weak_flat(k, out);
    };
    for (NSNumber* id in order) {
        if (made_prim[parent_of[id]]) continue;
        if (kids_of[id].count == 0) continue;
        NSString* s = shape(id);
        SpikeNode* r = [g_rows[s] lastObject];
        if (!r) continue;
        [g_rows[s] removeLastObject];
        NSMutableArray<NSNumber*>* ids = [NSMutableArray new];
        flat(id, ids);
        NSMutableArray<SpikeNode*>* nodes = [NSMutableArray new];
        preorder(r, nodes);
        for (NSUInteger i = 0; i < ids.count && i < nodes.count; i++) {
            SpikeNode* m = nodes[i];
            NSInteger nid = ids[i].integerValue;
            m.nid = nid;
            m.view.tag = nid;
            m.control.tag = nid;
            m.fresh = [NSMutableSet new];
            g_nodes[ids[i]] = m;
            [carried addObject:ids[i]];
        }
        [roots addObject:id];
        g_rows_reused++;
    }
    return carried;
}

static NSString* rest(NSArray<NSString*>* w, NSUInteger from) {
    return w.count > from ? [[w subarrayWithRange:NSMakeRange(from, w.count - from)] componentsJoinedByString:@" "] : @"";
}

// A frame's records applied: each a record's words — the text frame's, split, or
// the direct calls', as they came.
static void apply_records(NSArray<NSArray<NSString*>*>* records) {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    NSMutableSet<NSNumber*>* roots = [NSMutableSet new];
    double r0 = CACurrentMediaTime();
    NSMutableSet<NSNumber*>* carried = paired(records, roots);
    g_pair_s += CACurrentMediaTime() - r0;
    for (NSArray<NSString*>* w in records) {
        if (w.count < 2) continue;
        NSString* op = w[0];
        NSInteger nid = w[1].integerValue;
        SpikeNode* n = g_nodes[@(nid)];
        double t1 = CACurrentMediaTime();
        if ([op isEqualToString:@"create"]) {
            if (![carried containsObject:@(nid)]) g_nodes[@(nid)] = taken(w[2], nid);
        } else if ([op isEqualToString:@"fact"] && w.count >= 5) {
            NSString* key = [NSString stringWithFormat:@"%@|%@", w[2], w[3]];
            NSString* value = rest(w, 4);
            if (!n.facts) n.facts = [NSMutableDictionary new];
            [n.fresh addObject:key];
            if (![n.facts[key] isEqualToString:value]) {
                fact_set(n, w[2].intValue, w[3], w[4], rest(w, 5));
                n.facts[key] = value;
            }
        } else if ([op isEqualToString:@"drop"]) {
            [n.facts removeObjectForKey:[NSString stringWithFormat:@"%@|%@", w[2], w.count > 3 ? w[3] : @"-"]];
            fact_dropped(n, w[2].intValue);
        } else if ([op isEqualToString:@"place"]) {
            if (![carried containsObject:@(nid)] || [roots containsObject:@(nid)]) placed(n, w[2].integerValue, w[3].integerValue);
        } else if ([op isEqualToString:@"remove"]) {
            SpikeNode* above = g_nodes[@(n.parent)];
            if (above) [above.kid_nodes removeObject:n];
            pooled(n);
        } else if ([op isEqualToString:@"listen"]) {
            if ([w[3] isEqualToString:@"button"] || [w[3] isEqualToString:@"link"] || [w[3] isEqualToString:@"dialog"]) n.seat = w[2].integerValue;
            else n.said_seat = w[2].integerValue;
        } else if ([op isEqualToString:@"rect"] && w.count >= 6) {
            framed(n, w[2].doubleValue, w[3].doubleValue, w[4].doubleValue, w[5].doubleValue);
        } else if ([op isEqualToString:@"content"] && w.count == 2) {
            painted();
        } else if ([op isEqualToString:@"content"] && w.count >= 3) {
            g_root.frame = CGRectMake(16, 16, w[1].doubleValue, w[2].doubleValue);
            g_scroll.contentSize = CGSizeMake(g_scroll.bounds.size.width, w[2].doubleValue + 32);
            painted();
        } else if ([op isEqualToString:@"unlisten"]) {
        } else {
            [g_unused addObject:op];
        }
        if (!g_op_s) g_op_s = [NSMutableDictionary new];
        g_op_s[op] = @([g_op_s[op] doubleValue] + CACurrentMediaTime() - t1);
    }
    for (NSNumber* id in carried) {
        SpikeNode* m = g_nodes[id];
        for (NSString* key in m.facts.allKeys) {
            if ([m.fresh containsObject:key]) continue;
            fact_dropped(m, [key componentsSeparatedByString:@"|"][0].intValue);
            [m.facts removeObjectForKey:key];
        }
        m.fresh = nil;
    }
    [CATransaction commit];
}

// THE TEXT FRAME, read for debugging: its lines split into records.
static void applied(NSString* frame) {
    double s0 = CACurrentMediaTime();
    NSMutableArray<NSArray<NSString*>*>* records = [NSMutableArray new];
    for (NSString* line in [frame componentsSeparatedByString:@"\n"]) [records addObject:[line componentsSeparatedByString:@" "]];
    g_parse_s += CACurrentMediaTime() - s0;
    apply_records(records);
}

// THE PROGRAM'S FRAME: drawn at once once the window stands, kept until then.
// What follows every frame applied: the unused records said, the first frame timed.
static void frame_done(void) {
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

void avra_spike_frame(const char* records) {
    NSString* frame = [NSString stringWithUTF8String:records];
    if (!g_root) {
        [g_pending addObject:frame];
        return;
    }
    if (NSProcessInfo.processInfo.environment[@"AVRA_SPIKE_FRAMES"]) said([@"frame: " stringByAppendingString:[frame stringByReplacingOccurrencesOfString:@"\n" withString:@" ; "]]);
    double a0 = CACurrentMediaTime();
    applied(frame);
    g_apply_s += CACurrentMediaTime() - a0;
    frame_done();
}

// THE DIRECT CALLS: the program says each patch as a call inside its turn, between
// a begin and an end; nothing is written as text or parsed. A frame said before
// the window stands waits for it.
static NSMutableArray<NSArray<NSString*>*>* g_ops;
static NSMutableArray<NSMutableArray<NSArray<NSString*>*>*>* g_pending_ops;

static NSString* num(int64_t n) { return [NSString stringWithFormat:@"%lld", n]; }
static NSString* text(const char* s) { return [NSString stringWithUTF8String:s]; }

void avra_spike_begin(void) { g_ops = [NSMutableArray new]; }
void avra_spike_create(int64_t id, const char* prim) { [g_ops addObject:@[ @"create", num(id), text(prim) ]]; }
void avra_spike_fact_text(int64_t id, int64_t code, const char* under, const char* value) { [g_ops addObject:@[ @"fact", num(id), num(code), text(under), @"t", text(value) ]]; }
void avra_spike_fact_flag(int64_t id, int64_t code, const char* under, int64_t on) { [g_ops addObject:@[ @"fact", num(id), num(code), text(under), @"f", on ? @"1" : @"0" ]]; }
void avra_spike_fact_number(int64_t id, int64_t code, const char* under, int64_t n) { [g_ops addObject:@[ @"fact", num(id), num(code), text(under), @"n", num(n) ]]; }
void avra_spike_fact_fraction(int64_t id, int64_t code, const char* under, double x) { [g_ops addObject:@[ @"fact", num(id), num(code), text(under), @"x", [NSString stringWithFormat:@"%g", x] ]]; }
void avra_spike_drop(int64_t id, int64_t code, const char* under) { [g_ops addObject:@[ @"drop", num(id), num(code), text(under) ]]; }
void avra_spike_place(int64_t id, int64_t parent, int64_t after) { [g_ops addObject:@[ @"place", num(id), num(parent), num(after) ]]; }
void avra_spike_remove(int64_t id) { [g_ops addObject:@[ @"remove", num(id) ]]; }
void avra_spike_listen(int64_t id, int64_t seat, const char* kind) { [g_ops addObject:@[ @"listen", num(id), num(seat), text(kind) ]]; }
void avra_spike_unlisten(int64_t id, int64_t seat) { [g_ops addObject:@[ @"unlisten", num(id), num(seat) ]]; }
void avra_spike_rect(int64_t id, int64_t x, int64_t y, int64_t w, int64_t h) { [g_ops addObject:@[ @"rect", num(id), num(x), num(y), num(w), num(h) ]]; }
void avra_spike_content(int64_t w, int64_t h) { [g_ops addObject:@[ @"content", num(w), num(h) ]]; }
void avra_spike_content_still(void) { [g_ops addObject:@[ @"content", @"still" ]]; }

void avra_spike_end(void) {
    if (!g_root) {
        if (!g_pending_ops.count) bench_mark("first frame said");
        if (!g_pending_ops) g_pending_ops = [NSMutableArray new];
        [g_pending_ops addObject:g_ops];
        return;
    }
    double a0 = CACurrentMediaTime();
    apply_records(g_ops);
    g_apply_s += CACurrentMediaTime() - a0;
    frame_done();
}

// ── What the witness reads: the accessibility tree ──────────────

static void announced(UIView* v, NSMutableArray<NSString*>* out) {
    if ([v isKindOfClass:[UISwitch class]] && v.accessibilityLabel.length) {
        [out addObject:[NSString stringWithFormat:@"switch %@: %@", ((UISwitch*)v).on ? @"on" : @"off", v.accessibilityLabel]];
        return;
    }
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

static UISwitch* switch_for(UIView* v, NSString* words) {
    if ([v isKindOfClass:[UISwitch class]] && [v.accessibilityLabel isEqualToString:words]) return (UISwitch*)v;
    for (UIView* c in v.subviews) {
        UISwitch* f = switch_for(c, words);
        if (f) return f;
    }
    return nil;
}

static void board_said(NSString* when) {
    said([NSString stringWithFormat:@"board %@: %@", when, [a11y_said() componentsJoinedByString:@" | "]]);
}

// The board's script: "Buy milk" typed and added at 3 s, ticked done at 7 s;
// the About dialog opened at 15 s when AVRA_SPIKE_BOARD_SCRIPT is 1.
static void board_scripted(void) {
    if ([NSProcessInfo.processInfo.environment[@"AVRA_SPIKE_BOARD_SCRIPT"] isEqualToString:@"3"]) {
        after(3, ^{ [(UIButton*)a11y_find(g_root, @"Dark mode") sendActionsForControlEvents:UIControlEventTouchUpInside]; });
        return;
    }
    after(3, ^{
        board_said(@"loaded");
        UITextField* f = (UITextField*)found_kind(g_root, [UITextField class]);
        f.text = @"Buy milk";
        [g_target typed:f];
        after(0.5, ^{
            [(UIButton*)a11y_find(g_root, @"Add") sendActionsForControlEvents:UIControlEventTouchUpInside];
        });
    });
    after(7, ^{
        board_said(@"after Add");
        UISwitch* s = switch_for(g_root, @"Buy milk");
        said([NSString stringWithFormat:@"board switch for Buy milk: %@", s ? @"found" : @"none"]);
        if (s) {
            s.on = YES;
            [g_target flipped:s];
        }
    });
    after(10, ^{ board_said(@"after tick"); });
    after(14, ^{ board_said(@"at 14 s"); });
    if ([NSProcessInfo.processInfo.environment[@"AVRA_SPIKE_BOARD_SCRIPT"] isEqualToString:@"1"]) {
        after(15, ^{
            [(UIButton*)a11y_find(g_root, @"About") sendActionsForControlEvents:UIControlEventTouchUpInside];
        });
    }
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

// The page's width changed — a rotation, a split, a resize — so the
// program's measures are stale and it places again.
@interface SpikeVC : UIViewController
@end
@implementation SpikeVC
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = g_scroll.bounds.size.width - 32;
    if (w <= 0 || w == g_width) return;
    BOOL first = g_width == 0;
    g_width = w;
    if (first) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!avra_host_idling()) return;
        avra_spike_resized();
        resumed();
    });
}
@end

// The width the page has, in points: the scroll view's less its margins,
// the screen's before it stands.
int64_t avra_spike_width(void) {
    if (g_width > 0) return (int64_t)g_width;
    return (int64_t)(UIScreen.mainScreen.bounds.size.width - 32);
}

static int64_t sixtieths(CGFloat points) { return (int64_t)llround(points * 60); }

// A control's own chrome, read once from one real instance of each.
typedef struct { CGSize sw; CGFloat field_h; CGFloat bar_h; CGFloat slider_h; CGSize spinner; } Chrome;

static Chrome chrome(void) {
    static Chrome c;
    static BOOL read;
    if (read) return c;
    read = YES;
    c.sw = [UISwitch new].intrinsicContentSize;
    UITextField* f = [UITextField new];
    f.borderStyle = UITextBorderStyleRoundedRect;
    f.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    c.field_h = f.intrinsicContentSize.height;
    c.bar_h = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault].intrinsicContentSize.height;
    c.slider_h = [UISlider new].intrinsicContentSize.height;
    c.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium].intrinsicContentSize;
    return c;
}

// Words in a text style, wrapped to `avail` points.
static CGSize words_in(NSString* s, UIFontTextStyle style, CGFloat avail) {
    if (s.length == 0) return CGSizeMake(0, 0);
    CGRect r = [s boundingRectWithSize:CGSizeMake(avail, CGFLOAT_MAX)
                               options:NSStringDrawingUsesLineFragmentOrigin
                            attributes:@{NSFontAttributeName : [UIFont preferredFontForTextStyle:style]}
                               context:nil];
    return CGSizeMake(ceil(r.size.width), ceil(r.size.height));
}

// A control's size from its words and its chrome, no control built.
static CGSize fitted(NSString* p, NSString* s, CGFloat avail) {
    Chrome c = chrome();
    if ([p isEqualToString:@"text"]) return words_in(s, UIFontTextStyleBody, avail);
    if ([p isEqualToString:@"heading"]) return words_in(s, UIFontTextStyleTitle2, avail);
    if ([p isEqualToString:@"button"] || [p isEqualToString:@"link"]) {
        CGSize w = words_in(s, UIFontTextStyleBody, avail - 24);
        return CGSizeMake(w.width + 24, w.height + 12);
    }
    if ([p isEqualToString:@"field"]) {
        CGSize w = words_in(s, UIFontTextStyleBody, avail);
        return CGSizeMake(MAX(w.width, 200), w.height + 8 + c.field_h);
    }
    if ([p isEqualToString:@"switch"] || [p isEqualToString:@"checkbox"]) {
        CGSize w = words_in(s, UIFontTextStyleBody, avail - c.sw.width - 8);
        return CGSizeMake(c.sw.width + 8 + w.width, MAX(c.sw.height, w.height));
    }
    if ([p isEqualToString:@"progress"] || [p isEqualToString:@"slider"]) {
        CGSize w = words_in(s, UIFontTextStyleBody, avail);
        return CGSizeMake(200, w.height + 8 + ([p isEqualToString:@"progress"] ? c.bar_h : c.slider_h));
    }
    if ([p isEqualToString:@"divider"]) return CGSizeMake(300, 1.0 / UIScreen.mainScreen.scale);
    if ([p isEqualToString:@"spinner"]) return c.spinner;
    if ([p isEqualToString:@"image"] || [p isEqualToString:@"icon"]) return words_in(@"▢", UIFontTextStyleCaption1, avail);
    if ([p isEqualToString:@"key"]) return CGSizeMake(0, 0);
    return words_in(s, [p isEqualToString:@"card"] ? UIFontTextStyleTitle3 : UIFontTextStyleHeadline, avail);
}

int64_t avra_spike_measure(const char* prim, const char* words, const char* placeholder, int64_t avail) {
    g_measures++;
    double t0 = CACurrentMediaTime();
    NSString* p = [NSString stringWithUTF8String:prim];
    NSString* s = [NSString stringWithUTF8String:words];
    BOOL container = [@[ @"row", @"column", @"surface", @"list", @"item", @"card", @"form", @"fieldset", @"dialog" ] containsObject:p];
    CGSize fit = container && s.length == 0 ? CGSizeMake(0, 0) : fitted(p, s, avail);
    g_measure_s += CACurrentMediaTime() - t0;
    CGFloat w = MIN(ceil(fit.width), (CGFloat)avail);
    return sixtieths(w) * 1000000 + sixtieths(ceil(fit.height));
}

int64_t avra_spike_narrowest(const char* prim, const char* words) {
    g_measures++;
    NSString* s = [NSString stringWithUTF8String:words];
    UIFont* f = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    CGFloat widest = 0;
    for (NSString* word in [s componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceCharacterSet])
        widest = MAX(widest, ceil([word sizeWithAttributes:@{NSFontAttributeName : f}].width));
    NSString* p = [NSString stringWithUTF8String:prim];
    if ([p isEqualToString:@"button"] || [p isEqualToString:@"link"])
        return sixtieths(ceil([s sizeWithAttributes:@{NSFontAttributeName : f}].width) + 25);
    if ([p isEqualToString:@"switch"] || [p isEqualToString:@"checkbox"]) widest += 59;
    if ([p isEqualToString:@"field"] || [p isEqualToString:@"progress"] || [p isEqualToString:@"slider"]) widest = MAX(widest, 120);
    return sixtieths(widest);
}

// ── The app ─────────────────────────────────────────────────────

@interface SpikeScene : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, strong) UIWindow* window;
@end

@implementation SpikeScene
- (void)scene:(UIScene*)scene willConnectToSession:(UISceneSession*)session options:(UISceneConnectionOptions*)options {
    bench_mark("scene connects");
    UIWindow* w = [[UIWindow alloc] initWithWindowScene:(UIWindowScene*)scene];
    UIViewController* vc = [SpikeVC new];
    vc.view.backgroundColor = UIColor.systemBackgroundColor;
    g_root = [UIView new];
    UIScrollView* sv = [UIScrollView new];
    sv.translatesAutoresizingMaskIntoConstraints = NO;
    [vc.view addSubview:sv];
    [sv addSubview:g_root];
    g_scroll = sv;
    UILayoutGuide* safe = vc.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [sv.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [sv.bottomAnchor constraintEqualToAnchor:vc.view.bottomAnchor],
        [sv.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor],
        [sv.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
    ]];
    w.rootViewController = vc;
    g_vc = vc;
    self.window = w;
    [w makeKeyAndVisible];
    g_scroll_watch = [SpikeScrollWatch new];
    g_scroll.delegate = g_scroll_watch;
    bench_attach(g_scroll, ^{
        UISwitch* s = (UISwitch*)found_kind(g_root, [UISwitch class]);
        if (!s) return;
        g_toggling = YES;
        s.on = !s.on;
        [g_target flipped:s];
    });
    for (NSString* f in g_pending) avra_spike_frame(f.UTF8String);
    for (NSMutableArray* ops in g_pending_ops) {
        g_ops = ops;
        avra_spike_end();
    }
    [g_pending_ops removeAllObjects];
    [g_pending removeAllObjects];
    sources_armed();
    g_frames = [SpikeFrames new];
    [[CADisplayLink displayLinkWithTarget:g_frames selector:@selector(ticked:)] addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    resumed();
    if (NSProcessInfo.processInfo.environment[@"AVRA_SPIKE_WITNESS"]) witnessed(w);
    if (NSProcessInfo.processInfo.environment[@"AVRA_SPIKE_BOARD_SCRIPT"]) board_scripted();
    bench_start();
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
    bench_mark("program reaches the host");
    g_started_ms = started_ms();
    g_nodes = [NSMutableDictionary new];
    g_pending = [NSMutableArray new];
    g_unused = [NSCountedSet new];
    g_target = [SpikeTarget new];
    avra_host_attach(host_loop);
}

// An app has no fork, so nothing is prepared for one.
void avra_fork_hook(int (*prepare)(const char** why)) { (void)prepare; }

// A line the program asks the host to say, flushed at once.
void avra_spike_log(const char* words) { said([NSString stringWithUTF8String:words]); }
