# P3.2 §12.3 群战守城 Phase 0 reality check

> 日期:2026-05-24 / 模型:Mac + Opus 4.7 xhigh
> 上游:`docs/ROADMAP_1_0.md:153-156` P3.2 段 / GDD.md:650 §12.3「群战 / 守城战」
> 沿例:`docs/phase0/p3_1_lightfoot_phase0_2026-05-23.md`(P3.1 6 维 grep 体例)

---

## TL;DR

`MassBattleStrategy` **完全 greenfield**(注释里 2 处占位,无 enum / 无 yaml / 无 test)。战斗 strategy 层 NvN-ready(`BattleState.leftTeam/rightTeam` 是 `List<BattleCharacter>` 不固定 3),邻近目录 `light_foot/`+`inner_demon/` 三层模板成熟,挂新 strategy 沿 LightFoot 体例 1 文件 ~120 行搞定。**真痛点 2 处**:① UI 层 `battle_screen.dart` 硬码 3 槽位(`for (var i = 0; i < 3; i++)` 2 处 + `slotKey = teamSide * 3 + slotIndex` + 6 个 attackController);② design question 未决(规模 / 玩家 build 决策点 / 群战 vs 守城归一 / AI 协作接口范围)→ 4 题需用户先拍板。

## 6 维 grep 结论

| 维度 | grep 结果 | 实装含义 |
|---|---|---|
| **① schema** | `MassBattleStrategy` 仅注释 2 处(`battle_strategy.dart:13` + `battle_providers.dart:56`)· 0 enum / 0 yaml 段 / 0 占位字段 | 完全 greenfield · 沿 LightFoot 加 `StageType.massBattle` + `numbers.yaml mass_battle` 段 |
| **② strategy 注入** | `startBattle(strategy: ...)` 已 ready(`battle_providers.dart:73`)· `BattleEngine` 委派 BattleStrategy 接口(`battle_engine.dart:24`) | 注入位 0 改 · 沿 LightFootStrategy implements BattleStrategy 体例直接挂 |
| **③ 邻近目录** | `lib/features/light_foot/` + `lib/features/inner_demon/` 三层(application/domain/presentation)成熟 | P3.2 建 `lib/features/mass_battle/` 同模板 + `MassBattleService.statusOf` + UI 三态 |
| **④ UI 入口** | main_menu 顺序 Mainline→Tower→**InnerDemon→LightFoot**→Leaderboard→Seclusion(`main_menu.dart:139-180`) | P3.2 入口插在 LightFoot 后、Leaderboard 前(P3.x 战斗形态分组) |
| **⑤ 红线 test** | `mass / siege / 群战 / 守城` test 0 命中 | 完全 greenfield · R5 跨 strategy 红线测自起 |
| **⑥ 3v3 硬码** | **数据层 ✅ NvN-ready**(`BattleState.leftTeam/rightTeam: List<BattleCharacter>` 不固定 3)· **UI 层 ❌ 硬码 3 处**(`battle_screen.dart:637/750 for i<3` + `_slotKey:292 teamSide*3` + 6 attackController · `battle_screen.dart:76`)· `inner_demon_service.dart:90 i < playerTeam.length && i < 3` mirror cap=3 | strategy + state 0 改 · **真痛点 = UI 槽位扩 N 或语义复用 3 槽** |

## 沿例参考(P3.1 LightFoot 体例锚点)

- `LightFootStrategy implements BattleStrategy` 组合委派 `DefaultGroundStrategy._calculateInBattle`(零代码重复 · `light_foot_strategy.dart` 123 行)
- `applyTerrainTo` 入口烘焙地形 modifier 到 BattleCharacter view layer(stat 烘焙 vs 战中实时计算)· 沿例 P3.2 群战可烘焙「阵型 / 守城 buff / 援军 stat」到 BattleCharacter
- 5 关 `stage_light_foot_01..05` yiLiu/jueDing 2 Tier × 3 terrain · 平行支线**不接管 wuSheng 突破链** · `isLayerLocked` 无 lightFoot 路径
- `numbers.yaml light_foot` 段 45 行 · `StageDef.terrainBiome` schema 字段 · `LightFootService.statusOf` 三态 reactive

## 4 个 design question(待用户拍板)

**Q1 阵营规模**:
- (A) 玩家 3 + 4 援军 vs 8 敌(沿 player 3 槽 + 队伍扩 AI 援军)
- (B) 双方都扩 5v5(改 UI 5 槽位)
- (C) **不动 player 3 + 敌方扩 5-7**(玩家保持 3,敌方多波次,沿 inner_demon mirror 体例)← **推荐**(改动最小 + 战略感「以少胜多」契合武侠语境)

**Q2 玩家 build 决策点**(扩展协作接口的核心):
- (a) 战前布阵(站位 / 阵型选择,如雁行 / 八卦 / 守势)
- (b) 战中召唤援军(限 1-2 次 / 关 · 援军走 NPC AI)
- (c) wave-based 守城(N 波敌人渐强,玩家中场无操作)
- (d) **组合 a+c**(战前选阵型 + wave-based 守城)← **推荐**(给玩家一次有意义决策 + 长线挂机不需中场操作 = 契合 §5.5 在线 = 离线)

**Q3 群战 vs 守城策略归一**:
- (A) 1 strategy `MassBattleStrategy` 通用群战 + 守城(wave 配置层切换)← **推荐**(YAGNI · 不抽多余 hook)
- (B) 2 strategy 分别 MassBattle / Siege(代码层分裂)

**Q4 AI 协作接口范围**:
- (i) 不扩协作 · NPC 各自决策(沿 `battle_ai.dart` 单角色)← **推荐**(P0 注释「可能扩」是 P3.3+ 决策,YAGNI)
- (ii) 扩 SquadAI 协作层(focus fire / 保护后排 / 联手大招)

## 关键不变量(P3.2 实装必守)

- **GDD §5.4 红线完全不动**:普伤 ≤8,000 / 玩家血 ≤20,000 / 内力 ≤15,000 / 装备攻击 ≤2,000 单件
- **GDD §5.3 三系锁死**:守城战可能给玩家高阶援军(NPC zongShi/wuSheng),但**玩家自身境界 ↔ 装备 ↔ 心法**仍锁死
- **GDD §5.5 在线 = 离线**:wave-based 守城不允许「在线加速」/「快进券」· wave 间隔走 tick(同 actionPoint)
- **§5.1 反留存焦虑**:不做「每日守城」/「限时活动」 · 群战是关卡型(可重玩 · 沿 mainline/lightFoot/innerDemon)
- **平行支线**:不接管 wuSheng 突破链 · `isLayerLocked` 无 massBattle 路径 · unlock 沿 stage_06_05 后挂 mass_battle_01..0X 链(类比 LightFoot)

## 估时锚点(spec 起步前预估)

- Phase 0(本)~30min ✅
- Phase 1 spec doc ~30-45min(≤150 行 · 4 题拍板后 Batch 拆解 · 沿 LightFoot spec 9 节体例)
- Phase 2 实装 ~5-7h opus xhigh(按 4 题决议 · LightFoot 实测 5h xhigh / spec 估 9.5h 精度 0.53× · memory `feedback_opus_xhigh_interactive_duration`)

## 下一步

读完本 doc → 用户回答 Q1-Q4(可全选推荐方案或单题改)→ 起 spec(`docs/spec/p3_2_mass_battle_spec_2026-05-24.md` ≤150 行)→ Batch 拆解 → 起 worktree `feat/p3_2_mass_battle` 或主 cwd 推进。

---

**Phase 0 收口**:greenfield 战斗形态 P3.x 第 2 条(LightFoot 后)· 沿例成熟 · 真痛点 UI 3 槽硬码 · 4 题待拍板 · 估时 5-7h xhigh
