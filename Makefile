TARGET := iphone:clang:16.5:15.0
ARCHS = arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Atria
Atria_FILES = $(shell find src -type f \( -name "*.x" -o -name "*.xm" -o -name "*.m" \) | sort)
Atria_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
Atria_FRAMEWORKS = UIKit Foundation CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = AtriaPrefs
AtriaPrefs_INSTALL_PATH = /Library/PreferenceBundles
AtriaPrefs_FILES = $(shell find Prefs/src -type f -name "*.m" | sort)
AtriaPrefs_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -DPACKAGE_VERSION='@"$(THEOS_PACKAGE_BASE_VERSION)"' -DPACKAGE_TYPE='@"Release"'
AtriaPrefs_FRAMEWORKS = UIKit Foundation
AtriaPrefs_PRIVATE_FRAMEWORKS = Preferences
AtriaPrefs_RESOURCE_DIRS = Prefs/Resources

include $(THEOS_MAKE_PATH)/bundle.mk

# RootHide / Relaxin 打包：
#   make package THEOS_PACKAGE_SCHEME=roothide
# 注意：THEOS_PACKAGE_INSTALL_PREFIX 由 RootHide 的规则自动定义（值为空），
# 这里不要再手动定义，否则会触发 -Werror macro-redefined 编译失败。
