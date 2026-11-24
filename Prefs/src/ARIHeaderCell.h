//
// Created by ren7995 on 2021-04-27 19:43:00
// Copyright (c) 2021 ren7995. All rights reserved.
//

#import <Preferences/PSTableCell.h>
#import <UIKit/UIKit.h>

// RootHide/rootless 环境下 /Library 前缀不可达，从 AtriaPrefs 自身真实安装路径取资源
NSString *ARIPrefsAssetPath(NSString *fileName, NSString *subdir);

@interface ARIHeaderCell : PSTableCell
@end
