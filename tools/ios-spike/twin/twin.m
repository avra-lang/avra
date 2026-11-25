// THE TWIN: the board's screen written the way a competent iOS developer
// writes it — a UITableView with cell reuse, a switch, the title and a Remove
// button per row, the header's controls above — over N tasks in memory, no
// Avra. Measured by the same instrument as the Avra app (spike_bench.m).
#import <UIKit/UIKit.h>
#import "../host/spike_bench.h"

@interface Task : NSObject
@property(nonatomic) NSInteger tid;
@property(nonatomic, copy) NSString* title;
@property(nonatomic) BOOL done;
@end
@implementation Task
@end

@interface TaskCell : UITableViewCell
@property(nonatomic, strong) UISwitch* box;
@property(nonatomic, strong) UILabel* title;
@property(nonatomic, strong) UIButton* remove;
@property(nonatomic, copy) void (^flipped)(BOOL on);
@property(nonatomic, copy) void (^removed)(void);
@end

@implementation TaskCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)rid {
    self = [super initWithStyle:style reuseIdentifier:rid];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.box = [UISwitch new];
    [self.box addTarget:self action:@selector(flip) forControlEvents:UIControlEventValueChanged];
    self.title = [UILabel new];
    self.title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    UIButtonConfiguration* cfg = [UIButtonConfiguration grayButtonConfiguration];
    cfg.title = @"Remove";
    self.remove = [UIButton buttonWithConfiguration:cfg primaryAction:nil];
    [self.remove addTarget:self action:@selector(drop) forControlEvents:UIControlEventTouchUpInside];
    UIStackView* row = [[UIStackView alloc] initWithArrangedSubviews:@[ self.box, self.title, self.remove ]];
    row.spacing = 8;
    row.alignment = UIStackViewAlignmentCenter;
    row.translatesAutoresizingMaskIntoConstraints = NO;
    [self.title setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self.contentView addSubview:row];
    UILayoutGuide* m = self.contentView.layoutMarginsGuide;
    [NSLayoutConstraint activateConstraints:@[
        [row.leadingAnchor constraintEqualToAnchor:m.leadingAnchor],
        [row.trailingAnchor constraintEqualToAnchor:m.trailingAnchor],
        [row.topAnchor constraintEqualToAnchor:m.topAnchor],
        [row.bottomAnchor constraintEqualToAnchor:m.bottomAnchor],
    ]];
    return self;
}
- (void)flip { if (self.flipped) self.flipped(self.box.on); }
- (void)drop { if (self.removed) self.removed(); }
@end

@interface Board : UIViewController <UITableViewDataSource>
@property(nonatomic, strong) NSMutableArray<Task*>* tasks;
@property(nonatomic, strong) UITableView* table;
@property(nonatomic, strong) UIProgressView* progress;
@property(nonatomic, strong) UILabel* footer;
@property(nonatomic) BOOL applied;
@end

@implementation Board
- (UIButton*)button:(NSString*)title filled:(BOOL)filled {
    UIButtonConfiguration* cfg = filled ? [UIButtonConfiguration grayButtonConfiguration] : [UIButtonConfiguration plainButtonConfiguration];
    cfg.title = title;
    return [UIButton buttonWithConfiguration:cfg primaryAction:nil];
}

- (UIView*)header {
    UILabel* title = [UILabel new];
    title.text = @"Tasks";
    title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleLargeTitle];
    UILabel* sub = [UILabel new];
    sub.text = @"Every task is a value; the screen is a function of state.";
    sub.textColor = UIColor.secondaryLabelColor;
    sub.numberOfLines = 0;
    UIStackView* words = [[UIStackView alloc] initWithArrangedSubviews:@[ title, sub ]];
    words.axis = UILayoutConstraintAxisVertical;
    UIStackView* top = [[UIStackView alloc] initWithArrangedSubviews:@[ words, [self button:@"Dark mode" filled:YES] ]];
    top.alignment = UIStackViewAlignmentCenter;
    top.spacing = 8;
    UILabel* done = [UILabel new];
    done.text = @"Done";
    self.progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    UIStackView* filters = [[UIStackView alloc] initWithArrangedSubviews:@[
        [self button:@"All" filled:YES], [self button:@"Active" filled:NO], [self button:@"Done" filled:NO],
        [self button:@"Clear done" filled:YES], [self button:@"Newest first" filled:NO],
    ]];
    filters.spacing = 8;
    UITextField* field = [UITextField new];
    field.placeholder = @"Type a task…";
    field.borderStyle = UITextBorderStyleRoundedRect;
    UIStackView* add = [[UIStackView alloc] initWithArrangedSubviews:@[ field, [self button:@"Add" filled:YES] ]];
    add.spacing = 8;
    self.footer = [UILabel new];
    UIStackView* all = [[UIStackView alloc] initWithArrangedSubviews:@[ top, done, self.progress, filters, add, self.footer ]];
    all.axis = UILayoutConstraintAxisVertical;
    all.spacing = 12;
    all.layoutMarginsRelativeArrangement = YES;
    all.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(16, 16, 16, 16);
    CGSize fit = [all systemLayoutSizeFittingSize:CGSizeMake(UIScreen.mainScreen.bounds.size.width, UILayoutFittingCompressedSize.height)
                    withHorizontalFittingPriority:UILayoutPriorityRequired
                          verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
    all.frame = CGRectMake(0, 0, fit.width, fit.height);
    return all;
}

- (void)counted {
    NSInteger done = 0;
    for (Task* t in self.tasks) done += t.done;
    self.progress.progress = self.tasks.count ? (float)done / self.tasks.count : 0;
    self.footer.text = [NSString stringWithFormat:@"%ld open · %ld done of %ld", (long)(self.tasks.count - done), (long)done, (long)self.tasks.count];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSInteger n = NSProcessInfo.processInfo.environment[@"AVRA_SPIKE_ROWS"].integerValue ?: 10000;
    self.tasks = [NSMutableArray arrayWithCapacity:n];
    for (NSInteger i = 0; i < n; i++) {
        Task* t = [Task new];
        t.tid = i + 1;
        t.title = [NSString stringWithFormat:@"Task %ld", (long)(i + 1)];
        t.done = i % 3 == 0;
        [self.tasks addObject:t];
    }
    self.table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.table.dataSource = self;
    self.table.rowHeight = UITableViewAutomaticDimension;
    self.table.estimatedRowHeight = 52;
    [self.table registerClass:[TaskCell class] forCellReuseIdentifier:@"task"];
    self.table.tableHeaderView = [self header];
    [self counted];
    [self.view addSubview:self.table];
    __weak Board* me = self;
    bench_attach(self.table, ^{
        Task* t = me.tasks.firstObject;
        t.done = !t.done;
        [me counted];
        [me.table reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:0 inSection:0] ] withRowAnimation:UITableViewRowAnimationNone];
        bench_toggle_applied();
    });
    bench_start();
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!self.applied) {
        self.applied = YES;
        bench_first_applied();
    }
}

- (NSInteger)tableView:(UITableView*)t numberOfRowsInSection:(NSInteger)s { return self.tasks.count; }

- (UITableViewCell*)tableView:(UITableView*)t cellForRowAtIndexPath:(NSIndexPath*)p {
    TaskCell* c = [t dequeueReusableCellWithIdentifier:@"task" forIndexPath:p];
    Task* task = self.tasks[p.row];
    c.title.text = task.title;
    c.title.textColor = task.done ? UIColor.secondaryLabelColor : UIColor.labelColor;
    c.box.on = task.done;
    __weak Board* me = self;
    __weak TaskCell* cell = c;
    c.flipped = ^(BOOL on) {
        task.done = on;
        [me counted];
        cell.title.textColor = on ? UIColor.secondaryLabelColor : UIColor.labelColor;
    };
    c.removed = ^{
        NSUInteger at = [me.tasks indexOfObject:task];
        if (at == NSNotFound) return;
        [me.tasks removeObjectAtIndex:at];
        [me counted];
        [me.table deleteRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:at inSection:0] ] withRowAnimation:UITableViewRowAnimationAutomatic];
    };
    return c;
}
@end

@interface TwinScene : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, strong) UIWindow* window;
@end
@implementation TwinScene
- (void)scene:(UIScene*)scene willConnectToSession:(UISceneSession*)session options:(UISceneConnectionOptions*)options {
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene*)scene];
    self.window.rootViewController = [Board new];
    [self.window makeKeyAndVisible];
}
@end

@interface TwinApp : UIResponder <UIApplicationDelegate>
@end
@implementation TwinApp
@end

int main(int argc, char* argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([TwinApp class]));
    }
}
