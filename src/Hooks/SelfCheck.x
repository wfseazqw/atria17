//
// 通用选项逐项自检：只读不写，不影响主逻辑。
// 目的：在没有 Mac / 无法调试的情况下，直接确认每一项依赖的私有接口在 iOS 17 上是否存在。
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "Shared.h"
#import "../Manager/ARITweakManager.h"

static void A17L(NSMutableString *o, NSString *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    NSString *line = [[NSString alloc] initWithFormat:fmt arguments:ap];
    va_end(ap);
    [o appendString:line ?: @"<nil>"];
    [o appendString:@"\n"];
}

// 方法是否存在。返回给日志看的字符串
static NSString *A17MethodState(const char *clsName, const char *selName) {
    Class cls = objc_getClass(clsName);
    if (!cls) return [NSString stringWithFormat:@"%@ 类不存在", @(clsName)];
    Method m = class_getInstanceMethod(cls, sel_registerName(selName));
    if (!m) return [NSString stringWithFormat:@"%@ %@ 方法不存在", @(clsName), @(selName)];
    return [NSString stringWithFormat:@"%@ %@ 存在", @(clsName), @(selName)];
}

static NSString *A17IvarState(const char *clsName, const char *ivarName) {
    Class cls = objc_getClass(clsName);
    if (!cls) return [NSString stringWithFormat:@"%@ 类不存在", @(clsName)];
    Ivar iv = class_getInstanceVariable(cls, ivarName);
    if (!iv) return [NSString stringWithFormat:@"%@ %@ ivar 不存在", @(clsName), @(ivarName)];
    return [NSString stringWithFormat:@"%@ %@ ivar 存在", @(clsName), @(ivarName)];
}

static BOOL A17HasMethod(const char *clsName, const char *selName) {
    Class cls = objc_getClass(clsName);
    return cls && class_getInstanceMethod(cls, sel_registerName(selName)) != NULL;
}

static BOOL A17HasIvar(const char *clsName, const char *ivarName) {
    Class cls = objc_getClass(clsName);
    return cls && class_getInstanceVariable(cls, ivarName) != NULL;
}

static void A17RunSelfCheck(void) {
    @autoreleasepool {
        ARITweakManager *manager = [ARITweakManager sharedInstance];
        BOOL isPad = [manager isDeviceIPad];
        NSMutableString *o = [NSMutableString string];

        A17L(o, @"=== Atria 通用项自检 ===");
        A17L(o, @"系统: %@", [[NSProcessInfo processInfo] operatingSystemVersionString]);
        A17L(o, @"设备: %@ (%@)", [[UIDevice currentDevice] model], isPad ? @"iPad, 支持浮动 Dock" : @"iPhone, 无浮动 Dock");
        A17L(o, @"");
        A17L(o, @"说明: OK=接口齐全且有实现  SKIP=接口缺失会被跳过  N/A=本机不适用");
        A17L(o, @"");

        // 1 小组件动态尺寸
        A17L(o, @"[1] 小组件动态尺寸（开关=%d）", [manager boolValueForKey:@"dynamicWidgetSizing"]);
        A17L(o, @"    依赖 %@", A17IvarState("SBIconListModel", "_gridSizeClassSizes"));
        A17L(o, @"    依赖 %@", A17IvarState("SBIconListModel", "_gridSize"));
        A17L(o, @"    依赖 %@", A17MethodState("SBIconListView", "iconGridSizeForClass:"));
        A17L(o, @"    结论: %@", (A17HasIvar("SBIconListModel", "_gridSizeClassSizes") && A17HasIvar("SBIconListModel", "_gridSize")) ? @"OK" : @"SKIP（缺 ivar，直接跳过）");
        A17L(o, @"");

        // 2 禁用 Dock 栏
        A17L(o, @"[2] 禁用 Dock 栏（开关=%d）", [manager boolValueForKey:@"disableDock"]);
        A17L(o, @"    依赖 %@", A17MethodState("SBDockView", "dockHeight"));
        A17L(o, @"    依赖 %@", A17MethodState("SBDockView", "setBackgroundAlpha:"));
        A17L(o, @"    结论: %@", (A17HasMethod("SBDockView", "dockHeight")) ? @"OK" : @"SKIP（SBDockView 变了）");
        A17L(o, @"");

        // 3 文件夹内图标也缩放
        A17L(o, @"[3] 文件夹内图标也缩放（开关=%d）", [manager boolValueForKey:@"scaleInsideFolders"]);
        A17L(o, @"    依赖 %@", A17MethodState("SBIconView", "iconContentScale"));
        A17L(o, @"    依赖 %@", A17MethodState("SBIconView", "setIconContentScale:"));
        A17L(o, @"    依赖 %@", A17MethodState("SBIconView", "setAllowsLabelArea:"));
        A17L(o, @"    结论: %@", (A17HasMethod("SBIconView", "iconContentScale") && A17HasMethod("SBIconView", "setAllowsLabelArea:")) ? @"OK" : @"SKIP（SBIconView 接口变了）");
        A17L(o, @"");

        // 4 / 5 桌面手势
        BOOL cfgClass = objc_getClass("SBRootFolderControllerConfiguration") != NULL;
        BOOL todaySel = A17HasMethod("SBRootFolderControllerConfiguration", "ignoresOverscrollOnFirstPageOrientations");
        BOOL libSel = A17HasMethod("SBRootFolderControllerConfiguration", "ignoresOverscrollOnLastPageOrientations");
        A17L(o, @"[4] 禁用今日视图（开关=%d）", [manager boolValueForKey:@"disableTodayGesture"]);
        A17L(o, @"    依赖 %@", A17MethodState("SBRootFolderControllerConfiguration", "ignoresOverscrollOnFirstPageOrientations"));
        A17L(o, @"    结论: %@", (cfgClass && todaySel) ? @"OK（注意：启动时读取一次，改完必须注销）" : @"SKIP（该类/方法在 iOS 17 变了）");
        A17L(o, @"");
        A17L(o, @"[5] 禁用资源库手势（开关=%d）", [manager boolValueForKey:@"disableAppLibraryGesture"]);
        A17L(o, @"    依赖 %@", A17MethodState("SBRootFolderControllerConfiguration", "ignoresOverscrollOnLastPageOrientations"));
        A17L(o, @"    结论: %@", (cfgClass && libSel) ? @"OK（注意：启动时读取一次，改完必须注销）" : @"SKIP（该类/方法在 iOS 17 变了）");
        A17L(o, @"");

        // 6-10 浮动 Dock 组
        BOOL fdClass = objc_getClass("SBFloatingDockController") != NULL;
        A17L(o, @"[6] 强制悬浮 Dock（开关=%d）", [manager boolValueForKey:@"forceFloatingDock"]);
        A17L(o, @"    依赖 %@", A17MethodState("SBFloatingDockController", "isFloatingDockSupported"));
        A17L(o, @"    结论: %@", isPad ? ((fdClass && A17HasMethod("SBFloatingDockController", "isFloatingDockSupported")) ? @"OK" : @"SKIP") : @"N/A（iPhone 本身没有浮动 Dock，强开也不会有界面）");
        A17L(o, @"");
        A17L(o, @"[7] 禁用 Dock 手势（开关=%d）", [manager boolValueForKey:@"disableFloatingDockGestures"]);
        A17L(o, @"    依赖 %@", A17MethodState("SBFloatingDockController", "isGesturePossible"));
        A17L(o, @"    结论: %@", isPad ? ((fdClass && A17HasMethod("SBFloatingDockController", "isGesturePossible")) ? @"OK" : @"SKIP") : @"N/A（仅浮动 Dock 有效）");
        A17L(o, @"");
        A17L(o, @"[8] 显示资源库（浮动 Dock 内，开关=%d）", [manager boolValueForKey:@"floatingDockAppLibrary"]);
        A17L(o, @"    依赖 %@", A17MethodState("SBFloatingDockDefaults", "appLibraryEnabled"));
        A17L(o, @"    结论: %@", isPad ? ((objc_getClass("SBFloatingDockDefaults") && A17HasMethod("SBFloatingDockDefaults", "appLibraryEnabled")) ? @"OK" : @"SKIP") : @"N/A（仅浮动 Dock 有效）");
        A17L(o, @"");
        A17L(o, @"[9] 显示最近使用（浮动 Dock 内，开关=%d）", [manager boolValueForKey:@"floatingDockRecents"]);
        A17L(o, @"    依赖 %@", A17MethodState("SBFloatingDockDefaults", "recentsEnabled"));
        A17L(o, @"    结论: %@", isPad ? ((objc_getClass("SBFloatingDockDefaults") && A17HasMethod("SBFloatingDockDefaults", "recentsEnabled")) ? @"OK" : @"SKIP") : @"N/A（仅浮动 Dock 有效）");
        A17L(o, @"");
        A17L(o, @"[10] 最近使用数量（当前=%d）", [manager intValueForKey:@"maxFloatingDockRecents"]);
        A17L(o, @"    依赖 %@", A17MethodState("SBFloatingDockSuggestionsModel", "initWithMaximumNumberOfSuggestions:iconController:recentsController:recentsDataStore:recentsDefaults:floatingDockDefaults:appSuggestionManager:applicationController:"));
        A17L(o, @"    结论: %@", isPad ? ((objc_getClass("SBFloatingDockSuggestionsModel") && A17HasMethod("SBFloatingDockSuggestionsModel", "initWithMaximumNumberOfSuggestions:iconController:recentsController:recentsDataStore:recentsDefaults:floatingDockDefaults:appSuggestionManager:applicationController:")) ? @"OK" : @"SKIP（该类在 iOS 17 改了初始化参数）") : @"N/A（仅浮动 Dock 有效）");
        A17L(o, @"");

        // 11 隐藏角标
        A17L(o, @"[11] 隐藏图标角标（开关=%d）", [manager boolValueForKey:@"hideBadges"]);
        A17L(o, @"    依赖 %@", A17MethodState("SBIconBadgeView", "setAlpha:"));
        A17L(o, @"    依赖 %@", A17MethodState("SBIconBadgeView", "alpha"));
        A17L(o, @"    结论: %@", A17HasMethod("SBIconBadgeView", "setAlpha:") ? @"OK" : @"SKIP（SBIconBadgeView 接口变了）");
        A17L(o, @"");

        // 12 隐藏页面圆点
        A17L(o, @"[12] 隐藏页面圆点（开关=%d）", [manager boolValueForKey:@"hidePageDots"]);
        A17L(o, @"    依赖 %@", A17MethodState("SBIconListPageControl", "setHidden:"));
        A17L(o, @"    结论: %@", A17HasMethod("SBIconListPageControl", "setHidden:") ? @"OK" : @"SKIP（分页控件类变了）");
        A17L(o, @"");

        // 13 隐藏文件夹背景
        A17L(o, @"[13] 隐藏文件夹背景模糊（开关=%d）", [manager boolValueForKey:@"hideFolderIconBG"]);
        A17L(o, @"    依赖 %@", A17MethodState("SBFolderIconImageView", "setBackgroundView:"));
        A17L(o, @"    结论: %@", A17HasMethod("SBFolderIconImageView", "setBackgroundView:") ? @"OK" : @"SKIP（文件夹图标视图接口变了）");
        A17L(o, @"");

        // 14-16 隐藏名称
        BOOL shyLabels = [manager isShyLabelsInstalled];
        A17L(o, @"[14] 桌面隐藏名称（开关=%d）", [manager boolValueForKey:@"hideLabels"]);
        A17L(o, @"    依赖 %@", A17MethodState("SBIconView", "setAllowsLabelArea:"));
        A17L(o, @"    ShyLabels 已安装: %d（装了就交给它处理，本项失效）", shyLabels);
        A17L(o, @"    结论: %@", (!shyLabels && A17HasMethod("SBIconView", "setAllowsLabelArea:")) ? @"OK" : @"SKIP");
        A17L(o, @"");
        A17L(o, @"[15] 资源库隐藏名称（开关=%d）", [manager boolValueForKey:@"hideLabelsAppLibrary"]);
        A17L(o, @"    结论: %@", (!shyLabels && A17HasMethod("SBIconView", "setAllowsLabelArea:")) ? @"OK" : @"SKIP");
        A17L(o, @"");
        A17L(o, @"[16] 文件夹内隐藏名称（开关=%d）", [manager boolValueForKey:@"hideLabelsFolders"]);
        A17L(o, @"    结论: %@", (!shyLabels && A17HasMethod("SBIconView", "setAllowsLabelArea:")) ? @"OK" : @"SKIP");

        NSString *text = [o copy];
        for (NSString *path in @[ @"/tmp/atria17-selfcheck.txt",
                                  @"/var/mobile/Documents/atria17-selfcheck.txt" ]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent]
                                     withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:nil];
            [text writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
        NSLog(@"[Atria17SelfCheck] written");
    }
}

__attribute__((constructor))
static void atria17_selfcheck_init(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        A17RunSelfCheck();
    });
}
