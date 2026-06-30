# 新手前 30 分钟体验审计 v2（2026-06-30）

## Scope

本次为只读体验审计，只新增本文档，不改 Dart/YAML 功能代码。覆盖当前新档路径：

- 空槽建档 -> 祖师塑形 -> 第一次进入主菜单。
- 主菜单「当前要事」与主线入口。
- 章节列表 / 选关页 / 战斗入口。
- 前几场胜利、普通关失败、Boss 失败反馈。
- 首批装备、心法、资源获得后的下一步清晰度。

明确不审：

- `lib/features/battle/presentation/battle_screen.dart` 与 tap 战斗实现代码。tap/拖招仅按已知规格纳入影响评估：首通新关强制 interactive，点击看简介、拖到目标即放，首通后可按设置回到自动。
- `numbers.yaml` / saveVer / schema / 伤害结算 / 离线收益 / 三系锁死。
- `PROGRESS.md`。

## Current Flow Map

1. 空槽：`SaveSelectScreen` 对空槽弹「新开江湖」确认，确认后切 slot 并进入 `FounderCreationScreen`；空槽不会直接 seed 默认祖师。
2. 祖师塑形：创建页一次展示三段选择：流派 3 项、出身 4 项、命盘候选 3 项；确认后 `OnboardingService.createFoundingMaster()` 写入单人祖师、起手主修、基础装备、磨剑石 50 + 出身加成。
3. 主菜单：`MainMenuStatusSummaryPanel` 若有可行动项会显示「当前要事」；无闭关/伤势/突破等更急事项时，fallback 到下一条主线目标。
4. 主线入口：主菜单「主线」按钮 hint 会使用 `NewSaveGoalText.mainMenuHint()`，将目标关、代表性奖励、推进理由压成一行。
5. 章节/选关：章节列表有路线图；第 1 章选关页顶部有章内行程、通章刷点、周目控件、扫荡按钮、章节卷轴。当前可打关卡会挂 `NewSaveGoalHintLine`。
6. 战斗入口：`runStageFlow()` 先播 opening，再进战斗。新关首通会由 `_StageBattleHost` 按进度判断 first clear 并强制 interactive，避免玩家完全错过拖招/破招入口。
7. 胜利：先落 `applyVictoryResolution()`、记录主线进度、技能掉落 hook、战绩/奇遇/弟子/里程碑等 hook；然后显示胜利仪式与 `StageVictoryContent`，分区展示装备、材料、秘籍/残页、战况、伤势/疗伤。
8. 失败：普通关失败弹「功亏一篑」并可立即再战；Boss 关失败会先结算散功/伤势类损失，若有关联 defeat narrative，则带损失 banner 进入战败剧情。

## Findings（P1/P2/P3）

### P1

未发现会阻断新档前 30 分钟的 P1 问题。

- 生产单人开局已有回归：`test/features/onboarding/onboarding_first_30min_battle_test.dart` 覆盖 stage_01_01 不应失败、首胜整备后 stage_01_02 至 stage_01_04 不应成为失败点、stage_01_05 必须有确定终态。
- 首关 `data/stages.yaml` 保证 100% 护甲 + 磨剑石；第二关保证 100% 武器，前 15-30 分钟至少有装备/材料反馈。
- 当前引导没有 `showDialog` 式教程弹窗堆叠；主菜单系统以锁定/灰化/hint 为主，符合 GDD §10 的非教程化方向。

### P2-1 · 祖师塑形首屏选择负担偏高，且默认选择的可逆性/影响范围不够显性

位置：

- `lib/features/onboarding/presentation/founder_creation_screen.dart:96`
- `lib/features/onboarding/presentation/founder_creation_screen.dart:115`
- `lib/features/onboarding/presentation/founder_creation_screen.dart:135`
- `lib/features/onboarding/presentation/founder_creation_screen.dart:407`

现状：玩家在第一次正式进入游戏前必须一次性读完三组选择。预览区能展示属性、起手心法、资源、开局建议，但没有把「会影响前几场战斗手感 / 以后仍可通过玩法弥补 / 不可重 roll」这些决策边界直接放到确认附近。

影响：不是阻断，但会让一部分新玩家在「还没玩到战斗」前开始 min-max。它不违反红线，但削弱 GDD §10.3「先感受问题，再给答案」。

风险等级：P2。原因是该页面在进入主循环前，是当前新档最长的阅读节点。

### P2-2 · 首胜掉落后的下一步不是完全直达：装备可看见，但“现在要不要去背包装备/强化”仍需玩家自己推断

位置：

- `lib/features/mainline/presentation/stage_victory_dialog.dart:228`
- `lib/features/mainline/presentation/stage_victory_dialog.dart:240`
- `lib/features/mainline/presentation/stage_victory_dialog.dart:631`
- `lib/features/main_menu/presentation/main_menu.dart:281`

现状：胜利结算能展示装备名、品阶、可用角色、锁定/稍后等动作；装备入口在主菜单常驻，且有 inventory status。但战后对「新拿到的可用装备，下一步去行囊处理」没有一个低侵入的路由/状态衔接。

影响：首关 100% 掉护甲、第二关 100% 掉武器是好的奖励节奏；但如果玩家连续点「继续」回到剧情/关卡列表，可能知道自己拿到了东西，却不确定是否已经装备、是否应该回主菜单进「行囊」。这会增加第一批奖励的消化摩擦。

风险等级：P2。它影响“获得装备后的下一步是否清楚”，但不影响数据正确性。

### P2-3 · 普通关失败与 Boss 失败反馈层级差异大，早期失败时可能缺少“为什么输/去哪里补”的稳定出口

位置：

- `lib/features/mainline/presentation/stage_entry_flow.dart:119`
- `lib/features/mainline/presentation/stage_entry_flow.dart:155`
- `lib/features/mainline/presentation/stage_entry_flow.dart:426`
- `lib/features/battle/presentation/victory_overlay.dart:77`

现状：战斗 overlay 本身有战败诊断与跳转能力；但 `runStageFlow()` 的普通关失败路径会在战斗屏 pop 后弹一个很轻的「再战/返回」对话框。Boss 失败则走损失结算 + defeat narrative。两者体验层级差异很大。

影响：前 30 分钟理论上 stage_01_01 至 stage_01_04 不应成为硬失败点，但玩家若因拖招误操作、低属性命盘或故意挑战失败，普通关反馈不够解释性；Boss 失败又可能突然严肃，产生“是不是我错过了养成步骤”的疑问。

风险等级：P2。不是平衡问题，是失败后的修复路径解释不稳定。

### P3-1 · 主菜单首屏信息量偏高，但已经通过锁定与当前要事缓解

位置：

- `lib/features/main_menu/presentation/main_menu.dart:200`
- `lib/features/main_menu/presentation/main_menu.dart:270`
- `lib/features/main_menu/presentation/main_menu.dart:907`
- `lib/features/main_menu/presentation/main_menu_status_summary.dart:45`

现状：主菜单第一小时内同时可见主线、爬塔、角色、行囊、资源总览、心法锁定、闭关锁定，以及若干后期锁定入口。优点是完整，缺点是新档第一次进入时“能点什么 / 该点什么”需要靠当前要事与主线高亮承担。

影响：当前要事能兜住主要路径，因此不升 P2。但如果视觉焦点弱于大网格入口，新玩家仍可能先点角色/行囊/资源总览而不是主线。

风险等级：P3。

### P3-2 · 选关页顶部工具对新档过早出现，扫荡/周目/刷点语义可能抢跑

位置：

- `lib/features/mainline/presentation/stage_list_screen.dart:135`
- `lib/features/mainline/presentation/stage_list_screen.dart:136`
- `lib/features/mainline/presentation/stage_list_screen.dart:138`
- `lib/features/mainline/presentation/stage_list_screen.dart:144`

现状：第 1 章新档进入选关页时，页面会先布置章内行程、通章刷点、周目选择、扫荡，再进入章节卷轴。实现上有条件显示，但概念本身偏“复刷/长线”。

影响：不构成教程弹窗，也不触发留存焦虑；但在前 30 分钟，它可能稀释“点当前可挑战关卡”的清晰度。

风险等级：P3。

### P3-3 · 材料掉落行显示品类而非具体名称，早期资源认知略弱

位置：

- `lib/features/mainline/presentation/stage_victory_dialog.dart:250`
- `lib/features/mainline/presentation/stage_victory_dialog.dart:363`

现状：装备掉落行会显示装备名与品阶；材料/银两行则用 `EnumL10n.itemType(...)` 展示品类 + 数量。首关会 100% 获得磨剑石和银两，但玩家看到的可能更接近「材料 x1 / 银两 xN」，不如「磨剑石 x1」直观。

影响：轻微。后续资源总览可查，但第一场胜利的“我拿到了什么、能做什么”表达可更具体。

风险等级：P3。

## Small Slice Recommendations

### S1 · 祖师塑形确认区补一行“低压力决策边界”

- 对应发现：P2-1。
- 文件区域：`founder_creation_screen.dart` 预览区 / `UiStrings.founderCreateConfirmLine` 邻近文案。
- 建议：在确认按钮上方或预览末尾补一行克制说明，例如“影响起手手感与主修方向，前几关均可稳过；后续仍可用装备/修炼补短。”不要解释公式，不做弹窗。
- 验证建议：补 widget test 覆盖三组选择后预览区仍渲染该说明；跑 `flutter test --no-pub -j1 test/features/onboarding`。
- 是否需用户拍板：不需要。属于文案与信息层级微调，不改玩法。

### S2 · 首次可用装备掉落后，在胜利卷宗增加一个“行囊整备”轻动作或状态桥

- 对应发现：P2-2。
- 文件区域：`stage_victory_dialog.dart` 装备掉落 section；必要时只加按钮回调接口，不直接改装备逻辑。
- 建议：当 `drops.equipments` 中存在当前角色可用装备时，在装备 section 增加低调动作“稍后去行囊整备”或“回主菜单后行囊可处理”。更理想的小切片是给 dialog 一个可选 `onOpenInventory`，调用方在结算关闭后导航；但这会涉及流程栈，需要单独测。
- 验证建议：`test/features/mainline/presentation/stage_victory_dialog_test.dart` 增加“可用装备时出现整备提示/按钮”；如加导航，再补 `stage_entry_flow_test`。
- 是否需用户拍板：文案提示不需要；若要战后直接跳转行囊，建议用户拍板，因为会改变胜利剧情/回关卡列表的现有流程节奏。

### S3 · 普通关失败重试框加入一条非教程化短诊断

- 对应发现：P2-3。
- 文件区域：`stage_entry_flow.dart` `_showStageRetryDialog()`；可复用 `BattleDiagnosis` 产物则更好，但先做静态小文案也可。
- 建议：普通关失败不必变重惩罚，继续保持免费再战；但在“再战/返回”之间补一句“可先回行囊换上新装备，或稍后再战”。避免写教学步骤，避免强引导。
- 验证建议：扩展 `test/features/mainline/presentation/stage_entry_flow_test.dart`，覆盖普通关失败对话框出现短诊断且“再战”仍只重打本场。
- 是否需用户拍板：不需要，若只是提示；若要接入跳转按钮，需要拍板。

### S4 · 新档阶段弱化复刷控件的视觉优先级

- 对应发现：P3-2。
- 文件区域：`stage_list_screen.dart` `_ChapterFarmSpotsPanel` / `CycleSelectControl` / `_ChapterSweepButton` 的显示条件或排序。
- 建议：未通完第 1 章前，保持“章节卷轴/当前目标”优先；复刷、周目、扫荡只在章通后或已有对应条件时出现/上移。不要新增教程弹窗。
- 验证建议：`stage_list_screen_test.dart` 增加新档第 1 章截图式 widget 断言：当前目标在首屏可见，扫荡/周目不抢占主要位置。
- 是否需用户拍板：不需要，如果只是显示条件/排序；若隐藏已存在入口，建议轻量拍板。

### S5 · 材料掉落行显示具体 item 名

- 对应发现：P3-3。
- 文件区域：`stage_victory_dialog.dart` `_VictoryItemRow`。
- 建议：从 item def / resolver 取 `磨剑石`、`银两` 等具体名，保留品类可作为副文本。这个切片只改展示，不改掉落。
- 验证建议：`stage_victory_dialog_test.dart` 增加 item drop 行显示具体名称。
- 是否需用户拍板：不需要。

## Do Not Start Tonight

- 不改首章战斗数值、掉落概率、伤害结算或敌我属性；现有前 30 分钟战斗已有测试兜底，今晚不碰平衡。
- 不把引导做成教程弹窗、遮罩、强制点击链路或红点日课。
- 不改 tap/拖招实现，不碰 `battle_screen.dart` 与 tap 测试。
- 不改 `numbers.yaml`、saveVer、schema、离线收益、三系锁死。
- 不改 `PROGRESS.md`。
- 不启动大范围主菜单重排；只建议后续小切片验证首屏焦点。
