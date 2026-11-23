#import "ARIEditManager.h"
#import "../Editor/ARISettingCell.h"
#import "ARITweakManager.h"

#include <objc/runtime.h>
#include <stdio.h>

void AtriaLogLine(NSString *line) {
    @autoreleasepool {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.dateFormat = @"HH:mm:ss";
        NSString *stamp = [fmt stringFromDate:[NSDate date]];
        NSString *full = [NSString stringWithFormat:@"[%@] %@\n", stamp, line];
        NSArray *paths = @[@THEOS_PACKAGE_INSTALL_PREFIX "/tmp/atria17-diag.log",
                           @THEOS_PACKAGE_INSTALL_PREFIX "/var/mobile/Documents/atria17-diag.log"];
        for (NSString *path in paths) {
            FILE *f = fopen(path.UTF8String, "a");
            if (f) {
                fprintf(f, "%s", full.UTF8String);
                fclose(f);
            }
        }
    }
}

@interface ARIEditManager ()
- (UIViewController *)_atriaPresentingViewController;
@end

@implementation ARIEditManager {
    BOOL _isEditing;
    BOOL _queueDockLayout;
    BOOL _singleList;
    NSString *_editingLocation;
    SBIconListView *_current;
}

@synthesize isEditing = _isEditing;
@synthesize singleListMode = _singleList;
@synthesize editingLocation = _editingLocation;

+ (instancetype)sharedInstance {
    static dispatch_once_t token;
    static ARIEditManager *manager;
    dispatch_once(&token, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

// Edit helper

- (void)toggleEditView:(BOOL)toggle withTargetLocation:(NSString *)targetLoc {
    if(toggle) {
        // Start edit
        if(_isEditing) return;
        _isEditing = YES;
        _editingLocation = targetLoc;

        UIViewController *iconController = (UIViewController *)[objc_getClass("SBIconController") sharedInstance];

        // Check if this list view has custom config
        _current = [[ARITweakManager sharedInstance] currentListView];
        // No per page layout for the following
        if(![targetLoc isEqualToString:@"dock"] && ![targetLoc isEqualToString:@"pagedot"]) {
            _singleList = [[ARITweakManager sharedInstance] doesCustomConfigForListViewExist:_current];
        } else {
            _singleList = NO;
        }

        ARIEditingMainView *view = [[ARIEditingMainView alloc] initWithTarget:targetLoc];
        view.alpha = 0.0F;
        view.transform = CGAffineTransformMakeScale(0.25F, 0.25F);
        [iconController.view addSubview:view];
        [NSLayoutConstraint activateConstraints:@[
            [view.centerXAnchor constraintEqualToAnchor:iconController.view.centerXAnchor],
        ]];

        [UIView animateWithDuration:0.2f
            delay:0.25f
            options:UIViewAnimationOptionCurveEaseOut
            animations:^{
                view.alpha = 1.0F;
                view.transform = CGAffineTransformMakeScale(1.0F, 1.0F);
            }
            completion:^(BOOL finished) {
                [view toggleOptionsView:nil];
            }];
        self.editView = view;
    } else {
        // End edit
        if(!_isEditing) return;
        _isEditing = NO;
        _editingLocation = nil;

        // Finish layout
        if(_queueDockLayout) {
            [[ARITweakManager sharedInstance] relayoutEntireIconModel];
            _queueDockLayout = NO;
        }

        [UIView animateWithDuration:0.15f
            delay:0.0f
            options:UIViewAnimationOptionCurveEaseIn
            animations:^{
                self.editView.alpha = 0.0F;
                self.editView.transform = CGAffineTransformMakeScale(0.2F, 0.2F);
            }
            completion:^(BOOL finished) {
                [self.editView removeFromSuperview];
                self.editView = nil;
            }];
    }
}

- (void)setDockLayoutQueued {
    _queueDockLayout = YES;
}

- (void)presentEditAlert {
    @try {
        AtriaLogLine(@"presentEditAlert called");
        ARITweakManager *manager = [ARITweakManager sharedInstance];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Atria"
                                                                       message:@"想编辑哪一部分？"
                                                                preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[self _createEditAlertAction:@"主屏幕页面" editLocation:@"hs"]];
        [alert addAction:[self _createEditAlertAction:@"Dock 栏" editLocation:@"dock"]];
        [alert addAction:[self _createEditAlertAction:@"页面标签" editLocation:@"label"]];
        [alert addAction:[self _createEditAlertAction:@"页面圆点" editLocation:@"pagedot"]];
        if([manager boolValueForKey:@"showBackground"]) {
            [alert addAction:[self _createEditAlertAction:@"背景模糊" editLocation:@"blur"]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                                  style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction *action){
                                                }]];

        dispatch_async(dispatch_get_main_queue(), ^{
            UIViewController *presenter = [self _atriaPresentingViewController];
            if (!presenter) {
                AtriaLogLine(@"presentEditAlert: no presenter found");
                return;
            }
            AtriaLogLine([NSString stringWithFormat:@"presenting on %@", NSStringFromClass([presenter class])]);
            [presenter presentViewController:alert
                                     animated:YES
                                   completion:^{
                                       AtriaLogLine([NSString stringWithFormat:@"present completion, presentingVC=%@",
                                                     NSStringFromClass([alert.presentingViewController class])]);
                                   }];
        });
    } @catch (NSException *e) {
        AtriaLogLine([NSString stringWithFormat:@"presentEditAlert exception: %@", e]);
    }
}

// iOS 17 上 SBIconController 直接 present 经常静默失败，这里逐级回退找一个真能弹的控制器
- (UIViewController *)_atriaPresentingViewController {
    Class iconControllerClass = objc_getClass("SBIconController");
    id iconController = iconControllerClass ? [iconControllerClass sharedInstance] : nil;

    if (iconController && [iconController isKindOfClass:[UIViewController class]]) {
        UIViewController *vc = (UIViewController *)iconController;
        while (vc.presentedViewController) vc = vc.presentedViewController;
        if (vc.view.window) {
            AtriaLogLine([NSString stringWithFormat:@"present path 1: SBIconController -> %@", NSStringFromClass([vc class])]);
            return vc;
        }
    }

    UIWindow *keyWindow = nil;
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        if (scene.activationState != UISceneActivationStateForegroundActive) continue;
        for (UIWindow *w in ((UIWindowScene *)scene).windows) {
            if (w.isKeyWindow) {
                keyWindow = w;
                break;
            }
        }
        if (keyWindow) break;
    }

    UIViewController *vc = keyWindow.rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    if (vc) {
        AtriaLogLine([NSString stringWithFormat:@"present path 2: keyWindow root -> %@", NSStringFromClass([vc class])]);
        return vc;
    }

    UIView *iconControllerView = [(UIViewController *)iconController view];
    UIWindow *window = iconControllerView.window;
    vc = window.rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    AtriaLogLine([NSString stringWithFormat:@"present path 3: iconController window root -> %@", NSStringFromClass([vc class])]);
    return vc;
}

- (UIAlertAction *)_createEditAlertAction:(NSString *)title editLocation:(NSString *)location {
    return [UIAlertAction actionWithTitle:title
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction *action) {
                                      [self toggleEditView:YES
                                          withTargetLocation:location];
                                  }];
}

- (NSMutableArray *)currentValidSettings {
    return self.editView.validsettingsForTarget;
}

- (void)toggleSingleListMode {
    _singleList = !_singleList;
    // Update if we just set to single list mode
    if(_singleList) _current = [[ARITweakManager sharedInstance] currentListView];

    if(_singleList && ![[ARITweakManager sharedInstance] doesCustomConfigForListViewExist:_current]) {
        // Freeze config for the page
        [[ARITweakManager sharedInstance] createCustomForListView:_current];
    } else if(!_singleList) {
        // Clear custom config
        [[ARITweakManager sharedInstance] deleteCustomForListView:_current];
    }
}

- (SBIconListView *)currentIconListViewIfSinglePage {
    return _singleList ? _current : nil;
}

// Collection view delegate and data source

- (ARISettingCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ARISettingCell *cell = (ARISettingCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"EditCell" forIndexPath:indexPath];
    NSString *key = self.editView.validsettingsForTarget[indexPath.row];
    cell.opLabel.text = [[ARITweakManager sharedInstance] getSettingByKey:key].translation;

    // Turn a key like "dock_inset_left" into "inset_left"
    NSArray *components = [key componentsSeparatedByString:@"_"];
    if([components count] > 1) {
        key = [key
            stringByReplacingOccurrencesOfString:[components[0] stringByAppendingString:@"_"]
                                      withString:@""];
    }

    // Calculate path and set image
    // iOS 17 / RootHide：优先用已注册的 bundle 定位资源，避免依赖 /var/jb 前缀
    NSBundle *prefsBundle = [NSBundle bundleWithIdentifier:@"me.lau.AtriaPrefs"];
    NSString *path = [prefsBundle pathForResource:key ofType:@"png" inDirectory:@"Editor"];
    if(!path) {
        path = [NSString stringWithFormat:@THEOS_PACKAGE_INSTALL_PREFIX "/Library/PreferenceBundles/AtriaPrefs.bundle/Editor/%@.png", key];
    }
    cell.img.image = [[UIImage imageWithContentsOfFile:path] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] ?: [UIImage systemImageNamed:@"gear"];

    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)numberOfItemsInSection {
    return [self.editView.validsettingsForTarget count];
}

- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *key = self.editView.validsettingsForTarget[indexPath.row];
    [self.editView setupForSettingKey:key];
    [self.editView toggleOptionsView:nil];
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                    layout:(UICollectionViewLayout *)collectionViewLayout
    sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(65, 65);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(5, 10, 10, 10); // top, left, bottom, right
}

@end
