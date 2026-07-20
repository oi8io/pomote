#import <Cocoa/Cocoa.h>
#import <UserNotifications/UserNotifications.h>

typedef NS_ENUM(NSInteger, PomodoroMode) {
    PomodoroModeFocus,
    PomodoroModeBreak
};

typedef NS_ENUM(NSInteger, AppLanguage) {
    AppLanguageChinese,
    AppLanguageEnglish
};

typedef NS_ENUM(NSInteger, ReminderMode) {
    ReminderModeVisual,
    ReminderModeNotification,
    ReminderModeSound
};

@interface PomodoroProgressView : NSView
@property(nonatomic) double progress;
@property(nonatomic, strong) NSColor *fillColor;
@end

@implementation PomodoroProgressView

- (BOOL)isFlipped {
    return YES;
}

- (void)setProgress:(double)progress {
    _progress = MIN(1.0, MAX(0.0, progress));
    self.needsDisplay = YES;
}

- (void)setFillColor:(NSColor *)fillColor {
    _fillColor = fillColor;
    self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = self.bounds;
    CGFloat radius = NSHeight(bounds) / 2.0;

    [[NSColor separatorColor] setFill];
    [[NSBezierPath bezierPathWithRoundedRect:bounds xRadius:radius yRadius:radius] fill];

    if (self.progress > 0) {
        NSRect fillRect = bounds;
        fillRect.size.width = MAX(NSHeight(bounds), NSWidth(bounds) * self.progress);
        [self.fillColor setFill];
        [[NSBezierPath bezierPathWithRoundedRect:fillRect xRadius:radius yRadius:radius] fill];
    }
}

@end

@interface AppDelegate : NSObject <NSApplicationDelegate, UNUserNotificationCenterDelegate>
@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) NSPopover *popover;
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic, strong) NSTimer *alarmTimer;
@property(nonatomic, strong) NSTimer *visualAlertTimer;
@property(nonatomic, strong) NSSound *alarmSound;
@property(nonatomic, strong) NSSound *focusAlarmSound;
@property(nonatomic, strong) NSSound *breakAlarmSound;
@property(nonatomic, strong) NSTextField *modeLabel;
@property(nonatomic, strong) NSTextField *timeLabel;
@property(nonatomic, strong) NSTextField *durationTitle;
@property(nonatomic, strong) NSTextField *focusTitle;
@property(nonatomic, strong) NSTextField *breakTitle;
@property(nonatomic, strong) NSTextField *focusInput;
@property(nonatomic, strong) NSTextField *breakInput;
@property(nonatomic, strong) NSTextField *focusUnitLabel;
@property(nonatomic, strong) NSTextField *breakUnitLabel;
@property(nonatomic, strong) NSTextField *reminderTitle;
@property(nonatomic, strong) PomodoroProgressView *progress;
@property(nonatomic, strong) NSButton *startButton;
@property(nonatomic, strong) NSButton *resetButton;
@property(nonatomic, strong) NSButton *switchButton;
@property(nonatomic, strong) NSButton *quitButton;
@property(nonatomic, strong) NSStepper *focusStepper;
@property(nonatomic, strong) NSStepper *breakStepper;
@property(nonatomic, strong) NSSegmentedControl *languageControl;
@property(nonatomic, strong) NSSegmentedControl *reminderControl;
@property(nonatomic) PomodoroMode mode;
@property(nonatomic) AppLanguage language;
@property(nonatomic) ReminderMode reminderMode;
@property(nonatomic) NSInteger remainingSeconds;
@property(nonatomic) NSInteger focusMinutes;
@property(nonatomic) NSInteger breakMinutes;
@property(nonatomic) NSInteger alarmPlaysRemaining;
@property(nonatomic) NSInteger visualAlertTicks;
@property(nonatomic) BOOL visualAlertOn;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    self.focusMinutes = [defaults integerForKey:@"focusMinutes"] ?: 25;
    self.breakMinutes = [defaults integerForKey:@"breakMinutes"] ?: 5;
    self.language = [defaults integerForKey:@"appLanguage"] == AppLanguageEnglish
        ? AppLanguageEnglish
        : AppLanguageChinese;
    NSNumber *savedReminder = [defaults objectForKey:@"reminderMode"];
    NSInteger reminderValue = savedReminder ? savedReminder.integerValue : ReminderModeVisual;
    self.reminderMode = MIN(ReminderModeSound, MAX(ReminderModeVisual, reminderValue));
    self.mode = PomodoroModeFocus;
    self.remainingSeconds = self.focusMinutes * 60;
    self.focusAlarmSound = [[NSSound alloc] initWithContentsOfFile:@"/System/Library/Sounds/Sosumi.aiff"
                                                      byReference:YES];
    self.breakAlarmSound = [[NSSound alloc] initWithContentsOfFile:@"/System/Library/Sounds/Glass.aiff"
                                                      byReference:YES];
    UNUserNotificationCenter.currentNotificationCenter.delegate = self;

    [self buildPopover];

    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    NSStatusBarButton *button = self.statusItem.button;
    button.image = [NSImage imageWithSystemSymbolName:@"timer"
                            accessibilityDescription:@"Pomote"];
    button.imagePosition = NSImageLeading;
    button.target = self;
    button.action = @selector(togglePopover:);

    [self updateUI];
}

- (NSTextField *)labelWithSize:(CGFloat)size weight:(NSFontWeight)weight {
    NSTextField *label = [NSTextField labelWithString:@""];
    label.font = [NSFont systemFontOfSize:size weight:weight];
    label.alignment = NSTextAlignmentCenter;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    return label;
}

- (NSButton *)buttonWithTitle:(NSString *)title action:(SEL)action {
    NSButton *button = [NSButton buttonWithTitle:title target:self action:action];
    button.bezelStyle = NSBezelStyleRounded;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    return button;
}

- (NSButton *)iconButtonWithSymbol:(NSString *)symbol
                             label:(NSString *)label
                            action:(SEL)action {
    NSImage *image = [NSImage imageWithSystemSymbolName:symbol accessibilityDescription:nil];
    NSButton *button = [NSButton buttonWithImage:image target:self action:action];
    button.title = @"";
    button.imagePosition = NSImageOnly;
    button.bezelStyle = NSBezelStyleRounded;
    button.toolTip = label;
    button.accessibilityLabel = label;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    return button;
}

- (NSTextField *)durationInputWithValue:(NSInteger)value
                                minimum:(NSInteger)minimum
                                maximum:(NSInteger)maximum
                                  action:(SEL)action {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.allowsFloats = NO;
    formatter.minimum = @(minimum);
    formatter.maximum = @(maximum);

    NSTextField *input = [[NSTextField alloc] init];
    input.formatter = formatter;
    input.integerValue = value;
    input.alignment = NSTextAlignmentRight;
    input.font = [NSFont monospacedDigitSystemFontOfSize:13 weight:NSFontWeightMedium];
    input.controlSize = NSControlSizeSmall;
    input.target = self;
    input.action = action;
    input.cell.sendsActionOnEndEditing = YES;
    input.translatesAutoresizingMaskIntoConstraints = NO;
    return input;
}

- (NSString *)zh:(NSString *)chinese en:(NSString *)english {
    return self.language == AppLanguageChinese ? chinese : english;
}

- (void)buildPopover {
    NSViewController *controller = [[NSViewController alloc] init];
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 290, 390)];
    controller.view = view;

    self.modeLabel = [self labelWithSize:16 weight:NSFontWeightSemibold];
    self.timeLabel = [self labelWithSize:42 weight:NSFontWeightSemibold];
    self.timeLabel.font = [NSFont monospacedDigitSystemFontOfSize:42 weight:NSFontWeightSemibold];

    self.languageControl = [NSSegmentedControl segmentedControlWithLabels:@[@"中", @"EN"]
                                                              trackingMode:NSSegmentSwitchTrackingSelectOne
                                                                    target:self
                                                                    action:@selector(changeLanguage:)];
    self.languageControl.selectedSegment = self.language;
    self.languageControl.controlSize = NSControlSizeSmall;
    self.languageControl.translatesAutoresizingMaskIntoConstraints = NO;

    self.switchButton = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"arrow.left.arrow.right"
                                                                               accessibilityDescription:nil]
                                             target:self
                                             action:@selector(switchMode:)];
    self.switchButton.bezelStyle = NSBezelStyleInline;
    self.switchButton.bordered = NO;
    self.switchButton.translatesAutoresizingMaskIntoConstraints = NO;

    self.progress = [[PomodoroProgressView alloc] init];
    self.progress.translatesAutoresizingMaskIntoConstraints = NO;

    self.resetButton = [self iconButtonWithSymbol:@"arrow.counterclockwise"
                                            label:@"重置"
                                           action:@selector(reset:)];
    self.startButton = [self iconButtonWithSymbol:@"play.fill"
                                            label:@"开始"
                                           action:@selector(toggleTimer:)];
    self.startButton.keyEquivalent = @" ";
    self.startButton.bezelColor = NSColor.secondaryLabelColor;

    self.durationTitle = [self labelWithSize:12 weight:NSFontWeightMedium];
    self.durationTitle.textColor = NSColor.secondaryLabelColor;

    self.focusTitle = [self labelWithSize:12 weight:NSFontWeightRegular];
    self.focusInput = [self durationInputWithValue:self.focusMinutes
                                           minimum:1
                                           maximum:90
                                             action:@selector(changeFocusInput:)];
    self.focusUnitLabel = [self labelWithSize:11 weight:NSFontWeightRegular];
    self.focusUnitLabel.textColor = NSColor.secondaryLabelColor;
    self.focusStepper = [[NSStepper alloc] init];
    self.focusStepper.minValue = 1;
    self.focusStepper.maxValue = 90;
    self.focusStepper.integerValue = self.focusMinutes;
    self.focusStepper.target = self;
    self.focusStepper.action = @selector(changeFocusDuration:);
    self.focusStepper.translatesAutoresizingMaskIntoConstraints = NO;

    self.breakTitle = [self labelWithSize:12 weight:NSFontWeightRegular];
    self.breakInput = [self durationInputWithValue:self.breakMinutes
                                           minimum:1
                                           maximum:30
                                             action:@selector(changeBreakInput:)];
    self.breakUnitLabel = [self labelWithSize:11 weight:NSFontWeightRegular];
    self.breakUnitLabel.textColor = NSColor.secondaryLabelColor;
    self.breakStepper = [[NSStepper alloc] init];
    self.breakStepper.minValue = 1;
    self.breakStepper.maxValue = 30;
    self.breakStepper.integerValue = self.breakMinutes;
    self.breakStepper.target = self;
    self.breakStepper.action = @selector(changeBreakDuration:);
    self.breakStepper.translatesAutoresizingMaskIntoConstraints = NO;

    self.reminderTitle = [self labelWithSize:12 weight:NSFontWeightMedium];
    self.reminderTitle.textColor = NSColor.secondaryLabelColor;
    NSArray<NSImage *> *reminderImages = @[
        [NSImage imageWithSystemSymbolName:@"eye" accessibilityDescription:nil],
        [NSImage imageWithSystemSymbolName:@"bell" accessibilityDescription:nil],
        [NSImage imageWithSystemSymbolName:@"speaker.wave.2" accessibilityDescription:nil]
    ];
    self.reminderControl = [NSSegmentedControl segmentedControlWithImages:reminderImages
                                                              trackingMode:NSSegmentSwitchTrackingSelectOne
                                                                    target:self
                                                                    action:@selector(changeReminderMode:)];
    self.reminderControl.selectedSegment = self.reminderMode;
    self.reminderControl.controlSize = NSControlSizeSmall;
    self.reminderControl.translatesAutoresizingMaskIntoConstraints = NO;

    self.quitButton = [self buttonWithTitle:@"退出 Pomote" action:@selector(quit:)];
    self.quitButton.bordered = NO;
    self.quitButton.contentTintColor = NSColor.secondaryLabelColor;
    self.quitButton.font = [NSFont systemFontOfSize:11];

    for (NSView *subview in @[self.languageControl, self.modeLabel, self.switchButton,
                              self.timeLabel, self.progress, self.resetButton, self.startButton,
                              self.durationTitle, self.focusTitle, self.focusInput,
                              self.focusUnitLabel, self.focusStepper, self.breakTitle,
                              self.breakInput, self.breakUnitLabel, self.breakStepper,
                              self.reminderTitle, self.reminderControl, self.quitButton]) {
        [view addSubview:subview];
    }

    [NSLayoutConstraint activateConstraints:@[
        [self.modeLabel.topAnchor constraintEqualToAnchor:view.topAnchor constant:20],
        [self.modeLabel.centerXAnchor constraintEqualToAnchor:view.centerXAnchor],
        [self.languageControl.centerYAnchor constraintEqualToAnchor:self.modeLabel.centerYAnchor],
        [self.languageControl.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:14],
        [self.languageControl.widthAnchor constraintEqualToConstant:66],
        [self.switchButton.centerYAnchor constraintEqualToAnchor:self.modeLabel.centerYAnchor],
        [self.switchButton.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-20],

        [self.timeLabel.topAnchor constraintEqualToAnchor:self.modeLabel.bottomAnchor constant:24],
        [self.timeLabel.centerXAnchor constraintEqualToAnchor:view.centerXAnchor],
        [self.progress.topAnchor constraintEqualToAnchor:self.timeLabel.bottomAnchor constant:14],
        [self.progress.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:38],
        [self.progress.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-38],
        [self.progress.heightAnchor constraintEqualToConstant:8],

        [self.resetButton.topAnchor constraintEqualToAnchor:self.progress.bottomAnchor constant:24],
        [self.resetButton.trailingAnchor constraintEqualToAnchor:view.centerXAnchor constant:-6],
        [self.resetButton.widthAnchor constraintEqualToConstant:48],
        [self.resetButton.heightAnchor constraintEqualToConstant:32],
        [self.startButton.topAnchor constraintEqualToAnchor:self.resetButton.topAnchor],
        [self.startButton.leadingAnchor constraintEqualToAnchor:view.centerXAnchor constant:6],
        [self.startButton.widthAnchor constraintEqualToConstant:48],
        [self.startButton.heightAnchor constraintEqualToConstant:32],

        [self.durationTitle.topAnchor constraintEqualToAnchor:self.resetButton.bottomAnchor constant:26],
        [self.durationTitle.centerXAnchor constraintEqualToAnchor:view.centerXAnchor],
        [self.focusTitle.topAnchor constraintEqualToAnchor:self.durationTitle.bottomAnchor constant:12],
        [self.focusTitle.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:16],
        [self.focusInput.centerYAnchor constraintEqualToAnchor:self.focusTitle.centerYAnchor],
        [self.focusInput.leadingAnchor constraintEqualToAnchor:self.focusTitle.trailingAnchor constant:6],
        [self.focusInput.widthAnchor constraintEqualToConstant:40],
        [self.focusUnitLabel.centerYAnchor constraintEqualToAnchor:self.focusTitle.centerYAnchor],
        [self.focusUnitLabel.leadingAnchor constraintEqualToAnchor:self.focusInput.trailingAnchor constant:4],
        [self.focusStepper.centerYAnchor constraintEqualToAnchor:self.focusTitle.centerYAnchor],
        [self.focusStepper.leadingAnchor constraintEqualToAnchor:self.focusUnitLabel.trailingAnchor constant:2],

        [self.breakTitle.centerYAnchor constraintEqualToAnchor:self.focusTitle.centerYAnchor],
        [self.breakTitle.leadingAnchor constraintEqualToAnchor:view.centerXAnchor constant:8],
        [self.breakInput.centerYAnchor constraintEqualToAnchor:self.breakTitle.centerYAnchor],
        [self.breakInput.leadingAnchor constraintEqualToAnchor:self.breakTitle.trailingAnchor constant:6],
        [self.breakInput.widthAnchor constraintEqualToConstant:40],
        [self.breakUnitLabel.centerYAnchor constraintEqualToAnchor:self.breakTitle.centerYAnchor],
        [self.breakUnitLabel.leadingAnchor constraintEqualToAnchor:self.breakInput.trailingAnchor constant:4],
        [self.breakStepper.centerYAnchor constraintEqualToAnchor:self.breakTitle.centerYAnchor],
        [self.breakStepper.leadingAnchor constraintEqualToAnchor:self.breakUnitLabel.trailingAnchor constant:2],

        [self.reminderTitle.topAnchor constraintEqualToAnchor:self.focusTitle.bottomAnchor constant:22],
        [self.reminderTitle.centerXAnchor constraintEqualToAnchor:view.centerXAnchor],
        [self.reminderControl.topAnchor constraintEqualToAnchor:self.reminderTitle.bottomAnchor constant:8],
        [self.reminderControl.centerXAnchor constraintEqualToAnchor:view.centerXAnchor],
        [self.reminderControl.widthAnchor constraintEqualToConstant:120],

        [self.quitButton.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-12],
        [self.quitButton.centerXAnchor constraintEqualToAnchor:view.centerXAnchor]
    ]];

    self.popover = [[NSPopover alloc] init];
    self.popover.contentSize = NSMakeSize(290, 390);
    self.popover.behavior = NSPopoverBehaviorTransient;
    self.popover.animates = YES;
    self.popover.contentViewController = controller;
}

- (NSInteger)totalSeconds {
    return (self.mode == PomodoroModeFocus ? self.focusMinutes : self.breakMinutes) * 60;
}

- (void)updateUI {
    NSString *time = [NSString stringWithFormat:@"%02ld:%02ld",
                      (long)(self.remainingSeconds / 60),
                      (long)(self.remainingSeconds % 60)];
    BOOL running = self.timer != nil;
    BOOL focusing = self.mode == PomodoroModeFocus;
    NSString *modeName = focusing ? [self zh:@"专注" en:@"Focus"] : [self zh:@"休息" en:@"Break"];
    NSString *modeLabel = focusing
        ? (running ? [self zh:@"专注中" en:@"Focusing"] : [self zh:@"专注" en:@"Focus"])
        : modeName;
    NSColor *modeColor = focusing ? NSColor.systemBlueColor : NSColor.systemGreenColor;
    NSString *statusSymbol = focusing ? @"timer" : @"cup.and.saucer.fill";
    if (self.visualAlertTicks > 0 && self.visualAlertOn) statusSymbol = @"bell.badge.fill";

    self.modeLabel.stringValue = modeLabel;
    self.modeLabel.textColor = modeColor;
    self.timeLabel.stringValue = time;
    self.timeLabel.font = [NSFont monospacedDigitSystemFontOfSize:42 weight:NSFontWeightSemibold];
    self.timeLabel.textColor = modeColor;
    self.durationTitle.stringValue = [self zh:@"时长设置" en:@"Durations"];
    self.focusTitle.stringValue = [self zh:@"专注" en:@"Focus"];
    self.breakTitle.stringValue = [self zh:@"休息" en:@"Break"];
    self.focusUnitLabel.stringValue = [self zh:@"分" en:@"min"];
    self.breakUnitLabel.stringValue = [self zh:@"分" en:@"min"];
    if (!self.focusInput.currentEditor) self.focusInput.integerValue = self.focusMinutes;
    if (!self.breakInput.currentEditor) self.breakInput.integerValue = self.breakMinutes;

    NSString *startLabel = running ? [self zh:@"暂停" en:@"Pause"] : [self zh:@"开始" en:@"Start"];
    NSString *resetLabel = [self zh:@"重置" en:@"Reset"];
    NSString *switchLabel = [self zh:@"切换专注和休息" en:@"Switch focus and break"];
    self.startButton.title = @"";
    self.startButton.imagePosition = NSImageOnly;
    self.startButton.image = [NSImage imageWithSystemSymbolName:(running ? @"pause.fill" : @"play.fill")
                                      accessibilityDescription:nil];
    self.startButton.toolTip = startLabel;
    self.startButton.accessibilityLabel = startLabel;
    self.resetButton.toolTip = resetLabel;
    self.resetButton.accessibilityLabel = resetLabel;
    self.switchButton.toolTip = switchLabel;
    self.switchButton.accessibilityLabel = switchLabel;
    self.focusInput.toolTip = [self zh:@"输入专注分钟数" en:@"Enter focus minutes"];
    self.focusInput.accessibilityLabel = self.focusInput.toolTip;
    self.breakInput.toolTip = [self zh:@"输入休息分钟数" en:@"Enter break minutes"];
    self.breakInput.accessibilityLabel = self.breakInput.toolTip;
    self.languageControl.toolTip = [self zh:@"切换语言" en:@"Switch language"];
    self.reminderTitle.stringValue = [self zh:@"提醒方式" en:@"Reminder"];
    [self.reminderControl setToolTip:[self zh:@"静默视觉提醒" en:@"Silent visual alert"] forSegment:ReminderModeVisual];
    [self.reminderControl setToolTip:[self zh:@"无声系统通知" en:@"Silent system notification"] forSegment:ReminderModeNotification];
    [self.reminderControl setToolTip:[self zh:@"播放提示音" en:@"Play alert sound"] forSegment:ReminderModeSound];
    self.quitButton.title = [self zh:@"退出 Pomote" en:@"Quit Pomote"];
    self.startButton.bezelColor = modeColor;
    self.progress.fillColor = modeColor;
    self.progress.progress = 1.0 - ((double)self.remainingSeconds / MAX(1, self.totalSeconds));

    self.statusItem.button.image = [NSImage imageWithSystemSymbolName:statusSymbol
                                            accessibilityDescription:modeName];
    self.statusItem.button.title = focusing ? @"" : [NSString stringWithFormat:@" %@", time];
    NSString *runState = running ? [self zh:@"进行中" en:@"Running"] : [self zh:@"已暂停" en:@"Paused"];
    self.statusItem.button.toolTip = [NSString stringWithFormat:@"%@ · %@", modeName, runState];
}

- (void)start {
    if (self.timer) return;
    [self stopAlarm];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                  target:self
                                                selector:@selector(tick:)
                                                userInfo:nil
                                                 repeats:YES];
    [self updateUI];
}

- (void)pause {
    [self.timer invalidate];
    self.timer = nil;
    [self updateUI];
}

- (void)tick:(NSTimer *)timer {
    if (self.remainingSeconds > 0) self.remainingSeconds--;

    if (self.remainingSeconds == 0) {
        self.mode = self.mode == PomodoroModeFocus ? PomodoroModeBreak : PomodoroModeFocus;
        self.remainingSeconds = self.totalSeconds;
        [self presentReminderForMode:self.mode];
    }
    [self updateUI];
}

- (void)toggleTimer:(id)sender {
    [self stopAlarm];
    [self stopVisualAlert];
    self.timer ? [self pause] : [self start];
}

- (void)reset:(id)sender {
    [self stopAlarm];
    [self stopVisualAlert];
    [self pause];
    self.remainingSeconds = self.totalSeconds;
    [self updateUI];
}

- (void)switchMode:(id)sender {
    [self stopAlarm];
    [self stopVisualAlert];
    [self pause];
    self.mode = self.mode == PomodoroModeFocus ? PomodoroModeBreak : PomodoroModeFocus;
    self.remainingSeconds = self.totalSeconds;
    [self updateUI];
}

- (void)presentReminderForMode:(PomodoroMode)mode {
    [self startVisualAlert];

    if (self.reminderMode == ReminderModeNotification) {
        [self sendNotificationForMode:mode];
    } else if (self.reminderMode == ReminderModeSound) {
        [self playAlarmForMode:mode];
    }
}

- (void)startVisualAlert {
    [self stopVisualAlert];
    self.visualAlertTicks = 10;
    self.visualAlertOn = YES;
    self.visualAlertTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                             target:self
                                                           selector:@selector(visualAlertTick:)
                                                           userInfo:nil
                                                            repeats:YES];
    [self updateUI];
}

- (void)visualAlertTick:(NSTimer *)timer {
    self.visualAlertTicks--;
    self.visualAlertOn = !self.visualAlertOn;
    if (self.visualAlertTicks <= 0) [self stopVisualAlert];
    [self updateUI];
}

- (void)stopVisualAlert {
    [self.visualAlertTimer invalidate];
    self.visualAlertTimer = nil;
    self.visualAlertTicks = 0;
    self.visualAlertOn = NO;
}

- (void)requestNotificationPermission {
    [UNUserNotificationCenter.currentNotificationCenter
        requestAuthorizationWithOptions:UNAuthorizationOptionAlert
        completionHandler:^(BOOL granted, NSError *error) {
            (void)granted;
            if (error) NSLog(@"Notification permission error: %@", error);
        }];
}

- (void)sendNotificationForMode:(PomodoroMode)mode {
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    if (mode == PomodoroModeFocus) {
        content.title = [self zh:@"休息结束" en:@"Break complete"];
        content.body = [self zh:@"准备进入下一轮专注。" en:@"Ready for the next focus session."];
    } else {
        content.title = [self zh:@"专注完成" en:@"Focus complete"];
        content.body = [self zh:@"起来活动一下，休息一会儿。" en:@"Take a short break and move around."];
    }

    NSString *identifier = NSUUID.UUID.UUIDString;
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                           content:content
                                                                           trigger:nil];
    [UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:request
                                                           withCompletionHandler:^(NSError *error) {
        if (error) NSLog(@"Notification delivery error: %@", error);
    }];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    completionHandler(UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionList);
}

- (void)playAlarmForMode:(PomodoroMode)mode {
    [self stopAlarm];
    self.alarmSound = mode == PomodoroModeFocus ? self.focusAlarmSound : self.breakAlarmSound;
    self.alarmPlaysRemaining = mode == PomodoroModeFocus ? 4 : 2;
    [self playAlarmOnce:nil];
    self.alarmTimer = [NSTimer scheduledTimerWithTimeInterval:0.9
                                                       target:self
                                                     selector:@selector(playAlarmOnce:)
                                                     userInfo:nil
                                                      repeats:YES];
}

- (void)playAlarmOnce:(NSTimer *)timer {
    if (self.alarmPlaysRemaining <= 0) {
        [self.alarmTimer invalidate];
        self.alarmTimer = nil;
        return;
    }

    if (self.alarmSound) {
        [self.alarmSound stop];
        [self.alarmSound play];
    } else {
        NSBeep();
    }
    self.alarmPlaysRemaining--;
}

- (void)stopAlarm {
    [self.alarmTimer invalidate];
    self.alarmTimer = nil;
    [self.alarmSound stop];
    self.alarmPlaysRemaining = 0;
}

- (void)changeFocusDuration:(NSStepper *)sender {
    [self applyFocusMinutes:sender.integerValue];
}

- (void)changeFocusInput:(NSTextField *)sender {
    [self applyFocusMinutes:sender.integerValue];
}

- (void)applyFocusMinutes:(NSInteger)value {
    self.focusMinutes = MIN(90, MAX(1, value));
    self.focusInput.integerValue = self.focusMinutes;
    self.focusStepper.integerValue = self.focusMinutes;
    [NSUserDefaults.standardUserDefaults setInteger:self.focusMinutes forKey:@"focusMinutes"];
    if (self.mode == PomodoroModeFocus) [self reset:nil];
    [self updateUI];
}

- (void)changeBreakDuration:(NSStepper *)sender {
    [self applyBreakMinutes:sender.integerValue];
}

- (void)changeBreakInput:(NSTextField *)sender {
    [self applyBreakMinutes:sender.integerValue];
}

- (void)applyBreakMinutes:(NSInteger)value {
    self.breakMinutes = MIN(30, MAX(1, value));
    self.breakInput.integerValue = self.breakMinutes;
    self.breakStepper.integerValue = self.breakMinutes;
    [NSUserDefaults.standardUserDefaults setInteger:self.breakMinutes forKey:@"breakMinutes"];
    if (self.mode == PomodoroModeBreak) [self reset:nil];
    [self updateUI];
}

- (void)changeLanguage:(NSSegmentedControl *)sender {
    self.language = sender.selectedSegment == AppLanguageEnglish
        ? AppLanguageEnglish
        : AppLanguageChinese;
    [NSUserDefaults.standardUserDefaults setInteger:self.language forKey:@"appLanguage"];
    [self updateUI];
}

- (void)changeReminderMode:(NSSegmentedControl *)sender {
    self.reminderMode = MIN(ReminderModeSound, MAX(ReminderModeVisual, sender.selectedSegment));
    [NSUserDefaults.standardUserDefaults setInteger:self.reminderMode forKey:@"reminderMode"];
    [self stopAlarm];
    [self stopVisualAlert];
    if (self.reminderMode == ReminderModeNotification) [self requestNotificationPermission];
    [self updateUI];
}

- (void)togglePopover:(id)sender {
    if (self.popover.shown) {
        [self.popover performClose:nil];
    } else {
        NSStatusBarButton *button = self.statusItem.button;
        [self.popover showRelativeToRect:button.bounds ofView:button preferredEdge:NSRectEdgeMinY];
        [self.popover.contentViewController.view.window makeKeyWindow];
    }
}

- (void)quit:(id)sender {
    [self stopAlarm];
    [self stopVisualAlert];
    [NSApp terminate:nil];
}

@end

int main(void) {
    @autoreleasepool {
        NSApplication *application = NSApplication.sharedApplication;
        AppDelegate *delegate = [[AppDelegate alloc] init];
        application.delegate = delegate;
        [application run];
    }
    return 0;
}
