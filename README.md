# Atria 17（RootHide / Relaxin 移植版）

原项目：[ren7995/Atria](https://github.com/ren7995/Atria)（GPL-3.0），支持 iOS 13–16。
本项目是它在 **iOS 17 + RootHide 越狱（Relaxin）** 上的移植尝试，面向 iPhone 13（iPhone14,5，A15，arm64e）。

## 和原版的差异

1. 构建链路改为 **RootHide（roothide Theos）**：
   - `ARCHS = arm64e`，包架构 `iphoneos-arm64e`
   - 打包命令 `make package THEOS_PACKAGE_SCHEME=roothide`
2. 补写了原仓库没有提交的 `Makefile`（tweak + 设置面板 bundle 两套目标）。
3. iOS 17 崩溃兜底：
   - 所有 hook 入口先检查核心私有类是否存在（`SBIconListView` / `SBIconListFlowExtendedLayout` / `SBIconListGridLayoutConfiguration` / `SBHDefaultIconListLayoutProvider`），缺失则不挂 hook，避免 SpringBoard 崩进安全模式。
   - `SBIconListModel` 的 `_gridSize` / `_gridSizeClassSizes` ivar 写入前检查存在性，避免野指针。
   - 编辑器入口 `presentEditAlert` / 三击手势回调加 `@try/@catch`。
4. 内置探测（`src/Hooks/Probe.x`）：启动后 6 秒把关键类/方法签名/ivar 写入
   - `/tmp/atria17-probe.txt`
   - `/var/mobile/Documents/atria17-probe.txt`
5. 编辑器图标资源改为通过 `NSBundle bundleWithIdentifier:@"me.lau.AtriaPrefs"` 定位，避免 RootHide 下 `/var/jb` 前缀失效。

## 构建

GitHub Actions（无需 Mac）：

1. 把本目录推到 GitHub 仓库（任意分支名，默认工作流监听 `main`）
2. Actions 会自动执行 `.github/workflows/build.yml`
3. 在 Actions 页面下载 artifact 里的 `deb`

本地（Linux/macOS 均可）：

```bash
export THEOS=~/theos   # roothide 版 Theos
make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=roothide
```

## 安装

用 Sileo / Zebra 安装 `packages/*.deb`，然后注销（respring）。
设置 App 里会出现 Atria 入口；主屏幕三击空白处或 3D Touch 图标可打开实时编辑器。

## 已知限制

- iOS 17 的私有 API 未在真机上验证过，第一版可能需要按崩溃日志迭代。
- 编辑器（`ARIEditingMainView`）是原版实现，若在 17 上打开即崩，需要进一步降级或简化。
- 设置面板里部分路径（注销、导出预设）仍使用 `/var/jb` 前缀，在 RootHide 下可能失效（不影响布局功能）。

## 许可证

原项目为 **GPL-3.0**。本移植版是其衍生作品，分发时必须同样以 GPL-3.0 提供源码（见 `LICENSE`）。
