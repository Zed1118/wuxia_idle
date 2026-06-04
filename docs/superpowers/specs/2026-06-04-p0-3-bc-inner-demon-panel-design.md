# P0-3 ②③ · 主修心法 hero 化 + 心魔成长瓶颈面板 · design

> 1.0 出版美术 pass · Phase C「角色卡」· §5.4「主修更强展示 / 成长瓶颈视觉」
> 上游 spec:`2026-06-03-p0-3-character-panel-identity.md`(① 装备外观已 merge,本 spec 承 ②③)
> 状态:**brainstorm 拍板(2026-06-04,xhigh)→ 待 writing-plans**
> 用户拍板:③ 武圣常驻进度面板 · ③ 挑战 CTA 即突破按钮(不引新机制) · ② 宣纸底 hero 化

## 背景与现状

`character_panel_screen.dart` 区块序:`_ProfileHeaderCard` → `_BreakthroughBlockerSection` → `_DerivedStatsSection` → `_EquipmentSection` → `_TechniqueSection`(含 `_MainTechniqueTile`)→ `EncounterSkillSection` → `_LineageSection`。① 装备外观可视化已 merge。

**②** `_MainTechniqueTile`(L1067)有进度条但像表格行,与 Phase B 心法面板「卷轴/宣纸」体例不统一。
**③** `_BreakthroughBlockerSection`(L355)**只在「武圣境 + 经验满 + 被心魔拦」三条件同时满足时显示**,其余时候 `SizedBox.shrink()`,绝大多数角色面板这块是空的,与 §5.4「成长瓶颈作为角色卡常驻视觉」目标不符。

**心魔系统数据管线(已探明)**:
- 7 个心魔关 `stage_inner_demon_01..07`,对应 wuSheng 7 层,定义在 `numbers.innerDemon`(`InnerDemonDef`)。
- 通关状态 = `MainlineProgress.clearedStageIds: List<String>`(Isar)。无另存。
- 拦截判定 = `InnerDemonService.isLayerLocked({nextTier, nextLayer, innerDemonDef, clearedStageIds})`(静态)。
- **进阶是自动的**:`CharacterAdvancementService.applyExperience` while-loop 升层,`isLayerLocked` 返 true 则 break + EXP 留账;玩家通关对应心魔后,下次 EXP 结算自动升层。**无玩家手动突破动作**。
- 现有 provider:`mainlineProgressProvider`(暴露 clearedStageIds)。**无**暴露「心魔 X/7 进度」的 provider。

## ③ 心魔成长瓶颈面板

### 数据层(新增)

新建 `lib/features/inner_demon/application/inner_demon_providers.dart`:

- 值对象 `InnerDemonProgress`(纯 Dart,immutable):
  - `clearedCount` — 已通关心魔数(`clearedStageIds` 中 `stage_inner_demon_*` 计数)
  - `totalCount` — **派生自 `innerDemonDef`**(不同心魔关 stage id 数,不硬编码 7)
  - `clearedStageIds` — `Set<String>`(供 section 复算拦截)
  - `nextUnclearedStageId` — 按 `stage_inner_demon_01..NN` 顺序第一个未通关关(null = 全通)
- 计算入口:抽纯静态函数 `InnerDemonProgress.from({innerDemonDef, clearedStageIds})` 便于单测(不依赖 Isar)。
- provider:`innerDemonProgressProvider`(从 `mainlineProgressProvider` + `GameRepository.instance.numbers.innerDemon` 派生)。

> totalCount 派生口径:取 `innerDemonDef.requiredRealmLayer.keys`(或 unlockTriggers 全 stage id 并集)中形如 `stage_inner_demon_*` 的去重计数。实装时以 InnerDemonDef 实际暴露的 map 为准,**单一口径**封装在 `InnerDemonProgress.from` 内。

### 视图层

`_BreakthroughBlockerSection` 重写可见性逻辑(消费 `character` + `innerDemonProgressProvider` + `mainlineProgressProvider`):

| 状态 | 条件 | 显示 |
|---|---|---|
| 非武圣 | `tier != wuSheng` | `SizedBox.shrink()`(不变) |
| **已尽** | `clearedCount == totalCount` | 完成态:「心魔已尽 7/7」+ 满进度条,无 CTA |
| **被拦**(强调) | 武圣 · exp 满 · `isLayerLocked`==true | 「突破被拦·经验留账」+ X/7 进度条 + 拦截关名 +「突破」CTA(强) |
| **进行中** | 武圣 · 其余 | X/7 进度条 + 下一关(`nextUncleared` 关名)预告 +「前往心魔关」CTA(弱) |

把现有 `InnerDemonBreakthroughBlocker`(纯文字 + 单 onNavigate)泛化为 `InnerDemonProgressPanel`(纯渲染,无状态):
```
InnerDemonProgressPanel({
  required InnerDemonPanelState state,   // cleared | blocked | inProgress
  required int clearedCount,
  required int totalCount,
  String? blockingStageName,             // blocked 态
  String? nextStageName,                 // inProgress 态
  RealmLayer? nextLayer,                 // blocked 态「想升 ...·...」
  VoidCallback? onNavigate,
})
```
- 进度条:`LinearProgressIndicator value = clearedCount/totalCount`(沿主修 tile 体例,墨/金色)。
- 「突破」CTA = `onNavigate → InnerDemonScreen`(沿现有路径,不引新机制)。
- **硬编码中文迁 `UiStrings`**(现 widget 内「突破被拦」「想升…经验留账」均硬编码,违 §5.6,本批清理)。

### 文案(新增 UiStrings)

面板标题「心魔试炼」、X/totalCount 进度 label、被拦「经验留账」句、进行中「下一关:XX」预告、已尽「心魔已尽」、CTA「突破」/「前往心魔关」。沿现有 `breakthroughGoToInnerDemon` 体例。

## ② 主修心法 hero 化(主观视觉 · 像素留 Codex)

- 主修 tile 改 hero:外层 `WuxiaPaperPanel`(宣纸底,`paperOpacity` 默认,errorBuilder/test 自动兜底暖宣纸)+ min-height ~120 + 主修名加大(校色 ~20px / w700)+ 阶名(`techniqueTier`)+ 段位(`cultivationLayer`)徽章 + 进度条 + 进度数值保留。
- empty / loading / error 三态维持(纸底壳内放占位/loading/错误文案)。
- 辅修 tile **维持现状**(不动 `_AssistTechniqueTile` / `_SlotShell`)。
- 纯视觉,最终观感留 Codex 验收 + 用户在场判。

## 测试

- **③ provider 单测**(`test()` 非 `testWidgets`,避 Isar 死锁):`InnerDemonProgress.from` —— 全未通(0/N)/ 部分(K/N)/ 全通(N/N)/ totalCount 派生正确 / nextUncleared 顺序正确。
- **③ section widget 测**(provider override,`testWidgets` + setSurfaceSize 扩 viewport):
  - 非武圣 → `shrink`(`findsNothing` 面板标题)
  - 武圣进行中 → 显进度条 + 下一关预告 + 弱 CTA
  - 武圣被拦 → 显「经验留账」+ 强 CTA
  - 武圣已尽 → 显「心魔已尽」+ 无 CTA
- **② hero widget 测**:主修名渲染 + 纸底(`WuxiaPaperPanel`)present + 进度条 + 缺图 errorBuilder 不崩(`takeException isNull`)。
- 全量 test + `flutter analyze` 0。

## 验收

- `VISUAL_ROUTE=characterPanelProfile`(`visual_route_host.dart:125` → `CharacterPanelScreen(characterId:1)`)。
- **③ 面板需 seed 武圣角色 + 部分心魔通关**才有内容:调 `phase2_seed_service` 的 character_panel seed,加一个 wuSheng 角色(exp 满触发被拦态)+ `MainlineProgress.clearedStageIds` 注入若干 `stage_inner_demon_*`(展示 K/N 进度 + 被拦)。
- 重跑 `tool/build_acceptance.sh` 预编 debug 包(改码后必重编,VISUAL_ROUTE 被 kDebugMode 门控)。
- 派 Codex@Pen 截图验收 doc(门:② 主修 hero 纸底/加大名/进度条;③ 三状态面板 X/7 进度条 + CTA + 无 overflow @1280×720)。

## 红线 / 约束

- `totalCount` 派生不硬编码;文案全走 `UiStrings`(§5.6)。
- 心魔进度单一真相源 = `MainlineProgress.clearedStageIds`,不另存状态。
- 不引新突破机制(进阶仍自动);CTA 仅导航。
- 不动 §5.4 数值红线;不动辅修 `_SlotShell` / `_AssistTechniqueTile`。
- `WuxiaPaperPanel` errorBuilder 兜底(asset gate);Image 缺图走占位(沿 asset_audit 体例)。
- 不动 `InnerDemonService.isLayerLocked` 拦截逻辑本体(仅消费)。

## 范围外(本批不做)

- 不改进阶为手动突破(自动模型保留)。
- 不动心魔关战斗 / unlock 链 / 数值。
- 辅修 tile 视觉不改。
