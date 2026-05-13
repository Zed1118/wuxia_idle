# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

**Phase 3 Week 8 T64 心法扩 21 本 + 招式扩 63 招**(2026-05-13)。详条见「已完成」末。W7 T63 / W6(详条 docs/handoff/week6_full_closeout_2026-05-14.md)同左。

## 已完成

- **Phase 1 T01-T18**（2026-05-10/11，tag v0.1.0-phase1）：脚手架 / 18 枚举 / 5 Def 类 + GameRepository 红线校验 / DamageCalculator 7 阶段公式 / BattleEngine + battleLog / 3v3 战斗 UI + Riverpod + 大招 overlay。160/160 测试 + 5 战例误差 ≤1.1%。详条 `phase1_summary.md`
- **Windows 视觉验收 T15/T16/T17**（2026-05-11，Pen 5 截图）：A 普伤 2613 ✅ / B 1.67× / C 1.92× / D 8370 一击杀；动画/飘字/HP 三段色/Opacity 0.3/大招置灰全部正常；销账 #20
- **Phase 2 T19-T32 装备 + 心法 + 战斗联动 + UI**（2026-05-11，tag v0.2.0-phase2，merge 5efe8d5）：EquipmentFactory/Rng / EnhancementService 4 段成功率 + 心血结晶 / ForgingService 3 槽开锋 / 装备战斗加成 + 师承内力上限 / TechniqueLearning 4 类 fail-fast / CultivationService recordSkillUsage + 散功算法 A / BattleResolutionService 战斗结算 hook / DropService sealed DropEntry / 4 UI 面板（角色 / 仓库+强化 / 开锋 / 心法+散功）/ Phase2SeedService 4 场景 / phase2_scenarios_test 11 用例 / 6 截图。累计 333/333，详条 `phase2_summary.md` + git log
- **T24 fixup #24 装备名渲染**（2026-05-11，fix/24-equipment-name）：inventory_row + enhance_dialog 接 EquipmentDef.name + Flexible/ellipsis；2 widget test，累计 335
- **Phase 3 Week 1 T33-T39 主线最小闭环**（2026-05-11，tag v0.3.0-w1，feat/phase3-mainline → main）：stages.yaml schema 升级（prevStageId / narrativeOpeningId / narrativeVictoryId）+ 6 关 backfill 3 章 × 2 关 / MainlineProgress @collection + MainlineProgressService 4 API / 章节列表 + 关卡列表 UI + 主线按钮接 main_menu / NarrativeLoader 缺文件兜底「[剧情待补]」 + 阅读 UI / StageBattleSetup + runStageFlow 串联 opening → battle → victory/defeat / docs/NARRATIVE_SCHEMA.md / 8 Pen 截图归档。累计 377/377（+42）。详条 `phase3_summary.md` §Week 1 + git log T33-T39。**销 #22**
- **T40 towers.yaml schema + TowerFloorDef + 30 层 fixture**（2026-05-11，feat/phase3-tower，commit `511264e`）：`enum TowerBossKind { minor, major }` + `TowerFloorStatus` 加 enums.dart；`lib/data/defs/tower_floor_def.dart` 新建（floorIndex/requiredRealm/enemyTeam/bossKind/narrativeOpening|VictoryId/dropTable + fromYaml + isBoss）；`data/towers.yaml` 30 层 fixture（每 5 层升一阶学徒→宗师，普通层单兵 HP 800→10000 / ATK 200→1500 线性，Boss × 1.5，1/2/3 人队 ×1.0/0.7/0.55 scale）；GameRepository 加 towerFloors + `_enforceTowerRedLines`（30 层连续 / Boss 严格 5·10·15·20·25·30 / 普通层 narrative 必 null / 敌人数 [1,3] / Boss 1 人 / baseHp ≤ 50000）+ `getTowerFloor` 便捷查询；test 加 13 用例（fromYaml 3 + 集成 6 + fail-fast 4），累计 390/390
- **T41 TowerProgress @collection + TowerProgressService**（2026-05-11，feat/phase3-tower）：`@collection TowerProgress`（saveDataId/highestClearedFloor/highestClearedAt/totalAttempts/totalDefeats/createdAt）；service 6 API（getOrCreate 幂等 / availableFloor 封顶 30 / canChallenge 边界 / floorList 30 行三态 / **recordClear 返回 `({isFirstClear, highestAfter})`**：仅 floorIndex==highest+1 才 ++ 否则 isFirstClear=false 不抛 / recordDefeat 仅增统计不退层）；IsarSetup 加 TowerProgressSchema + saveVersion 0.2.0→0.3.0；isar_setup_test 同步改期望值；test 加 15 用例（接真 Isar 临时目录，覆盖跳层非法/与 MainlineProgress 独立校验），累计 405/405
- **Phase 3 Week 3 T47-T52 闭关地图 v0.3.0-w3 交付**（2026-05-11/12，tag `v0.3.0-w3`，merge d37d09d）：5 张闭关地图 fixture（mountain/cave/temple/lake/ancient_battlefield）+ `SeclusionMapDef` + `RetreatConfig` / `RetreatSession @collection` + `SeclusionService`（start/compute/complete/abandon）/ 地图列表、选时长、进行中、收功结果 4 UI 屏 + main_menu「闭关修炼」入口 / saveVersion 0.3.0→0.4.0。405→457（+52）测试，analyze 0 issues。**T52 Pen Windows 视觉验收通过**（2026-05-12）：① 收功后 result 显示完整 + 返回 list 刷新 OK ② 同 ItemType 经 Phase2/闭关/爬塔多路写入后 InventoryItem 不分裂 OK。同 merge 一并带入 DeepSeek 端 narrative schema 拆分（32ae3f3），Mac 端 NarrativeLoader 适配挂账 #27 待开工。
- **P1 #1 narrative schema Mac 端接手**（2026-05-12，销账 #27）：NarrativeLoader 扫 `data/narratives/stages/` 子目录（扁平→子目录→placeholder 三段兜底）；stages.yaml 6 关 stage_id 迁移 `mainline_test_NN → stage_NN_NN`，narrativeOpeningId/VictoryId + prevStageId 全链对齐 DeepSeek 拆分；全仓库 ~67 处 hard-coded `mainline_test_0` 引用 sed 批量重命名；narrative_loader_test 新增 2 case（扁平缺失→子目录命中 + 双缺失调用顺序契约）；stage_list_screen_test 「点关卡进剧情」case 改证「真实文案『山门之外 · 启』可加载」。**widget 端验证 main 主线剧情已脱离 placeholder regression**。493→495 测试，analyze 0 issues。涉及 10 文件 +172/-106。
- **Phase 3 Week 4 T53 masters.yaml schema + MasterDef + 红线校验**（2026-05-13，commit `9349626`）：`lib/data/defs/master_def.dart` 新建（MasterDef + AttributeProfile 纯 Dart 不入 Isar）；`data/masters.yaml` 3 角色 fixture（祖师一流/大弟子二流/二弟子三流，方案 A 降级避飞升）；`GameRepository.masters` 字段 + `_enforceMasterRedLines` 7 项（3 条 / slotIndex 连续 / role 与 slot 对应 / founder 唯一 / 不允许 wuSheng / 属性单项 1-10 总和 16-24 / 三系锁死 starting tier ≤ defaultRealm）+ `getMasterBySlot` / `getFounderMaster` 便捷查询；test +10（MasterDef.fromYaml 3 + 师徒红线 fail-fast 7），累计 495 → 505。祖师遗物 isLineageHeritage 校验留 TODO 待 T55
- **Phase 3 Week 4 T54 seedMasterDisciple + P5 入口 + 销账 #25**（2026-05-13，commit `ed8b183`）：`Phase2SeedService.seedMasterDisciple` 一次 writeTxn 完成 3 师徒 + 双向关系 + 9 件装备（EquipmentFactory.fromDef 标准 roll）+ 4 本心法（祖师 main+assist / 2 弟子 main 各 1）+ SaveData.activeCharacterIds=[1,2,3] + founderCharacterId=1 + 基础物料 2000 磨剑石/200 心血结晶；P5 按钮接入 `phase2_test_menu` 跳 CharacterPanelScreen；test +6（3 师徒结构 / 装备心法齐 / 主修流派透传 / reseed 一致 / 与 P1 切换边界 / **销账 #25：buildTeams 不再 fail-fast**）+ widget test 4→5 同步，累计 505 → 511
- **Phase 3 Week 4 T55 EquipmentDef.isLineageHeritage + 祖师遗物红线启用**（2026-05-13，commit `1418176`）：EquipmentDef 加 `isLineageHeritage` 字段 + fromYaml 读 key（camelCase 对齐 schoolBias 体例）；equipment.yaml 标 2 件遗物 fixture（祖师传家剑 weapon_liqi_long_quan + 传家护甲 armor_haojiahuo_jin_pao），仅加一行不动平衡值；EquipmentFactory.fromDef 函数体 OR `def.isLineageHeritage` → drop / 师承种子统一行为，参数保留为 override；GameRepository 启用祖师遗物红线（解 T53 TODO，祖师 startingEquipmentIds 必须 ≥ 1 件 def.isLineageHeritage=true）；test +5（fromYaml 字段 1 + Factory 透传 3 + 红线 fail-fast 1），累计 511 → 516。**运行时副作用**：祖师战斗内力上限自动 +5%（GDD §5.3 师承遗物 buff 在 Demo 路径首次落地，derived_stats.internalForceMaxWithLineage 已存在）
- **Phase 3 Week 4 T56 角色面板「师承」段 UI + 销账 #26**（2026-05-13）：`CharacterPanelScreen` 改 ConsumerStatefulWidget，顶部 TabBar 三段切换（祖师/大弟子/二弟子，按 `activeCharacterIdsProvider` 顺序，构造参数指首屏 Tab）；新增 `_LineageSection`（4 行：师父姓名 / 徒弟姓名 join / 「[传记待补]」占位 / 遗物名 join，遗物名走 GameRepository.equipmentDefs[defId].name）；新增 `activeCharacterIdsProvider`（读 SaveData.activeCharacterIds）；MainMenu 改 ConsumerWidget + 新建 `_SeclusionMenuButton`（Riverpod `.when()` 异步读首位角色 realmTier，loading→Opacity 0.4 disabled，error/null→ fallback id=1/xueTu），**销账 #26**（main_menu.dart:77-78 硬编码已移除）；character_panel test +4（3 Tab 渲染 / Tab 切换 / 师承段 4 行 / 内力 lineage +10%）+ main_menu test +2（按钮 Opacity 1.0/0.4），累计 516 → 522。UI 视觉验收留 Windows Pen
- **Phase 3 Week 4 T57 3v3 默认入阵 + 战斗集成测试 + T55 战斗路径补齐**（2026-05-13）：`test/services/master_disciple_battle_test.dart` 6 用例端到端：3 师徒装配完整 / 境界对齐 masters.yaml / 装备攻击+招式+内力正确 / 祖师 maxInternalForce 含 lineage +10% / victory leftWin / defeat path 不阻塞（人造 left 全员阵亡 → isFinished + 非 leftWin + availableSkills 保留）。**顺手修 T55 commit message 误导**：`BattleCharacter.fromCharacter` 之前 `maxInternalForce: character.internalForceMax`（直接字段值不含 lineage），改用 `CharacterDerivedStats.internalForceMaxWithLineage(character, equipped, numbers)` —— T55 "祖师战斗内力 +5%" 现真正落地战斗路径，不仅 UI；battle_state_test +1（师承遗物 2 件 → maxInternalForce 含 +10%）。累计 522 → 529（+7）
- **Phase 3 Week 4 T58 Pen 视觉验收 + tag v0.3.0-w4**（2026-05-13，Pen 13:44-13:53 一气呵成）：8 截图归档 `docs/screenshots/phase3_w4/`，覆盖 P5 种子按钮 / 角色面板 3 Tab 切换（祖师/大弟子/二弟子各 1 张）/ 师承段 4 行完整 / 山门之外·启 narrative / stage_01_01 3v3 victory + 战斗日志 / 关卡列表通关旁证。**核心验收点**：祖师 UI 内力 3800/4180（lineage +10% 实测落地）/ 师承段「龙泉剑/锦袍」遗物名走 GameRepository 解析 / 3v3 同阵 7 tick 速胜 / 刚猛+灵巧+阴柔三流派克制 ×0.75 全部触发。**Pen 端首跑环境基线失败**根因：T56 新加 `activeCharacterIdsProvider` 但 `*.g.dart` 全 gitignored，Pen 本地缺生成产物 → spec 补 build_runner 步骤后通过（memory `feedback_wuxia_pen_build_runner.md` 记新踩坑）。phase3_summary.md Week 4 段完整 + tag v0.3.0-w4 push origin
- **Phase 3 Week 5 T59 stages.yaml 6→15 关 + narrativeDefeatId schema**（2026-05-13）：StageDef 加 `narrativeDefeatId`（fromYaml + 构造函数）/ stages.yaml 全量重写 3 章 × 5 关（Ch1 学徒 1.0→1.8 / Ch2 三流 1.5→2.3 / Ch3 二流 2.0→2.8 难度递增）/ 章末两关 4/5 isBossStage=true 配 defeat 文案对齐 DeepSeek 6 个 defeat 文件（stage_NN_04/05_defeat.yaml）/ 数值梯度按 GDD §3 三阶守红线（xueTu HP 1500-3500、sanLiu HP 3500-7000、erLiu HP 7000-11000） / 现 6 关数值层与 DeepSeek narrative 编号不对齐的旧账一并修（stage_02_02 黑风寨 Boss → 改为 sanLiu 中段「茶馆论剑」普通关、stage_03_02 一战封王 → 改为 erLiu 中段「许昌擂台」、章末大 Boss 重定位到 stage_NN_05）。**新增 GameRepository._enforceMainlineRedLines**：mainline 总数=15 / 3 章 × 5 关 / narrativeDefeatId 必须仅在 isBossStage=true 关。test/data/game_repository_test 新增「主线 15 关红线」用例 + 既有 5 个测试期望同步更新（stageDefs.length 6→15 / dropTable 计数 / mainline_progress_service Ch1 全通=5 关 / chapter_list_screen 全 15 关通关 / stage_list_screen 5 关全名 + 锁数）。529 → 530 测试，analyze 0 issues
- **Phase 3 Week 5 T60 stage_entry_flow 战败 narrative hook + 销账 #29**（2026-05-13）：runStageFlow 战败分支改写——若 `stage.narrativeDefeatId != null && context.mounted` → push NarrativeReaderScreen（content 走 NarrativeLoader.load，缺文件兜底「[剧情待补]」），看完 pop 回 stage list；不记录进度 / 不掉装备（Phase 4 再加战败结算）。章内普通关（无 narrativeDefeatId）战败分支保留旧行为直接返回 list。dartdoc 注释更新「3b. defeat」段说明 Boss 关 vs 普通关分流
- **Phase 3 Week 5 T62 Pen Windows 视觉验收 + 2 旁支 fix + tag v0.3.0-w5**（2026-05-13，Pen 14:56-15:23）：6 截图归档 `docs/screenshots/phase3_w5/`。**核心销账截图 06**：风雨渡口·败 NarrativeReaderScreen 标题 + 文案「撑伞的人没有追。他只是站在雨里，看着你退回渡口。」+ 1/3 分页 + 继续按钮（T60 defeat hook 视觉落地）。**截图 05** 战斗右队胜 0v2 17 tick 玩家方全阵亡（erLiu 跨 2 阶设计生效）。**旁支 fix 1**：CharacterPanelScreen 无返回按钮（T56 加 Tab 时遗漏）→ commit `87387ad` AppBar + BackButton（canPop 才显示）。**旁支 fix 2**：stage_01_05 原 xueTu yuanShu 玩家方碾压（10 tick 左队胜 21673 总伤）→ balance commit `73c1f37` 跨 2 阶到 erLiu（撑伞高人 10000HP 750Atk / 渡口刀客剑客 9000HP 700-720Atk），设计语义「章末大 Boss 暗示需升阶」。phase3_summary.md Week 5 段完整 + tag v0.3.0-w5 push origin
- **Phase 5 W6 升级 + 架构重构 tag v0.3.0-w6**(2026-05-14):isar→isar_community 3.3.2 / flutter_riverpod 3.x / riverpod_annotation 4.x / riverpod_generator 4.x / analyzer 5.x→9.x。8 个有 Isar 依赖的 service 改实例化 + 构造函数接 Isar;新 `IsarSetup.instanceOrNull` + nullable isarProvider + 9 个 service provider,widget test 自动短路(替代旧 widget `Isar.getInstance` guard,4 处全删)。**销账 #23**(架构层面)。530/530 测试,详条 `docs/handoff/week6_full_closeout_2026-05-14.md`
- **Phase 3 Week 7 T63 装备 fixture 扩 10→35 件 + 覆盖度红线**(2026-05-13):equipment.yaml 7 阶 × 5 件重写(weapon 3 三流派 + armor 1 + accessory 1);数值范围照搬 numbers.yaml tier 段;drop_source_tags 占位(Phase 4 回填)。GameRepository 抽 `_enforceEquipmentRedLines`:单件 baseAttackMax ≤ 2000 + 覆盖度三件套(每阶 ≥5 件 / 每阶 weapon 三流派齐 / armor + accessory 各 ≥1)。test +2 fail-fast,累计 530 → 532
- **Phase 3 Week 8 T64 心法扩 6→21 本 + 招式扩 18→63 招 + 覆盖度红线**(2026-05-13):techniques.yaml 按 7 阶 × 3 流派重写(+15 本,changLian/menPai/jiangHu/shiChuan/chuanShuo 各 3 流派);skills.yaml 21×3=63 招,每本 basic/skill/ult 各 1,数值梯度 basic=500/skill=80%cap/ult=cap(对齐 numbers.yaml `techniques.tiers.max_skill_multiplier` 软约定);命名(常练:横扫拳/破甲掌/穿云剑/万剑诀/拂袖手/销魂指 等;绝学:落雷掌/怒龙翻/燕回身/流星剑/鬼影爪/摄魂引;秘传:裂山掌/霸王击/凌波剑/御剑诀/魅影手/摧魂咒;失传:玄武拳/天崩裂/太虚剑/长虹经天/蛛丝手/阴煞印;传说:玄黄拳/九霄龙吟/太初剑/万象归元/幽冥指/无相劫)。GameRepository 加 `_enforceTechniqueRedLines`:7 阶 × 3 流派组合每个 ≥1 本 + 每本 skillIds.length==3 + 每本 3 招 type 精确 {normalAttack, powerSkill, ultimate} + 每招 parentTechniqueDefId 指向自身。test +2 fail-fast(组合缺失 / 招式 type 错位),累计 532 → 534

## 进行中

**Phase 3 Week 8 T64 心法扩 21 本 ✅**(2026-05-13)。Mac 端代码完成 534/534。无 UI 改动,Pen 视觉验收非必需。

## 已知偏差 / 挂账事项

2. **lib/ 目录结构**：CLAUDE.md 写 DDD，实际用 phase1_tasks 的 flat。Phase 5 整理
3. **`riverpod_lint` 仍未引入**（W6 重评估）：analyzer 已升 ^9 解开 isar 链路上限,但 custom_lint 0.8.x 锁 analyzer ^7.5/^8 与 riverpod_generator 4.x 链路 ^9 互斥；等 custom_lint 升级支持 analyzer ^9 再补
4. **IDS_REGISTRY.md 自报「143 个内容 ID」错误**：实际 238 个，等 DeepSeek 改
6. **GDD §5.3/§5.6 公式系数 vs numbers.yaml**：GDD 字面 ×8 / ×5 是「口误」，代码以 yaml 平衡值（×1.0 / ×0.7）为准
7. **numbers.yaml 节气列表混入「中秋」**：中秋是农历节日不是节气，GDD 没明确 24 节气，待定
8. **CLAUDE.md §12 待人类决策清单 13 条**：境界/修炼度层重名等，实现到对应位置时按需提问
9/11. **T05/T07 验收**：Mac 无 Xcode 跑不了 desktop，留 Windows 首跑验
10. **yaml key 命名约定差异**：numbers.yaml snake_case，内容 yaml camelCase，按文件类型隔离不冲突
12. **`LevelDiffModifier.diff3OrMore.attacker` 数据层 vs 公式层语义不同**：NumbersConfig 兜底为 diff2.attacker(=2.5)，公式层取 1.0，Phase 5 收尾改
17. **phase1_tasks T12 §709 笔误**：差 2 守方 0.05 错（实际差 2 守方=0.3，差 3+ 才 0.05），「必败」语义仍成立
~~18. flutter build web 被 Isar 阻塞~~ **W6 验证为伪挂账（2026-05-14）**：项目无 web platform target（GDD §2 Windows 单平台），isar_community 仍 native-only 不重要
~~23. widget test 不接真 Isar~~ **架构层面已销账（2026-05-14 W6-S2）**：service 实例化 + nullable propagation 替代旧 widget _persist 的 Isar.getInstance guard。widget 端 `ref.read(xxxServiceProvider)` 返回 null 时短路。FakeAsync vs 真 Isar 的底层不兼容仍在,但不再污染生产代码
~~25. Phase2SeedService.seedP1 缺主修~~ **已销账（2026-05-13 T54）**：seedMasterDisciple 路径 3 师徒齐主修，主菜单点 P5 后可直接进主线战斗。P1 fixture 自身仍是无主修（保留体例），玩家从 P1 入口进战斗的旧路径未修复——若需修复请走 P5 入口
~~26. 闭关入口硬编码 characterId=1 / RealmTier.xueTu~~ **已销账（2026-05-13 T56）**：`MainMenu` 改 ConsumerWidget，`_SeclusionMenuButton` Riverpod `.when()` 异步读 `activeCharacterIdsProvider` 首位 + `characterByIdProvider(firstId)` 解析 realmTier；loading 时按钮 Opacity 0.4 disabled，error/空 fallback 到 `id=1/xueTu`（保留旧默认作为不可达兜底）
28. **闭关 widget 端到端 test 缺失（P2 #3 后续）**：P2 #3 修复了 setup→active→result 导航链，但 SeclusionService 是 static 方法无法 mock，widget test 接真 Isar 阻塞（#23 同源），暂只能靠 Pen 视觉验收兜底。Phase 5 service 注入后补「开始闭关 → 收功 → 返回 list 刷新」端到端 widget test
~~29. defeat hook + 9 关扩容~~ **已销账（2026-05-13 T59+T60）**：stages.yaml 扩到 15 关（3 章×5 关）+ narrativeDefeatId schema + GameRepository 主线红线 + stage_entry_flow 战败路径 push NarrativeReaderScreen（Boss 关 4/5 才触发，普通关战败直接返回）。对齐 DeepSeek 30 narrative + 6 defeat 文件。仅 Pen 视觉验收 T62 待跑
30. **闭关 3 个扩展维度未接 service**（§12 #5 收口留尾，2026-05-13）：`numbers.yaml retreat` 已配 `technique_learn_rate` / `internal_force_growth` / 节气日 +30% / 正午阳刚 +20%，但 `seclusion_service.computeOutputs` 仅消费 mojianshi/experience/equipmentDropRate/子时。前两项依赖 Character 修炼度/内力字段（与挂账 #25/#26 同源），节气日依赖农历库 + 完整节气清单（与挂账 #7 同源）。Phase 4 fixture 改造 + 农历库选型后一并接入

> 已解决条目（#1/#5/#13/#14/#15/#16/#19/#20/#21/#22/#24/#26/#27，T52 Pen 视觉验收 2026-05-12）见文末归档。

## 下一步

W9 候选(W8 后):A 爬塔 UI(schema 已 W2 ready,缺 UI 串联)/ Phase 4 战斗结算扩展(掉装备/境界/散功代价,需先讨论范围)/ #30 闭关 3 维度(§12 #7 节气清单阻塞)/ C 奇遇 + E 武学领悟(§12 #6 机缘值规则阻塞)。

> CLAUDE.md §12 #1（境界 vs 修炼度名重叠）实质消解：Phase 1 已用「启蒙/入门/熟练/精通/圆熟/化境/登峰」vs「初窥/小成/中成/大成/圆满/巅峰/通神/无瑕/极境」严格不同名，见 `enum_localizations.dart:39,78` 注释；文档与代码已分叉，CLAUDE.md 是禁碰文件不改，此处记录即可。

## 关键约束（每次开局必读）

- 数值红线：普伤 ≤8000、玩家血 ≤20000、内力 ≤15000、装备攻击 ≤2000（GDD §5.2）
- 不硬编码数值（走 numbers.yaml）、不硬编码中文文案（战斗调试日志走 enum_localizations.dart，UI 标签走 lib/ui/strings.dart，剧情走 data/narratives, lore, events）
- Riverpod 状态管理；Isar 本地存储；data/ 是 asset 根目录
- 写代码不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md（DeepSeek 领地）
- Mac 端写 lib/、data/*.yaml（顶层）、test/；DeepSeek 写 data/narratives/、data/lore/、data/events/

## 远程仓库

- GitHub：https://github.com/Zed1118/wuxia_idle
- 主分支 main
- 双端协作：Mac+Opus 写代码与数值；Windows+DeepSeek 写文案

## 归档（已解决挂账 + Phase 1 详条）

### 已解决挂账
#1 Riverpod 锁 2.x / #5 T17 笔误"差 2"→"差 3"（T17 commit 修） / #13 yaml b/c max_hp / #14-#15 灵巧暴击 +0.20 与 ×2.0 yaml 化 / #16 战例 E ≤100000（详见 T11 前清账冲刺 commit）/ #19 T15 远程沙箱无 Flutter（2026-05-10 Mac 本地 review 时实跑 analyze + test 全绿，153/153）/ #20 T15/T16/T17 Windows 视觉验收（2026-05-11，5 截图 4 场景 A2613/B1.67×/C1.92×/D8370 全部命中）/ #21 shake/tier 颜色 helper 抽取（2026-05-12 Codex 夜班 commit b3f3613 `refactor: 抽取 screen_shake + tier_colors helper`）/ #22 T32 #22a/#22b：3 个 service.persistResult + widget 端 `Isar.getInstance` guard + service-level test 验落地（2026-05-11，308/308）/ Phase 2 全交付 v0.2.0-phase2（2026-05-11，merge 5efe8d5）：T19-T32 装备+心法+战斗联动+UI+4场景验收+6截图，333/333 测试 / #24 装备名未渲染（2026-05-11，fix/24-equipment-name）：inventory_row + enhance_dialog 接 EquipmentDef.name + Flexible/ellipsis 兜底 + 2 widget test，335/335 / #27 narrative schema 对齐（2026-05-12，main 上 P1 #1 接手）：NarrativeLoader 子目录扫描 + stages.yaml 6 关 id 迁移 stage_NN_NN + 全仓库引用清理 + widget test 验真实剧情可加载，495/495

### Phase 1 详条
T01-T18 每个任务的文件清单 / 公式 / 用例数 / 验收结论已迁至 `phase1_summary.md` + git log v0.1.0-phase1 前 commits（约 25 条带 `[Tnn]` 前缀），本表不再展开
