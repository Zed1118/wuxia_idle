# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

**Phase 2 装备 + 心法系统**（phase2_tasks.md 定义的 T19-T32），目标 3 周交付。Phase 1 已完成（v0.1.0-phase1）。

## 已完成

- **Phase 1 T01-T18**（2026-05-10/11，main 分支 tag v0.1.0-phase1）：工程脚手架 / 18 枚举 + 5 embedded + @collection / 5 Def 纯类 + GameRepository + 红线校验 / RealmUtils + CharacterDerivedStats + DamageCalculator 7 阶段公式 / BattleState/Engine/AI + battleLog 5 分支 / 战斗 UI（3v3 + 攻击动画 + 飘字）+ Riverpod 串接 + 大招 overlay / 4 测试场景 + 验收。160/160 测试 + 5 战例误差 ≤1.1%。详条见 git log v0.1.0-phase1 前 commits + phase1_summary.md
- **Windows 视觉验收 T15/T16/T17**（2026-05-11，Pen 实测 5 截图）：A 普伤 2613 ✅ / B 1.67× 精确 / C 1.92× 精确 / D 8370 一击杀；动画/飘字/HP 三段色/Opacity 0.3/大招置灰/中文 BMP 外字符 全部正常；销账 #20
- **Phase 2 Week 1 数值层装备**（2026-05-11，分支 feat/phase2-equipment）
  - T19 EquipmentFactory + Rng 抽象（10 用例：固定种子复现 / 蒙特卡洛区间 / fail-fast）
  - T20 强化服务 + 心血结晶（20 用例：4 段成功率 / +20-49 公式 / penalty half/full / 保底 3 段 / 1000 次蒙卡 ±5%）
  - T21 开锋服务 + EquipmentDef.specialSkillCandidates（18 用例：3 槽 unlock / 槽 2 互斥 / specialSkill 三类校验）
  - T22 装备战斗加成整合 + 师承内力上限 + 11 战例验收（+0/+12/+19/+49 / 全栈 883 / 师承 0/1/4 件）
  - 累计 219/219 测试，0 issues
- **T23 心法学习服务**（2026-05-11，分支 feat/phase2-equipment）
  - `data/numbers.yaml` 新增 `techniques.learning_cost`（assist=100 / main=500，Pen 拍板）
  - `lib/data/numbers_config.dart`：新增 `LearningCostConfig`；`NumbersConfig` 加字段 + fromYaml 接 `techniques.learning_cost`
  - `lib/combat/derived_stats.dart`：新增 `RealmUtils.techniqueTierCapOf(RealmTier) → TechniqueTier`（仿 equipmentTierCapOf）
  - `lib/services/technique_learning.dart`（新建）：`TechniqueLearningService.learn(...)` 返回 `TechniqueLearningResult`；4 类校验 fail-fast 顺序：tier 上限 → 主修存在 → 辅修槽满 → 领悟点；服务只构造 Technique 实例，写 Isar / 改 Character 字段归调用方
  - 单测 10/10；累计 229/229 测试，0 issues
- **T24 修炼度累积**（2026-05-11，分支 feat/phase2-equipment）
  - `lib/data/numbers_config.dart`：新增 `Map<CultivationLayer, int> cultivationProgressToNext`（解析 `techniques.cultivation.progress_to_next`，仅 8 entry，jiJing 不收录）
  - `lib/services/cultivation_service.dart`（新建）：`recordSkillUsage({tech, skillId, progressToNextMap, delta=1})` 返回 `CultivationProgressResult(didLevelUp/oldLayer/newLayer/layersGained/currentProgress/currentProgressToNext)`；in-place 修改 Technique
  - 升层逻辑：increment skillUsage → progress += delta → while (layer != jiJing && progress >= progressToNext) 消耗升层 + 切换 progressToNext；jiJing 时保留 progressToNext=6500 作封顶上限
  - 单测 12/12；累计 241/241 测试，0 issues
- **T25 散功服务**（2026-05-11，分支 feat/phase2-equipment）
  - `lib/data/numbers_config.dart`：补 `dispersionInternalForcePenalty`（=0.5，Phase 1 时漏接）
  - `lib/services/dispel_service.dart`（新建）：`dispel({ch, mainTech, newMainTech, n})` 返回 `DispelResult`；3 类校验 fail-fast（旧主修非 main / 新主修不属于该角色 / 新主修非 assist）
  - **算法 A（Pen 拍板）**：散功后 progress×0.5，layer 不变；服务层 `_recalcLayerByRollback` 向下回退直到 progress >= prev→current 的 progress_required；progress 直接继承到回退后的 layer
  - 副作用全 in-place：内力 ×0.5 floor / 旧主修 progress×0.5+role=assist+layer 回退 / 新主修 role=main / Character.mainTechniqueId 切 / assistTechniqueIds 移除新主修后塞旧主修；满 3 时旧主修丢弃（调用方决定回背包）
  - 单测 12/12；累计 253/253 测试，0 issues
- **T27 装备掉落服务**（2026-05-11，分支 feat/phase2-equipment）
  - `lib/data/defs/drop_entry.dart`（新建）：`sealed class DropEntry` + `EquipmentDrop` / `ItemDrop`；`fromYaml` 按 `equipmentDefId` / `inventoryItemDefId` 二选一分发；quantity 支持缺省 [1,1] / 单数字 [n,n] / `[min, max]` 三种写法；fail-fast 校验
  - `lib/data/defs/stage_def.dart`：扩 `dropTable: List<DropEntry>`（默认空，向后兼容）；旧 `dropEquipmentDefIds` / `dropItemDefIds` 保留为 Phase 1 占位，Phase 5 整理时再清
  - `lib/services/drop_service.dart`（新建）：`DropService.rollDrops(StageDef, Rng) → DropResult(equipments, items)` 纯函数，不写 Isar；遍历 dropTable 每条独立 `rng.nextDouble() < dropChance`；装备命中调 `EquipmentFactory.fromDef`（T19）；注入式 `equipmentDefLookup` + `now` 便于测试
  - `data/stages.yaml`：mainline_test_02（30% 铁剑 + 必掉磨剑石 1-3）+ mainline_test_06（必掉龙泉剑 + 50% 玉佩 + 必掉心血结晶 5-8）；其他 4 关 dropTable 留空（T28 视觉验收时再补，Pen 拍板：本阶段先 2 关）
  - 单测 16 + 1（game_repository 真实 yaml 加载断言）；累计 270/270 测试，0 issues

## 进行中

- Phase 2 Week 2 心法 + 战斗联动（T26 待开），分支 feat/phase2-equipment

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

> 已解决条目（#1/#5/#13/#14/#15/#16/#19/#20）见文末归档。

## 下一步

T26 战斗结算 hooks：`BattleResolutionService.resolve({finalState, participatingCharacters, stageDef, rng})` → 装备 battleCount++（参战 3 件，未参战不算） + 心法 skillUsageCount[skillId] 反推 actionLog 累加 + 主修调 `CultivationService.recordSkillUsage` 升层 + 调 `DropService.rollDrops`（T27✅）入背包；纯结果返回，副作用归 caller；`BattleNotifier` 扩展 result 翻转 hook + `battleResolutionServiceProvider` 注入；单测 ≥10 + widget 测试 1 fakeIsar/in-memory。**模型建议保持 opus 4.7**。

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
#1 Riverpod 锁 2.x / #5 T17 笔误"差 2"→"差 3"（T17 commit 修） / #13 yaml b/c max_hp / #14-#15 灵巧暴击 +0.20 与 ×2.0 yaml 化 / #16 战例 E ≤100000（详见 T11 前清账冲刺 commit）/ #19 T15 远程沙箱无 Flutter（2026-05-10 Mac 本地 review 时实跑 analyze + test 全绿，153/153）/ #20 T15/T16/T17 Windows 视觉验收（2026-05-11，5 截图 4 场景 A2613/B1.67×/C1.92×/D8370 全部命中）

### Phase 1 详条
T01-T18 每个任务的文件清单 / 公式 / 用例数 / 验收结论已迁至 `phase1_summary.md` + git log v0.1.0-phase1 前 commits（约 25 条带 `[Tnn]` 前缀），本表不再展开
