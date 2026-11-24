//
// Created by ren7995 on 2021-04-27 19:44:31
// Copyright (c) 2021 ren7995. All rights reserved.
//

#import "ARIHeaderCell.h"
#import <dlfcn.h>

// RootHide/rootless 下 THEOS_PACKAGE_INSTALL_PREFIX 为空、/Library 前缀不可达，
// 改为从 AtriaPrefs 自身真实安装路径取资源：先用 dladdr 定位可执行所在目录，失败再退回 bundle 路径
NSString *ARIPrefsAssetPath(NSString *fileName, NSString *subdir) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSMutableArray<NSString *> *bases = [NSMutableArray array];

    Dl_info info;
    if(dladdr((const void *)&ARIPrefsAssetPath, &info) && info.dli_fname) {
        NSString *selfPath = [NSString stringWithUTF8String:info.dli_fname];
        if(selfPath) [bases addObject:[selfPath stringByDeletingLastPathComponent]];
    }
    NSString *bundlePath = [NSBundle bundleForClass:[ARIHeaderCell class]].bundlePath;
    if(bundlePath) [bases addObject:bundlePath];

    for(NSString *base in bases) {
        NSString *path = subdir ? [base stringByAppendingPathComponent:subdir] : base;
        path = [path stringByAppendingPathComponent:fileName];
        if([fm fileExistsAtPath:path]) return path;
    }
    return nil;
}

@implementation ARIHeaderCell {
    UIImageView *_icon;
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if(self) {
        NSString *iconPath = ARIPrefsAssetPath(@"full.png", nil);
        UIImage *iconImage = iconPath ? [UIImage imageWithContentsOfFile:iconPath] : nil;
        _icon = [[UIImageView alloc] initWithImage:iconImage ?: [UIImage systemImageNamed:@"gearshape"]];
        [self addSubview:_icon];
        _icon.layer.masksToBounds = YES;
        _icon.layer.cornerCurve = kCACornerCurveContinuous;
        _icon.layer.cornerRadius = 12;
        _icon.translatesAutoresizingMaskIntoConstraints = NO;

        [NSLayoutConstraint activateConstraints:@[
            [_icon.widthAnchor constraintEqualToConstant:60],
            [_icon.heightAnchor constraintEqualToConstant:60],
            [_icon.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [_icon.topAnchor constraintEqualToAnchor:self.topAnchor
                                            constant:10],
        ]];

        UILabel *label = [[UILabel alloc] init];
        label.text = [NSString stringWithFormat:@"版本 %@（帆哥特别版）", PACKAGE_VERSION];
        label.numberOfLines = 0;
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentCenter;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:label];
        [NSLayoutConstraint activateConstraints:@[
            [label.widthAnchor constraintEqualToAnchor:self.widthAnchor
                                              constant:-50],
            [label.bottomAnchor constraintEqualToAnchor:self.bottomAnchor
                                               constant:-10],
            [label.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [label.topAnchor constraintEqualToAnchor:_icon.bottomAnchor
                                            constant:10],
        ]];
    }

    return self;
}

- (void)setSeparatorStyle:(UITableViewCellSeparatorStyle)style {
    [super setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

- (void)setBackgroundColor:(UIColor *)color {
    [super setBackgroundColor:[UIColor clearColor]];
}

@end
