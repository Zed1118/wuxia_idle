# P2.3 §7.1 飞升 + 遗物 transfer spec

> 日期:2026-05-24 / 模型:Mac + Opus 4.7 xhigh
> 上游 Phase 0:对话内六维 grep(无独立 phase0 doc · 现状 70%+ 就绪)
> 沿例:`docs/spec/p3_2_mass_battle_spec_2026-05-24.md`(9 节体例)

---

## 0. 4 题决议(用户拍板:方向 B + Q1a/Q2c/Q3b/Q4d)

| Q | 选项 | 决议 |
|---|---|---|
| Q1 飞升后玩家状态 | **a** `isFounder=true` + `isActive=false` 出阵(隐居)| 不加 `isAscended` 字段 · 复用现字段语义(已飞升 = founder 但 !active) |
| Q2 大弟子身份 | **c** `lineageRole` 不变 · UI 显「现任掌门」 | 不真切 founder · P5+ 师徒升级再决策真传位 |
| Q3 选件 UI | **b** 玩家手动勾选 1-2 件 | `multi_disciple_allocation=player_pick` 4 字段真消费 · GDD §7.1 player_pick 语义 |
| Q4 触发条件 | **d** `stage_inner_demon_07` cleared **+** wuSheng·dengFeng **+** `stage_06_05` cleared | 3 条件并存 · 任一未满足 → 入口 locked |

## 1. 范围

- **核心 deliverable**:① `AscendService`(eligibility + multi-disciple allocation + batch heritage transfer + founder buff trigger 切换)② `AscensionScreen`(仪式 + 选件 + 多徒弟分配)③ `founder_buff_service` trigger 改判(0 代码改 · 复用 isActive=false 自动 inactive · 仅更新注释)④ R5 红线 5 族测
- **配套**:numbers.yaml 4 规则字段 lib 端真消费(`transfer_trigger` / `multi_disciple_allocation` / `stack_across_generations` / `conflict_slot_resolution`)+ `LineagePanelScreen` 加飞升入口按钮
- **范围 OUT**:多代飞升(`stack_across_generations=false` 锚 Demo 仅一代)/ `conflict_slot_resolution=auto_swap` 实装(大弟子尚未装备同 slot,YAGNI)/ P5+ 真传位(大弟子接管 founder 身份)/ AscensionCutscene 动画 / inner_demon_07 + mainline_06_05 victory 自动触发(用户手动节奏)

## 2. schema 改动

- **Character**:0 改(复用 `isFounder` + `isActive` + `lineageRole` + `discipleIds`)
- **Equipment**:0 改(复用 `isLineageHeritage` + `previousOwnerCharacterIds` + `inheritFrom`)
- **NumbersConfig**:扩 `HeritageItems` 4 字段解析(yaml 已落,lib 端补消费)

```dart
// lib/data/numbers_config.dart(HeritageItems 扩 4 字段)
class HeritageItems {
  // 已有 4 字段:piecesPerGenerationMin/Max / autoBuffInternalForceMax / resonanceRetention
  // 新增 4 字段:
  final String transferTrigger;           // "ascend_to_wusheng"
  final String multiDiscipleAllocation;   // "player_pick"
  final bool stackAcrossGenerations;      // false
  final String conflictSlotResolution;    // "auto_swap"
}
```

```yaml
# data/numbers.yaml(尾部加 ascension 段 · 类比 inner_demon/light_foot unlock_triggers)
ascension:
  unlock_triggers:
    cleared_stages: [stage_inner_demon_07, stage_06_05]   # 双拦截
    required_realm: { tier: wuSheng, layer: dengFeng }    # 境界拦截
```

## 3. AscendService 设计(~120 行 · `lib/features/ascension/application/ascend_service.dart`)

- **ctor 注入**:`Isar isar` + `NumbersConfig n`
- **`computeEligibility()`** → `AscensionEligibility`(`canAscend` + 4 子条件 bool · `inActiveCharacters` / `realmAtPeak` / `innerDemon07Cleared` / `mainline0605Cleared`)
  - founder isActive 在 `SaveData.activeCharacterIds` && realm=wuSheng·dengFeng && `clearedStageIds` 含 2 关
- **`listHeritageCandidates(founderId)`** → `List<Equipment>` 玩家 founder 全部装备(allow 任选,不预过滤 `isLineageHeritage`)
- **`listDiscipleTargets()`** → `List<Character>` active 中 lineageRole=disciple 且 isAlive=true 的徒弟
- **`performAscend(selections: Map<int, int>)`** — 主流程(单 `writeTxn`)
  - `selections` = `{equipmentId: targetDiscipleCharacterId}`
  - 校验:① `selections.length` 在 `[piecesPerGenerationMin, piecesPerGenerationMax]=[1,2]` ② 每件装备 ownerCharacterId == founderId ③ 每个 target lineageRole=disciple && isAlive
  - 副作用:每件 `inheritFrom(founderId, n)` + `ownerCharacterId = targetDiscipleId` / founder.isActive=false / `SaveData.activeCharacterIds` remove founderId
  - 返回 `AscensionResult(transferredCount, founderRetired=true)`
- **invalidate**:`founderBuffActiveProvider`(P1.1 候选 2)+ `allEquipmentsProvider` + `activeCharactersProvider`

## 4. 触发链

- `LineagePanelScreen` 新增「飞升渡劫」按钮(`computeEligibility().canAscend == true` 才 enable · disable 时 tooltip 显未满足子条件清单)
- 点击 → push `AscensionScreen` · 完成后 pop 回 main_menu + snackbar「飞升渡劫已成 · 你已退出江湖,门派由弟子接管」
- `chapter_list_screen.dart` Ch6 已显「飞升」入口 ✅ 不动
- `stage_inner_demon_07` / `stage_06_05` victory 不自动触飞升(玩家手动节奏 · sane default 不强推叙事)

## 5. AscensionScreen UI(~250 行 · `lib/features/ascension/presentation/ascension_screen.dart`)

- 三段式:
  - **顶部仪式横幅**:title「飞升渡劫」+ `ascension_intro` narrative 摘录(玩家姓名 + 大弟子姓名)
  - **中部 founder 装备列表**:卡片显玩家全部装备(slot 图标 + name + tier + baseStats 摘要 + 共鸣阶段 chip)· 多选框 1-2 件 · 实时统计「已选 X/2 件」
  - **中部下 disciple 分配**:每件已选装备显「分配给:[大弟子▼]」下拉(默认大弟子 · 玩家可逐件改 · 二徒弟时多 1 选项)
  - **底部确认按钮**:「确认飞升」disable iff 选择数 ∉ [1,2] · 点击 → confirmDialog「飞升后你将退出江湖无法回头 · 确认?」→ `AscendService.performAscend`
- 沿 `inner_demon_screen` 三态 + `lineage_panel_screen` 卡片体例
- `UiStrings.ascensionTitle` / `ascensionRitualHint` / `ascensionPickEquipment` / `ascensionAssignTo` / `ascensionConfirmDialog` 5 段

## 6. founder_buff_service 改注(0 代码改)

- 现行:`isActive=true && isFounder=true` → buff 激活(P1.1 候选 2)
- 飞升后:founder.isActive=false + `activeCharacterIds` remove founderId → 现 `computeBuffActive` 自然返 false ✅
- **仅改注释**:`founder_buff_service.dart:18-19` 头注「Phase 5+ 飞升机制实装」改「P2.3 飞升后,founder isActive=false → buff 自然 inactive(无需扩 trigger)· Phase 5+ 真传位语义(大弟子接管 founder)留新设计」

## 7. narrative ~600 字

- `data/narratives/ascension/` 新目录(类比 `chapters/`)
- `ascension_intro.yaml` 仪式开场 ~200 字(玩家姓名 + 大弟子姓名 + 师父三句遗言**第 4 次贯穿** + 师承遗物 transfer 仪式感)
- `ascension_complete.yaml` 完成 ~150 字(founder 退场 + 弟子接旨)
- `ascension_pick_hint.yaml` 选件 hint ~80 字(为何选某件 · "你最常用的兵器" / "陪你最久的甲胄")
- `ascension_disciple_thank.yaml` 各 disciple 接受台词 ~80 字 × 2 大/二弟子
- 风格:Ch4 yiLiu 词「沉着/肃杀/老练/冷静」沿用(memory `project_wuxia_idle_ch4_cultural_arc`)+ Ch6 飞升基调

## 8. 测试

- **R5.1 飞升红线 e2e**:fixture wuSheng·dengFeng + active + 2 关 cleared + 2 disciples → eligibility=true → performAscend 选 2 件分大弟子 → ownerCharacterId 改 + isLineageHeritage=true + founder.isActive=false + buff inactive
- **R5.2 eligibility 4 子条件**:每子条件取反 1 测(共 4 测 + 1 全 ok)
- **R5.3 multi_disciple_allocation player_pick**:2 件全大弟子 / 1+1 分 2 徒 / 全二弟子 三测
- **R5.4 边界**:0 件 throw / 3 件 throw / 非 founder 装备 throw / 非 disciple 目标 throw
- **R5.5 数值红线 §5.4**:飞升前 heritage 0 件 + 飞升后大弟子 +2 件 → `internalForceMaxWithLineage` mult ≤ 1.10 / clamp ≤ 15000 红线
- **baseline 1269 + delta ~15-20**(实际数 spec 起草前未 grep · Batch 3.3 R5 落地后实测)

## 9. Batch 拆解(估时 ~4h opus xhigh)

| Batch | 内容 | 估时 |
|---|---|---|
| 3.1 schema + Service | numbers.yaml `ascension` 段 + `HeritageItems` 4 字段解析 + `AscendService` 实装 + provider + `AscensionEligibility/Result` model | ~1.5h |
| 3.2 UI | `AscensionScreen` + `LineagePanelScreen` 入口按钮 + `UiStrings` 5 段 + 4 narrative yaml | ~1.5h |
| 3.3 R5 + closeout | R5.1-5.5 5 族测 + closeout + GDD v1.10→v1.11 §12.2 #10 实装记 + ROADMAP P2.3 段 + PROGRESS 顶段 | ~1h |

## 10. 不变量沿用

- **GDD §5.4 红线完全不动** · §5.3 三系锁死 · §5.5 在线 = 离线 · §5.1 反留存(飞升手动触发不强推)
- **Character/Equipment schema 0 改**(只复用现字段)· Isar 不破现有 fixture · `inheritFrom` 单件 transfer 不动(`entities_test.dart:138` 既有测继续 pass)
- **`founder_buff_service` 0 代码改**(仅更新注释 · isActive=false 自然让 buff 退出)
- **`stack_across_generations=false`** Demo 仅一代飞升,不验证多代场景(YAGNI · P5+ 多代师徒升级再实装)
- **`conflict_slot_resolution=auto_swap` 不实装**(大弟子飞升前装备空槽 · spec 注 P5+ 实装)
- **doc 体量**:本 spec ≤150 · closeout ≤80 · PROGRESS 净增长 ≤ 0(新顶段加 = 旧段砍)
- **memory `feedback_phase05_diagnose_before_solve`**:R5 测有挂账时 Phase 0.5 诊断不直上候选解法

---

**P2.3 spec 收口**:方向 B + Q1a/Q2c/Q3b/Q4d 拍板 + Batch 3.1-3.3 拆解 + 估时 ~4h xhigh · 主 cwd 直推 main(沿 P3.2.C 体例)待用户拍板进 Batch 3.1
