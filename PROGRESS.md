# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

**Phase 2 已交付**（v0.2.0-phase2，2026-05-11）。Phase 3 待规划（主线关卡 / 爬塔 / 闭关地图 / 奇遇 / 师徒传承 / 武学领悟）。

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

## 进行中

- —（Phase 2 已交付 v0.2.0-phase2，Phase 3 待规划，先 fixup 挂账 #24 再开 phase3_tasks.md）

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
24. **装备名未渲染**：inventory_row + enhance_dialog 显示「武器」而非 EquipmentDef.name（如「龙泉剑」），T32 子提交 5 Pen 视觉验收发现，不影响数值/流程，Phase 3 起手第一个 fixup

> 已解决条目（#1/#5/#13/#14/#15/#16/#19/#20/#22）见文末归档。

## 下一步

Phase 3 起点：
1. **挂账 #24 fixup**：inventory_row + enhance_dialog 接 EquipmentDef.name（独立 commit `[T33] #24 fixup: 装备名显示` + widget test）
2. **Phase 3 规划讨论**：主线 15-20 关 / 爬塔 30 层 / 闭关地图 5 / 奇遇 20-30 / 师徒传承 / 武学领悟 30-50 招（GDD §7-§8，Demo 总量见 CLAUDE.md §7）—— 先讨论范围与里程碑再开 phase3_tasks.md
3. **CLAUDE.md §12 待决项 13 条**：实现到对应位置时按需提问

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
#1 Riverpod 锁 2.x / #5 T17 笔误"差 2"→"差 3"（T17 commit 修） / #13 yaml b/c max_hp / #14-#15 灵巧暴击 +0.20 与 ×2.0 yaml 化 / #16 战例 E ≤100000（详见 T11 前清账冲刺 commit）/ #19 T15 远程沙箱无 Flutter（2026-05-10 Mac 本地 review 时实跑 analyze + test 全绿，153/153）/ #20 T15/T16/T17 Windows 视觉验收（2026-05-11，5 截图 4 场景 A2613/B1.67×/C1.92×/D8370 全部命中）/ #22 T32 #22a/#22b：3 个 service.persistResult + widget 端 `Isar.getInstance` guard + service-level test 验落地（2026-05-11，308/308）/ Phase 2 全交付 v0.2.0-phase2（2026-05-11，merge 5efe8d5）：T19-T32 装备+心法+战斗联动+UI+4场景验收+6截图，333/333 测试

### Phase 1 详条
T01-T18 每个任务的文件清单 / 公式 / 用例数 / 验收结论已迁至 `phase1_summary.md` + git log v0.1.0-phase1 前 commits（约 25 条带 `[Tnn]` 前缀），本表不再展开
