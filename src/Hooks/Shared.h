//
// Created by ren7995 on 2021-04-25 12:49:18
// Copyright (c) 2021 ren7995. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// AppLibrary = SBIconLocationAppLibrary
// Root = SBIconLocationRoot OR SBIconLocationRootWithWidgets
// Dock = SBIconLocationDock OR SBIconLocationFloatingDock
// AppLibraryPod = SBIconLocationAppLibraryCategoryPod OR SBIconLocationAppLibraryCategoryPodExpanded
// TodayView = SBIconLocationTodayView
// Folder = SBIconLocationFolder

#define IsLocationRoot(x) [x containsString:@"SBIconLocationRoot"]
#define IsLocationFloatingDock(x) [x isEqualToString:@"SBIconLocationFloatingDock"]
#define IsLocationDock(x) ([x isEqualToString:@"SBIconLocationDock"] || IsLocationFloatingDock(x))
#define IsLocationAppLibrary(x) [x isEqualToString:@"SBIconLocationAppLibrary"]
#define IsLocationAppLibraryPod(x) [x containsString:@"SBIconLocationAppLibraryCategoryPod"]
#define IsLocationFolder(x) [x isEqualToString:@"SBIconLocationFolder"]

#define IconListIsRoot(x) IsLocationRoot(x.iconLocation)
#define IconListIsDock(x) IsLocationDock(x.iconLocation)
#define IconListIsFloatingDock(x) IsLocationFloatingDock(x.iconLocation)
#define IconListIsAppLibrary(x) IsLocationAppLibrary(x.iconLocation)
#define IconListIsAppLibraryPod(x) IsLocationAppLibraryPod(x.iconLocation)
#define IconListIsFolder(x) IsLocationFolder(x.iconLocation)

#define IconIsInRoot(x) IsLocationRoot(x.location)
#define IconIsInDock(x) IsLocationDock(x.location)
#define IconIsInFloatingDock(x) IsLocationFloatingDock(x.location)
#define IconIsInAppLibrary(x) IsLocationAppLibrary(x.location)
#define IconIsInAppLibraryPod(x) IsLocationAppLibraryPod(x.location)
#define IconIsInFolder(x) IsLocationFolder(x.location)

// ---- iOS 17 port guard ----
// 核心私有类缺失时不挂 hook：宁可不生效，也不让 SpringBoard 进安全模式
static inline BOOL Atria17CoreClassesAvailable(void) {
    return objc_getClass("SBIconListView") != NULL &&
           objc_getClass("SBIconListFlowExtendedLayout") != NULL &&
           objc_getClass("SBIconListGridLayoutConfiguration") != NULL &&
           objc_getClass("SBHDefaultIconListLayoutProvider") != NULL;
}

// 诊断日志（同时写 /tmp 和 /var/mobile/Documents，方便 Filza 查看）
void AtriaLogLine(NSString *line);
