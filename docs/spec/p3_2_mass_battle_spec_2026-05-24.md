# P3.2 §12.3 群战守城 spec

> 日期:2026-05-24 / 模型:Mac + Opus 4.7 xhigh
> 上游 Phase 0:`docs/phase0/p3_2_mass_battle_phase0_2026-05-24.md`
> 沿例:`docs/spec/p3_1_lightfoot_spec_2026-05-23.md`(P3.1 9 节体例)

---

## 0. 4 题决议(用户拍板)

| Q | 选项 | 决议 |
|---|---|---|
| Q1 阵营规模 | **C** 玩家 3 + 敌方 5-7 | 沿 inner_demon `buildMirrorEnemyTeam` 体例 · UI 0 改 · `rightTeam.length` 动态 5-7 · 「以少胜多」武侠战略感 |
| Q2 玩家决策点 | **d** 战前选阵型 + wave-based 守城 | 阵型 3 选 1 烘焙 stat / wave 2-4 波渐强 / 中场无操作 契 §5.5 |
| Q3 策略归一 | **A** 1 strategy MassBattleStrategy 通用 | wave_count=1 单场群战 / wave_count=N 守城 |
| Q4 AI 协作 | **i** 不扩协作 · 沿现状 battle_ai 单角色 | YAGNI · P3.3+ 再决策 |

## 1. 范围

- **战斗形态**:`MassBattleStrategy implements BattleStrategy` 组合委派 `DefaultGroundStrategy._calculateInBattle`(零代码重复 · 沿 LightFoot 体例)
- **核心机制**:① wave-based 守城(玩家 HP/IF 跨 wave **保留**不重置 / actionPoint wave 间重置 / 敌方每 wave 全新生成)② 阵型 3 选 1 战前烘焙 BattleCharacter stat 修正(idempotent)
- **5 关 yiLiu 3 + jueDing 2 跨 tier**(沿 LightFoot 5 关体例) · diff 6.5-8.5 · 平行支线**不接管 wuSheng 突破链**
- **范围 OUT**:援军召唤 / SquadAI 协作 / siege 限时活动 / wave 间补给 UI 等 YAGNI 项

## 2. schema 改动

```dart
// lib/core/domain/enums.dart
enum StageType {
  mainline, tower, innerDemon, lightFoot,
  massBattle,  // 新增 · 1.0 P3.2 §12.3 群战守城
}

enum Formation {  // 新增 · 阵型 3 选 1
  yanXing,    // 雁行:crit +0.10 / defense -0.05(攻势)
  baGua,      // 八卦:defense +0.10 / evasion +0.05(守势)
  fengShi,    // 锋矢:damage +0.10 / crit +0.05(突击)
}
```

```dart
// lib/core/domain/stage_def.dart(扩 StageDef)
final int? massBattleWaveCount;        // null = 非 mass · 1-4 wave
final List<int>? massBattleEnemyCounts; // 每 wave 敌人数 [5,6] or [5,6,7]
```

```yaml
# data/numbers.yaml(尾部加 mass_battle 段,沿 inner_demon/light_foot 体例)
mass_battle:
  formations:
    yanXing:  { critRateBonus: 0.10, defenseRateDelta: -0.05 }
    baGua:    { defenseRateDelta: 0.10, evasionRateBonus: 0.05 }
    fengShi:  { damageMultiplier: 1.10, critRateBonus: 0.05 }
  wave_intermission:
    reset_action_point: true          # wave 间 actionPoint 归 0
    preserve_hp: true                  # wave 间 HP 保留(不回血)
    preserve_internal_force: true      # wave 间内力保留(限大招使用)
    preserve_cooldowns: false          # wave 间 cd 重置(给玩家大招机会)
  stage_formations:    # 每关默认阵型(玩家未选时 fallback)
    stage_mass_battle_01: yanXing
    # ...01..05
  unlock_triggers:
    stage_mass_battle_01: stage_06_05  # 沿 LightFoot 平行支线挂 Demo Ch6 后
    stage_mass_battle_02: stage_mass_battle_01
    # ...03/04/05
```

## 3. MassBattleStrategy 设计(~140 行 · `lib/features/battle/domain/strategy/mass_battle_strategy.dart`)

- **ctor 注入**:`formation` / `waveCount` / `enemyTeamsPerWave: List<List<BattleCharacter>>`(预生成各 wave)
- **组合委派**:持 `DefaultGroundStrategy _ground` · `runToEnd` 入口先 `applyFormationTo` 烘焙玩家 stat,再 for wave in 0..waveCount:`state.copyWith(rightTeam: enemyTeamsPerWave[w])` → `_ground.runToEnd(state)` → 若 leftDead → rightWin / 否则 `_intermission(state)` 重置 actionPoint=0 + cd=0 但 **保留 HP/IF** → 下一 wave;全 wave 通过 → leftWin
- **`applyFormationTo` idempotent**(沿 LightFoot `applyTerrainTo` 体例):烘焙 `Formation` 对应 modifier 到 leftTeam BattleCharacter 的 critRate/defenseRate/evasionRate/attackPowerMultiplier · clamp [0.0, 0.95] 防破红线 · 仅玩家(阵型不沾敌方)

## 4. 5 关设计

| stage_id | tier | wave_count | enemy_counts | diff | 主题 |
|---|---|---|---|---|---|
| stage_mass_battle_01 | yiLiu·qiMeng | 2 | [5, 5] | 6.5 | 守村:山贼围攻 |
| stage_mass_battle_02 | yiLiu·jingTong | 3 | [5, 6, 6] | 7.0 | 守镇:江湖匪众 |
| stage_mass_battle_03 | yiLiu·dengFeng | 3 | [6, 6, 7] | 7.5 | 守县:他派偷袭 |
| stage_mass_battle_04 | jueDing·qiMeng | 4 | [5, 6, 6, 7] | 8.0 | 守关:边镇胡骑 |
| stage_mass_battle_05 | jueDing·jingTong | 4 | [6, 6, 7, 7] | 8.5 | 守城:西凉残部 |

> **数值校验**:R5.1 5 关 × 50 种子玩家 leftWins 预期 ≥30/50(>=60%) · draws ≤15 · §5.4 红线压测

## 5. UI 入口 + 阵型选择

- `lib/features/mass_battle/` 三层(application/domain/presentation)沿 light_foot 模板
- `MassBattleScreen` 三态(cleared/available/locked)· 沿 LightFootScreen
- **阵型选择 dialog**:进入 stage 前弹 3 选 1(雁行/八卦/锋矢 · 显本关默认 + 玩家选定)→ 注入 MassBattleStrategy ctor
- `main_menu` 入口插 LightFoot 后、Leaderboard 前:Tower → InnerDemon → LightFoot → **MassBattle** → Leaderboard
- `UiStrings.mainMenuMassBattle` / `Hint` + `main_menu_test` 13→14

## 6. narrative ~2.2k 字(沿 LightFoot ~2.1k)

`chapter_mass_battle` 章首尾(无名守城术 5 处试炼 · Tier yiLiu「沉着/肃杀/老练」+ jueDing「沉静/从容」沿 LightFoot 风格梯度词)+ 10 stage opening/victory(守村/镇/县/关/城)· 第二人称「你」(stage) + 第三人称「李寒」(chapter)· 黑名单同 Ch4-6 沿用。

## 7. 测试

- **R6 阵型烘焙 4 测**:yanXing crit / baGua def / fengShi dmg / 仅玩家烘焙
- **R5.1** 5 关 × 50 种子 leftWins ≥30/50 + draws ≤15
- **R5.2** wave 间 4 测:actionPoint reset / HP preserve / IF preserve / cd reset
- **R5.3** §5.4 红线 + clamp ≤0.95
- **R5.4** unlock 链 e2e stage_06_05 → mass_battle_01..05
- **预期 baseline 1242 → ~1260 pass**(+15-20)

## 8. Batch 拆解(估时 ~6-7h opus xhigh)

| Batch | 内容 | 估时 |
|---|---|---|
| 2.1 schema | StageType +massBattle / Formation enum / StageDef 字段 / numbers.yaml mass_battle 段 / repo 解析 | ~45min |
| 2.2 strategy | MassBattleStrategy 实装(runToEnd wave 循环 + applyFormationTo idempotent + _intermission) + 委派 DefaultGround | ~1.5h |
| 2.3 stages + service | stages.yaml stage_mass_battle_01..05 + MassBattleService.statusOf + 阵型选择 dialog 注入 ctor | ~1h |
| 2.4 narrative + UI | chapter + 10 stage o/v + MassBattleScreen + main_menu 入口 + UiStrings | ~1.5h |
| 2.5 R5/R6 + doc | R5/R6 4 测族 + closeout + GDD v1.13 + ROADMAP P3.2 段实装详条 + PROGRESS 顶段 | ~1h |

## 9. 不变量沿用

- **GDD §5.4 红线完全不动** · §5.3 三系锁死 · §5.5 在线 = 离线(wave 间 actionPoint reset 走 tick · 无快进)· §5.1 反留存(不做每日守城)
- **Ch1-Ch6 主线 + Demo 49 层 + 心魔 7 关 wuSheng 突破链 + LightFoot 5 关完全不变**(massBattle 独立平行支线 · `isLayerLocked` 无 massBattle 路径)
- **BattleStrategy 接口 3 method 不动**(组合委派 + 烘焙 sticky 体例)
- **doc 体量**:closeout ≤80 · handoff ≤50 · 本 spec ≤150 · PROGRESS 净增长 ≤ 0(顶段加 = 旧段砍)

---

**P3.2 spec 收口**:沿 LightFoot 体例 + 4 题决议明确 + Batch 2.1-2.5 拆解 + 估时 6-7h xhigh · 起 worktree `feat/p3_2_mass_battle` 或主 cwd 推进待用户拍板
