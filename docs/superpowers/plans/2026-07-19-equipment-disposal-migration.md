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

- [x] `grep lib/data/` features 反向 import（相对与 package: 两种形式）= 0 命中（豁免 isar_setup composition root，07-18 批明文口径）。
- [x] 级联评估结论入 plan（本节下方「级联评估」）。
- [x] 迁移纪律：方法体逐字迁不改逻辑；除 import/export 调整外零行为变化。
- [x] `flutter analyze` = 0 issue。
- [x] `flutter test --no-pub test/features/equipment/` 全绿（202/202）。
- [x] 消费 numbers_config 的邻近 targeted 抽 2 文件复跑绿（9/9）。
- [x] §8.2 四证据齐（见文末）。

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

1. ✅ 预热（worktree/pub 对齐/build_runner/冒烟）+ 级联评估 + 本 plan → commit `15c02b69`。
2. ✅ 迁移实施：新 def 文件 + import/export + numbers_config import 调整 → dart format → analyze → targeted → commit `e8d58520`。
3. ✅ 邻近复跑（numbers_config 消费方抽 2 文件）。
4. ✅ 目标 2 核实：已由 main@`39a4be47` 落地，本单不重复开工，独立复跑留档（见下）。
5. ✅ 四证据补齐 + [READY] 冻结。

## 目标 2 核实留档（不重复开工）

任务书现状描述（_pickFormation 无测）已过时：`test/features/mainline/presentation/stage_entry_flow_formation_test.dart` 已于 2026-07-19 经 commit `39a4be47`「目标2:补阵型选择分支行为级测试(三态/默认/回退/装配落点)」落在 main（本单基点 db9151d1 已含）。真队伍装配 wiring（真 Isar fallback 单人队 + SharedPreferences mock + 录制 battleProvider 观测 strategy 阵型烘焙）与断言破坏证红由该 commit 自带。

本单独立复跑验证（worktree 内实测）：
- `flutter test --no-pub test/features/mainline/presentation/stage_entry_flow_formation_test.dart` → All tests passed (2/2)。
- `flutter test --no-pub --coverage test/features/mainline/presentation/` → 106/106 全绿；lcov 实测 `stage_entry_flow.dart` 行覆盖 **359/481 = 74.6%**（A 单后基线 262/481 = 54.5% → **+20.1pt**，分母同 481 同口径）。
- 结论：目标 2 期望终态已达成，本单零追加改动（禁区 presentation 零触碰）。

## 当前恢复点

- **状态**：目标 1 完成并验证，目标 2 核实留档；切片 5 四证据补齐后打 [READY] 冻结。
- **最后完成**：迁移 commit `e8d58520`（3 文件：+1 def 新文件 / numbers_config import 改指 / feature 文件改 import+export）；analyze 0；targeted 全绿。
- **下一步**：无（待主会话合并 Gate 评审）。
- **已跑验证**（全部 worktree 内实测，命令均可独立复跑）：
  - 反向边：`grep -rn "import.*'\.\./features\|import.*'package:wuxia_idle/features" lib/data/ | grep -v '^lib/data/isar_setup.dart'` → **0 命中**（isar_setup 为 07-18 批明文豁免的 composition root，文件内有豁免注释 L12-15；main 基线即 15 条 import，非本单引入）。
  - `flutter analyze` → **No issues found!**
  - `flutter test --no-pub test/features/equipment/` → **202/202 全绿**（首跑 198/199 有 1 例 equipment_detail_screen_test 锁定装备用例失败，单文件复跑 5/5 过、整目录重跑 202/202 过 → 隔离型 flaky，与本改动无关：纯类搬迁零行为变化）。
  - 邻近 numbers_config 消费方：`flutter test --no-pub test/core/domain/entities_test.dart test/tools/enhancement_material_supply_test.dart` → **9/9 全绿**。
  - 目标 2 复跑：见上节（2/2 + 106/106 + 覆盖 74.6%）。
- **阻塞项**：无。

## 边界约束（任务书原文）

- 可碰域：lib/data/（仅迁移落位与 import 调整）、lib/features/equipment/、test/、本 plan。
- 禁区：numbers.yaml 及全部 data/*.yaml、schema/saveVersion、presentation、strings.dart、GDD.md、PROGRESS.md、pubspec.yaml、战斗结算与公式。
- 测试节奏：targeted + analyze，不跑全量（批末主会话统一）。
- Edit 过的 dart 文件 commit 前 dart format；commit message 中文动宾。

## §8.2 四证据

1. **生产接线**：本单为依赖方向收敛，无新接线；既有生产链路零改动 —— `NumbersConfig.disposal`（`lib/data/numbers_config.dart:104` 字段 / :407-409 fromYaml）经 `GameRepository` 加载后由 `EquipmentDisposalService`（出售/分解出口）、`inventory_organization`、`bulk_disposal_dialog`、`equipment_detail_screen` 等 7 个生产消费方使用；消费方 import 全部经 feature 文件 `export` 透传，符号来源改指 `lib/data/defs/equipment_disposal_def.dart`，callsite 零改动。
2. **targeted test**：命令与通过数见「当前恢复点 · 已跑验证」—— equipment 域 202/202、邻近 9/9、目标 2 复跑 2/2 + mainline presentation 目录 106/106。
3. **红线影响**：零数值触碰（data/*.yaml 未碰，`EquipmentDisposalConfig.fromYaml` 逐字搬迁，解析语义不变）；三系锁死 / 在线=离线 / §5.1 反主流不涉；无中文文案/数值常量写入 Dart（def 文件仅类定义，与原文件逐字一致）；schema/saveVersion 未碰；战斗结算与公式未碰；presentation 零触碰（`git diff main --stat` 可证：仅 2 dart + 1 新 def + 1 plan）。
4. **残留风险**：① equipment_detail_screen_test 存在隔离型 flaky（目录并发跑偶发 1 例失败，单跑/重跑均过，main 基线已存在，非本单引入，建议批末全量时留意）；② `equipment_disposal.dart` 现同时 import+export 同一 def 文件（export 保下游、import 供本文件签名），是 Dart 标准手法但风格上属首例，主会话若偏好逐点改 import 可在后续批收口（会碰 presentation，本单边界内不可行）；③ 全量测试未跑（按任务书节奏留批末主会话统一）。
