# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

**Phase 3 Week 2 进行中**（爬塔 30 层 T40-T46，2026-05-11 启动）。Week 1 v0.3.0-w1 已交付。Week 2 切 A 爬塔，与 §12 待决项零依赖；详条 `phase3_tasks.md` §Week 2，5 minor 决策已拍板（境界曲线 / 不退层 / 复用奖励池 / 不重置 / 重打不发奖）。

## 已完成

- **Phase 1 T01-T18**（2026-05-10/11，main 分支 tag v0.1.0-phase1）：工程脚手架 / 18 枚举 + 5 embedded + @collection / 5 Def 纯类 + GameRepository + 红线校验 / RealmUtils + CharacterDerivedStats + DamageCalculator 7 阶段公式 / BattleState/Engine/AI + battleLog 5 分支 / 战斗 UI（3v3 + 攻击动画 + 飘字）+ Riverpod 串接 + 大招 overlay / 4 测试场景 + 验收。160/160 测试 + 5 战例误差 ≤1.1%。详条见 git log v0.1.0-phase1 前 commits + phase1_summary.md
- **Windows 视觉验收 T15/T16/T17**（2026-05-11，Pen 实测 5 截图）：A 普伤 2613 ✅ / B 1.67× 精确 / C 1.92× 精确 / D 8370 一击杀；动画/飘字/HP 三段色/Opacity 0.3/大招置灰/中文 BMP 外字符 全部正常；销账 #20
- **Phase 2 Week 1 数值层装备**（2026-05-11，分支 feat/phase2-equipment）
  - T19 EquipmentFactory + Rng 抽象（10 用例：固定种子复现 / 蒙特卡洛区间 / fail-fast）
  - T20 强化服务 + 心血结晶（20 用例：4 段成功率 / +20-49 公式 / penalty half/full / 保底 3 段 / 1000 次蒙卡 ±5%）
  - T21 开锋服务 + EquipmentDef.specialSkillCandidates（18 用例：3 槽 unlock / 槽 2 互斥 / specialSkill 三类校验）
  - T22 装备战斗加成整合 + 师承内力上限 + 11 战例验收（+0/+12/+19/+49 / 全栈 883 / 师承 0/1/4 件）
  - 累计 219/219 测试，0 issues
- **Phase 2 Week 2 心法 + 战斗联动**（2026-05-11，分支 feat/phase2-equipment）
  - T23 心法学习服务：4 类校验 fail-fast（tier 上限 / 主修存在 / 辅修槽满 / 领悟点）；10 测试
  - T24 修炼度累积：`CultivationService.recordSkillUsage` 升层逻辑 + `progressToNext` yaml 化（jiJing 封顶 6500）；12 测试
  - T25 散功服务（算法 A）：progress×0.5 + layer 反向回退（`_recalcLayerByRollback`）+ 内力×0.5 in-place 副作用；12 测试
  - T26 战斗结算 hooks：`BattleResolutionService` 纯函数；装备 battleCount++ / 主修走 CultivationService / 辅修仅计数 / `DropService.rollDrops` 联动；防御 assert participatingCharacters 必在双方；战败平局也结算；13 测试
  - T27 装备掉落服务：`sealed class DropEntry`(EquipmentDrop/ItemDrop) + `StageDef.dropTable` yaml + `DropService.rollDrops` 纯函数；17 测试
  - 累计 270/270 测试，0 issues。详条见 git log T23-T27 commits
- **Phase 2 Week 3 UI**（2026-05-11，分支 feat/phase2-equipment，T28-T31 详条见 git log + phase2_tasks.md）
  - T28 角色面板 UI：4 块布局 + characterProviders 3 family + 速度无主修兜底 `—`；4 widget test，累计 287
  - T29 装备仓库 UI + EnhanceDialog：rng_provider + inventory_providers + 预览/强化/保底/shake/金光；5 widget test，累计 292
  - T30 开锋 UI：TabBar 切换强化/开锋 + ForgingPanel 3 槽 + AlertDialog 二确 + ForgingSlotType 中文化；4 widget test，累计 296
  - T31 心法面板 UI + DispelConfirmDialog：tier 分组渲染 + 主修/辅修边框区分 + 二确散功 + characterAllTechniquesProvider；4 widget test，累计 300
- **T32 销账 #22 + 4 场景验收 + 视觉验收**（2026-05-11，详条 git log T32 #22a-#22f + 子提交 4-5 + docs/screenshots/phase2/）：service.persistResult writeTxn / Phase2SeedService / MainMenu+Phase2TestMenu / phase2_scenarios_test 11 用例 / 6 截图 5✅+1⚠️（#24 装备名）；累计 333/333，0 issues
- **v0.2.0-phase2 tag + main 合并**（2026-05-11，merge 5efe8d5）：Phase 2 装备+心法系统交付，feat/phase2-equipment → main no-ff；详见 phase2_summary.md
- **T33 stages.yaml schema 升级**（2026-05-11，feat/phase3-mainline）：StageDef 加 prevStageId / narrativeOpeningId / narrativeVictoryId 三字段 + @Deprecated 旧 narrativeId；6 关 fixture backfill 链成 3 章 × 2 关；GameRepository.\_enforceRedLines 加 stage 链路校验（prev 必须存在 + 同章不跨）；test 加 6 用例（defs 3 + repo 链路 3），累计 341/341
- **T34 MainlineProgressService + Isar collection**（2026-05-11，feat/phase3-mainline）：新 @collection MainlineProgress（saveDataId / currentChapterIndex / clearedStageIds / clearedAt 同序）；service 静态 4 API（getOrCreate 幂等 / availableStages 三态按 prev 链排序 / recordVictory 幂等 append / chapterCompleted）；StageStatus enum；IsarSetup schema 加 + saveVersion 0.1.0→0.2.0；test 加 12 用例（接真 Isar + 临时目录），累计 353/353
- **T35 章节列表 + 关卡列表 UI + 接 main_menu**（2026-05-11，feat/phase3-mainline）：mainline_providers 3 个（progress / chapterStages family / chapterCompleted family）；ChapterListScreen 3 章卡（cleared ✓ / inProgress 高亮 / locked 灰锁）；StageListScreen 三态行（cleared 绿勾 / available 主色 / locked 锁 + 「通关前一关解锁」）；main_menu 加「主线」按钮（顶部首位）+ 包 SingleChildScrollView 防 6 按钮溢出；T37 落地前点 available 弹 SnackBar 占位；test 加 6 widget 用例（chapter 3 + stage 3）+ main_menu_test 6 按钮顺序更新，累计 359/359
- **T36 NarrativeLoader + 剧情阅读 UI**（2026-05-11，feat/phase3-mainline）：lib/data/narrative_loader.dart NarrativeContent + load 注入式 + 缺文件/损坏/非 map 顶层全部兜底 placeholder（不抛异常）；lib/ui/narrative/narrative_reader_screen.dart 一段一页 + 「继续/完成」按钮 + 跳过 + placeholder 弱提示（⚠ 剧情占位）+ 段落淡入；test 加 11 用例（loader 7 + screen 4），累计 370/370
- **T37 关卡进入流程串联**（2026-05-11，feat/phase3-mainline，**销 PROGRESS #22 P2/P4 战斗 stub**）：lib/services/stage_battle_setup.dart 装配 (左,右) BattleCharacter（左从 SaveData.activeCharacterIds 取角色 + 装备 + 主修 → fromCharacter；右 EnemyDef → BattleCharacter，characterId 用 -(slot+1) 防冲突）；lib/ui/mainline/stage_entry_flow.dart runStageFlow async 串联 opening → battle → victory/defeat；BattleScreen 加 onVictory/onDefeat 可选回调（保留 onBattleEnd 兼容旧入口）；stage_list_screen onTap 接 runStageFlow；test 加 6 + 改 1（StageBattleSetup 6 用例接真 Isar + stage_list 占位用例改成验证 NarrativeReader 进入），累计 377/377
- **T38 docs/NARRATIVE_SCHEMA.md**（2026-05-11，feat/phase3-mainline）：给 DeepSeek 端的剧情 yaml 格式约定（文件命名 / id 字段 / paragraphs / 占位 fallback / Week 1 待写 12 文件清单 / 章节标题映射），不动数值文档
- **T39 Pen 视觉验收 + tag v0.3.0-w1**（2026-05-11，feat/phase3-mainline → main no-ff）：8 截图归档 docs/screenshots/phase3_w1/（主菜单 / 章节 / 关卡 / 剧情占位 / 战斗准备失败兜底 / P3 心法面板 / 战斗中 / 战斗胜利 dialog）；victory placeholder + cleared stage list 链路经 Pen 操作确认正常（视觉同 04+03 设计）；phase3_summary.md 起头（Week 1 交付清单 + 截图清单 + 已知偏差 + Week 2 候选议题 A-E）；Pen 端 377/377 + analyze 0 已 SSH 验证
- **v0.3.0-w1 tag + main 合并**（2026-05-11）：Phase 3 Week 1 主线最小闭环交付，feat/phase3-mainline → main no-ff；详见 phase3_summary.md
- **T40 towers.yaml schema + TowerFloorDef + 30 层 fixture**（2026-05-11，feat/phase3-tower）：`enum TowerBossKind { minor, major }` + `enum TowerFloorStatus` 加 enums.dart；`lib/data/defs/tower_floor_def.dart` 新建（floorIndex/requiredRealm/enemyTeam/bossKind/narrativeOpening|VictoryId/dropTable + fromYaml + isBoss getter）；`data/towers.yaml` 30 层 fixture（每 5 层升一阶学徒→宗师，普通层单兵 HP 800→10000 / ATK 200→1500 线性，Boss × 1.5，1/2/3 人队 ×1.0/0.7/0.55 scale）；GameRepository 加 towerFloors 字段 + 加载 towers.yaml + `_enforceTowerRedLines`（30 层连续 / Boss 严格 5·10·15·20·25·30 / 普通层 narrative 必为 null / 敌人数 [1,3] / Boss 1 人 / baseHp ≤ 50000）+ `getTowerFloor` 便捷查询；test 加 13 用例（fromYaml 3 + 集成 6 + fail-fast 4），累计 390/390

## 进行中

- **T41** TowerProgress @collection + TowerProgressService（getOrCreate / availableFloor / recordClear / recordDefeat / canChallenge / floorList）+ IsarSetup schema 注册 + saveVersion 0.2.0→0.3.0

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

Phase 3 Week 2 已拍板走 A 爬塔，T40-T46 详条已落 `phase3_tasks.md`：
- **T40** towers.yaml schema + TowerFloorDef + 30 层 fixture（当前）
- **T41** TowerProgress @collection + TowerProgressService
- **T42** 爬塔列表 UI + 进度展示 + main_menu「问鼎九霄」入口
- **T43** tower_entry_flow（普通层 / Boss 层差异化流程）
- **T44** 爬塔奖励 hook（扩 DropService，重打不发奖）
- **T45** test + analyze 双绿（预期累计 ≥ 410）
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
