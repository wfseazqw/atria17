TARGET := iphone:clang:latest:15.0
ARCHS = arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Atria
Atria_FILES = $(shell find src -type f \( -name "*.x" -o -name "*.m" \) | sort)
Atria_CFLAGS = -fobjc-arc -DTHEOS_PACKAGE_INSTALL_PREFIX='"/var/jb"'
Atria_FRAMEWORKS = UIKit Foundation CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = AtriaPrefs
AtriaPrefs_INSTALL_PATH = /Library/PreferenceBundles
AtriaPrefs_FILES = $(shell find Prefs/src -type f -name "*.m" | sort)
AtriaPrefs_CFLAGS = -DTHEOS_PACKAGE_INSTALL_PREFIX='"/var/jb"'
AtriaPrefs_FRAMEWORKS = UIKit Foundation
AtriaPrefs_PRIVATE_FRAMEWORKS = Preferences
AtriaPrefs_RESOURCE_DIRS = Prefs/Resources

include $(THEOS_MAKE_PATH)/bundle.mk

# RootHide / Relaxin 打包：
#   make package THEOS_PACKAGE_SCHEME=roothide
