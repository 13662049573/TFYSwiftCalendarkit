# TFYSwiftCalendarkit 2.0.1

## 可用于 GitHub Release 的说明

本版本为 **iOS 16+** 现代化补丁，无破坏性 API 变更。

- 在 iOS 17 及更高版本使用 `registerForTraitChanges` 监听界面风格变化，更新单元格、事件点与星期栏的动态颜色；iOS 16 仍通过 `traitCollectionDidChange` 处理。
- 日历头部上一页/下一页按钮改用 `UIAction`，替代 `#selector` 与 `addTarget`。
- 月/周范围切换的布局动画在开启 **减少动态效果（Reduce Motion）** 时立即完成，与选中动画行为一致。

回归测试共 60 项（与仓库 `Tests/TFYSwiftCalendarkitTests` 中 XCTest 方法数量一致）。

## 本地验收

发布前在 iOS 16 模拟器或更高版本运行：

```sh
python3 Scripts/validate_release_metadata.py --tag 2.0.1

xcodebuild test -scheme TFYSwiftCalendarkit \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES SWIFT_SUPPRESS_WARNINGS=NO
```

## 维护者发布提示

1. 合并包含本说明的 PR，确认 iOS CI 通过。
2. 创建 GitHub Release：**Tag 为 `2.0.1`**（与 `spec.version` 一致，勿使用 `v` 前缀）。
3. 标签校验与 CocoaPods 流程同 [2.0.0 发布说明](RELEASE_2.0.0.md)；本补丁不要求 trunk push，除非维护者主动发布。
