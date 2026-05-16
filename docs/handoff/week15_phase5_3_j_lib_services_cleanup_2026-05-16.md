# Phase 5 #3 第 5 批 — J 任务 lib/services/ 收尾

**日期**:2026-05-16
**模型**:Opus 4.7 high(sonnet 1h 预算,opus 接力 C+I 未降档)
**会话密度**:1 会话 / 1 commit / 7 文件改动(4 rename + 3 modified)/ 27 行 import 改 / 全程零回退
**HEAD**:`20e738e`(push 待)
**测试**:653/653 + analyze 0 issues(1 次 verify,机械工作一气呵成)

---

## 1. 一句话结论

`lib/services/` **目录消失**。phase2_seed_service(715 行 debug fixture)迁 `lib/features/debug/application/`,technique_learning(100 行 utility)迁 `lib/features/cultivation/application/`。lib/ 顶层 9 → 8 项,Phase 5 #3 重构整体收口,目录结构 100% feature-first。

---

## 2. 会话密度统计

| 指标 | 值 |
|---|---|
| commit 数 | 1(`20e738e` 主实施 + docs commit 待) |
| 文件 rename | 4(2 lib + 2 test 同迁) |
| 文件 modified | 3(2 self import 改 + 1 lib consumer + 4 test consumer,实际 modify 7 但 4 在 rename 内) |
| import 改动 | 27 行 |
| verify 节点 | 1(机械工作,一气呵成) |
| 回退次数 | **0** |
| 用户介入 | 1 次(归属决策,拍板「推荐方案」即 debug/cultivation feature) |

---

## 3. 用户拍板:归属决策

### 3.1 phase2_seed_service 归属

3 选项推荐 A:
- **A(推荐 ⭐)**:`lib/features/debug/application/phase2_seed_service.dart` — 新建 debug feature application 层,presentation/ 即 lib/ui/debug/ 3 文件留待 D+E 整体迁
- B:`lib/fixtures/phase2_seed_service.dart` — 顶层 fixtures/ 与 features/ 平级
- C:留 lib/services/ — 打破 J 目标

**理由 A**:debug 整 feature 化语义最自然(715 行 debug fixture + 后续 lib/ui/debug/ 3 文件迁 presentation/ 闭环)。

### 3.2 technique_learning 归属

2 选项推荐 A:
- **A(推荐 ⭐)**:`lib/features/cultivation/application/technique_learning.dart` — cultivation feature 已存在,语义最贴(心法学习 = 修炼范畴)
- B:`lib/features/technique_panel/application/` — technique_panel 是 panel UI 定位,application 层放 service 不自然

**理由 A**:GDD §7.2 武学领悟系统的核心服务,语义归修炼/散功簇,与 cultivation 一致。

### 3.3 J 任务边界

- **小范围(选)**:只迁 2 service 本体 + test 同迁 + consumer import 切换。lib/services/ 目录消失,lib/ui/debug/ 留待 D+E
- 大范围:连 lib/ui/debug/ 3 文件一并迁 features/debug/presentation/ — 超 sonnet 1h 预算

---

## 4. 实施步骤

### 4.1 J-1:phase2_seed_service 迁 features/debug/application/

**git mv**:lib/services/phase2_seed_service.dart → lib/features/debug/application/(test 同迁 test/services/ → test/features/debug/application/)。

**自身 17 import 深度调整**:
- `'../data/X'` / `'../core/X'` / `'../utils/X'` → `'../../../X'`(深度 +2:services/ 1 层 → debug/application/ 3 层)
- `'../features/encounter/X'` / `'../features/equipment/X'` / `'../features/mainline/X'` → `'../../X'`(深度 -1:从同 lib 层间引到 features/ 内同层 peer)

**4 consumer import 切换**:
| consumer | 原 | 新 |
|---|---|---|
| lib/ui/debug/phase2_test_menu.dart | `'../../services/phase2_seed_service.dart'` | `'../../features/debug/application/phase2_seed_service.dart'` |
| test/services/master_disciple_battle_test.dart | `package:wuxia_idle/services/phase2_seed_service.dart` | `package:wuxia_idle/features/debug/application/phase2_seed_service.dart` |
| test/services/stage_battle_setup_test.dart | 同上 | 同上 |
| test/features/debug/application/phase2_seed_service_test.dart(自迁) | 同上 | 同上 |

analyze 0 issues。

### 4.2 J-2:technique_learning 迁 features/cultivation/application/

**git mv**:lib/services/technique_learning.dart → lib/features/cultivation/application/(test 同迁)。

**自身 6 import 深度调整**:
- `'../features/battle/domain/derived_stats.dart'` → `'../../battle/domain/derived_stats.dart'`(features/ 内同层 peer)
- `'../data/X'` / `'../core/X'` → `'../../../X'`(深度 +2)

**1 consumer import 切换**:test/features/cultivation/application/technique_learning_test.dart(自迁,`package:wuxia_idle/services/` → `package:wuxia_idle/features/cultivation/application/`)。

**lib 端 0 consumer**(GDD §7.2 武学领悟系统未实装,纯预留)。dispel_service.dart line 105 提及 `TechniqueLearningService` 是文档注释,非 import。

### 4.3 J-3:空目录清理 + verify + commit

`rmdir lib/services/`(git mv 后空目录残留)→ **lib/ 顶层 9 → 8 项**(去掉 services/)。

`flutter test` 全测 **653/653** + `flutter analyze` 0 issues。

`git add -u`(stage perl 改的 7 modified)+ commit `20e738e` 一次性。

---

## 5. 数字实测复审(memory feedback_closeout_numbers_grep)

| 数字 | 实测值 | 来源 |
|---|---|---|
| commit 数 | 1 | `git log --oneline f356092..HEAD` 仅 `20e738e` |
| 文件 rename | 4 | `git diff --stat HEAD~1` rename 段 |
| 文件 modified | 3(rename 外) | rename 段 4 + modified 段 3 = 7 总改 |
| import 改 | 27 行 insertions = 27 deletions | `git show --stat 20e738e` |
| phase2_seed 自身 import | 17 | `grep -c "^import" lib/features/debug/application/phase2_seed_service.dart` |
| technique_learning 自身 import | 6 | 同上 |
| phase2_seed 总行数 | 715 | `wc -l` |
| technique_learning 总行数 | 100 | `wc -l` |
| lib/ 顶层项数 | 8 | `ls lib/ \| wc -l` |
| 全测 | 653/653 | flutter test 最后行 |
| analyze | 0 issues | flutter analyze 最后行 |
| 回退次数 | 0 | git log 单 commit |

`test/services/` 还有 8 个 test 文件(battle_resolution / cultivation_service / dispel_persist / dispel_service / master_disciple_battle / phase2_scenarios / skill_usage_persist / stage_battle_setup),这些是 service test 文件位置规整,**不属 J 任务范围**(对应 service 已分散到各 features/,test 位置仍在 test/services/ 留 D+E 处理)。

---

## 6. 下次开局必读

### 6.1 状态快照

- HEAD `20e738e`(J commit + docs commit 待)/ tag `v0.5.3-w15-final` 保留
- 653/653 + analyze 0 issues
- **lib/services/ 目录消失**(lib/ 顶层 8 项:core / data / features / providers / shared / ui / utils + main.dart)
- features/ 11 → **12 feature**(新增 debug,cultivation 既有补 application/ phase2_seed + technique_learning 2 文件 = cultivation 首次有真实业务代码)
- **test/services/ 仍剩 8 test 文件**(battle/cultivation/dispel/master_disciple/phase2_scenarios/skill_usage/stage_battle 系 service test),test 位置规整属 D+E/后续范围
- **lib/ui/debug/ 3 文件未动**(battle_test_menu / encounter_debug_picker / phase2_test_menu),与 J 小范围边界匹配,D+E 时迁 features/debug/presentation/
- §12 待决 2 条不变(#7 流派 extra_effect / #10 师承遗物规则)

### 6.2 开局动作

1. 读 PROGRESS.md「当前阶段」+「下一步」+「挂账事项」
2. 读 本 closeout §6 下次开局必读
3. `git pull --rebase --autostash` 看 drift(本会话已 push,正常无)

### 6.3 下波 5 候选

J 任务完成后剩 4 候选 + 1 新候选:

| # | 任务 | 模型 | 时长 | 备注 |
|---|---|---|---|---|
| **D+E** ⭐ | service interface 抽离 + lib/shared UI 通用(含 lib/ui/debug/ 3 文件迁 features/debug/presentation/) | sonnet | 2-3h | B/C/I/J 重构后边角整理,**含 lib/ui/debug/ 闭环 debug feature** |
| F | #34 stage drop 视觉验收 Pen 环境改善 | Codex 派单 | 1h | 老挂账 |
| G | Pen-only T64 test fail 排查 | sonnet | 30min | 老挂账 |
| H | techniqueLearnPoints / internalForcePoints 消费层接入 | opus | 2-3h | #30 新维度落 Character/Technique,独立功能 |
| **新** K | test/services/ 8 文件位置规整(各 test 迁对应 features/<X>/application/test/) | sonnet | 1h | J 衍生,test 位置 100% feature-first |

**推荐起手**:D+E(含 lib/ui/debug/ 完整迁,把 debug feature presentation/ 一并闭环)+ K 顺手并入(test 位置规整),合 sonnet 2-3h,做完 lib/{services,ui/debug} 完全归化。

或单做 K(sonnet 1h)进一步收口,然后 D+E 单 sonnet 2h 整理 UI 通用 + shared/。

### 6.4 硬约束沿用

延续 C+I 任务硬约束清单(详 `week15_phase5_3_isar_provider_split_2026-05-16.md` §6.4)。本批新增:
- **空 dir rmdir 收尾**:git mv 完空目录残留(macOS 下),用户感官「目录消失」需 rmdir 一并清,否则 ls 仍显
- **0 consumer 不等于死代码**:technique_learning lib 端 0 consumer 但是 GDD §7.2 武学领悟系统预留实装,**不能按 I 任务死 provider 删除决策一刀切**,要看是否系统未实装(GDD 锚点)还是 W6-S2 副产物
