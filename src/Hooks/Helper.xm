//
// Created by ren7995 on 2021-04-25 15:48:29
// Copyright (c) 2021 ren7995. All rights reserved.
//

#import "Shared.h"
#import "../Manager/ARITweakManager.h"
#import "../Manager/ARIEditManager.h"
#import "../UI/Splash/ARISplashViewController.h"
#import "../UI/Label/ARILabelView.h"

#include <dlfcn.h>


%hook SBIconController 

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    [[ARIEditManager sharedInstance] toggleEditView:NO withTargetLocation:nil];

    ARITweakManager *manager = [ARITweakManager sharedInstance];
    if(![manager boolValueForKey:ARIDidSplashPreferenceKey]) {
        ARISplashViewController *splash = [[ARISplashViewController alloc] initWithSubtitle:@"新手引导"];
        [splash addEntry:@"长按（3D Touch）桌面图标，或在壁纸空白处三击，就能进入布局编辑" image:[UIImage systemImageNamed:[manager firmwareVersion] >= 14 ? @"square.grid.3x3.fill.square" : @"square"]];
        [splash addEntry:@"拖动编辑器里的滑块，桌面会实时跟着变" image:[UIImage systemImageNamed:@"slider.horizontal.3"]];
        [splash addEntry:@"点滑块下方那个数字，可以直接输入精确数值" image:[UIImage systemImageNamed:@"wand.and.rays"]];
        [splash addEntry:@"点编辑器上这个页面图标，可以只改当前这一页" image:[UIImage systemImageNamed:@"doc"]];
        [splash addEntry:@"更多选项在“设置”App 的 Atria 面板里" image:[UIImage systemImageNamed:[manager firmwareVersion] >= 14 ? @"gearshape" : @"gear"]];
        [splash addEntry:@"遇到问题欢迎反馈，记得带上机型和系统版本。" image:[UIImage systemImageNamed:[manager firmwareVersion] >= 14 ? @"ladybug" : @"ant"]];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [[objc_getClass("SBIconController") sharedInstance] presentViewController:splash animated:YES completion:nil];
        });
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    [[ARIEditManager sharedInstance] toggleEditView:NO withTargetLocation:nil];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id)coordinator {
    %orig;
    [[ARIEditManager sharedInstance] toggleEditView:NO withTargetLocation:nil];
}

%end


%hook SBMainSwitcherWindow

- (void)setHidden:(BOOL)arg {
    %orig;
    [[ARIEditManager sharedInstance] toggleEditView:NO withTargetLocation:nil];
}

%end


%hook SBIconScrollView

- (void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated {
    // Prevents the scroll view from scrolling on its own when typing in text fields
    // for homescreen page labels. Crossing my fingers this doesn't break anything.
}

%end


%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)arg1 {
    %orig;
    [[ARITweakManager sharedInstance] onSpringboardLaunched];
}

%end


%group TodayViewFixiPad
%hook SBTodayViewController

// These next two hooked methods fix label bugging on iPad with today view

- (void)viewWillAppear:(BOOL)arg1 {
    %orig;
    [[NSNotificationCenter defaultCenter]
            postNotificationName:ARIUpdateLabelVisibilityNotification
                          object:nil
                        userInfo:@{@"alpha" : @(0.0F), @"animationDuration" : @(0.3F)}];
}

- (void)viewDidDisappear:(BOOL)arg1 {
    %orig;
    [[NSNotificationCenter defaultCenter]
            postNotificationName:ARIUpdateLabelVisibilityNotification
                          object:nil
                        userInfo:@{@"alpha" : @(1.0F), @"animationDuration" : @(0.3F)}];
}

%end
%end

%group ZenithFix
%hook SBIconListModel

// Prevents a crash seeimingly caused by an interaction between Atria and Zenith.
// Zenith attempts to insert icons in a way that doesn't work with modified layout, leading to an exception.

- (id)insertIcons:(id)arg1 atIndex:(NSUInteger)arg2 options:(NSUInteger)arg3 {
    // Amazing..
	@try {
		return %orig;
	} @catch(NSException *exc) {
		return nil;
	}
}

// Fix for a crash with Zenith that occurs when its installed on its own (related to App Library).
// When -[SBHLibraryCategory updateCategoryWithIcons:] is invoked, it calls this method.

- (id)insertIcon:(id)arg1 atIndex:(NSUInteger)arg2 {
	@try {
		return %orig;
	} @catch(NSException *exc) {
		return nil;
	}
}

%end
%end

%ctor {
    ARITweakManager *manager = [ARITweakManager sharedInstance];
	if([manager isEnabled]) {
		NSLog(@"[Atria]: Loading hooks from %s", __FILE__);
		if(!Atria17CoreClassesAvailable()) {
			NSLog(@"[Atria17] core layout classes missing, skip hooks (%s)", __FILE__);
			return;
		}
		%init();

        if([manager isDeviceIPad]) {
            %init(TodayViewFixiPad);
        }

        // Zenith compatibility
        NSString *const zenithPath = @THEOS_PACKAGE_INSTALL_PREFIX "/Library/MobileSubstrate/DynamicLibraries/Zenith.dylib";
        if([[NSFileManager defaultManager] fileExistsAtPath:zenithPath]) {
            dlopen([zenithPath UTF8String], RTLD_NOW);
            %init(ZenithFix);
        }
	}
}
