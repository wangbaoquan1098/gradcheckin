# 打卡趋势功能设计

## 背景

用户希望在考研打卡应用中按周或按月直观看到打卡趋势。趋势入口放在设置菜单中，界面需要美观，并同时展示打卡率和打卡天数。

## 范围

本次功能新增一个独立的「打卡趋势」页面，从首页右上角设置菜单进入。页面支持按周和按月切换，主图展示打卡率趋势，辅助信息展示每个周期的已打卡天数和应打卡天数。

不新增数据库表，不改变现有打卡记录结构，不调整首页日历打卡交互。

## 用户体验

- 设置菜单新增「打卡趋势」菜单项，位于历史记录附近。
- 点击后打开新页面，保留 Material 返回导航。
- 趋势页顶部展示两个概览指标：
  - 当前周期打卡率。
  - 当前周期打卡天数，格式为 `已打卡/应打卡 天`。
- 页面提供「按周 / 按月」分段切换，默认显示按周。
- 图表以折线展示各周期打卡率，并用辅助柱或标签体现打卡天数。
- 周期列表按时间从早到晚展示，只展示打卡开始日期到今天之间的周期；如果今天晚于打卡结束日期，则只展示到结束日期。
- 空数据时仍展示周期，打卡率为 0%，避免用户误以为页面坏掉。

## 数据规则

- 数据来源为 `CheckinProvider.checkedDates` 和 `AppDates.checkinStartDate/checkinEndDate`。
- 周统计以周一到周日为一个周期，沿用 `AppDates.getWeekNumber` 的周数概念。
- 首周和末周只统计与有效日期范围相交的日期。
- 当前周和当前月只统计到今天。
- 未来日期不计入应打卡天数。
- 月统计按自然月聚合，首月和末月同样只统计有效范围内的日期。
- 每个周期包含：
  - `label`：如 `第1周`、`3月`。
  - `startDate` / `endDate`：该周期实际统计范围。
  - `checkedDays`：已打卡天数。
  - `totalDays`：应打卡天数。
  - `rate`：`checkedDays / totalDays`，`totalDays` 为 0 时为 0。

## 技术设计

- 新增纯 Dart 模型和计算工具：
  - `lib/data/models/checkin_trend.dart`
  - `lib/core/utils/checkin_trend_calculator.dart`
- 新增页面和图表组件：
  - `lib/screens/trends/trend_screen.dart`
  - `lib/screens/trends/widgets/checkin_trend_chart.dart`
- 修改：
  - `lib/screens/home/home_screen.dart`：设置菜单新增入口并导航。
  - `lib/core/constants/app_strings.dart`：新增趋势相关文案。
- 图表使用 `CustomPainter` 实现，不引入第三方图表库。
- 趋势页通过 `Consumer<CheckinProvider>` 读取当前打卡集合。打卡数据在应用启动时已加载，页面不直接访问数据库。

## 视觉方向

采用用户选择的 A 方案：独立趋势分析页。整体延续现有蓝色主色和绿色打卡状态色；深色模式使用现有暗色 surface、outline 和文本色。图表卡片圆角控制在 8px 左右，页面布局保持清晰、克制、适合反复查看。

## 测试

新增趋势计算单元测试：

- 按周聚合会正确处理首周不足 7 天。
- 当前日期会截断未来日期。
- 按月聚合会正确统计跨月范围。
- 空打卡集合会生成 0% 周期。
- 已打卡日期只在有效范围内计入。

实现后运行：

```bash
flutter test
flutter analyze
dart format lib test
```

## 验收标准

- 设置菜单可进入「打卡趋势」页面。
- 用户可在按周和按月之间切换。
- 图表和摘要同时展示打卡率与天数。
- 深色模式下趋势页可读、无明显刺眼色块。
- 趋势计算测试通过，项目分析无新增错误。
