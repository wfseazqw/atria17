//
// Created by ren7995 on 2021-04-17 13:45:45
// Copyright (c) 2021 ren7995. All rights reserved.
//

#import "ARIRootListController.h"
#import "../../src/UI/Splash/ARISplashViewController.h"

@implementation ARIRootListController

- (NSArray *)specifiers {
    if(!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }

    return _specifiers;
}

- (void)resetPrefs:(id)sender {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"重置设置"
                         message:@"确定要重置所有设置吗？设备会注销（Respring）。"
                  preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *defaultAction = [UIAlertAction
        actionWithTitle:@"否"
                  style:UIAlertActionStyleCancel
                handler:nil];
    UIAlertAction *yes = [UIAlertAction
        actionWithTitle:@"是"
                  style:UIAlertActionStyleDestructive
                handler:^(UIAlertAction *action) {
                    NSUserDefaults *prefs = [[NSUserDefaults standardUserDefaults] init];
                    [prefs removePersistentDomainForName:ARIPreferenceDomain];
                    [self respringWithAnimation];
                }];

    [alert addAction:defaultAction];
    [alert addAction:yes];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)resetSaveState:(id)sender {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"重置保存的图标状态"
                         message:@"确定要重置保存的图标状态吗？设备会注销（Respring）。"
                  preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *defaultAction = [UIAlertAction
        actionWithTitle:@"否"
                  style:UIAlertActionStyleCancel
                handler:nil];
    UIAlertAction *yes = [UIAlertAction
        actionWithTitle:@"是"
                  style:UIAlertActionStyleDestructive
                handler:^(UIAlertAction *action) {
                    NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:ARIPreferenceDomain];
                    [prefs removeObjectForKey:@"_saveState"];
                    [prefs synchronize];
                    [self respringWithAnimation];
                }];

    [alert addAction:defaultAction];
    [alert addAction:yes];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)exportSettingsString {
    // Sync defaults
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:ARIPreferenceDomain];
    [defaults synchronize];

    // Load preferences plist
    NSError *error;
    NSURL *url = [NSURL fileURLWithPath:@THEOS_PACKAGE_INSTALL_PREFIX "/var/mobile/Library/Preferences/me.lau.AtriaPrefs.plist"];
    NSMutableDictionary *dict = [[NSDictionary dictionaryWithContentsOfURL:url error:&error] mutableCopy]
                                    ?: [NSMutableDictionary new];
    if(error) {
        [self displayAlert:@"导出失败" message:[NSString stringWithFormat:@"错误：%@", error.localizedDescription]];
        return;
    }

    // The underscore prefix means it's an internal setting, not meant to be shared
    for(NSString *key in [dict allKeys])
        if([key hasPrefix:@"_"]) [dict removeObjectForKey:key];

    // Easier to make it json imho
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:0
                                                         error:&error];
    if(error) {
        [self displayAlert:@"导出失败" message:[NSString stringWithFormat:@"错误：%@", error.localizedDescription]];
        return;
    }

    NSString *encoded = [jsonData base64EncodedStringWithOptions:0];
    [UIPasteboard generalPasteboard].string = encoded;
    [self displayAlert:@"成功" message:@"设置已导出，并复制到剪贴板了"];
}

- (void)importSettingsString {
    NSString *pasteboardString = [UIPasteboard generalPasteboard].string;
    if(!pasteboardString) {
        [self displayAlert:@"导入失败" message:@"剪贴板里没找到内容。"];
        return;
    }
    NSData *decodeData = [[NSData alloc] initWithBase64EncodedString:pasteboardString options:0];
    if(!decodeData) {
        [self displayAlert:@"导入失败" message:@"解码失败，剪贴板里的设置串可能无效。"];
        return;
    }

    NSError *error;
    NSDictionary *settingsDictionary = [NSJSONSerialization JSONObjectWithData:decodeData options:kNilOptions error:&error];

    if(!settingsDictionary) {
        [self displayAlert:@"导入失败" message:[NSString stringWithFormat:@"剪贴板里的设置串可能无效。\n\n错误：%@", error.localizedDescription]];
        return;
    }

    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:ARIPreferenceDomain];
    [defaults removePersistentDomainForName:ARIPreferenceDomain];
    defaults = [[NSUserDefaults alloc] initWithSuiteName:ARIPreferenceDomain];
    [defaults synchronize];

    // Set ARIDidSplashPreferenceKey, since they are in preferences already
    [defaults setObject:@(YES) forKey:ARIDidSplashPreferenceKey];

    for(NSString *key in [settingsDictionary allKeys]) {
        // The underscore prefix means it's an internal setting, not meant to be shared
        if([key hasPrefix:@"_"]) continue;
        [defaults setObject:settingsDictionary[key] forKey:key];
    }
    [defaults synchronize];

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"成功"
                         message:[NSString stringWithFormat:@"设置已导入。建议注销一次让全部生效。\n\n已导入：%@", settingsDictionary]
                  preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *defaultAction = [UIAlertAction
        actionWithTitle:@"注销"
                  style:UIAlertActionStyleDestructive
                handler:^(UIAlertAction *action) {
                    [self respringWithAnimation];
                }];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)displayAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:title
                         message:message
                  preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *defaultAction = [UIAlertAction
        actionWithTitle:@"好"
                  style:UIAlertActionStyleCancel
                handler:nil];

    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
