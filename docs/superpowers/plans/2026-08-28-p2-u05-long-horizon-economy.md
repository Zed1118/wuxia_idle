# P2 U05 长周期经济模拟计划

## 目标

在 N14 `[READY]` tip `85ee8483` 已证明手动、前台 bot、headless 与扫荡重复
3 次共享收益 profile 的基础上，补齐 7 阶 × 7/14/30 天的跨系统资源容量模拟。
本任务只新增诊断代码与测试，不修改生产逻辑、配置、数值或玩家可见内容。

## 分支与范围

- 分支：`codex/p2-u05-long-horizon-economy-20260828`
- 基线：`85ee84833b6d4ebf41176ce261ec19c3fe5cd73d`
- 允许：本计划、`test/support/`、`test/tools/`
- 禁止：`lib/`、`data/`、`GDD.md`、`PROGRESS.md`、`CLAUDE.md`、
  `lib/shared/strings.dart`、`pubspec.yaml`、`.github/`
- 测试删除明示例外表：无；不得删除或弱化任何既有测试行。

## 固定验收分母

U05 共 2 个子门：

1. N14 已关闭：同一真实关卡、同 seed、重复 3 次，四模式 tick/hash 与奖励
   profile 一致。
2. 本任务关闭：7 个 `RealmTier` × 3 个时间窗，共 21 个诊断格；每格覆盖
   闭关、桃花岛独立配方容量、同阶主线重打期望掉落与装备全卖/全拆边界；
   另列 +15/+30/+49 强化和三槽开锋主要 sink。

第二门只判断证据是否完整、非负、有限、随时间不倒退以及生产配置/纯函数是否
被真实消费；不判断数值“好坏”，不把一天一次重打的归一化负载解释为产品日课。

## 实现切片

1. 新增纯诊断模型，直接调用 `SeclusionService.computeSettlement`、
   `IslandProductionService.settle`、`equipmentSellPrice`、
   `equipmentDisassembleRewards` 与生产 `GameRepository` 配置。
2. 对 7 阶逐阶选择已解锁闭关图；桃花岛各配方独立跑满，避免替用户决定并行
   配方占比；主线按同阶关卡平均期望掉落归一化为每时间单位一次对比负载。
3. 生成 21 格矩阵和主要 sink 到 ignored `build/phase2_wiring_receipts/U05/`。
4. 定向测试断言矩阵完整、所有资源有限非负、同一阶随 7→14→30 天不倒退、
   五类目标资源均有真实生产来源。
5. 提交后双向破坏证红：移除闭关贡献、强制桃花岛产出归零；每次精确反向补丁
   还原并核 HEAD/clean。
6. 跑 targeted、`flutter analyze --no-pub lib test tool`、整仓 format、全量测试、
   diff/禁区审计；最终 `[READY]` 或真实 `[BLOCKED]`。

## 验收标准

- 21/21 格生成，7 个 `RealmTier` 与 7/14/30 天各无缺口。
- `item_mojianshi`、`item_xinxuejiejing`、`item_silver`、
  `item_liaoshangdan`、`item_kaifeng_fucai` 五类均至少有一个生产来源。
- 所有数量有限、非负；同阶同来源随时间窗不倒退。
- 强化/开锋 sink 全从 production config 计算，无复制产品数值。
- 变异任一方向不红即 `[BLOCKED]`。
- 最终工作树 clean，tip 为 `[READY]`/`[BLOCKED]`，receipt 写在 ignored build 路径，
  不提交 receipt。

## 当前恢复点

- 状态：WIP
- 最后完成：复核 N14 已覆盖重复重打/扫荡收益一致性，冻结本任务唯一剩余分母。
- 下一步：实现诊断模型与 21 格测试。
- 已跑验证：仅只读符号与现有测试核对。
- 阻塞项：无。
