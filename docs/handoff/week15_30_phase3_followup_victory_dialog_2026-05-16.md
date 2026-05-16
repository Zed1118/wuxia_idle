# W15 #30 P3 后续 A · victory dialog 升层 + drop banner closeout

> 2026-05-16 / Mac · opus 4.7 / 单会话 ~1.5h / 3 commit / 零回退

## 1. 一句话

主线 victory **0→1 新建 dialog**(沿塔体例),塔 victory `_FirstClearContent` **追多角色升层 banner**。`AdvancementSummary` widget 抽出双端复用,seclusion 单角色 `_AdvancementBanner` 不动(数据形态不同)。Codex F #34 closeout §7 暴露的 2 UI 缺口本批落 1(victory drop banner),物料 Tab 留下波。

## 2. Phase 0 grep 结论(2 维度法)

| 项 | 状态 |
|---|---|
| mainline `_applyVictoryResolution`(line 287)| ✅ caller 1 处(line 101),但**无 victory dialog**,只跳 NarrativeReaderScreen |
| tower `_showVictoryDialog`(line 348)| ✅ 已有 AlertDialog + `_FirstClearContent` 列 drop,**缺升层 banner** |
| AdvancementResult(mainline:356 / tower:291)| ❌ return value 被丢弃(P3 closeout §5.6 提及"本批暂不暂存")|
| InventoryScreen TabBar | ❌ 单 ListView,**0 Tab**,改造需新 provider + widget ~2-3h |
| seclusion `_AdvancementBanner`(retreat_result_screen:174)| ✅ 体例可参考,但单 character 不接多 character |

**两维矩阵**:`AdvancementResult` 类已存在(维度 A ✓)+ caller 2 处但 return value 丢弃(维度 B ⚠️ "半完成 wire")→ 改动小,只需 `for` 循环改成收集 + 传到 UI。

## 3. 拍板决策

- **Q1 主线 victory 用 dialog**(沿塔体例,新建 `_showStageVictoryDialog`),叙事屏不动
- **Q2 多角色 banner = 单 banner 多行**(每 character 一行 + Icons.auto_awesome),扩 UiStrings `advancementForCharacter(chName, realmAfter, layers)`
- **Q3 AdvancementResult 暂存 = `List<AdvancementEntry>`**(`({String chName, AdvancementResult result})`),顺序保留 active 顺序
- **scope 边界 = A.1 主线 + A.2 塔 + A.4 暂存,A.3 InventoryScreen 物料 Tab 留下波**(单独 ~2-3h)

## 4. 代码改动清单

5 文件 modified + 3 文件 new = 8 文件:

| 文件 | 改动 |
|---|---|
| `lib/ui/strings.dart` | 加 `stageVictoryTitle/Confirm/DropLabel/NoDrop` + `advancementForCharacter(chName, realmAfter, layers)`(layers==1 用"突破至",N 用"连破 N 层 →") |
| `lib/features/cultivation/presentation/advancement_summary.dart` | **新建** `AdvancementSummary` widget + `AdvancementEntry` data class;仅渲染 `didAdvance=true` 条目,empty 返回 `SizedBox.shrink` |
| `lib/features/mainline/presentation/stage_victory_dialog.dart` | **新建** `showStageVictoryDialog` + 公开 `StageVictoryContent`(便于 widget test);drop 列(沿 tower `_FirstClearContent` 体例)+ AdvancementSummary |
| `lib/features/mainline/presentation/stage_entry_flow.dart` | `_applyVictoryResolution` 返回 `({DropResult drops, List<AdvancementEntry> advancements})?` + 早期 return null;caller 在 recordVictory 后/narrative 前 `showStageVictoryDialog`;import AdvancementSummary / DropResult / stage_victory_dialog |
| `lib/features/tower/presentation/tower_entry_flow.dart` | `_applyTowerVictoryResolution` 返回 `List<AdvancementEntry>` + 早期 return `const []`;`_showVictoryDialog` 加 `advancements` 参数;`_FirstClearContent` 重构:drop empty 但有升层时仍渲染 banner(避免"首通无奖+升了一层"被吃掉),纯 drop empty 仍显 `towerFirstClearNoReward`;import AdvancementSummary |
| `test/features/cultivation/presentation/advancement_summary_test.dart` | **新建** 5 widget test:empty / 0 advanced / layers=1 / layers=4 / mixed only advanced |
| `test/features/mainline/presentation/stage_victory_dialog_test.dart` | **新建** 6 widget test:empty drop+0 advance / item drop+0 advance / 0 drop+1 advance / drop+mixed / drop+all flat / dialog open+close |

## 5. 关键决策细节

### 5.1 mainline 早期 return 改 `null`,outcome 暂存供 caller 决定显不显

`_applyVictoryResolution` 4 个早期分支(isar==null / !isFinished / ids empty / characters empty)统一返回 `null`,caller `if (outcome != null && context.mounted)` 判 null 跳过 dialog 不阻塞 narrative 流(沿 `_applyBossDefeatPenalty` 返 `const []` 兜底体例)。

### 5.2 tower `_FirstClearContent` 显示分支重构

旧逻辑:`if (drops.isEmpty) return Text(towerFirstClearNoReward)`,直接吞掉无 drop 但有升层的场景。

新逻辑:
- drop empty + 升层 → 显 "首通本层无固定奖励" + AdvancementSummary
- drop empty + 无升层 → 显 "首通本层无固定奖励"(同旧)
- drop 有 + 升层 → 显 drop list + AdvancementSummary
- drop 有 + 无升层 → 显 drop list(同旧)

### 5.3 `AdvancementSummary` 抽到 cultivation/presentation/

放 cultivation feature 而非 shared/,因升层是 cultivation 领域概念,mainline / tower 跨 feature 引用(`'../../cultivation/presentation/'`)是合规的(feedback `feedback_avoid_over_engineer_abstraction`:实际有 2 caller 时不 over-engineer,但 ROI 高就抽,本批 2 caller × 一模一样 banner 体例 → 抽合理)。

seclusion 现有 `_AdvancementBanner` 单角色版**不动**:输入是单个 `AdvancementResult` 不带 chName,与多角色版数据形态不同。如果后续 seclusion 也切多角色,再统一(YAGNI)。

### 5.4 widget test 不依赖 GameRepository

新 widget test 走 `StageVictoryContent` 公开类直接 pump(不走 `showDialog` flow,只 1 个 dialog open/close test 走 flow)。drop 列内 `GameRepository.isLoaded` false 时回退到 `eq.defId` 显示,因此 test fixture 用 `ItemDropResult` 而非 `Equipment`,绕开 GameRepository 依赖。

## 6. 测试与验证

| 阶段 | 命令 | 结果 |
|---|---|---|
| 新 test | `flutter test test/features/cultivation/presentation/ test/features/mainline/presentation/` | 17/17 |
| 全仓回归 | `flutter test` | **690/690** 全过(原 679 + 11 新增) |
| analyze | `flutter analyze` | **0 issues** |

## 7. 销账

- ✅ PROGRESS §65 下一步候选 A.1 主线 victory drop banner + 升层 banner
- ✅ PROGRESS §65 候选 A.2 塔 victory dialog 升层 banner
- ✅ Codex F #34 closeout §7 暴露 UI 缺口 1/2(victory drop banner)
- ⏭️ A.3 InventoryScreen 物料 Tab 留下波 polish

## 8. 下次开局必读

### 8.1 状态快照

- 3 commit 待 push origin/main(feat / test / docs)
- 690/690 + analyze 0 issues
- 主线 victory dialog 链路新建,叙事屏不动
- 塔 victory dialog `_FirstClearContent` 重构后兼容旧 drop-only / 旧 reward-empty / 新升层场景

### 8.2 下波 4 候选

| # | 任务 | 模型 | 时长 | 备注 |
|---|---|---|---|---|
| **A** | InventoryScreen 物料 Tab(磨剑石/心血结晶可见) | sonnet | 2-3h | Codex F #34 第 2 UI 缺口 |
| B | §12.1 #7 三流派 extra_effect 数值拍板 | sonnet | 30-60min | 老挂账,讨论型 |
| C | §12.1 #10 师承遗物规则拍板 | sonnet | 30-60min | 老挂账,讨论型 |
| D | mainline / tower victory 写回 widget integration test | sonnet | 1-2h | 本批新 dialog 单元 test 已覆盖,e2e 收口可选 |
| E | 主线 victory dialog Codex 视觉验收 | Codex Pen | - | 派单(本批新 UI 拿真硬截图) |

### 8.3 硬约束沿用

- 主线 / 塔 victory 流程 W11 #32 销账区 careful(`feedback_layered_bugs`):本批 Phase 0 grep 已确认改动小且服务层 in-place 副作用 0 改,纯 UI 层加 banner + 暂存 return
- AdvancementSummary 不接 GameRepository(EnumL10n.realm 纯 enum 映射,zero 外部依赖,widget test 不需 Isar mock)
- `feedback_red_line_test_semantics`:新 test 用约束语义("含 Icon.auto_awesome" / "含「甲 · 突破至」")不写瞬时数值
