# 2026-07-19 · equipment_disposal 反向依赖收敛（K1 单）

> 执行端：kimi（转正首单 · 非表现层常规执行）。基点：main@db9151d1（origin 已同步）。
> 规矩源：CLAUDE.md §8.0/§8.2/§8.3；已读 docs/spec/rejected_task_registry.md（无冲突项）。

## 目标

- **目标 1**：消除 `lib/data/numbers_config.dart:7` 对 `features/equipment/domain/equipment_disposal.dart` 的 import —— 07-18 审查落地批后 data 层唯一残留 data→features 反向边（followup backlog #6）。
- **目标 2（弹性尾）**：`_pickFormation` 阵型分支测试补强（目标 1 [READY] 后、时间富余才做）。

## 分支 / worktree

- 分支：`kimi/equipment-disposal-migration`
- worktree：`.worktrees/equipment-disposal-migration`
- 环境：PUB_HOSTED_URL 必须 = `https://pub.flutter-io.cn`（与主 checkout 对齐；不带会翻源改 pubspec.lock —— 已实测踩过，lock 已还原并对齐重跑，diff 为空）。build_runner 已跑（128 outputs），冒烟 `equipment_disposal_test.dart` 3/3 过，libisar 无加载问题。

## 验收标准（目标 1 · 可观测）

- [ ] `grep -rn "features/" lib/data/`（相对与 package: 两种 import 形式）= 0 命中。
- [ ] 级联评估结论入 plan（本节下方「级联评估」）。
- [ ] 迁移纪律：方法体逐字迁不改逻辑；除 import/export 调整外零行为变化。
- [ ] `flutter analyze` = 0 issue。
- [ ] `flutter test --no-pub test/features/equipment/` 全绿。
- [ ] 消费 numbers_config 的邻近 targeted 抽 1-2 文件复跑绿。
- [ ] §8.2 四证据齐（见文末交付段）。

## 级联评估（先评估后动手 · 结论）

**numbers_config 实际消费面**：仅 `EquipmentDisposalConfig` 一个符号（`lib/data/numbers_config.dart` 字段声明 :107、构造参 :287、`fromYaml` :410-411，共 3 处 + import :7）。保护策略/出售价/分解函数等其余 8 个符号 numbers_config 一概不碰。

**equipment_disposal.dart 符号盘点（9 个）**：
- 纯配置/纯函数（无 slot_occupancy 依赖）：`EquipmentDisposalConfig`、`DisassembleRewards`、`equipmentSellPrice`、`equipmentDisassembleRewards`。
- 保护逻辑（依赖 feature 局部 `equipment_slot_occupancy.isEquipmentEquippedBySlot`）：`EquipmentProtectionReason`、`EquipmentProtectionPolicy`、`equipmentProtectionReason`、`isEquipmentProtected` 及 import。

**消费方 callsite 量**（grep 实测，生产 7 文件 + 测试 4 文件）：
- `EquipmentDisposalConfig`：numbers_config（3 处）+ equipment_disposal_service（1 处）。
- 保护逻辑符号：bulk_disposal_dialog(11)/inventory_organization(9)/equipment_disposal_service(15)/equipment_detail_screen(4)/equipment_service(3)/inventory_screen(1) —— 全在 features 内部，其中 3 个在 presentation（禁区）。
- `equipment_slot_occupancy` 另有 5 个独立消费方（全 features 内部）。

**整体迁移证伪**：把 equipment_disposal 整文件迁 `data/defs/` 会把 `equipmentProtectionReason` 一起带走 → defs 新文件 import features 的 `equipment_slot_occupancy` → **制造新的 data→features 反向边**，与本单目标背道而驰。backlog #6 所说「同迁」则要把 slot_occupancy 及其 5 个消费方一起拽进 data，级联面大且把纯 feature 关注点（槽位占用判定）错放进数据层。

**解耦证伪**：把 `isEquipmentEquippedBySlot` 内联/复制进迁移文件 = 复制逻辑，违反零行为变化与不重复原则；保护逻辑消费方全在 features，无迁 data 的收益。

**选定方案 = 拆分迁（最小面）**：
1. 新建 `lib/data/defs/equipment_disposal_def.dart`：**仅** `EquipmentDisposalConfig` 逐字迁入（唯一被 data 层消费的符号；与既有 31 个纯 def 同构）。
2. `lib/features/equipment/domain/equipment_disposal.dart` 删除该类，改为 `export '../../../data/defs/equipment_disposal_def.dart';` —— 7 个生产 import 点 + 3 个测试 import 点**零改动**（presentation 禁区文件完全不碰，这是否决「逐点改 import」方案的决定性约束）。
3. `numbers_config.dart` import 改指 `defs/equipment_disposal_def.dart`，删 5-6 行残留注释。
4. 保护逻辑 4 符号与 calc 2 函数留在 features 原文件不动（它们本就不被 data 消费，迁了反而扩大 diff 面）。

**零数值红线**：全程不碰 data/*.yaml；`fromYaml` 逐字搬，解析语义不变。

## 任务切片

1. ✅ 预热（worktree/pub 对齐/build_runner/冒烟）+ 级联评估 + 本 plan。
2. 迁移实施：新 def 文件 + export + numbers_config import 调整 → dart format → analyze → targeted。
3. 邻近复跑（numbers_config 消费方抽 1-2）→ commit。
4. （弹性）目标 2：`_pickFormation` 测试。
5. [READY] 冻结。

## 当前恢复点

- **状态**：切片 1 完成，切片 2 未开始。
- **最后完成**：级联评估结论（见上）；环境预热绿（pub get 无 lock 漂移 / build_runner 128 outputs / 冒烟 3/3）。
- **下一步**：建 `lib/data/defs/equipment_disposal_def.dart`，逐字迁 `EquipmentDisposalConfig`。
- **已跑验证**：`flutter test --no-pub test/features/equipment/domain/equipment_disposal_test.dart` → All tests passed (3/3)。
- **阻塞项**：无。

## 边界约束（任务书原文）

- 可碰域：lib/data/（仅迁移落位与 import 调整）、lib/features/equipment/、test/、本 plan。
- 禁区：numbers.yaml 及全部 data/*.yaml、schema/saveVersion、presentation、strings.dart、GDD.md、PROGRESS.md、pubspec.yaml、战斗结算与公式。
- 测试节奏：targeted + analyze，不跑全量（批末主会话统一）。
- Edit 过的 dart 文件 commit 前 dart format；commit message 中文动宾。

## §8.2 四证据（交付时填）

1. **生产接线**：（迁移完成后填：入口/消费方）
2. **targeted test**：（命令 + 通过数）
3. **红线影响**：（数值/三系/在线=离线/反主流/硬编码逐项）
4. **残留风险**：（未覆盖项）
