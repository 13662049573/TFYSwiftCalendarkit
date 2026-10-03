# TFYSwiftCalendarkit 全面评估与完善记录

评估日期：2026-10-03。范围包括全部 13 个组件源文件、SwiftUI 封装、公开协议、SPM/CocoaPods 资源打包、测试、11 个示例入口及 CI。评估开始时工作区干净；本轮改动纳入 2.0.0，最低系统统一为 iOS 16。GitHub Release/标签由维护者创建后，再从标签执行发布验收。

## 当前结构与优点

| 层次 | 职责 | 评价 |
| --- | --- | --- |
| `TFYSwiftCalendar` | UIKit 容器、页面、选择、手势与代理 | 对接简单，数据源与代理弱引用，UI 在主线程隔离 |
| `TFYSwiftCalendarMath` | 民用日期与网格计算 | 使用 Calendar 运算，避免固定秒数造成夏令时偏移 |
| CollectionViewLayout | 分页、连续滚动、吸顶标题 | 可见区域按需生成属性；连续分区二分定位 |
| Cell / Appearance / DayStyle | 复用、全局外观、逐日期样式 | 业务内容与绘制分离；支持动态颜色、自定义 Cell 与事件点 |
| CalendarView | SwiftUI 状态桥接 | UIKit 能力可复用，无第三方运行时依赖 |
| 包与资源 | SPM、CocoaPods、隐私清单、英中语言资源 | 具备独立集成基础；示例工程引用本地包 |

原有 39 个测试全部通过，但这些测试主要覆盖常规公历使用；通过测试不等于跨历法、配置切换和 SwiftUI 状态契约完整。

## 本轮风险与修复

| 优先级 | 问题与实际影响 | 修复及验证 |
| --- | --- | --- |
| 高 | 日期键只包含纪元/年/月/日，农历二月与闰二月同一天相互覆盖；分量排序也不等于时间顺序 | 使用指定 Calendar 的绝对日开始时间作为身份和排序依据；验证普通月、闰月及跨闰月范围选择 |
| 高 | 在农历中构造年份 1970/2099，被解释成农历年份；复现的公历范围变成 3953—4083 年 | 默认范围固定为组件时区内的公历 1970-01-01 至 2099-12-31，展示历法独立 |
| 高 | 切换水平/垂直与分页/连续模式时，旧滚动回调覆盖 currentPage；页面可能跳到首页 | 布局变更统一重新对齐当前页；布局事务期间阻止旧偏移写回；验证行高、吸顶高度与内边距变化 |
| 高 | NaN/Infinity 进入布局属性会触发 UIKit “requires finite coordinates” 异常；负值可能生成无效尺寸 | 清理公开尺寸、内边距、星期栏样式与描边参数；保护无效 IndexPath；小尺寸 Cell 保持非负几何 |
| 高 | SwiftUI 收到多个绑定日期就强制开启多选，绕过 configure 的单选策略；configure 回调未完全纳入同步保护 | 配置策略为准，创建与更新共用同步入口；整个配置事务禁止同步写回 Binding |
| 中 | 超出选择上限、范围裁剪后的 SwiftUI Binding 仍保留无效日期 | 新增最终选择集合回调；更新结束后延迟写回实际选择、页码与 scope；新更新和拆除取消旧任务 |
| 中 | month 的 currentPage 规范化到月初后，切换 week 丢失目标日；SwiftUI 再次同步月初进一步覆盖锚点 | 独立保存目标日，优先使用当前页内的选中日；桥接层只在页码绑定实际变化时应用请求 |
| 中 | 整个日期范围先创建数组，设置少量选择上限仍付出全范围内存与代理调用成本 | 懒生成日期，达到上限后停止；一年范围/上限 3 的测试仅进行 4 次 shouldSelect 判断 |
| 中 | RTL 自动镜像布局与手工滚动偏移使用不同坐标，页面查询和页码回写不一致 | 显式镜像列与页面，共用偏移映射；标题按钮及范围端点遵循方向；验证可见 Cell 和滚动回写 |
| 中 | 同一天同时出现在本月和占位页时，只更新绘制状态，UICollectionView 的 isSelected 可能不一致 | 同步所有可见实例的真实选择状态；验证两份 Cell 同步选中和取消 |
| 中 | 占位日期隐藏时，范围填充仍延伸到空白格；重复选择已有日期无法返回其页面 | 根据可见月份边界断开连接；重复选择仍执行导航，保持选择事件幂等 |
| 中 | 无障碍状态语言跟随设备而不跟随组件 locale；样式提供的事件点未计入播报 | 按组件 locale 选择资源；日期数字本地化；事件播报采用实际生效的内容/样式 |
| 中 | 示例 EventKit 把恰好在午夜结束的事件算到第二天；查询末日可能不完整，拒绝权限仍保留旧数据 | 使用半开区间交集，单独处理零时长事件；查询覆盖末日，拒绝时清空缓存 |
| 低 | preferredHeight 忽略上下内边距和连续标题；可见吸顶标题不参与外观刷新；反复计算总页数 | 补齐高度组成与标题刷新，缓存页数，并复用连续分区行数 |

月起点采用 `Calendar.dateInterval(of: .month, for:)`，避免自行重组日期分量。回归测试包含日本纪元切换所在月份。参考：[Apple Calendar 文档](https://developer.apple.com/documentation/foundation/calendar)、[Calendar.Component 文档](https://developer.apple.com/documentation/foundation/calendar/component)。

## 接入与行为约定

- 日期身份是组件 Calendar/时区下的民用日。更改时区后，已有绝对时间重新归一化并去重，可能改变显示日期或减少选择数量。
- currentPage 是当前月或周的起点，可能早于 minimumDate（范围从月中开始时）；范围内的日期仍由 minimumDate/maximumDate 控制。
- 数据源或代理赋值后，调用 reloadData 更新范围和内容；更换内容或样式但范围不变时优先使用 reloadDates / reloadVisibleDates / invalidateAppearance。
- selectedDates 按时间排序；selectedDate 是最晚日期。单选批量请求保留最晚候选日期。
- 空数组并替换会清空；无效或全部被 shouldSelect 拒绝的非空请求保留原选择。
- deselectDate 尊重 shouldDeselect；批量替换、清空、关闭多选及降低上限会强制移除日期，shouldDeselect 不参与这些操作。最终集合变化通过 calendarSelectionDidChange 通知；范围裁剪也触发该回调。
- allowsSelection 关闭用户选择/取消与程序选择；显式的程序取消仍可用。无障碍 Cell 同步标记不可操作。
- 范围选择会开启多选；它按时间连续枚举，但 shouldSelect 拒绝某日或达到上限时，实际集合可能不连续。
- SwiftUI 的 configure 必须可重复执行；多选需显式设置 allowsMultipleSelection。超限/越界请求会在当前更新结束后归一化到 Binding。
- 自定义 Cell 必须继承 TFYSwiftCalendarCell，并在 cellFor 回调中通过组件 dequeueReusableCell 获取恰好一份 Cell；使用未注册标识或重复出队属于调用错误。
- 连续垂直布局的初次度量仍与月份数量成正比；页面网格缓存上限为 48。无限制的长范围选择仍须保存所有被选择的日期；大型业务范围应设置 maximumSelectedDates。

## 验证结果

| 检查 | 结果 |
| --- | --- |
| 改动前包测试 | 39 个测试，0 失败 |
| 2.0.0 / iOS 16 配置下包测试，Swift 警告作为错误 | 59 个测试，0 失败；新增 20 个边界与状态测试 |
| 2.0.0 示例工程构建，Swift 警告作为错误 | 成功 |
| CocoaPods 本地 lint，包含 Tests test spec | passed validation；允许工具链警告 |
| 模拟器 | iPhone 18 Pro Max / iOS 27.0 |
| 示例运行 | SwiftUI、范围选择、全屏连续日历、自定义日期标签的启动/已有烟雾入口与画面检查 |

本机 CocoaPods 验证存在 Metal 工具链搜索路径、AppIntents 元数据跳过，以及 XCTest 二进制最低版本相关的工具链警告。SPM 与示例的 Swift 警告作为错误检查通过。具体命令见 CONTRIBUTING.md。发布准备新增元数据一致性检查，并修复 CI 的固定 Xcode/模拟器路径依赖；GitHub 发布标签后会校验远程 Pod 源码。

## 仍需关注的不足

1. `TFYSwiftCalendar` 同时管理选择、页面、手势与渲染，文件较大。本轮统一选择提交入口和布局事务，但后续适合在测试保护下抽取内部选择状态与页面控制对象，保持公开 API 不变。
2. headerOrder 与事件指示器 fallbackColor 仍为旧接口保留项，现有绘制使用 headerDateFormat 与显式 eventColors。接入时使用实际生效的接口，后续主版本可整理这些冗余设置。
3. 原有 today 是创建时快照；长期运行的宿主应在跨日或回到前台时更新 today。today = nil 是关闭今日强调的方式。
4. 本轮没有在 iOS 16 真机或各历史历法/跳过整日的时区上逐项验收；不把现代日期回归结果泛化为所有历法历史正确性。
5. VoiceOver 完整导航、最大辅助字体下的易用性，以及真实设备滚动帧率仍需人工/性能工具验收。本轮验证了语义属性、图层复用、有限缓存与模拟器画面，未提供性能基准数字。
6. EventKit 修复经过示例构建验证；未读取用户设备日历或实测权限撤销，宿主业务需要单独验收权限和事件更新流程。

库本身不发送网络请求、不读取设备日历、不持久化选择、不包含认证密钥。EventKit 只存在于示例，授权由系统管理。此次检查未发现需要按安全漏洞处理的网络或凭证路径，主要高风险集中在日期身份、UI 异常和状态一致性。
