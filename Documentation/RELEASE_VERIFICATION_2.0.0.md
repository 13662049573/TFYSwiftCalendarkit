# 2.0.0 发布验收记录

核验日期：2026-10-03。最低支持系统：iOS 16。组件语言模式：Swift 6。

## 发布来源

- [GitHub 正式 Release](https://github.com/13662049573/TFYSwiftCalendarkit/releases/tag/2.0.0)：tag 为 `2.0.0`，非 Draft、非 Pre-release。
- 标签提交：`df5fe5b836a7806838257ba1bf633a1fd97a4996`；源码树：`5feaa2898abb2629d575eb1c5ee02792dd4422aa`。
- [标签 CI](https://github.com/13662049573/TFYSwiftCalendarkit/actions/runs/37121866664)、[Release CI](https://github.com/13662049573/TFYSwiftCalendarkit/actions/runs/37121866875) 均成功，包含远程源码 Pod 校验。
- CocoaPods trunk 于 `2026-10-03 12:25:36 UTC` 接受 `2.0.0`，是该 Pod 首次发布。
- [官方 Specs 记录](https://github.com/CocoaPods/Specs/blob/48e4057c4d5b8b949563892751d8d9bec1a069e2/Specs/3/d/e/TFYSwiftCalendarkit/2.0.0/TFYSwiftCalendarkit.podspec.json) 与已验证标签的 Pod 规格完全一致，源码标签为 `2.0.0`，最低系统为 `16.0`。

## 验收结果

| 项目 | 结果 |
| --- | --- |
| 标签源码元数据、iOS 16 编译目标 | 通过 |
| 标签源码 SPM 测试 | 60 项，0 失败；Swift 警告作为错误 |
| 标签源码示例构建 | 通过；Swift 警告作为错误 |
| 远程源码 pod spec lint，包含 Tests test spec | 通过 |
| 实际 DIY 农历/事件按钮点击回归 | 通过；连续切换保留 4 个选择及日期格位置；临时 UI 验收不计入 60 项包测试 |
| 独立 SPM 项目精确版本解析 | `2.0.0`，提交与标签一致 |
| 独立 SPM 项目构建与运行 | 通过；中文按钮/选中状态资源加载通过 |
| 官方 Pod 规格的独立项目构建与运行 | 通过；实际从标签下载的 16 个源码/资源文件与标签一致，中文资源加载通过 |
| 标准 CDN 精确版本安装与构建 | 等待 CDN 索引同步，尚未完成 |

独立项目最低编译目标均为 iOS 16.0，运行环境为 Xcode 27.0 / iPhone 18 Pro Max / iOS 27.0。GitHub CI 使用 Xcode 16.4。

## 本次复查的补充

在 main 补齐 DIY 示例首次显示前的数据源范围及外观加载，并修正 README 的测试数量和构建参数。元数据检查增加 XCTest 测试数量与 README / Release 说明的一致性检查。这些示例和维护文件补充未改写正式 `2.0.0` 标签；组件库 `Sources`、`Package.swift`、Pod 规格与发布标签一致。

## 验收边界

已确认的问题及修复证据见 [质量评估](QUALITY_REVIEW.md)。本次复查未发现新的组件发布阻断问题，不代表所有潜在问题均已消除。iOS 16 真机运行、真实用户事件数据、完整手动 VoiceOver / Dynamic Type 及设备性能验收仍需在业务集成环境完成。

目前 SPM 与 trunk / 官方 Specs 已发布；标准 CocoaPods CDN 索引验收仍在跟进，不能将它与上传成功混为一谈。无需再次上传同一版本。
