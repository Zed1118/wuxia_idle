# 战斗角色快照 seam 深化计划

> 日期：2026-08-20
> 分支：`codex/stage-snapshot-seam-0820`
> 状态：READY
> 上位：路线 C 共享层/headless 前置排程；`docs/sessions/NEXT.md` P1.1

## 目标

把 `StageBattleSetup` 中可长期复用的角色/敌人开战快照职责从旧 3v3 orchestration 中抽出，使 Phase 0A 不再直接依赖待退役的 `StageBattleSetup`。不改数值、公式、三系锁死、内容 YAML 或玩家可见行为。

## 架构判断

- 当前 `StageBattleSetup` 是有 Depth 的深 Module，但 seam 错绑旧 3v3：阵容选择、Isar/autoFill 写回、玩家派生、敌人周目/Boss 派生、主线/塔/心魔 orchestration 混在一个 interface。
- 删除测试：直接删除会把复杂度散回主线、塔、扫荡、远征、断魂庄与 Phase 0A；因此不能机械拆 helper。
- 第一条真实 seam 是 player roster selection：active roster 允许 occupancy filter + seed fallback；exact IDs 必须严格保序、缺失即失败、绝不 fallback。
- 第二条 seam 是敌方快照深 Module：隐藏周目/塔/境界推进/首通可读等 implementation；旧 3v3 与 Phase 0A 是两个真实 Adapter。

## 切片

1. [x] 红测 exact IDs 为空、重复或缺失时 fail-fast，证明现有静默换人问题。
2. [x] 将 player interface 分为 `buildActivePlayerTeam` 与 `buildExactPlayerTeam`；兼容旧入口委托，显式 IDs 走 strict。
3. [x] 提取敌方快照 module，旧 `StageBattleSetup.buildEnemyTeam` 保持兼容委托，旧 3 人 cap 不进入可复用 seam。
4. [x] Phase 0A mapper/host 改走新 module；源码删除 Gate 禁止直接 import/引用 `StageBattleSetup`。
5. [x] targeted + analyze + 全量；更新 NEXT/PROGRESS。

## 验收（CLAUDE §8.2）

- [x] 生产接线：Phase 0A 无 `StageBattleSetup` 直接依赖；旧主线/塔/扫荡行为不变。
- [x] Targeted：selection、enemy parity、Phase 0A Ch1 五关、远征/断魂庄 exact roster。
- [x] 红线：零 YAML/公式/数值调整；旧 3 人 cap 不污染 Phase 0A。
- [x] 残留风险：`BattleCharacter` 类型本身仍属旧 battle domain，后续再迁 engine-neutral `CombatantSnapshot`。

## 当前恢复点

- 最后完成：`EnemyBattleCharacterAssembler`/`PlayerBattleCharacterAssembler` 两个深 Module 落地；旧 StageBattleSetup 降为 orchestration + legacy Adapter；0A、远征、断魂庄走新 seam；源码 Gate 禁旧 interface。
- 下一步：打 `[READY]` 恢复点并走合并 Gate；合并态复跑 analyze、关键 targeted 与文档扫描。
- 已跑验证：targeted 全绿；`flutter analyze` 0 issue；最终全量 **5213 pass / 0 fail**。
- 阻塞：无。
