# P3.1 §12.3 轻功对决 · Phase 1 spec doc

> 日期:2026-05-23 夜 · Mac + Opus 4.7 xhigh · worktree `feat/p3_1_lightfoot`
> 上游:`docs/phase0/p3_1_lightfoot_phase0_2026-05-23.md`(6 维 grep + 4 主轴拍板)
> 下游:Batch 2.1 schema → 2.2 strategy → 2.3 narrative/UI → 2.4 R5 + doc

## TL;DR

P3.1 §12.3 轻功对决全闭环 · **战斗形态 + 5 关 + narrative + UI 入口 + R5 红线**。LightFootStrategy 组合委派 DefaultGroundStrategy(零代码重复 + immutable);BattleState 不动,terrain modifier 烘焙到 BattleCharacter stat;5 关跨 yiLiu/jueDing 2 Tier × water/rooftop/bamboo 3 terrain。**spec 估 ~9.5h opus xhigh,实测预期 ~7-7.5h(0.74×)**。

## 一 · 5 关 unlock 矩阵

| Stage ID | 关名 | Tier·Layer | Terrain | Diff | Reward | Biome (stage 标签) |
|---|---|---|---|---|---|---|
| `stage_light_foot_01` | 水面踏波 | yiLiu·qiMeng | water | 5.0 | EXP 4500 | dock |
| `stage_light_foot_02` | 屋脊追风 | yiLiu·jingTong | rooftop | 5.5 | EXP 5500 | cityWall |
| `stage_light_foot_03` | 竹海听风 | yiLiu·dengFeng | bamboo | 6.0 | EXP 6500 | bambooForest |
| `stage_light_foot_04` | 险崖飞渡 | jueDing·qiMeng | water | 6.2 | EXP 7500 | cliffWaterfall |
| `stage_light_foot_05` | 长风万里 | jueDing·jingTong | rooftop | 6.5 | EXP 9000 | frontier |

**Unlock 链**:`stage_06_05`(Ch6 末 Boss 飞升前)victory → `stage_light_foot_01` unlock(沿 inner_demon `unlock_triggers` 体例;但**轻功对决与心魔解耦** — 心魔走 wuSheng 突破链,轻功是 yiLiu/jueDing 平行支线,**不接管突破链** = `isLayerLocked` 无 lightFoot 路径)。

**Required realm layer**:沿 stages.yaml 现有 `requiredRealmTier/Layer` 字段(主线机制),不新增配置。

## 二 · LightFootStrategy 组合委派架构

```dart
class LightFootStrategy implements BattleStrategy {
  const LightFootStrategy({
    required this.terrainBiome,
    required this.terrainModifiers,
  });
  final TerrainBiome terrainBiome;
  final LightFootTerrainModifiers terrainModifiers;
  static const _delegate = DefaultGroundStrategy();

  @override
  BattleState tick(s, n, {rng}) => _delegate.tick(s, n, rng: rng);

  @override
  BattleState runToEnd(initial, n, {maxTicks = 1000, rng}) {
    final modified = _applyTerrain(initial);
    return _delegate.runToEnd(modified, n, maxTicks: maxTicks, rng: rng);
  }

  @override
  BattleState requestUltimate(s, id, ult) =>
      _delegate.requestUltimate(s, id, ult);

  BattleState _applyTerrain(BattleState s) {
    final m = terrainModifiers.forBiome(terrainBiome);
    return s.copyWith(
      leftTeam: List.unmodifiable(s.leftTeam.map((c) => _bake(c, m)).toList()),
      rightTeam: List.unmodifiable(s.rightTeam.map((c) => _bake(c, m)).toList()),
    );
  }

  BattleCharacter _bake(BattleCharacter c, LightFootModifier m) => c.copyWith(
    criticalRate: (c.criticalRate + m.critDelta).clamp(0.0, 0.95),
    evasionRate: (c.evasionRate + m.evasionDelta).clamp(0.0, 0.95),
    defenseRate: (c.defenseRate + m.defenseDelta).clamp(0.0, 0.95),
  );
}
```

**优点**:① 复用 DefaultGroundStrategy 主循环 478 行 zero 代码重复 ② immutable(terrain bake 在 runToEnd 入口一次,委派接 modified state) ③ memory `feedback_avoid_over_engineer_abstraction`(真痛点 = terrain 入口,不抽象多余 hook)。

**注入点**:`BattleNotifier.startBattle(strategy: LightFootStrategy(...))` — 已支持(`battle_providers.dart:73`)。StageEntryFlow 按 `stage.stageType == StageType.lightFoot` 注入。

## 三 · numbers.yaml `light_foot:` 段草案

```yaml
# =============================================================================
# 轻功对决配置(1.0 P3.1 §12.3,GDD v1.10→v1.11)
# =============================================================================
# 4 主轴拍板:① 5 关 terrain 分布(water/rooftop/bamboo + 2 高阶混)
#           ② terrain modifier ≥15% 单维度有效(memory feedback_balance_buff_singledim_no_effect)
#           ③ 架构=LightFootStrategy 组合委派 DefaultGroundStrategy
#           ④ skill 不新增(YAGNI · stages.yaml enemyTeam[] 用现有 skills)

light_foot:
  terrain_modifiers:                 # 3 terrain × {crit/evasion/defense/damage} delta,双方对等
    water:
      critical_rate_delta: 0.00
      evasion_rate_delta: 0.15       # 水波闪躲
      defense_rate_delta: -0.10      # 滑步难防
      damage_multiplier: 1.00
    rooftop:
      critical_rate_delta: 0.10      # 高处优势
      evasion_rate_delta: 0.00
      defense_rate_delta: -0.05      # 无遮蔽
      damage_multiplier: 1.15        # 瓦上劲风
    bamboo:
      critical_rate_delta: 0.00
      evasion_rate_delta: 0.20       # 竹影遮蔽
      defense_rate_delta: 0.00
      damage_multiplier: 0.90        # 竹挡力卸

  stage_terrain:                     # 5 关 → terrainBiome 映射(LightFootStrategy ctor)
    stage_light_foot_01: water
    stage_light_foot_02: rooftop
    stage_light_foot_03: bamboo
    stage_light_foot_04: water
    stage_light_foot_05: rooftop

  unlock_triggers:                   # 触发关 victory → 下一关 unlock 链(平行支线 · 不接管 wuSheng)
    stage_06_05: stage_light_foot_01
    stage_light_foot_01: stage_light_foot_02
    stage_light_foot_02: stage_light_foot_03
    stage_light_foot_03: stage_light_foot_04
    stage_light_foot_04: stage_light_foot_05
```

## 四 · stages.yaml `stage_light_foot_01..05` 5 entries(略,沿 stage_inner_demon 体例 + `terrainBiome` 字段)

每关 yaml schema:
- `id / chapter='light_foot' / stageType: lightFoot / requiredRealmTier+Layer / difficulty / enemyTeam[3] / dropTable[] / narrative*Id / terrainBiome`
- enemyTeam[3] 沿 mainline 三人组体例(realm 与 player 同 tier,baseHp/baseAttack/baseSpeed 对齐 stages.yaml stage_03_05 等 yiLiu 关数值)
- dropTable[]:轻功对决奖励暂沿 mainline drop pattern(material/equipment 不新增),P3.1.B 子批扩

## 五 · enums.dart 改动

```dart
// StageType +1
enum StageType { mainline, tower, innerDemon, lightFoot }

// 新建 TerrainBiome enum(独立于 EncounterBiome · 进战斗机制)
enum TerrainBiome {
  water,      // 水面(渡口/急流)
  rooftop,    // 屋脊(青瓦/飞檐)
  bamboo,     // 竹林(密竹/江南)
}
```

EncounterBiome **不动**(stage 标签层,rooftop biome 缺但 lightfoot 不需要 — terrainBiome 独立)。

## 六 · UI 入口 + LightFootScreen

- **main_menu.dart** _MenuButton 序:Tower → InnerDemon → **LightFoot**(P2.2 心魔后)
- **LightFootScreen** 沿 `inner_demon_screen.dart:212` reactive 三态:
  - `cleared`:绿勾(MainlineProgress.clearedStageIds 含 stage_light_foot_xx)
  - `available`:主色按钮(unlock_triggers reverse 链查 → 上一关 cleared)
  - `locked`:灰色 + 锁图标(上一关未通)
- **LightFootService** 沿 `inner_demon_service.dart` 但简化 — 无 isLayerLocked(轻功不接管突破链),只判 stage clearance + unlock chain
- **strings.dart** 加 keys:`light_foot.title / locked / available / cleared` + 5 关 stage 标题

## 七 · R5 跨地形红线测计划

`test/redline/p3_1_light_foot_redline_test.dart` 3 测(沿 P2.2 R5 体例 + memory `feedback_red_line_test_semantics`):
- **R5.1** 5 关 × 50 种子分布:玩家 yiLiu/jueDing 满 build vs stage enemyTeam,断言「至少 ≥30/50 玩家胜利」(轻功对决玩家强 build 应主导,与心魔「克己难赢」语义对称)
- **R5.2** terrain modifier cap e2e:water/rooftop/bamboo 三 terrain bake 后 critRate/evasionRate/defenseRate ≤0.95(clamp 校验)+ damage 不破 §5.4 普伤 ≤8000 红线
- **R5.3** unlock 链 e2e:stage_06_05 victory → light_foot_01 unlock + light_foot_01..05 顺序解锁(不接管 wuSheng 突破链 · isLayerLocked 无 lightFoot 路径)

## 八 · Batch 计划(B.1-C.2 5 commit)

| commit | 内容 | 估时 |
|---|---|---|
| 3 (Batch A.3) | schema:enums + numbers.yaml light_foot 段 + 5 stages 占位 + test baseline | ~45min |
| 4 (Batch B.1) | LightFootStrategy + LightFootTerrainModifiers + StageDef terrainBiome + setup 分支 + 5-8 测 | ~1.5-2h |
| 5 (Batch B.2) | chapter_light_foot.yaml + 10 stage narrative ~1.5-2k 字 | ~1-1.5h |
| 6 (Batch B.3) | LightFootScreen + LightFootService + main_menu 入口 + strings + main_menu_test | ~45-60min |
| 7 (Batch C.1) | R5.1-R5.3 3 测 e2e | ~30-45min |
| 8 (Batch C.2) | GDD v1.10→v1.11 + ROADMAP P3.1 final + closeout ≤80 + PROGRESS 顶段 + push | ~45-60min |

## 九 · 不变量沿用

- GDD §5.4 数值红线**完全不动**(terrain modifier 走 BattleCharacter clamp + R5.2 校验)
- GDD §5.3 三系锁死**完全不动**(轻功对决不引入新装备/心法阶)
- GDD §6 核心公式**完全不动**(terrain modifier 烘焙到 BattleCharacter stat → 公式自动吸收)
- Ch1-Ch6 主线 + Demo 49 层 EXP 自动升层路径**完全不变**(轻功对决独立支线 / isLayerLocked 无 lightFoot 路径)
- Riverpod 3.x / Isar / 不引第三方游戏引擎
- CLAUDE.md v1.9 Mac+Opus 单端全权(GDD/ROADMAP/numbers/data 顶部变更摘要明文)
- doc 体量(memory `feedback_doc_inflation_overnight`):本 spec ~140 行 ≤150 ✓ / closeout ≤80 / handoff ≤50

## 十 · GDD v1.10 → v1.11 变更摘要(本 commit 起草 + 全收尾时升级行状态)

§12.3「轻功对决」行从纯 1.0 P3.1 占位升「**1.0 P3.1 Phase 1 spec 拍板**」(沿 v1.8 心魔体例)。Batch 2.1-2.4 全收尾时再升「Batch 2.1-2.4 全收尾 ✅」。
