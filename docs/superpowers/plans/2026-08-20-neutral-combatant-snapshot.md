# Engine-neutral CombatantSnapshot 迁移计划

> 日期：2026-08-20
> 分支：`codex/combatant-snapshot-neutral-0820`
> 状态：READY
> 上位：路线 C 前置排程；内容迁移 ADR D1/D3/D4；前批 snapshot seam 深化

## 目标

建立不可变、引擎无关的 `CombatantSnapshot` Interface，让开战装配结果不再以旧 3v3 `BattleCharacter` 作为公共类型。旧 3v3 与 Phase 0A 各自通过 Adapter 消费；Phase 0A application/presentation 生产链禁止回引 `battle_state.dart`、`BattleCharacter`。不改数值、公式、YAML、三系锁死和玩家可见行为。

## 架构判断

- `BattleCharacter` 同时承载已装配领域快照与旧 3v3 运行态，Interface 泄漏 `teamSide/slotIndex/actionPoint/cooldowns/charging/stagger/bossPhaseIndex` 等 implementation，使 Phase 0A 被旧槽位约束污染。
- 新 `CombatantSnapshot` 只保留开战前稳定事实：身份/展示、境界流派、HP/Qi/内力、派生攻防、技能与熟练度、稳定装备/Boss 机制配置；不包含队伍槽位与战中动态状态。
- `Legacy3v3CombatantAdapter` 注入 team/slot 与旧运行态默认；`Phase0aCombatantInput` 直接持有 neutral snapshot。两个 Adapter 令 seam 真实。
- deletion test：删除 neutral snapshot 后，字段转换与 fail-fast 会重新散回 mapper/factory/visual/settlement/legacy orchestration；因此该 Module 有 Depth、Leverage 与 Locality。

## Interface 红线

- neutral 禁止：`teamSide`、`slotIndex`、`actionPoint`、`isAlive`、`internalInjury`、`chargingSkill`、`chargeTicksRemaining`、`staggerTicksRemaining`、`staggerDefenseDownOverride`、`bossPhaseIndex`、`coopStrikeUsedInCharge`、`coopStrikeConsumedAtTick`。
- 旧 `skillCooldowns` 仅以开战配置语义 `openingSkillCooldowns` 进入 neutral；旧 Adapter 再投影回运行态初值。
- `Legacy3v3CombatantAdapter.toSnapshot` 只接受尚未进入战中的初始 `BattleCharacter`；发现动态状态或 multiplier source 已写入时 fail-fast，禁止静默丢字段。
- 集合全部防御性不可变；Phase 0A actor id 继续由调用方显式给出，不能从 character id 猜测。

## 切片

1. [x] 红测 neutral immutable/interface 与 legacy round-trip parity。
2. [x] 新增 `CombatantSnapshot` 与 `Legacy3v3CombatantAdapter`。
3. [x] 玩家/敌方 assembler 公共 Interface 改为 neutral；旧主线/塔/远征/断魂庄经 legacy Adapter 回旧引擎。
4. [x] Phase 0A factory/mapper/visual/settlement/host/debug fixture 改直接消费 neutral。
5. [x] source-contract 反转：Phase 0A 禁 `BattleCharacter`、`battle_state.dart` 与 legacy Adapter。
6. [x] targeted + analyze + 全量；更新 NEXT/PROGRESS/BACKLOG，打 READY 并合入干净 main。

## 验收

- 旧 3v3：队伍顺序、slot、数值、技能、Boss 机制与结算不变。
- Phase 0A：Ch1 五关、live/headless、视觉 roster、真实结算同 seed 结果不变；任意敌人数不继承 3 人 cap。
- 动态机制：吸血/护法/脆弱/活跃踉跄构造期 fail-fast 继续成立。
- 删除 Gate：Phase 0A 生产目录零 `BattleCharacter`/`battle_state.dart`；neutral schema 零旧运行态字段。
- 工程：format、analyze、targeted、全量与 dead-link 基线全部通过。

## 当前恢复点

- 最后完成：neutral Module/legacy Adapter、assembler 公共 Interface、Phase 0A/旧引擎双 Adapter 接线及删除 Gate；analyze 0，相关 targeted 410/410，cycle/synergy/orchestration 153/153，最终全量 **5219 pass / 0 fail**。
- 下一步：完成文档扫描后打 `[READY]` 恢复点，合并态复验并清理 worktree。
- 阻塞：无。
