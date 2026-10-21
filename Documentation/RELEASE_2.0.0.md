# TFYSwiftCalendarkit 2.0.0

## 可用于 GitHub Release 的说明

本版本将最低支持系统提升至 **iOS 16**，统一 Swift Package Manager、CocoaPods、SwiftUI 封装及示例工程的系统要求。仍需支持 iOS 15 的项目请继续使用 GitHub 的 1.1.0 标签（SPM）。

- 修复农历普通月与闰月的日期身份冲突，以及切换历法后默认年份范围错误。
- 修复水平/垂直、分页/连续布局切换时跳页，月/周切换保留目标日与选择锚点。
- 加固无效尺寸、内边距与布局查询，统一 RTL 页面偏移与范围连接方向。
- SwiftUI 严格遵循单选/多选配置，延迟归一化绑定，取消过期同步任务。
- 新增最终选择集合变化回调，覆盖日期范围裁剪及数量限制变化。
- 范围选择按需生成日期，达到上限后停止，降低长范围选择的额外开销。
- 同步同一天所有可见占位实例的选择状态，补齐本地化无障碍说明。
- 修复示例 EventKit 午夜与末日边界，并使权限请求桥接兼容旧 SDK 的 Swift 6 隔离检查；更新接入、迁移和质量评估文档。
- 修复 DIY / 全屏示例切换农历及事件时的闪烁，原地刷新并保留选中状态与滚动位置；避免并发权限请求和成功空结果反复加载。
- 回归测试共 60 项，其中新增 21 项边界与状态同步测试。

## 本地最终验收

2026-10-03 已完成：版本/系统元数据一致性检查、iOS 16 编译目标下的 60 项 SPM 测试、示例工程构建和包含 Tests test spec 的 CocoaPods 本地校验，均通过。测试运行环境为 Xcode 27.0 / iPhone 18 Pro Max / iOS 27.0；最低系统编译目标核验为 iOS 16.0，尚未进行 iOS 16 真机运行验收。

准备阶段查询 trunk 时尚无该名称的已发布 Pod，因此 2.0.0 将是本组件的首次 CocoaPods 发布；已有 GitHub 1.1.0 标签供 SPM 使用。当前 trunk 登录会话有效，正式发布前仍须再次核验会话与名称状态。

## 维护者创建 GitHub Release

1. 等待本次 main 提交及 iOS CI 检查完成。
2. 在 GitHub 仓库的 Releases 中创建新版本：**Tag 为 `2.0.0`，Target 为本次已验证的 main 提交，标题可用 `2.0.0`**。
3. 发布正式 Release（不选 Draft 或 Pre-release）。可复制上面的说明。

标签必须为 `2.0.0`，因为 podspec 的源码标签严格取 `spec.version.to_s`；`v2.0.0` 不能替代它。本次准备工作只提交与推送代码，GitHub Release 由维护者创建。

## 标签出现后的验收与 CocoaPods 发布

从 `2.0.0` 标签检出干净源码，确认其指向经过验证的提交。运行元数据一致性检查、SPM 测试、示例构建及远程源码 Pod 校验；标签/Release 对应的 GitHub Actions 也必须通过。

```sh
python3 Scripts/validate_release_metadata.py --tag 2.0.0

pod spec lint TFYSwiftCalendarkit.podspec --allow-warnings --test-specs=Tests

# 仅在正式 GitHub Release、标签源码及全部检查通过后执行。
pod trunk push TFYSwiftCalendarkit.podspec --allow-warnings
```

发布需要有效的 CocoaPods trunk 会话且账号具有该 Pod 的发布权限。发布后检查 trunk 的版本记录，并在干净消费者工程使用 `pod 'TFYSwiftCalendarkit', '2.0.0'` 验证可解析和构建；以成功解析的精确版本证明发布结果。CocoaPods CDN 收录可能晚于 trunk 接受，未收录时继续等待，避免重复发布。

严格构建同时指定 `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES SWIFT_SUPPRESS_WARNINGS=NO`，避免某些 Xcode 自动对包依赖抑制警告时出现参数冲突。

SPM 不需要额外上传：GitHub 的有效版本标签提供包版本，但仍应在独立的 iOS 16 消费者工程验证精确 `2.0.0` 可解析与构建。最低系统构建检查不等同于 iOS 16 真机运行验收。

完整行为约定与验收边界见 [质量评估](QUALITY_REVIEW.md)；本地构建命令见 [Contributing](../CONTRIBUTING.md)。
