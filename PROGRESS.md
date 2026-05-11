# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

**Phase 3 Week 2 进行中**（爬塔 30 层 T40-T46，2026-05-11 启动）。Week 1 v0.3.0-w1 已交付。Week 2 切 A 爬塔，与 §12 待决项零依赖；详条 `phase3_tasks.md` §Week 2，5 minor 决策已拍板（境界曲线 / 不退层 / 复用奖励池 / 不重置 / 重打不发奖）。

## 已完成

- **Phase 1 T01-T18**（2026-05-10/11，tag v0.1.0-phase1）：脚手架 / 18 枚举 / 5 Def 类 + GameRepository 红线校验 / DamageCalculator 7 阶段公式 / BattleEngine + battleLog / 3v3 战斗 UI + Riverpod + 大招 overlay。160/160 测试 + 5 战例误差 ≤1.1%。详条 `phase1_summary.md`
- **Windows 视觉验收 T15/T16/T17**（2026-05-11，Pen 5 截图）：A 普伤 2613 ✅ / B 1.67× / C 1.92× / D 8370 一击杀；动画/飘字/HP 三段色/Opacity 0.3/大招置灰全部正常；销账 #20
- **Phase 2 T19-T32 装备 + 心法 + 战斗联动 + UI**（2026-05-11，tag v0.2.0-phase2，merge 5efe8d5）：EquipmentFactory/Rng / EnhancementService 4 段成功率 + 心血结晶 / ForgingService 3 槽开锋 / 装备战斗加成 + 师承内力上限 / TechniqueLearning 4 类 fail-fast / CultivationService recordSkillUsage + 散功算法 A / BattleResolutionService 战斗结算 hook / DropService sealed DropEntry / 4 UI 面板（角色 / 仓库+强化 / 开锋 / 心法+散功）/ Phase2SeedService 4 场景 / phase2_scenarios_test 11 用例 / 6 截图。累计 333/333，详条 `phase2_summary.md` + git log
- **T24 fixup #24 装备名渲染**（2026-05-11，fix/24-equipment-name）：inventory_row + enhance_dialog 接 EquipmentDef.name + Flexible/ellipsis；2 widget test，累计 335
- **Phase 3 Week 1 T33-T39 主线最小闭环**（2026-05-11，tag v0.3.0-w1，feat/phase3-mainline → main）：stages.yaml schema 升级（prevStageId / narrativeOpeningId / narrativeVictoryId）+ 6 关 backfill 3 章 × 2 关 / MainlineProgress @collection + MainlineProgressService 4 API / 章节列表 + 关卡列表 UI + 主线按钮接 main_menu / NarrativeLoader 缺文件兜底「[剧情待补]」 + 阅读 UI / StageBattleSetup + runStageFlow 串联 opening → battle → victory/defeat / docs/NARRATIVE_SCHEMA.md / 8 Pen 截图归档。累计 377/377（+42）。详条 `phase3_summary.md` §Week 1 + git log T33-T39。**销 #22**
- **T40 towers.yaml schema + TowerFloorDef + 30 层 fixture**（2026-05-11，feat/phase3-tower，commit `511264e`）：`enum TowerBossKind { minor, major }` + `TowerFloorStatus` 加 enums.dart；`lib/data/defs/tower_floor_def.dart` 新建（floorIndex/requiredRealm/enemyTeam/bossKind/narrativeOpening|VictoryId/dropTable + fromYaml + isBoss）；`data/towers.yaml` 30 层 fixture（每 5 层升一阶学徒→宗师，普通层单兵 HP 800→10000 / ATK 200→1500 线性，Boss × 1.5，1/2/3 人队 ×1.0/0.7/0.55 scale）；GameRepository 加 towerFloors + `_enforceTowerRedLines`（30 层连续 / Boss 严格 5·10·15·20·25·30 / 普通层 narrative 必 null / 敌人数 [1,3] / Boss 1 人 / baseHp ≤ 50000）+ `getTowerFloor` 便捷查询；test 加 13 用例（fromYaml 3 + 集成 6 + fail-fast 4），累计 390/390
- **T41 TowerProgress @collection + TowerProgressService**（2026-05-11，feat/phase3-tower）：`@collection TowerProgress`（saveDataId/highestClearedFloor/highestClearedAt/totalAttempts/totalDefeats/createdAt）；service 6 API（getOrCreate 幂等 / availableFloor 封顶 30 / canChallenge 边界 / floorList 30 行三态 / **recordClear 返回 `({isFirstClear, highestAfter})`**：仅 floorIndex==highest+1 才 ++ 否则 isFirstClear=false 不抛 / recordDefeat 仅增统计不退层）；IsarSetup 加 TowerProgressSchema + saveVersion 0.2.0→0.3.0；isar_setup_test 同步改期望值；test 加 15 用例（接真 Isar 临时目录，覆盖跳层非法/与 MainlineProgress 独立校验），累计 405/405

## 进行中

- **T42 ✅** 爬塔层列表 UI + 进度展示 + main_menu「问鼎九霄」入口（commit `41530aa`，411/411 测试）：tower_providers（2 FutureProvider）/ tower_floor_list_screen（AppBar+进度卡+ListView.builder 30行+initState 一次性滚到 available）/ tower_floor_card（三态+Boss金紫边框+推荐境界chip+cleared重打AlertDialog）/ main_menu 7 按钮顺序 / strings.dart 爬塔标签 / 6 widget test
- **T43 ✅** 爬塔进入流程串联（commit `e8b35c6`，416/416 测试）：tower_entry_flow（runTowerFlow async 状态机 opening→battle→victory/defeat）+ _TowerBattleHost + @visibleForTesting DI + StageBattleSetup 重构（buildEnemyTeam public / _buildPlayerTeam private / buildTeamsForTower 爬塔版）+ 5 widget test
- **T44 ✅** 爬塔奖励 hook（commit `2ff976d`，420/420 测试）：DropService.rollTowerRewards + _persistDrops Isar writeTxn + _showVictoryDialog 首通列掉落/重打无奖励 + 4 unit test
- **T45 ✅** 全量 test + analyze 双绿（420/420，analyze 0 issues，T44 提交内同步完成）
- **T46** Pen 视觉验收 + tag v0.3.0-w2（当前）

## 已知偏差 / 挂账事项

2. **lib/ 目录结构**：CLAUDE.md 写 DDD，实际用 phase1_tasks 的 flat。Phase 5 整理
3. **`riverpod_lint` 砍掉**：与 `isar_generator 3.x` analyzer 互斥，Phase 5 切 Isar 4.x 时再补
4. **IDS_REGISTRY.md 自报「143 个内容 ID」错误**：实际 238 个，等 DeepSeek 改
6. **GDD §5.3/§5.6 公式系数 vs numbers.yaml**：GDD 字面 ×8 / ×5 是「口误」，代码以 yaml 平衡值（×1.0 / ×0.7）为准
7. **numbers.yaml 节气列表混入「中秋」**：中秋是农历节日不是节气，GDD 没明确 24 节气，待定
8. **CLAUDE.md §12 待人类决策清单 13 条**：境界/修炼度层重名等，实现到对应位置时按需提问
9/11. **T05/T07 验收**：Mac 无 Xcode 跑不了 desktop，留 Windows 首跑验
10. **yaml key 命名约定差异**：numbers.yaml snake_case，内容 yaml camelCase，按文件类型隔离不冲突
12. **`LevelDiffModifier.diff3OrMore.attacker` 数据层 vs 公式层语义不同**：NumbersConfig 兜底为 diff2.attacker(=2.5)，公式层取 1.0，Phase 5 收尾改
17. **phase1_tasks T12 §709 笔误**：差 2 守方 0.05 错（实际差 2 守方=0.3，差 3+ 才 0.05），「必败」语义仍成立
18. **`flutter build web` 被 Isar 阻塞**：dart:ffi web 不支持，Phase 5 切 Isar 4.x 时一并恢复
21. **shake / tier 颜色 / 金光效果未抽 helper**：battle_screen / enhance_dialog 各 inline 一份 sin 公式；character_panel / enhance_dialog / inventory_screen 各 inline 一份 `_tierColor` 映射。Phase 5 抽 `lib/ui/effects/screen_shake.dart` + `lib/ui/theme/tier_colors.dart`
23. **widget test 不接真 Isar**：testWidgets FakeAsync 与 `Isar.findFirst` / writeTxn 异步 IO 不兼容；当前 widget 端在 `_persist` 加 `Isar.getInstance` guard 测试旁路，真落地走 service-level test。Phase 5 Riverpod 3.x + IsarProvider 注入时再统一
25. **Phase2SeedService.seedP1 缺主修，主线进入需先跑 P3**：T37 验收时发现 P1 fixture（沿用 Phase 2 spec：仅装备+材料）无主修心法，导致 P1 → 主线进战斗 StageBattleSetup fail-fast。临时 workaround：用户/Pen 在主菜单点「Phase 2 调试场景 → P3 散功代价」种子后再回主线即可。Phase 4 重写 fixture 时让 Demo 默认入口直通主线战斗

> 已解决条目（#1/#5/#13/#14/#15/#16/#19/#20/#22/#24）见文末归档。

## 下一步

Phase 3 Week 2（爬塔，详条 `phase3_tasks.md` §Week 2）：
- ✅ **T40** towers.yaml + TowerFloorDef + 30 层 fixture（390/390）
- ✅ **T41** TowerProgress + TowerProgressService + saveVersion 0.3.0（405/405）
- ✅ **T42** 爬塔层列表 UI + main_menu 入口（411/411）
- ✅ **T43** 爬塔进入流程串联（416/416）
- ✅ **T44** 爬塔奖励 hook（420/420）
- ✅ **T45** 全量 test + analyze 双绿（420/420）
- **T46** Pen 视觉验收 + tag v0.3.0-w2
- **T45** test + analyze 双绿（预期 ≥ 410）
- **T46** Pen 视觉验收 + tag v0.3.0-w2

Week 3 候选（待 Week 2 跑通后再拆）：B 闭关 / C 奇遇 / D 师徒 / E 武学领悟（多个待决 §12 #5/#6/#10/#11）

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
#1 Riverpod 锁 2.x / #5 T17 笔误"差 2"→"差 3"（T17 commit 修） / #13 yaml b/c max_hp / #14-#15 灵巧暴击 +0.20 与 ×2.0 yaml 化 / #16 战例 E ≤100000（详见 T11 前清账冲刺 commit）/ #19 T15 远程沙箱无 Flutter（2026-05-10 Mac 本地 review 时实跑 analyze + test 全绿，153/153）/ #20 T15/T16/T17 Windows 视觉验收（2026-05-11，5 截图 4 场景 A2613/B1.67×/C1.92×/D8370 全部命中）/ #22 T32 #22a/#22b：3 个 service.persistResult + widget 端 `Isar.getInstance` guard + service-level test 验落地（2026-05-11，308/308）/ Phase 2 全交付 v0.2.0-phase2（2026-05-11，merge 5efe8d5）：T19-T32 装备+心法+战斗联动+UI+4场景验收+6截图，333/333 测试 / #24 装备名未渲染（2026-05-11，fix/24-equipment-name）：inventory_row + enhance_dialog 接 EquipmentDef.name + Flexible/ellipsis 兜底 + 2 widget test，335/335

### Phase 1 详条
T01-T18 每个任务的文件清单 / 公式 / 用例数 / 验收结论已迁至 `phase1_summary.md` + git log v0.1.0-phase1 前 commits（约 25 条带 `[Tnn]` 前缀），本表不再展开
