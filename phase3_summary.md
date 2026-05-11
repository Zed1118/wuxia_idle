# phase3_summary.md · 第三阶段交付摘要

> 滚动维护：每个 Week 结束追加摘要 + 截图 + 下一 Week 议题。

---

## Week 1 · 主线最小闭环（T33-T39，2026-05-11）

**目标**：把 Phase 1/2 的「装备+心法+战斗」上接到玩家主菜单入口，让 Demo
能从主菜单进章节 → 选关 → 看剧情 → 打战斗 → 结算 → 解锁下一关。

**分支 / tag**：`feat/phase3-mainline` → main no-ff，tag `v0.3.0-w1`。

### 交付清单

| T | 内容 | 测试 |
|---|---|---|
| T33 | stages.yaml schema 升级 + StageDef 加 prevStageId / narrativeOpeningId / narrativeVictoryId + 6 关 fixture backfill 链成 3 章 × 2 关 + GameRepository._enforceRedLines 加 stage 链路 fail-fast 校验 | +6 |
| T34 | MainlineProgress @collection（saveDataId / currentChapterIndex / clearedStageIds / clearedAt 同序）+ MainlineProgressService 4 API（getOrCreate / availableStages 三态 / recordVictory 幂等 / chapterCompleted）+ StageStatus enum + IsarSetup schema 加 + saveVersion 0.1.0 → 0.2.0 | +12 |
| T35 | mainline_providers 3 个 + ChapterListScreen（3 章卡：cleared ✓ / inProgress 高亮 / locked 灰锁）+ StageListScreen（三态行：cleared 绿勾 / available 主色 / locked 锁）+ main_menu 加「主线」按钮置首位 + SingleChildScrollView 防 6 按钮溢出 | +6 |
| T36 | NarrativeLoader（缺文件/损坏/非 map 顶层全部兜底 placeholder，不抛异常）+ NarrativeReaderScreen（一段一页 + 段落淡入 + 跳过 + placeholder 弱提示） | +11 |
| T37 | StageBattleSetup 装配双队（左队从 SaveData.activeCharacterIds 接 BattleCharacter.fromCharacter；右队 EnemyDef → BattleCharacter，characterId 用 -(slot+1)）+ runStageFlow async 串联 opening → battle → victory/defeat + BattleScreen 加 onVictory/onDefeat 回调（保留 onBattleEnd 兼容）；**销 PROGRESS #22 P2/P4 战斗 stub** | +7 |
| T38 | docs/NARRATIVE_SCHEMA.md：DeepSeek 端剧情 yaml 格式约定（命名 / id / paragraphs / 占位 / Week 1 待写 12 文件清单 / 章节标题映射） | — |
| T39 | Pen 视觉验收 5 截图归档 + 本 summary 起头 + tag v0.3.0-w1 | — |

**累计测试**：335（Phase 2 末）→ 377（Week 1 末，+42）/ analyze 0 issues。

### 视觉验收（Pen Windows，2026-05-11 19:26）

| # | 截图 | 验收点 |
|---|---|---|
| 01 | [01_main_menu_with_mainline.jpg](screenshots/phase3_w1/01_main_menu_with_mainline.jpg) | 主菜单 6 按钮顺序：主线 → Phase1 → Phase2 → 角色 → 装备 → 心法；「主线」副标题「3 章 6 关，按章节顺序解锁」 |
| 02 | [02_chapter_list.jpg](screenshots/phase3_w1/02_chapter_list.jpg) | 章节列表 3 章：Ch1 学武出山「进行中」金色高亮边框 / Ch2 武林初识 锁灰 / Ch3 名扬江湖 锁灰；章节简介路由正确 |
| 03 | [03_stage_list_ch1.jpg](screenshots/phase3_w1/03_stage_list_ch1.jpg) | Ch1 关卡列表：山道试剑「3 名敌人 / 可挑战」金色 chip ✓；林间伏击「通关前一关解锁」灰锁；prev 链顺序与 stages.yaml T33 backfill 一致 |
| 04 | [04_narrative_placeholder.jpg](screenshots/phase3_w1/04_narrative_placeholder.jpg) | 剧情阅读 placeholder：顶部「⚠ 剧情占位（DeepSeek 待补）」弱提示 + 段落「[剧情待补：mainline_test_01_opening]」+ 1/1 + 「完成」按钮 + 跳过；**NarrativeLoader 缺文件兜底完美工作**（T36 设计核心） |
| 05 | [05_battle_setup_fail_p1_no_main.jpg](screenshots/phase3_w1/05_battle_setup_fail_p1_no_main.jpg) | 战斗准备失败兜底屏：`StageBattleSetup: 角色 测试角色 未修主修，无法进入战斗`；说明 T37 流程串联完整（opening 完 → push battle host → catch 兜底）；fixture 限制（P1 不创建主修），见 §已知偏差 |
| 06 | [06_p3_technique_panel.jpg](screenshots/phase3_w1/06_p3_technique_panel.jpg) | P3 种子生效证明：心法面板显示主修「刚猛 · 圆满 1500/1500」红条 + 辅修「阴柔 · 大成 0/900」紫条 + 「设为主修」按钮；与 phase2_seed_service.dart P3 fixture 一致（tech_gangmeng_mingjia / tech_yinrou_mingjia） |
| 07 | [07_battle_in_progress.jpg](screenshots/phase3_w1/07_battle_in_progress.jpg) | 战斗中 1v2 回合 10：测试角色（红圈「测」二流圆熟 HP 10344/11000 IF 8820/10000）vs 流民甲乙丙（乙已击杀灰显）；飘字 374/282；战斗日志「[第 7 tick] 测试角色 用『裂石掌』对流民乙 18079 伤害 灵巧克刚猛 ×0.75 击杀」 |
| 08 | [08_battle_victory_dialog.jpg](screenshots/phase3_w1/08_battle_victory_dialog.jpg) | 战斗胜利结算 dialog：1v0 回合 19 / 左队胜 / 总伤害 72000 暴击 0 用时 19 tick / 「返回菜单」按钮；onVictory 路径触发，后续 narrativeVictoryId placeholder + 回 Ch1 关卡列表（01 ✓ + 02 解锁）经 Pen 操作确认全部正常（视觉同 04 + 03 设计） |

### 已知偏差 / Phase 4 跟进

- **P1 fixture 缺主修，主线进入需先跑 P3**：Phase2SeedService.seedP1 不创建心法（沿用 Phase 2 P1 spec：仅装备+材料），导致直接 P1 → 主线进战斗时 StageBattleSetup fail-fast。当前 workaround：先在主菜单点 `Phase 2 调试场景 → P3 散功代价` 跑一次种子（P3 fixture 含主修），再回主线即可正常进战斗。Phase 4 重写 fixture 时一并修（让 Demo 默认入口直通主线战斗）。

### 下一 Week 议题（待与用户讨论拍板）

候选方向（GDD §7-§8 + CLAUDE §7）：

- **A. 爬塔 30 层**：3 小 Boss [5/15/25] + 3 大 Boss [10/20/30]，新 TowerProgress collection + 闯关 UI；纯结构化系统，与主线解耦
- **B. 闭关地图 5 张**：兵器/心法/属性/共鸣/...，需先决 §12 #5 每小时产出公式
- **C. 奇遇 20-30**：encounters.yaml 触发条件（Mac）+ events/ 文案（DeepSeek），需先决 §12 #6 机缘值累积规则
- **D. 师徒传承**：祖师+大弟子+二弟子 数据 model + 遗物三系锁死校验，§12 #10/#11 待决
- **E. 武学领悟 30-50 招**：插槽机制 + 触发条件，§12 #6 机缘值累积待决

**优先级建议**（待 Pen 反馈玩 Week 1 截图后体感）：A 与主线最解耦、最容易 Week 2 完整跑通；D/E 需要先决多个 §12 待决项，更高复杂度。

---

## Week 2 · 爬塔 30 层（T40-T46，2026-05-11）

**目标**：完整实现「问鼎九霄」30 层爬塔系统，含数据层 / 进度持久化 / 层列表 UI / 进入流程串联 / 奖励 hook / Pen 视觉验收。

**分支 / tag**：`feat/phase3-tower` → main no-ff，tag `v0.3.0-w2`。

### 交付清单

| T | 内容 | 测试增量 |
|---|---|---|
| T40 | `towers.yaml` schema（30 层 fixture，每 5 层升境界，Boss ×1.5，1/2/3 人 ×1.0/0.7/0.55 scale）+ `TowerFloorDef`（fromYaml / isBoss）+ `enum TowerBossKind` + `GameRepository._enforceTowerRedLines`（30 层连续 / Boss 严格 5·10·…·30 / 普通层 narrative 必 null / 敌人数 [1,3] / baseHp ≤ 50000） | +13 |
| T41 | `TowerProgress @collection`（saveDataId / highestClearedFloor / totalAttempts / totalDefeats）+ `TowerProgressService` 6 API（getOrCreate 幂等 / availableFloor 封顶 30 / canChallenge / floorList 30 行三态 / recordClear 返回 `({isFirstClear, highestAfter})` / recordDefeat 不退层）+ IsarSetup schema 加 + saveVersion 0.2.0→0.3.0 | +15 |
| T42 | `tower_providers`（2 FutureProvider）+ `tower_floor_list_screen`（进度卡 + ListView 30 行 + initState 滚到 available）+ `tower_floor_card`（三态 + Boss 金/紫边框 + 推荐境界 chip + 已通关重打 AlertDialog）+ `main_menu` 第 2 位「问鼎九霄」按钮 | +6 |
| T43 | `runTowerFlow` async 状态机（opening→battle→victory/defeat）+ `_TowerBattleHost`（ConsumerStatefulWidget，initState 调 `StageBattleSetup.buildTeamsForTower`）+ `@visibleForTesting` DI 三路注入 + `StageBattleSetup` 重构（buildEnemyTeam public / buildTeamsForTower 爬塔版） | +5 |
| T44 | `DropService.rollTowerRewards`（从 `TowerFloorDef.dropTable` 按 weight 随机）+ `_persistDrops` Isar writeTxn（guard: `Isar.getInstance`）+ `_showVictoryDialog`（首通列掉落 / 重打显示「重打不发奖」） | +4 |
| T45 | 全量 `flutter test` + `dart analyze` 双绿（420/420，0 issues） | — |
| T46 | Pen Windows 视觉验收 3 截图 + tag v0.3.0-w2 + merge main | — |

**累计测试**：377（Week 1 末）→ 420（Week 2 末，+43）/ analyze 0 issues。

### 视觉验收（Pen Windows，2026-05-11）

| # | 截图 | 验收点 |
|---|---|---|
| 01 | pen_t46_maxmenu.png | 全屏 1920×1080 主菜单，7 按钮完整可见：「主线」第 1 / **「问鼎九霄」第 2**，副标题「30 层，无限重试，永久记录」 ✅ |
| 02 | pen_t46_floor_list.png | 爬塔层列表：顶部进度卡「已通 0/30 层 · 总尝试 0 · 失败 0」/ 第 1 层「可挑战」金色 / 第 2-30 层「灰锁」/ **第 5 层 Boss 金色粗边框 + 小 Boss chip** ✅ |
| 03 | pen_t46_floor1.png | 第 1 层战斗入口 → 「战斗准备失败」兜底屏（P1 fixture 缺主修，#25 已知偏差，T43 `_TowerBattleHost` 错误捕获正确） ✅ |

### 已知偏差 / Phase 4 跟进

- **#25 P1 fixture 缺主修，无法演示实际爬塔战斗**：workaround 同 Week 1（先跑 P3 种子）。Phase 4 重写 Demo 入口 fixture 时修复。
- **爬塔胜利弹窗（`_showVictoryDialog`）**：代码 + widget test 完整，但因 #25 Pen 端无法演示到 live 胜利画面；后续 Phase 4 fixture 修复后即可演示。

### 下一 Week 议题

Week 3 候选（开工前需先决 §12 待决项）：

- **B. 闭关地图 5 张**：需先决 §12 #5（每小时产出公式 / 挂机结算规则）
- **C. 奇遇 20-30**：需先决 §12 #6（机缘值累积规则），与 DeepSeek 端 events/ 联动
- **D. 师徒传承**：需先决 §12 #10/#11（传递时机 / 多徒弟继承 / 祖师爷 buff 内容）
- **E. 武学领悟 30-50 招**：需先决 §12 #6（同 C）

建议先讨论 B 或 C，两者都有 §12 待决项但范围可控；D/E 牵涉更多未知量。
