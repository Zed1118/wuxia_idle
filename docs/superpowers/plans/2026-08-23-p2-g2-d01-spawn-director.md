# P2-G2-D01：SpawnDirector 基础合同

## 任务元数据

- taskId: P2-G2-D01-SPAWN-DIRECTOR
- milestone: M1 / D 生成与攻击令牌（本任务只做生成侧）
- owner: Pi（DeepSeek V4 Flash 契约生产端）
- branch: `codex/phase2-g2-d01-spawn-director-20260823`
- worktree: `/Users/a10506/Desktop/Projects/挂机武侠-phase2-g2-d01-spawn-director`
- 依据: `docs/superpowers/plans/2026-08-23-p2-g2-batch2-encounter-foundation.md` + `二阶段优化方案.md` §12.3 / §12.4 / §17.3 / M1 / M2

## 目标与非目标

目标：纯 Dart、引擎无关的 `SpawnDirector` 领域合同，把总量/活跃/后备明确分离；显式入口；补兵阈值；入口预警与攻击宽限快照；稳定 reserve 顺序；不硬编任何 tuning 数值。

非目标：不接 reducer / 战斗模型 / 数据 loader / UI / 存档 / 生产关卡数据；不做入口几何/位置/通道（属 C02/geometry 流）；不做攻击令牌预算（D02 切片）；不替 E01 选参与角色；不写 20%–30%、8–16、2–4 之类默认 tuning。

## 白名单

- `lib/features/battle/domain/phase0a/spawn_director.dart`
- `test/features/battle/domain/phase0a/spawn_director_test.dart`
- 本计划文件

禁止修改其他文件（含 reducer / data / UI / save / 生产关卡数据）。

## 冻结合同

- `SpawnDirectorConfig`：`activeLimit`(>0)、`reinforcementThreshold`([0, activeLimit))、`entryWarningTicks`(≥0)、`attackGraceTicks`(≥0) 全部 required、构造期严格校验，**Dart 内无任何默认 tuning 值**。
- `SpawnEntry`：`entryId` + `enemyId` 均非空、去首尾空白后仍非空、且不含任何空白字符；`entryId` 全量唯一（重复 fail closed）；同一 `enemyId` 可出现在多个入口。
- 生成只来自显式入口：空入口列表 → 永不生成，仅推进 tick。
- reserve 顺序 = 按 `entryId` 字典序的稳定排序，与输入顺序无关；构造时对入口列表做防御性不可修改副本，调用方 list 后续 mutation 不污染 director。
- 生命周期：`pending`(后备) → `warning`(入口预警) → `active`(上场，带攻击宽限) → `removed`(离场，仅 `markExited` 且仅 active 可离场)。
- 补兵：`activeCount <= reinforcementThreshold` 且 `activeCount + warningCount < activeLimit` 且后备非空时，按 reserve 顺序补入至管道满；预警 tick 数大于 0 时先进 warning，等于 0 时直接 active。
- 攻击宽限：单位上场当拍 `remainingGraceTicks = attackGraceTicks`，次拍起逐拍递减；`canAttack` 仅当 `stage == active && remainingGraceTicks == 0`。
- 输出：每拍 `advance()` 返回新 director + 不可变事件列表（`warningStarted` / `entered` / `graceExpired`）；快照列表不可变、按稳定顺序（pending→warning→active→removed，组内 entryId 升序，active/removed 再按 tick 升序）。`markExited` 返回新 director。
- 支持后备耗尽（pending 空则停补，active 可低于上限）与 active 已满（管道满则不补）。

## 验收与验证

- TDD：先写红测（引用未实现类 → 编译红），再实现转绿。
- 命令：`dart format lib/features/battle/domain/phase0a/spawn_director.dart test/features/battle/domain/phase0a/spawn_director_test.dart docs/superpowers/plans/2026-08-23-p2-g2-d01-spawn-director.md`
- 命令：`flutter test --no-pub test/features/battle/domain/phase0a/spawn_director_test.dart`
- 限定 analyze：`flutter analyze lib/features/battle/domain/phase0a/spawn_director.dart test/features/battle/domain/phase0a/spawn_director_test.dart`
- `git diff --check` 通过。
- 普通实现 commit → 追加空 commit `[READY][PI][P2-G2-D01] 完成 SpawnDirector 基础合同`。

## 当前恢复点

- 状态：计划文件已建，尚未写红测。
- 下一步：写红测（构造校验 / 输入顺序无关 / 生命周期 / 补兵 / 后备耗尽 / active 已满 / 不可变 / 确定性）→ 运行确认红 → 实现 → 转绿。
- 已跑验证：无（未开始）。
- 风险：纯领域合同未接生产；API 待 G1 主审确认；后续黑风岭生产纵切在 M2，本批不冒充已完成。
