# P1 #42 Phase 1 · §9 上线第一屏 + 江湖见闻录 + 延续典故 hook + GameEvent 写入 · 完整 spec

> **任务级别**:P1 阶段第一波(P0 4 项 100% 收口后纵深,1.0 路线图 `docs/ROADMAP_1_0.md` v1.2 §P1)
> **范围**:**选项 B**(§9 主屏 + 江湖见闻录 + 延续典故 hook + GameEvent 7 type 写入)。§10 新手引导骨架推 **Phase 2 单独 P1.x**(跨多 Demo 系统时间锚点 + DeepSeek 主线 Ch1 师父教学剧情对接,不是纯 Mac 端 spec 可闭环)
> **预估**:opus xhigh **8-11h**(6 phase 串行,Phase 2 GameEventService + hook 是主工作量 ~2-3h)
> **开工模型**:**opus xhigh 全程**(用户指定 + memory `feedback_model_selection` 跨子系统建议升档)
> **commit 前缀**:`[feat]`(§9 主屏/Baike/延续典故 0→1)+ `[arch]`(GameEventService helper)
> **作者**:Mac + Opus 4.7 · 2026-05-17 晚续起草

---

## 1. 背景

PROGRESS.md 挂账 #42 原文:**§9 上线第一屏 / §10 新手引导 / §6.6 延续典故动态机制未实装**(外部 + 本会话 audit P1):GameEvent 类已建主屏未消费 / `tutorialStep` 0 实装 / 江湖见闻录 0 Screen / 延续典故 Isar schema 留接口无追加逻辑。

**P0 阶段全收口里程碑**(2026-05-17 晚续):
- P0.1 #38 base maxHp 数值重平衡(方案 D)
- P0.2 #40 本地排行榜 + Supabase placeholder(方案 D)
- P0.3 #41 MSIX + itch.io 发包链路(决议方案 C 砍归档推 P5.4b)
- P0 battle_engine 抽 strategy 层重构(5 phase + 943/943 + analyze 0 issues)

Demo §7 12/12 GUI 全 ✅,**Demo 内容总量表 7/7 全达 GDD §8.4**。本批进 P1 系统纵深。

**为何拆 Phase 1 选项 B(本批) + Phase 2 §10(后续)**:
1. **§10 引导节奏的真正阻塞不是技术**:GDD §10.1 8 档解锁节奏 cross-cuts 多个 Demo 系统(0-15 战斗/境界/装备 → 30-45 心法 → 2-3h 师徒 → 3-5h 奇遇)。其中"剧情包装的强制引导"(§10.2 第 1 方式)需 **DeepSeek 写主线 Ch1 师父教学剧情** + 各系统解锁时间锚点 wire,**Mac 端独立 spec 不能闭环**
2. **§9 + 3 消费侧是闭环子系统**:GameEvent 数据流 → 上线第一屏金色摘要 + 江湖见闻录百科 + 延续典故 hook,Demo 可独立交付价值(玩家上线看摘要 / 装备详情有延续典故 / 江湖见闻录可查)
3. **§10 应作为「Demo 上线前最后一公里」P1.x 单独立项**,等 §9 落地后所有 GameEvent 数据流就位,"现象先于规则"(GDD §10.3 设计哲学)才有素材可用

---

## 2. Reality check 汇总(Agent A + Agent B 调研输出精炼)

> 调研于 spec 起草前完成,Agent A(GameEvent 9 type hook 全审计)+ Agent B(GDD §9§10 + 引导组件基线)各 opus 一次。本节抽核心结论,完整调研报告见会话 thread。

### 2.1 GameEvent 9 type 写入点全审计(Agent A 三分类)

| Type | 业务位置 | 分类 | 关键 |
|---|---|---|---|
| #1 retreatCompleted | `seclusion_service.dart:261` `completeRetreat` | B | Service 持 isar 句柄,writeTxn 内加 1 行 `put`,characterId 已入参 |
| #2 adventureTriggered | `encounter_service.dart:252-308` `applyOutcome` | B | writeTxn 已开,需 caller 把 `founderId` 传进或在 hook 层补写 |
| #3 equipmentObtained | `_persistDrops`(`tower_entry_flow.dart:356`)+ `_applyVictoryResolution`(`stage_entry_flow.dart:406-436`) | A | drop_service / equipment_factory 注释自证"由 caller 写",每件 drop.equipments 元素 1 条 event |
| #4 techniqueLearned | `technique_learning.dart:51` `TechniqueLearningService.learn` | **C** | **0 业务 caller**(只 test/seed 调),Phase 5+ §7.2 武学领悟 UI 实装才能挂。**本 spec 留接口不写入** |
| #5 skillEnlightened | `encounter_service.dart:272-279` `case OutcomeType.unlockSkill` | B | 同 #2 caller,与 #2 是否合并待决(本 spec §3.2 拍板拆两条) |
| #6 realmBreakthrough | `character_advancement_service.dart:30` `applyExperience` static,3 处 caller(闭关/主线/爬塔 victory) | B | 抽 `GameEventService.recordBreakthrough` helper DRY,3 caller 共用 |
| #7 resonanceUpgraded | `battle_resolution.dart:123` `eq.battleCount += 1` 循环 | B | **需扩 `BattleResolutionResult.resonanceUpgradedEquipmentIds: List<int>`** + resolve 签名传 numbersConfig |
| #8 bossDefeated | 主线 `stage_entry_flow.dart:131` `recordVictory` 后 + 爬塔 `tower_entry_flow.dart:116` `recordClear` 后 | B | caller 兜底,主线需读 `MainlineProgress.clearedStageIds` 判 isFirstClear 防刷,爬塔已有 `clearResult.isFirstClear` |
| #9 disciplePromoted | **0 业务收口**(grep 仅 domain field + UI 渲染 + seed) | **C** | Demo 实质 = #6 + `lineageRole == disciple`,真独立路径要等 Phase 5+ 师徒系统。**本 spec 借 #6 caller 路由实装** |

**实装范围**:**7 type 实装**(#1/#2/#3/#5/#6/#7/#8)+ **2 type 留接口**(#4 等 Phase 5+ §7.2 / #9 借 #6 路由不独立 schema)。

### 2.2 GDD §9 §10 + 引导组件基线(Agent B 原文锁死)

**GDD §9.2 上线第一屏 = "昨晚发生的事"**(原文):
> - 金色文字的摘要,**不是任务列表**
> - **快速领取按钮**(30 秒最低限度上线流程)
> - Windows 桌面通知极简可关
> - **不做快进**:在线离线收益相同
> - 设计理由:让"打开游戏"具有仪式感——不是看到一堆红点要清,而是看到一段故事的延续

**GDD §10.2 三种引导方式**(本 spec **不消费**,推 Phase 2):剧情包装强制引导(前 30min)+ 上下文气泡(30min 后)+ 江湖见闻录百科(永久可查)。本 spec 只交付第 3 方式的 **百科 Screen 容器骨架**,内容填充推 Phase 2(yaml 文案 DeepSeek 端)。

**反主流红线 8 项**(CLAUDE.md §5.1 §5.7 §9):
1. ❌ 教程弹窗
2. ❌ 任务列表 / 红点焦虑
3. ❌ 登录奖励 / 每日任务
4. ❌ 快进券 / 体力 / 战令
5. ❌ Material 默认饱和色(走 `WuxiaColors`)
6. ❌ Dart 中写中文文案(走 `UiStrings` / DeepSeek narratives)
7. ❌ 强制 modal 拦截
8. ❌ tutorialStep 硬编码节奏数字(本 spec 暂留 const,推 Phase 2 抽 yaml)

**现有代码基线**(关键发现):

| 维度 | 状态 | 文件:行 |
|---|---|---|
| `GameEvent` schema | ✅ 已落 Phase 1 占位 9 type | `lib/core/domain/game_event.dart:1-29` |
| GameEvent 业务写入 | ❌ 0 | — |
| 上线第一屏 Screen | ❌ 0,cold start 直进 MainMenu | `lib/main.dart:38` |
| `NarrativeReader` 通用阅读屏 | ✅ 可复用做剧情引导 | `lib/features/narrative/presentation/narrative_reader_screen.dart` |
| 气泡组件 | ❌ 0(`_HintBanner` 全宽 banner 不算) | — |
| 百科 Screen | ❌ 0(`lore_loader.dart` 是 yaml loader 非 Screen) | — |
| `_MenuButton.disabled` 灰显 | ✅ 已有可复用 | `main_menu.dart:233-285` |
| **💎 `SaveData.isOnboardingCompleted`** | ⚠️ **已落但 0 业务代码读写**(死字段,沿 P0.2 #40 `highestTowerLayer` 同款) | `save_data.dart:39` |
| `_currentSaveVersion` | 0.9.0(P0.2 #40 刚 bump,本批 → 0.10.0) | `isar_setup.dart:66` |
| `Lore @embedded` 延续典故 schema | ✅ 字段全备(`isPreset` / `addedAt` / `triggerEventDesc`)0 caller | `lib/core/domain/lore.dart` |

### 2.3 4 子系统耦合关系最终澄清

```
GameEvent 9 type 写入(本 spec 7 实装 + 2 留接口)
    ├─→ §9 主屏「昨晚发生的事」金色摘要 feed(独立 Screen, replace home)
    ├─→ 江湖见闻录 = §10.2 第 3 方式百科入口 + GameEvent 全量列表深入页
    └─→ 延续典故 hook:GameEvent.bossDefeated / equipmentObtained 触发
         equipment.lore 追加 isPreset=false
§10 引导骨架(SaveData 扩 tutorialStep,推 Phase 2)
    └─→ MainMenu 按钮 disabled 根据 tutorialStep 灰显 + 三方式
```

**4 子系统实质 = GameEvent 数据流为中心 + 3 个消费侧**,不是 4 个独立系统。

---

## 3. 决议拍板(2026-05-17 晚续)

### 3.1 范围:**选项 B**

- ✅ §9 上线第一屏 + 江湖见闻录 + 延续典故 hook + GameEvent 7 type 写入
- ⏭️ §10 新手引导骨架推 Phase 2 单独 P1.x(DeepSeek 主线 Ch1 师父教学剧情对接 + 8 档节奏前 2 档 wire)
- ⏭️ #4 techniqueLearned / #9 disciplePromoted 独立路径推 Phase 5+

### 3.2 3 架构决策

**决策 1**:✅ **抽 `GameEventService` helper**(`lib/features/event/application/game_event_service.dart`)

- **理由**:5+ caller 分散(seclusion / encounter / drop persist 2 处 / advancement 3 处 victory hook + boss 2 处),callsite ≥ 5 符合 memory `feedback_refactor_facade_callsite` 抽 facade 兜底降迁移成本
- **API 形态**(7 method,1 type 1 method):
  ```dart
  class GameEventService {
    final Isar isar;
    GameEventService(this.isar);
    
    /// 同一 writeTxn 内调用,caller 已持锁
    Future<void> recordRetreatCompleted({required int characterId, required Duration actualTime, required String summary});
    Future<void> recordAdventureTriggered({required int characterId, required String encounterId, required String title});
    Future<void> recordEquipmentObtained({required int characterId, required int equipmentDefId, required String equipmentName, required String source});
    Future<void> recordSkillEnlightened({required int characterId, required String skillId, required String skillName});
    Future<void> recordRealmBreakthrough({required int characterId, required Character character, required AdvancementResult result});
    Future<void> recordResonanceUpgraded({required int characterId, required int equipmentDefId, required String equipmentName, required int newStage});
    Future<void> recordBossDefeated({required int characterId, required String bossId, required String bossName, required String stageContext});
  }
  ```
- **#9 disciplePromoted 复用**:`recordRealmBreakthrough` 内根据 `character.lineageRole == LineageRole.disciple` 路由 eventType,不开独立 method
- **provider**:`@riverpod GameEventService gameEventService(Ref ref) => GameEventService(ref.watch(isarProvider))`

**决策 2**:✅ **#2 adventureTriggered + #5 skillEnlightened 拆两条**

- **理由**:GameEventType 枚举本就分两 type,合并破坏 type 语义;同次 applyOutcome 双发合理(奇遇触发 + 武学领悟解锁 = 两件叙事独立的事)
- **实装**:`EncounterService.applyOutcome` writeTxn 内,先 `recordAdventureTriggered` 必发,再判 `OutcomeType.unlockSkill` 条件发 `recordSkillEnlightened`

**决策 3**:✅ **§9 主屏独立 Screen replace `main.dart:38` home**

- **理由**:GDD §9.2 原文锁死"独立屏 + 快速领取按钮 30s 流程",顶部 banner 是 P0.2 节日 chip 装饰体例不匹配仪式感
- **实装**:新建 `HomeFeedScreen`(`lib/features/home_feed/presentation/home_feed_screen.dart`),`main.dart:38` `home: const HomeFeedScreen()` + 快速领取按钮 push `MainMenu`(`pushReplacement` 替换路由栈避免返回回 HomeFeed)
- **首次启动 / 空 feed**:无 GameEvent 时显占位文案"江湖初醒,昨夜风平浪静"+ 直接快速领取进 MainMenu

### 3.3 模型档全程 opus

用户 2026-05-17 晚续指定,本 spec 起草到 closeout 全程 opus(不再 sonnet)。

---

## 4. 实装拆解(6 phase 串行,每 phase 单 commit 间断 checkpoint)

### Phase 1:SaveData schema bump(0.5h)

**改动**:
1. `lib/core/domain/save_data.dart`:加 `int tutorialStep = 0;` 字段(留 §10 Phase 2 接口,本批 0 业务读写)
2. `lib/data/isar_setup.dart:66`:`_currentSaveVersion` `0.9.0` → `0.10.0`
3. `dart run build_runner build`(memory `feedback_wuxia_pen_build_runner` 纪律,*.g.dart gitignored)
4. test:运行 `flutter test`,基线 943/943 → 期望 943/943(0 业务消费 0 case 改动)
5. `flutter analyze`:0 issues 保持

**验收**:`flutter test && flutter analyze` 双绿,`isOnboardingCompleted` 不动(留 §10 Phase 2 复用),`tutorialStep` 已落 schema 0 业务消费(将作为 §10 P1.x 入口)

**commit**:`[schema] Phase 1 SaveData 加 tutorialStep + bump 0.10.0(留 §10 接口)`

### Phase 2:GameEventService helper + 7 type 写入 hook(2-3h)

**Step 2.1**:新建 `lib/features/event/{application,domain}/` 目录树

- `lib/features/event/application/game_event_service.dart`(~150 行):7 method API(§3.2 决策 1 详)
- `lib/features/event/application/game_event_service.g.dart`(codegen)
- `lib/features/event/domain/game_event_summary.dart`(可选,封装 9 type 摘要文案派生)
- `lib/shared/strings.dart`:加 9 type 标题模板 const(`gameEventRetreatTitle / gameEventAdventureTitle / ...`)+ 派生 helper(`formatRetreatSummary(actualHours, summary)` 等)

**Step 2.2**:7 type caller 接入

| Type | Caller | 改动 |
|---|---|---|
| #1 retreatCompleted | `seclusion_service.dart:351` writeTxn 内 | 加 `await gameEventService.recordRetreatCompleted(...)` 1 行 |
| #2 adventureTriggered | `encounter_service.dart:applyOutcome` writeTxn 内 | 加 `recordAdventureTriggered` 必发 + caller 传 `founderId` |
| #5 skillEnlightened | 同 #2,条件 `case OutcomeType.unlockSkill` | 在 #2 之后判 type 发 `recordSkillEnlightened` |
| #3 equipmentObtained | `stage_entry_flow._applyVictoryResolution:406-436` + `tower_entry_flow._persistDrops:356` | 每件 drop 元素 putAll 之后调 `recordEquipmentObtained` |
| #6 realmBreakthrough(+ #9 disciplePromoted 共用) | 3 处:`seclusion_service:342` / `stage_entry_flow:396` / `tower_entry_flow:333`(各 caller 已收 `AdvancementResult`) | `r.didAdvance && r.layersGained > 0` 即调 `recordRealmBreakthrough`,内部按 `character.lineageRole` 路由 eventType |
| #7 resonanceUpgraded | `battle_resolution.dart:123` 循环内 | 改 `BattleResolutionResult` 加 `resonanceUpgradedEquipmentIds: List<int>` 字段;`resolve()` 签名 numbersConfig 必传;循环内 stage 跨档检测加入返回;caller(`stage_entry_flow._applyVictoryResolution` + `tower_entry_flow._applyTowerVictoryResolution`)拿到后调 `recordResonanceUpgraded` |
| #8 bossDefeated | `stage_entry_flow:131` recordVictory 后(条件 `stage.isBossStage && isFirstClear`)+ `tower_entry_flow:116` recordClear 后(条件 `floor.isBoss && clearResult.isFirstClear`) | 主线 isFirstClear 判:`recordVictory` 内 pre-read `MainlineProgress.clearedStageIds` 不含 stageId(防回归刷)|

**Step 2.3**:`flutter test` + `flutter analyze`

- 期望 test 943 → ~963(+20:7 type 红线契约 case 各 2-3 + GameEventService 单元 5)
- `_persistDrops` / `_applyVictoryResolution` mock injection 沿 `battleRunnerForTest` / `victoryRecorderForTest` 体例(`@visibleForTesting` DI hook)

**验收**:
- 7 type 各自至少 1 红线 case 验证写入(GameEvent 表 occurredAt 倒序读 1st 条 eventType 匹配)
- `BattleResolutionResult.resonanceUpgradedEquipmentIds` backward-compatible(老 caller 不传 numbersConfig 时 nullable 路径走 fallback)
- 防刷:主线 boss stage 重打不重复发 #8(stageId 已在 `clearedStageIds` 跳过)
- analyze 0 issues

**commit**:`[arch] Phase 2 GameEventService helper + 7 type 写入 hook(7 caller + isFirstClear 防刷)`

### Phase 3:HomeFeedScreen 上线第一屏(1.5-2h)

**Step 3.1**:新建 `lib/features/home_feed/`

- `presentation/home_feed_screen.dart`(~200 行):
  - `Scaffold + AppBar('江湖见闻')`(GDD §9.2 体例,不用"主菜单"标题)
  - body:`Consumer` 读 `gameEventsProvider`(`@riverpod` Stream/Future GameEvent 按 occurredAt desc limit 20)
  - 列表 item:`_GoldenFeedItem(eventType / title / summary / occurredAt)` 金色文字(`WuxiaColors.goldFeed = Color(0xFFC9A961)` 新增)+ 时间相对格式(`刚才 / N 分钟前 / 昨日 / N 日前`)
  - 空态:占位文案 `UiStrings.homeFeedEmptyHint = '江湖初醒,昨夜风平浪静'`
  - **快速领取按钮**:底部固定 `_QuickClaimButton(label: '直入江湖')`,onTap `Navigator.pushReplacement(MainMenu())` + mark 所有 GameEvent.isRead = true(批量 writeTxn)
- `application/home_feed_providers.dart`:`@riverpod Future<List<GameEvent>> gameEventsFeed(Ref ref, {int limit = 20})` 派生
- `application/home_feed_providers.g.dart`(codegen)

**Step 3.2**:`lib/shared/strings.dart` 加 9 type 摘要文案模板

- 复用 `lib/core/domain/game_event_summary.dart`(Phase 2 已建)的派生 helper
- `homeFeedScreenTitle` / `homeFeedEmptyHint` / `homeFeedQuickClaimLabel` 等 const

**Step 3.3**:`lib/main.dart:38` 改 `home: const HomeFeedScreen()`(原 `home: const MainMenu()`)

**Step 3.4**:测试

- `test/features/home_feed/presentation/home_feed_screen_test.dart` ~6 case:
  - 空态显占位 + 快速领取仍可点
  - 非空态显金色 feed 列表倒序
  - 9 type 各显对应 icon / 颜色(可选)
  - 快速领取 mark isRead = true + pushReplacement 进 MainMenu
- `test/features/home_feed/application/home_feed_providers_test.dart` ~3 case:limit 截断 / occurredAt desc 排序 / 空 list

**验收**:
- cold start 进入 HomeFeedScreen(非 MainMenu)
- 30s 内可走完上线流程(主观验收,实测时间)
- 金色文字主题对齐 WuxiaColors 不用 Material 饱和色
- analyze 0 issues + test 全过

**commit**:`[feat] Phase 3 HomeFeedScreen 上线第一屏(replace main.dart home + 快速领取 + 金色 feed)`

### Phase 4:BaikeScreen 江湖见闻录(1-1.5h)

**Step 4.1**:新建 `lib/features/baike/presentation/baike_screen.dart`(~180 行)

- `Scaffold + AppBar('江湖见闻录')` + `TabBar(2 tab: 见闻 / 典故)`
  - **Tab 1 见闻**:GameEvent 全量列表(分页 `limit=50` 增量加载),沿 HomeFeed 体例但带 9 type filter chip(可选 P1.x 加,本批不做)
  - **Tab 2 典故**:`Consumer` 读 `equipmentLoreProvider`(`@riverpod Future<List<EquipmentLoreEntry>> equipmentLore(Ref ref)`),按 7 阶分组显示装备名 + 预设典故文案(Phase 5 后混排延续典故)
- 复用 `lore_loader.dart` 读 yaml,Phase 4 本批只显预设典故

**Step 4.2**:MainMenu 加入口按钮(11 → 12 按钮)

- `main_menu.dart`:在 `_MenuButton('师徒名单' lineage)` 后插入新按钮 `_MenuButton('江湖见闻录' baike)`(`mainMenuBaike` / `mainMenuBaikeHint`)
- onTap `_push(context, const BaikeScreen())`
- `lib/shared/strings.dart` 加 2 const
- `test/features/main_menu/...main_menu_test.dart`:按钮总数 11→12,顺序断言更新

**Step 4.3**:测试

- `test/features/baike/presentation/baike_screen_test.dart` ~5 case:
  - 见闻 tab 显 GameEvent 全量列表
  - 典故 tab 显 7 阶分组装备
  - 切换 tab UI 渲染正确
  - 空态(0 装备 / 0 GameEvent)显占位
  - 主菜单按钮 push 路由

**验收**:主菜单 12 按钮,江湖见闻录路由可入,2 tab 切换无 lag,analyze 0 issues + test 全过

**commit**:`[feat] Phase 4 BaikeScreen 江湖见闻录(2 tab + MainMenu 11→12 按钮)`

### Phase 5:延续典故动态追加 hook(0.5-1h)

**Step 5.1**:`GameEventService` 内 hook 延续典故追加

- `recordBossDefeated` 内部加分支:若 `bossDefeated event` 关联角色当前装备(`character.equippedIds`)非空,**为每件主战装备追加一段 Lore**:
  ```dart
  // 在 recordBossDefeated writeTxn 内,GameEvent put 之后
  for (final eq in character.equipment) {
    eq.lore.add(Lore()
      ..text = '${bossName}一战,${eq.name}伴你穿身,沾血未崩。'  // 占位文案,Phase 2 抽 yaml/DeepSeek
      ..isPreset = false
      ..addedAt = DateTime.now()
      ..triggerEventDesc = 'bossDefeated:$bossId');
    await isar.equipments.put(eq);
  }
  ```
- `recordEquipmentObtained` 同款:新获得装备追加首段延续典故 `'于 ${source} 得此 ${eq.name},初见锋芒。'`

**Step 5.2**:`EquipmentDetailScreen` 显化延续典故(混排)

- `lib/features/inventory/presentation/equipment_detail_screen.dart`:
  - 现有典故段读 `lore_loader` 预设 → 改读 `eq.lore` Isar 数据(预设 yaml 加载时 push `isPreset=true`,与延续混排)
  - 每段 Lore item 加 chip:`isPreset ? '·典故·' : '·延续·'`(色调区分,延续用墨青 `WuxiaColors.ink`)
  - 按 `addedAt` 倒序(预设 `DateTime(2000)` 永远沉底)

**Step 5.3**:测试

- `test/features/event/application/game_event_service_lore_hook_test.dart` ~4 case:
  - bossDefeated 触发主战装备 lore 追加,`isPreset=false` + `triggerEventDesc` 写入
  - equipmentObtained 触发新装备首段 lore
  - 非 boss 战不触发(stage `isBossStage=false`)
  - 重复 bossDefeated(防刷)不重复追加 lore(Phase 2 isFirstClear 已防 GameEvent 重写,lore 同步不发)

**验收**:打 boss 后装备详情有"·延续·"chip 标记的新 lore 段,卸下装备后仍持久;预设典故顺序不变;analyze 0 issues + test 全过

**commit**:`[feat] Phase 5 延续典故动态追加(bossDefeated/equipmentObtained hook + 详情屏混排)`

### Phase 6:test + analyze + closeout(1.5-2h)

**Step 6.1**:全量回归

- `flutter test` 期望 943 → ~980+(Phase 2 +20 / Phase 3 +9 / Phase 4 +5 / Phase 5 +4 共 +38)
- `flutter analyze` 0 issues
- 手动跑 `flutter build web` + http.server 预览(用户偏好"先看效果再调整",memory `feedback_cli_no_gui_screenshots` 但 Flutter Mac 端 visual check 需用户介入)

**Step 6.2**:closeout 文档

- `docs/handoff/p1_42_phase1_closeout_2026-05-17.md`:
  - 9 段销账(Phase 1-6 各一段 + 总览 + 验收 + 风险实测 + memory 教训沉淀)
  - test 数字 grep 实测(memory `feedback_closeout_numbers_grep` 实战:不依赖 spec 预估)
  - 6 phase 各自 commit hash + 实测耗时 vs spec 预估对比

**Step 6.3**:PROGRESS.md 销账 + ROADMAP_1_0.md v1.3 更新

- PROGRESS「当前阶段」加 P1 #42 Phase 1 销账段
- 「已知偏差」#42 改 `~~42.~~ ✅ Phase 1 销账`(留备注:§10 引导骨架 + DeepSeek 主线 Ch1 师父教学剧情对接推 Phase 2 P1.x)
- ROADMAP_1_0.md §P1 加销账段 + 修订记录 bump v1.2 → v1.3

**Step 6.4**:commit + push

- closeout commit:`[docs] Phase 6 closeout + PROGRESS 销账 + ROADMAP v1.3(P1 #42 Phase 1 收口)`
- `git push origin main` 同步全部 phase commit

**验收**:test 980+/980+ + analyze 0 issues + closeout 完整 + PROGRESS 销账 + ROADMAP v1.3 + 远程同步

---

## 5. 验收红线(spec 级,所有 phase 闭环后必过)

1. **公式语义零变化**:本 spec 0 涉及战斗公式,但 Phase 2 改 `BattleResolutionResult` 签名扩字段后,主线 / 爬塔 victory 后的装备共鸣升档行为必须与重构前 100% 等价(老 e2e 不退步)
2. **数值红线全守**:GDD §5.4 普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000 不动(本 spec 0 涉及数值)
3. **反主流 8 红线全守**:无教程弹窗 / 无任务列表 / 无登录奖励 / 无快进券 / 无 Material 饱和色 / 无 Dart 中文硬编码 / 无强制 modal / 无 tutorialStep 硬编码节奏数字
4. **GameEvent isRead 标记**:HomeFeedScreen 快速领取后所有 event mark isRead=true,BaikeScreen 进入不自动 mark(让用户主观决定"看过没")
5. **延续典故 isPreset 区分**:Phase 5 hook 写入的 Lore 必 `isPreset=false`,预设 yaml loader 路径必 `isPreset=true`,UI chip 必区分显示
6. **cold start 路由**:第一帧渲染 HomeFeedScreen,**非 MainMenu**(GDD §9.2 锁死)
7. **isFirstClear 防刷**:主线 / 爬塔 boss 重打不重复发 #8 GameEvent + 不重复追加延续典故 lore
8. **schema bump 单调**:`_currentSaveVersion` 0.9.0 → 0.10.0 单向,旧存档启动默认 `tutorialStep=0` 不抛
9. **test 增量**:本 spec 预期 +38 case(Phase 2 20 / Phase 3 9 / Phase 4 5 / Phase 5 4),最终 980+/980+
10. **analyze 0 issues**:每 phase commit 前必 `flutter analyze` 跑过

---

## 6. 风险 + 对策

### R1:Phase 2 BattleResolutionResult 签名扩字段破坏 25+ test 处直调

- **现状**:`battle_resolution_test.dart` 1004 行 + 多处 mock `BattleResolutionResult` 构造
- **对策**:`resonanceUpgradedEquipmentIds` 默认 `[]`(必填带默认),不 break 老 test;numbersConfig 已在 v0.4.0-w11 部分 victory 路径传过(`stage_entry_flow.dart:247` 已传),全场景检查
- **回退**:若破坏面 > 5 处,改 `BattleResolutionResult` 加 optional field + caller 端 nullable 解构

### R2:HomeFeedScreen cold start replace 破坏开发期 hot-reload 体验

- **现状**:dev 时每次 hot-restart 直进 HomeFeed,空 feed 看一次占位后快速领取进 MainMenu
- **对策**:`_QuickClaimButton` onTap 走 `pushReplacement`,不污染 route stack;空 feed 状态 1s 内一眼可走
- **回退**:若开发期影响调试,加 `kDebugMode + DebugMenu.skipHomeFeed: bool` 开关默认 false(Phase 6 验收看实际感受,不预设开关)

### R3:Phase 5 延续典故文案占位

- **现状**:Phase 5 hook 写的 lore.text 是 Dart 端占位文案(`'${bossName}一战,${eq.name}伴你穿身,沾血未崩。'`),违反 CLAUDE.md §5.6 不硬编码中文
- **对策**:**本 spec 暂留 Dart 端模板**(Phase 1 范围,延续典故内容雏形)+ closeout 标记挂账 `#44`(新挂账):**延续典故文案抽 yaml 推 DeepSeek 端写模板池**(Phase 2 P1.x 或 §10 单独冲刺)
- **风险锚**:memory `feedback_extension_hardcode_audit` extension on 硬编码高发区,Phase 6 closeout 必扫一遍 GameEventService 内是否漏抽

### R4:isFirstClear 主线判定 race condition

- **现状**:`MainlineProgress.clearedStageIds` 在 `recordVictory` 内追加,#8 bossDefeated 在 `recordVictory` 后 hook
- **对策**:Phase 2 实装时,#8 hook 用 `MainlineProgress.clearedStageIds` **本次 victory 前的快照**(进入 `recordVictory` 时 snapshot,判 `stageId not in snapshot` 即首通)
- **回退**:若 race 难写,fallback 用 `MainlineProgress.bossDefeatedStageIds: Set<String>`(新加字段)显式 set 持久化(schema bump 0.10.0 → 0.10.1)

### R5:GameEventService 跨 feature 引用 build_runner 失败

- **现状**:Riverpod codegen 需 @Dependencies 显式声明,memory `feedback_riverpod_lint_plugin_enable` 教训
- **对策**:`game_event_service.dart` 顶部 `@Dependencies([isarProvider])` 显式列依赖;`build_runner` 必跑(Phase 2 Step 2.1 后立即跑)
- **回退**:若 codegen 报错,降级用 `Provider` 手动(沿 wuxia_idle 历史套路)

### R6:HomeFeedScreen widget test pumpAndSettle 死锁风险

- **现状**:GameEvent feed 是 Future/Stream,widget test 有 NarrativeReader 异步死锁前车之鉴(memory `feedback_e2e_playwright_pitfalls` 类似)
- **对策**:沿 `stage_entry_flow_test` 体例(memory `feedback_e2e_playwright_pitfalls` W17 候选 F 实战),test 内用 `pump(Duration(ms))` 不 `pumpAndSettle`;mock GameEvent provider override 同步返回
- **回退**:若 pump 单帧仍不稳,加 `@visibleForTesting` 同步 mock provider hook

---

## 7. 测试矩阵

### 7.1 单元 / service 层(Phase 2)

| File | Case | 验证 |
|---|---|---|
| `game_event_service_test.dart` | 7 type 各 1 case = 7 + 边界 3 | 写入 occurredAt 倒序 / eventType 匹配 / characterId 入参 / nullable 防御 |
| `battle_resolution_test.dart` | +2 | `resonanceUpgradedEquipmentIds` 全量 stage 跨档检测 / 老 caller 不传 numbersConfig fallback 不退步 |
| `seclusion_service_test.dart` | +1 | `completeRetreat` writeTxn 内 GameEvent +1 行原子 |
| `encounter_service_test.dart` | +2 | `applyOutcome` 双发 #2+#5 / 仅 #2 单发(非 unlockSkill outcome) |

### 7.2 widget 层(Phase 3-5)

| File | Case | 验证 |
|---|---|---|
| `home_feed_screen_test.dart` | 6 | 空态 / 非空态倒序 / 9 type icon / 快速领取 mark isRead / pushReplacement / 时间相对格式 |
| `baike_screen_test.dart` | 5 | 2 tab 切换 / 见闻全量 / 典故 7 阶分组 / 空态 / 路由 push |
| `main_menu_test.dart` | +1 改 | 按钮数 11 → 12 + 顺序断言更新 |
| `equipment_detail_screen_test.dart` | +3 | 延续 lore chip 显化 / 预设+延续混排 / addedAt 倒序 |
| `game_event_service_lore_hook_test.dart` | 4 | bossDefeated 触发 / equipmentObtained 触发 / 非 boss 不触发 / 重复 boss 防刷 |

### 7.3 集成 / e2e 层(Phase 2 / 6)

| File | Case | 验证 |
|---|---|---|
| `stage_entry_flow_test.dart` | +2 | victory + boss → #6 + #3 + #8 GameEvent 三连发 + isFirstClear 重打不重复 |
| `tower_entry_flow_test.dart` | +2 | 同上,爬塔 floor 30 boss |

**预期总 case 增量**:+38(7+2+1+2 = 12 service / 6+5+1+3+4 = 19 widget / +2+2 = 4 e2e + 兜底 3),最终 943 → ~981

---

## 8. memory 引用(本 spec 起草已应用的纪律)

| memory | 应用点 |
|---|---|
| `feedback_phase0_grep_two_axes` | reality check 两维 grep(字段已落 + caller)分类 A/B/C 三类 |
| `feedback_model_selection` | 跨子系统建议升 opus xhigh,用户已指定全程 opus |
| `feedback_refactor_facade_callsite` | callsite ≥ 5 时抽 GameEventService helper(5+ caller 分散) |
| `feedback_layered_bugs` | Phase 2 7 caller 修上层后下层暴露,closeout 不静默吞 |
| `feedback_red_line_test_semantics` | test 红线断言写约束语义不写瞬时事实(eventType 匹配 / list 非空 / 不写具体数字) |
| `feedback_isar_pitfalls` | schema bump 0.9.0 → 0.10.0 单调 + 嵌套 writeTxn 警惕(GameEventService 在 caller writeTxn 内调) |
| `feedback_wuxia_pen_build_runner` | Phase 1/2 codegen 后必跑 `dart run build_runner build`(*.g.dart gitignored) |
| `feedback_closeout_numbers_grep` | Phase 6 closeout test 数字必 grep 实测不依赖预估 |
| `feedback_extension_hardcode_audit` | Phase 5 延续典故文案占位 R3 风险锚,closeout 必扫硬编码 |
| `feedback_clear_session_timing` | 6 phase 完成不强制清,同 P1 子系统纵深;若 Phase 4 / 5 后用户决定切单独 P1.x §10 再清 |
| `feedback_e2e_playwright_pitfalls` | Phase 3-5 widget test pump 不 pumpAndSettle,async dialog 死锁前车 |
| `feedback_invalid_assignment_dynamic_chain` | Phase 2 BattleResolutionResult 扩字段后 analyze 必跑,确认 import 链路无 dynamic 回退 |
| `feedback_session_close_prompt_on_demand` | closeout 末尾只 1 行清理建议,不主动输出新会话提示词 |

---

## 9. 决策日志

| 时刻 | 决策 | 拍板人 | 理由 |
|---|---|---|---|
| 2026-05-17 晚续 1 | 拍板范围选项 B(§9+江湖见闻+延续典故,§10 推 Phase 2) | 用户 | §10 跨多 Demo 系统 + DeepSeek 文案,Mac 端独立 spec 不闭环;§9+3 消费侧是闭环子系统 |
| 2026-05-17 晚续 2 | 抽 GameEventService helper(决策 1) | 用户 | 5+ caller 分散,callsite ≥ 5 符合 memory `feedback_refactor_facade_callsite` |
| 2026-05-17 晚续 3 | #2 + #5 拆两条(决策 2) | 用户 | 枚举本就拆,同次 applyOutcome 双发合理 |
| 2026-05-17 晚续 4 | §9 主屏独立 Screen replace home(决策 3) | 用户 | GDD §9.2 原文锁死"独立屏" + 快速领取 30s 流程 |
| 2026-05-17 晚续 5 | 模型档全程 opus | 用户 | memory `feedback_model_selection` 跨子系统建议升档 |
| 2026-05-17 晚续 6 | 6 phase 串行单 commit checkpoint | spec | sequential checkpoint 风险可控,每 phase 完成 commit + push,Phase 2 后 / Phase 4 后是自然会话边界 |
| 2026-05-17 晚续 7 | #4 techniqueLearned + #9 disciplePromoted 留接口不写独立 schema | spec | #4 0 业务 caller 等 Phase 5+ §7.2 / #9 借 #6 路由按 lineageRole 派生 eventType |

---

**spec 起草完毕。Phase 0 收口,Phase 1 SaveData schema bump 开工。**
