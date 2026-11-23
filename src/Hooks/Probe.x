#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

// 移植版内置探测：不影响主逻辑，只把关键私有 API 的存在性/签名落盘，
// 便于在没有 Mac 的情况下定位 iOS 17 上的差异点。

static void A17P(NSMutableString *out, NSString *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    NSString *line = [[NSString alloc] initWithFormat:fmt arguments:ap];
    va_end(ap);
    [out appendString:line ?: @"<nil>"];
    [out appendString:@"\n"];
}

static void A17Class(NSMutableString *out, const char *name) {
    Class cls = objc_getClass(name);
    if (!cls) {
        A17P(out, @"[CLASS] %s : NOT FOUND", name);
        return;
    }
    A17P(out, @"[CLASS] %s : FOUND size=%zu super=%s",
         name, class_getInstanceSize(cls), class_getName(class_getSuperclass(cls)));
}

static void A17Method(NSMutableString *out, const char *clsName, const char *selName) {
    Class cls = objc_getClass(clsName);
    if (!cls) {
        A17P(out, @"[METHOD] %s %s : CLASS MISSING", clsName, selName);
        return;
    }
    Method m = class_getInstanceMethod(cls, sel_registerName(selName));
    if (!m) {
        A17P(out, @"[METHOD] %s %s : MISSING", clsName, selName);
        return;
    }
    A17P(out, @"[METHOD] %s %s : %s", clsName, selName, method_getTypeEncoding(m));
}

static void A17Ivar(NSMutableString *out, const char *clsName, const char *ivarName) {
    Class cls = objc_getClass(clsName);
    if (!cls) {
        A17P(out, @"[IVAR] %s %s : CLASS MISSING", clsName, ivarName);
        return;
    }
    Ivar iv = class_getInstanceVariable(cls, ivarName);
    if (!iv) {
        A17P(out, @"[IVAR] %s %s : MISSING", clsName, ivarName);
        return;
    }
    A17P(out, @"[IVAR] %s %s : %s offset=%td", clsName, ivarName, ivar_getTypeEncoding(iv), ivar_getOffset(iv));
}

static void A17RunProbe(void) {
    @autoreleasepool {
        NSMutableString *out = [NSMutableString string];
        A17P(out, @"=== Atria 17 port probe ===");
        A17P(out, @"system: %@", [[NSProcessInfo processInfo] operatingSystemVersionString]);

        A17P(out, @"\n--- classes ---");
        A17Class(out, "SBHDefaultIconListLayoutProvider");
        A17Class(out, "SBIconListFlowExtendedLayout");
        A17Class(out, "SBIconListFlowLayout");
        A17Class(out, "SBIconListGridLayoutConfiguration");
        A17Class(out, "SBIconListModel");
        A17Class(out, "SBIconListView");
        A17Class(out, "SBRootFolderView");
        A17Class(out, "SBHIconGridSizeClassDomain");

        A17P(out, @"\n--- methods ---");
        A17Method(out, "SBHDefaultIconListLayoutProvider", "layoutForIconLocation:");
        A17Method(out, "SBIconListFlowExtendedLayout", "initWithLayoutConfiguration:");
        A17Method(out, "SBIconListGridLayoutConfiguration", "setNumberOfPortraitColumns:");
        A17Method(out, "SBIconListGridLayoutConfiguration", "setNumberOfPortraitRows:");
        A17Method(out, "SBIconListGridLayoutConfiguration", "portraitLayoutInsets");
        A17Method(out, "SBIconListGridLayoutConfiguration", "setPortraitLayoutInsets:");
        A17Method(out, "SBIconListView", "layout");
        A17Method(out, "SBIconListView", "layoutIconsNow");
        A17Method(out, "SBIconListView", "iconSpacing");
        A17Method(out, "SBIconListView", "iconAtCoordinate:metrics:");
        A17Method(out, "SBIconListView", "originForIconAtCoordinate:metrics:");
        A17Method(out, "SBIconListModel", "gridSize");
        A17Method(out, "SBIconListModel", "setGridSize:");
        A17Method(out, "SBIconListModel", "gridSizeForGridSizeClass:");

        A17P(out, @"\n--- ivars ---");
        A17Ivar(out, "SBIconListModel", "_gridSize");
        A17Ivar(out, "SBIconListModel", "_gridSizeClassSizes");
        A17Ivar(out, "SBIconListView", "_model");

        NSString *text = [out copy];
        for (NSString *path in @[ @"/tmp/atria17-probe.txt",
                                  @"/var/mobile/Documents/atria17-probe.txt" ]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent]
                                     withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:nil];
            [text writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
        NSLog(@"[Atria17Probe] probe written");
    }
}

__attribute__((constructor))
static void atria17_probe_init(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        A17RunProbe();
    });
}
