# P3.1 §12.3 轻功对决 · Phase 0 reality check

> 日期:2026-05-23 夜 · Mac + Opus 4.7 xhigh · worktree `feat/p3_1_lightfoot`(8h overnight)
> 上游:1.0 P2.2 §12.1 心魔系统全收尾 HEAD `613a072` · 1220 pass / 0 analyze
> 下游:Phase 1 spec doc(本 doc 4 主轴拍板入 spec 起手)

## TL;DR

P3.1 codebase 0 引用 greenfield。**BattleStrategy plug-in 路径全 ready**(`BattleNotifier.startBattle(strategy:)` 已接注入参数)+ `EncounterBiome` 已有 `dock/bambooForest/cliffWaterfall/frontier`(轻功 5 关 4 关复用)。**4 主轴自主拍板沿 fallback 清单**,无 schema 歧义,Phase 1 spec 起草即可推进。

## 6 维 reality check 结果

| D | 维度 | 现状(file:line)| 扩展点 |
|---|---|---|---|
| D1 | BattleStrategy 抽象 | `lib/features/battle/domain/strategy/battle_strategy.dart:23-55` 3 method(tick/runToEnd/requestUltimate)粗粒度足够,P0.2 重构时已留 LightFootStrategy hook 注释(7-14) | LightFootStrategy implements BattleStrategy,组合委派 DefaultGroundStrategy |
| D2 | DefaultGroundStrategy 模板 | `lib/features/battle/domain/strategy/default_ground_strategy.dart` 478 行,immutable 纯函数,_resolveAction 内 _calculateInBattle 是公式入口 | LightFootStrategy 复用 ~85%,差异点是 runToEnd 入口应用 terrain modifier 到双方 BattleCharacter stat |
| D3 | stage_battle_setup.dart 分支 | `lib/features/battle/application/stage_battle_setup.dart:44-50` innerDemon 分支(buildMirrorEnemyTeam 镜像);buildEnemyTeam(70 `i < 3`)从 stages.yaml enemyTeam[] | 加 lightFoot 分支 = **不**走 mirror,**沿** buildEnemyTeam(stages.yaml enemyTeam[]),无需新装配函数 |
| D4 | BattleState 容器 | `lib/features/battle/domain/battle_state.dart` `leftTeam/rightTeam` 任意长(实际 3v3),`BattleResult` 三态(leftWin/rightWin/draw) | **无需扩 BattleState 字段** — terrain modifier 直接烘焙到 BattleCharacter stat(critRate/evasionRate/defenseRate)即生效现有公式 |
| D5 | numbers.yaml 顶级段 | `data/numbers.yaml` 1346 行;`combat:39 / retreat:825 / inner_demon:1289`;末尾 1344 行后 | `light_foot:` 段插 1344 前(沿 inner_demon 体例),~40-50 行(3 terrain × 3 modifier + lightfoot_skill_boost) |
| D6 | stages.yaml 体例 | `data/stages.yaml` 2015 行;`stage_inner_demon_01:1898 / _07:2000` 7 关心魔 + Ch5 13 文件 stage_05_01..05 | `stage_light_foot_01..05` 5 entries 插 inner_demon 后(2010+);沿 inner_demon entry 体例 + 加 `terrainBiome:` 字段 |
| D7 | enums.dart | `lib/core/domain/enums.dart` `StageType:157`(mainline/tower/innerDemon 3 项)/ `EncounterBiome:213`(18 项,**dock/bambooForest/cliffWaterfall/frontier 已有 4 项可复用,rooftop 缺**) | StageType +1 `lightFoot` / **新建 TerrainBiome enum**(water/rooftop/bamboo/mixed)独立于 EncounterBiome — 后者继续做 stage 标签,前者进战斗机制 |
| D8 | BattleStrategy 注入位 | `lib/core/application/battle_providers.dart:58/75` `BattleNotifier.startBattle(strategy: ...)` 已支持注入 + 默认 fallback DefaultGroundStrategy | StageEntryFlow / TowerEntryFlow 调 startBattle 时按 stage.stageType 注入 LightFootStrategy 实例(constructor 接 terrainBiome + numbers.lightFoot) |

## 4 主轴自主拍板

按 memory `feedback_user_offline_autonomous` 用户离线自主拍板 + plan 自主决策清单对齐:

1. **5 关 terrain 分布 + Tier 跨度**:
   - stage_light_foot_01 水面踏波 · yiLiu·qiMeng · terrainBiome=water · diff=5.0
   - stage_light_foot_02 屋脊追风 · yiLiu·jingTong · terrainBiome=rooftop · diff=5.5
   - stage_light_foot_03 竹海听风 · yiLiu·dengFeng · terrainBiome=bamboo · diff=6.0
   - stage_light_foot_04 险崖飞渡 · jueDing·qiMeng · terrainBiome=water · diff=6.2(高阶 water)
   - stage_light_foot_05 长风万里 · jueDing·jingTong · terrainBiome=rooftop · diff=6.5(高阶 rooftop)
   - 理由:yiLiu 3 关走齐 3 terrain(water/rooftop/bamboo),jueDing 2 关重水/屋脊高阶版,bamboo 不上 jueDing(GDD §12.3 三 terrain 全覆盖即可,不强求 5 terrain 5 关一一对应)

2. **terrain modifier 数值范围**(沿 memory `feedback_balance_buff_singledim_no_effect` ≥15%):
   - water(水面): evasionRate +0.15 / defenseRate -0.10(滑步难防 + 水波闪躲)
   - rooftop(屋脊): criticalRate +0.10 / damage_multiplier 1.15 / defenseRate -0.05(高处优势)
   - bamboo(竹林): evasionRate +0.20 / speed +10% / damage_multiplier 0.90(竹影遮蔽 + 卸力)
   - 双方对等生效(地形是中立的),clamp(0.0, 0.95)防破界

3. **架构方案 — LightFootStrategy 组合委派**(不继承不复制):
   - LightFootStrategy implements BattleStrategy + 内部持 `const DefaultGroundStrategy _delegate`
   - runToEnd 入口应用 terrain modifier 烘焙 BattleCharacter stat → 委派 _delegate.runToEnd
   - tick / requestUltimate 直接委派,无差异
   - 优点:复用 _delegate 主循环 + immutable + 零代码重复;**memory `feedback_avoid_over_engineer_abstraction` 体例符合(真痛点 = terrain modifier 入口,不抽象多余 hook)**
   - terrain modifier 在 startBattle 后只应用一次(idempotent by ctor)

4. **UI 入口位置 + skill 是否新增**:
   - main_menu 入口序:Tower → InnerDemon → **LightFoot**(P2.2 心魔后,沿战斗形态扩展序)
   - LightFootScreen 沿 inner_demon_screen reactive 三态 cleared/available/locked
   - 轻功 skill 暂**不新增 skills.yaml**(YAGNI)— stages.yaml enemyTeam[] 引用现有 skill,P3.1.B 子批可补轻功专属招式(留挂账)

## 调整记录(本批 0 项)

5 关 / terrain / 架构方案与 plan 自主决策清单**完全对齐**,无调整。

## 入 Phase 1 spec 起手

- spec doc `docs/spec/p3_1_lightfoot_spec_2026-05-23.md` ~130 行
- 5 关 unlock 矩阵 + terrain × Tier 表
- LightFootStrategy 实装草案 + numbers.yaml light_foot 段草案
- GDD v1.10 → v1.11 §12.3 轻功对决展开 + §6.7 terrain modifier 新节
- 1 commit:`docs(p3.1 轻功): Phase 0 reality check + 4 主轴自主拍板`
