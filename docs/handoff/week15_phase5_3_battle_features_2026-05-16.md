# Phase 5 #3 第 5 批 — 战斗系统 features 迁(B 任务)

**日期**:2026-05-16
**模型**:Opus 4.7 xhigh(用户拍板升档)
**会话密度**:1 会话 / 4 commit / combat 7 + ui/battle 6 + services 4 = **17 文件迁** / ~150 行 import 改 / 全程零回退
**HEAD**:`ce84cd3`(本会话末态,push 待)
**测试**:653/653 + analyze 0 issues(3 步 verify 全过,每步 1 次 analyze + 全测)

---

## 1. 一句话结论

把战斗系统 17 个文件分 3 步迁到 `lib/features/{battle,cultivation,dispel}/`:combat/ 7 → battle/domain/、ui/battle/ 6 → battle/presentation/、4 service → 各 feature application/。**lib/combat/ 目录消失 / lib/ui/battle/ 目录消失 / lib/services/ 4 service 离场**。改 ~150 处 import,Phase 5 主战场 7/14 → **10/14 feature 落地**。

---

## 2. 会话密度统计

| 指标 | 值 |
|---|---|
| commit 数 | 4(`afcfd87` combat rename / `14c183a` combat import / `06158cf` ui/battle / `ce84cd3` services) |
| 文件迁移 | combat 7 + ui/battle 6 + services 4 = **17 .dart** + 0 .g.dart |
| import 改动 | Step 1 ~144 行 / Step 2 30 行 / Step 3 46 行 = **~220 行 import 改动** |
| 改动文件数 | Step 1 35 文件 / Step 2 10 文件 / Step 3 17 文件 = **62 文件触及**(去重约 50 独立文件) |
| verify 节点 | 3(每 step 一次 analyze + 全测,653/653 三次全过) |
| 回退次数 | **0**(2 次漏改雷达暴露,补 1 行 perl 继续) |
| 用户介入 | 1 次(B/C/D/E/F/G/H 候选选 B + xhigh 升档) |

---

## 3. 用户拍板

### 3.1 B 起手 + xhigh

closeout `week15_phase5_3_lib_core_extract_2026-05-16.md` §6.3 推 B(战斗系统 features 迁)起手 xhigh,理由 core 抽完后核心收益在 B/C。本会话开局列 B-H 候选 + 推荐,用户拍板 B + xhigh。

### 3.2 combat/ 归属决策(本会话自主)

closeout §6.3 写「combat/ → features/battle/domain/」,但盘点发现 combat/ 7 文件被 12+ 非 battle 文件引用(enhancement / character_panel / inventory / technique_panel / seclusion / tower / strings / debug),不是 battle feature 独占。考虑过拆分:

- 选项 A:整体进 features/battle/domain/(closeout §6.3 原方案)
- 选项 B:拆分 — 运行时(engine/ai/state/log)进 battle/domain/,公式(damage/derived)+ 枚举本地化进 core/domain/
- 选项 C:整体进 core/domain/combat/

最终选 **A 整体进 features/battle/domain/**,理由:
- `enum_localizations` 引 `battle_state` 的 `BattleResult`(`show BattleResult`),**与 battle_state 强耦合不可拆**,破了选项 B
- `derived_stats` 单独拎出来会破 combat/ 内部家庭感(damage_calc 也广引 5 次,enum_loc 13 次,广引不等于 core/domain/ 性质)
- 跨 feature 走 `../../battle/domain/` cookbook 允许,改动量集中可控

### 3.3 stage_battle_setup 归属

进 **battle/application/**(职责为「为战斗准备 BattleState」,跟 battle_resolution 同语义,非 mainline 独占)。

---

## 4. 代码改动清单

### 4.1 Step 1 — combat/ 7 文件迁(commit afcfd87 rename + 14c183a content)

**文件迁移**(`git mv` ×7):
- `lib/combat/{battle_ai,battle_engine,battle_log,battle_state,damage_calculator,derived_stats,enum_localizations}.dart` → `lib/features/battle/domain/`

**被迁文件内部 outgoing imports 深度 +2**(6 文件 ~24 行):
- `'../data/'` → `'../../../data/'`
- `'../core/'` → `'../../../core/'`
- 内部互引 `'X.dart'`(同级)不变

**跨引外部 4 种 import 形式**(~25 文件):
- 形式 1 lib/services/(3):`'../combat/X'` → `'../features/battle/domain/X'`
- 形式 2 lib/ui/battle, ui/enhancement, ui/debug, core/application/(7):`'../../combat/X'` → `'../../features/battle/domain/X'`
- 形式 3 lib/features/*/presentation/(6 引用 in 6 文件):`'../../../combat/X'` → `'../../battle/domain/X'`(深度 -1)
- 形式 4 test/(11):`'package:wuxia_idle/combat/X'` → `'package:wuxia_idle/features/battle/domain/X'`

**Sed 策略**:形式 3 features/ 单独 perl(深度 -1 需独立处理),剩余形式 1/2/4 全仓 sed `combat/` → `features/battle/domain/` 一刀切。**一次过 analyze 0 issues**(combat/ 内部互引同级 `'X.dart'` 不含 `combat/` 串,sed 不动到 — 路径模式选「全唯一」教训)。

**工作流踩坑**:`git mv` 后 `perl -i` 改的内容**未自动 stage**,首个 commit `afcfd87` 只 commit 了 100% similarity 的 rename。立即补 commit `14c183a` 把 import 修改 staging 进去。本批 Step 1 拆 2 commit,Step 2/3 修正(git mv + perl + git add 一起做)。

### 4.2 Step 2 — ui/battle/ 6 文件迁(commit 06158cf rename + content)

**文件迁移**:
- `lib/ui/battle/{attack_animation,battle_demo,battle_screen,character_avatar,damage_popup,hp_bar}.dart` → `lib/features/battle/presentation/`

**被迁文件内部 imports 调整**(6 文件 ~17 处):
- 同 feature 内收敛:`'../../features/battle/domain/X'` → `'../domain/X'`(深度 -1)
- 跨 lib 深度 +1:`'../../data/'` `'../../core/'` → `'../../../data/'` `'../../../core/'`
- 跨 ui 同层 → 跨目录:`'../effects/'` `'../strings.dart'` `'../theme/'` → `'../../../ui/effects/'` `'../../../ui/strings.dart'` `'../../../ui/theme/'`
- 同目录互引 `'hp_bar.dart'` `'attack_animation.dart'` 等不变

**跨引外部 3 文件**:
- lib/features/{tower,mainline}/presentation/entry_flow:`'../../../ui/battle/X'` → `'../../battle/presentation/X'`(features 内 -1)
- test/widget_test.dart:`'package:wuxia_idle/ui/battle/X'` → `'package:wuxia_idle/features/battle/presentation/X'`

**漏改雷达暴露 1 处**(教训第 2 次复证):
- `lib/ui/debug/battle_test_menu.dart:8` 用 `'../battle/X'` 形式(同 ui 下 1 层相对路径,不含 `ui/battle/` 串),首轮 grep 漏列。analyze 第 1 次直接锁定 2 error,1 行 perl 补齐 → `'../../features/battle/presentation/X'`(深度 +1)。

### 4.3 Step 3 — 4 service 迁(commit ce84cd3 rename + content)

**文件迁移**(`git mv` ×4):
- `lib/services/battle_resolution.dart` + `stage_battle_setup.dart` → `lib/features/battle/application/`
- `lib/services/cultivation_service.dart` → `lib/features/cultivation/application/`
- `lib/services/dispel_service.dart` → `lib/features/dispel/application/`

**被迁文件内部 imports 调整**(4 文件 ~20 行):
- 同 feature 收敛(battle 内):`'../features/battle/domain/X'` → `'../domain/X'`
- 同源服务链跨 feature(battle_resolution):`'cultivation_service.dart'` `'dispel_service.dart'` → `'../../cultivation/application/X'` `'../../dispel/application/X'`
- 跨 lib 深度 +2:`'../core/'` `'../data/'` `'../utils/'` `'../features/tower/'` → `'../../../X/'` / `'../../tower/'`
- `battle_resolution` 引 `lib/services/drop_service.dart`(还在原位)→ `'../../../services/drop_service.dart'`(drop_service 留待 C 装备系迁)

**跨引外部**(5 lib + 9 test):
- lib/core/application/battle_providers.dart(深 2)
- lib/providers/isar_provider.dart(深 1,引 stage_battle_setup + dispel_service)
- lib/features/{tower,mainline}/presentation/entry_flow(深 3,features 内 -1)
- lib/features/technique_panel/presentation/technique_panel_screen.dart(深 3)
- test/services/ 9 文件 package: 路径切换

**漏改雷达暴露 1 处 + 连锁 1 error**(教训第 3 次复证 + **新 bug 模式**):
- `battle_resolution.dart` 引 `'drop_service.dart'`(同 services/ 同级),首轮 grep cross-ref 时只列了 cultivation/dispel 两个**并迁服务**,漏掉 drop_service 这个**留原位的服务**。
- analyze 第 1 次锁定 4 error(uri + undefined_class)+ stage_entry_flow.dart:367 **连锁 1 error**(`invalid_assignment`:double 不能赋给 int)
- 连锁 error 排查:漏改 drop_service import 让 `result.dropResult.items` 类型推断**回退 dynamic**,`item.quantity` 是 dynamic 加到 int 上推断为 num → `+=` 触发类型错误。修 drop_service import 后**连锁 error 自动消失**,印证 type inference 传染机制。
- 1 行 perl `s|'drop_service\.dart|'../../../services/drop_service.dart|g` 补齐继续。

---

## 5. 关键决策

### 5.1 combat/ 整体进 features/battle/domain/(本会话拍板)

见 §3.2 详。结论:**广引不等于 core/domain/ 性质**,内部互引强耦合(`enum_localizations` show `BattleResult`)优先于跨 feature 引用数量考量。

### 5.2 cultivation / dispel 各为独立 feature(非 battle 子模块)

cultivation_service / dispel_service 跟 battle_resolution 有调用关系(同源服务链),但**各自有独立的运行逻辑和领域语义**:cultivation 是修炼度计算,dispel 是散功代价计算。平级 lib/features/{battle,cultivation,dispel}/ 平级 feature,避免「battle feature 越界吸纳跨域服务」。

### 5.3 stage_battle_setup 进 battle/application/

虽然 stage 概念属 mainline / tower 系统,但 `stage_battle_setup` 的职责是「把 stage 配置转换为 BattleState」,**核心是 battle 数据准备**而非 mainline / tower 逻辑。跟 `battle_resolution` 同职责语义,进 battle/application/ 内聚。

### 5.4 drop_service / enhancement / forging / equipment_factory 留 lib/services/

这 4 service 属装备系,**留待下波 C 任务整体迁**。本批不顺手迁的理由:范围控制 + Step 3 已经引入跨服务链改动(battle_resolution → cultivation/dispel),再加装备系会让单 commit 过大失控。

---

## 6. 下次开局必读

### 6.1 状态快照

- HEAD `ce84cd3`(本会话末态,push 待 — 本批 4 commit + closeout/PROGRESS commit)
- tag `v0.5.3-w15-final` 保留(W15 锚点)
- 653/653 测试 + analyze 0 issues
- §12 待决 2 条不变(#7 流派 extra_effect / #10 师承遗物规则)
- **lib/features/battle/**:domain(7)+ application(2)+ presentation(6)= **15 文件三层全**
- **lib/features/cultivation/**:application(1)
- **lib/features/dispel/**:application(1)
- **lib/combat/**:目录消失
- **lib/ui/battle/**:目录消失
- **lib/services/**:剩 6 文件(drop / enhancement / equipment_factory / forging / phase2_seed / technique_learning)
- **lib/ui/**:剩 7 项(debug / effects / enhancement / narrative / theme + main_menu.dart + strings.dart)
- Phase 5 主战场 **10/14 feature 落地**

### 6.2 开局动作

1. 读 PROGRESS.md「当前阶段」+「下一步」+「挂账事项」
2. 读本 closeout §6 下次开局必读
3. `git pull --rebase --autostash` 看 drift(本会话末态待 push)
4. 选读 §7 教训沉淀 2 条(工作流 git mv + perl 分批 stage / invalid_assignment 类型推断连锁)

### 6.3 下波候选

| 候选 | 模型 | 时长 | 备注 |
|---|---|---|---|
| **C. 装备系统 features 迁** ⭐ | xhigh + 拍板 | 2-3h | drop / equipment_factory / forging / enhancement + ui/enhancement/ 一团。battle_resolution 引 drop_service 现在走 `'../../../services/'`,C 完后改 `'../../equipment/application/'` 收敛 |
| D. service interface 抽离 + Mocktail 引入 | sonnet | 1-2h | 正规化 `implements concrete class`,B/C 完后服务边界更清晰 |
| E. lib/shared 抽 UI 通用组件 | sonnet | 1-2h | theme/effects/tier_colors/screen_shake |
| F. #34 stage drop 视觉验收 Pen 环境改善 | Codex 派单 | 1h | 老挂账 |
| G. Pen-only T64 test fail 排查 | sonnet | 30min | 老挂账 |
| H. techniqueLearnPoints / internalForcePoints 消费层接入 | opus | 2-3h | #30 新维度落 Character/Technique |

**推荐起手 C**(装备系统 features 迁):
- battle_resolution → drop_service 跨目录引用有「债」,C 完直接收敛到 `'../../equipment/application/drop_service.dart'`
- lib/services/ 剩 4 service(drop / equipment_factory / forging / enhancement)+ lib/ui/enhancement/ 一团,迁完 lib/services/ 剩 2 个(phase2_seed / technique_learning)
- B 后顺手做 C 把战斗 + 装备两大系一起收完,Phase 5 主战场 10/14 → 12/14 落地

### 6.4 硬约束(沿用 + 本批新增)

**沿用**(Phase 5 #2/#3/#4 各批纪律):
- 不动 GDD.md / numbers.yaml 数值层 / IDS_REGISTRY.md / data_schema.md
- 不动 data/narratives/ data/lore/ data/events/(DeepSeek 领地)
- Mac 缺 Xcode 跑不了 `flutter run -d macos`,实战截图派 Pen Codex
- catch 块加 debugPrint / Isar @embedded List 写前 List.of 转 growable
- preset lore 按需 LoreLoader.load 不写 Isar
- 红线测试写「约束语义」不写「瞬时事实」
- closeout 数字必 grep 实测
- 派单 spec 的「预期值」必须 grep 派单源头
- UI 字段读取:实例可与 def 不一致的字段一律读实例
- 视觉验收 FAIL 字段类 1 行 fix → widget test 兜底
- Codex 双备份角色,默认三方隔离
- Pen GUI 长链路连续导航不稳 → 走干净启动 + fixture 路径
- 节气清单方案 A 公历 hardcode
- 闭关产出 4 维度全乘 `realmScale × solarBonus`,内力维度额外乘 `ziShiBonus`
- yaml 字段命名暗示语义
- lib/core/domain/ 是领域模型唯一归宿
- lib/core/application/ 收跨 feature 共享业务 providers
- 基础设施 providers 留 lib/providers/(isar / rng)
- 批量 import 改用全仓 sed 一刀切优先,字符串选择性强的路径(如 `/data/models/`、`/combat/`)安全;字符串冲突路径单独 perl 跑
- path-level analyze 漏改预警:全仓 sed 后第 1 次 analyze 必跑

**Phase 5 #3 第 5 批新增**:
- **战斗系统三层全 feature 化**:battle 是 Phase 5 第 1 个完整三层的 feature(domain/application/presentation 全)
- **同源服务链跨 feature 引用走相对路径**:battle_resolution 引 cultivation_service / dispel_service,从「同 services/ 同级」改为「跨 feature 相对 `'../../cultivation/application/X'`」,符合 cookbook 跨 feature 纪律
- **stage_battle_setup 归 battle/application/**(语义内聚,非 mainline / tower 独占)
- **【新教训 1 — 工作流】**:`git mv` + `perl -i` 改被迁文件内容时,perl 修改**不会自动 staging**(只 stage 了 rename)。两种修法:① git mv 后 `git add` 一次再 commit(rename + content 合一);② 分 2 commit(本批 Step 1 撞到),不优雅但符合「不 amend」纪律。**最佳实践**:git mv → perl-i → `git add -u` → commit。
- **【新教训 2 — 漏改雷达延伸】**:漏改 import 不仅会触发 `uri_does_not_exist` 直接 error,**还可能让下游类型推断回退 dynamic,引发看似无关的 `invalid_assignment` 连锁 error**。本批 Step 3 漏 drop_service import 让 `result.dropResult.items` 推断为 dynamic,传染到 `stage_entry_flow.dart:367` `existing.quantity += item.quantity` 触发 double → int 错。**判断方法**:看到 `invalid_assignment` 且周边没明显类型 mismatch,先排查是否有 import 漏改。
- **grep cross-ref 时记得列「留原位的同源服务」**:本批 grep 只列了 cultivation / dispel(并迁),漏 drop_service(留原位,但被同源 battle_resolution 引用)。**判定纪律**:被迁文件的同目录 import 全列,无论 import 目标是否同批迁。

---

## 7. 教训沉淀(本批 2 新坑 + 老教训复证 3 次)

### 7.1 【新坑】git mv 后 perl -i 改的内容必须 git add 才会 stage

**现象**:Step 1 commit `afcfd87` 显示「7 files changed, 0 insertions(+), 0 deletions(-)」 — 只 stage 了 100% similarity 的 rename,perl 改的内容全在 working tree 未 stage。

**原因**:`git mv` staging 的是 rename 操作(index 里旧路径 → 新路径,内容不变)。之后用 `perl -i` 直接修改新位置文件,这是 working tree 改动,**不会自动同步到 index**。

**修法**:
- 方案 A(本批 Step 2/3 用):git mv → perl-i → `git add -u` → commit(一次性 rename + content 合一)
- 方案 B(本批 Step 1 撞到):commit rename → perl-i → git add → 第 2 个 commit(content)。**不优雅但符合「不 amend」纪律**

**最佳实践**:**先全部 git mv,再全部 perl-i,最后一次 `git add -u` + commit**。

(memory 沉淀:`feedback_git_mv_perl_stage.md`)

### 7.2 【新坑】漏改 import 触发的 invalid_assignment 连锁 error

**现象**:Step 3 漏改 `battle_resolution.dart` 内 `'drop_service.dart'` import → analyze 同时报:
- 4 个直接 error(uri_does_not_exist + undefined_class + creation_with_non_type)
- 1 个**连锁 error**:`lib/features/mainline/presentation/stage_entry_flow.dart:367` `'double' can't be assigned to 'int'`

**原因**:`result.dropResult.items` 因 `DropResult` 类型不可用,推断回退 `dynamic`。`item.quantity` 是 dynamic 类型,`existing.quantity += item.quantity` 在 Dart 里推断为 `num`(dynamic + int),但 `existing.quantity` 是 `int`,触发 `invalid_assignment`。

**判断方法**:看到 `invalid_assignment` 报错且周边没明显类型 mismatch,**先排查是否有 import 漏改导致类型回退 dynamic**。修 import 后,连锁 error 通常自动消失。

**通用经验**:**先 fix uri_does_not_exist 类直接 error,再 re-analyze 看剩余 error 是否连锁消失**,不要被连锁 error 误导去修无关代码。

(memory 沉淀:`feedback_layered_bugs.md` 已有「上层 fail 掩盖下层 bug」,本批是「上层 fail 引发无关下层假象 bug」,补充进同一 memory)

### 7.3 【老教训复证】全仓 sed 优先选「全唯一」字符串模式

第 4 批沉淀的 `feedback_batch_sed_analyze_radar` 本批**实测 2 次**:
- Step 1 `lib/combat/` → `lib/features/battle/domain/` 路径全唯一,一刀切零漏改(combat/ 内部互引同级 `'X.dart'` 不含 `combat/` 串,sed 不动到)
- Step 2 `lib/ui/battle/` 漏一处 `'../battle/'`(lib/ui/debug/battle_test_menu.dart 引用 — 同 ui 下 1 层路径不含 `ui/battle/` 串)
- Step 3 `services/X.dart` 漏 drop_service(同源 import 列表不全)

**判断纪律**:全仓 sed 后**第 1 次 analyze 必跑**,error list 是漏改雷达。本批 3 步全用 sed 一刀切,3 次 analyze 各暴露 0/2/5 error(全 1 行 perl 补齐),零回退。

### 7.4 【老教训复证】跨目录迁后内部 import 深度调整

第 4 批 §7.2 沉淀的「同层 -1 / 跨层 +1」纪律,本批 Step 1/2/3 全 3 次复证:
- Step 1 combat/ → features/battle/domain/(深 1 → 深 3,深度 +2 跨层 / 内部互引同级不变)
- Step 2 ui/battle/ → features/battle/presentation/(深 2 → 深 3,深度 +1 跨层 / 同 feature 内 -1 收敛 / 跨 ui 同层 → 跨目录)
- Step 3 services/ → features/<F>/application/(深 1 → 深 3,深度 +2 跨层 / 同 feature 内 -1 收敛 / 同源服务跨 feature)

**通用公式**:`新深度 = lib 到新位置的 ../ 层数`,内部 import 深度 = 路径调整 = `(原相对路径 ../ 数) +/- (深度变化)`。

### 7.5 【老教训复证】.g.dart 走 mv 不 git mv

本批战斗系 0 .g.dart(combat / ui/battle / services 全 0 .g.dart 文件),不撞这个坑。但**B 任务暴露 features/ 内有 .g.dart 的需要按第 4 批纪律处理**(下波 C 任务 Riverpod 装备相关 service 可能有 .g.dart)。

---

## 8. 文件清单

### 8.1 新位置(lib/features/{battle,cultivation,dispel}/)

**lib/features/battle/domain/**(7 文件,Step 1):
- battle_ai.dart
- battle_engine.dart
- battle_log.dart
- battle_state.dart
- damage_calculator.dart
- derived_stats.dart
- enum_localizations.dart

**lib/features/battle/presentation/**(6 文件,Step 2):
- attack_animation.dart
- battle_demo.dart
- battle_screen.dart
- character_avatar.dart
- damage_popup.dart
- hp_bar.dart

**lib/features/battle/application/**(2 文件,Step 3):
- battle_resolution.dart
- stage_battle_setup.dart

**lib/features/cultivation/application/**(1 文件,Step 3):
- cultivation_service.dart

**lib/features/dispel/application/**(1 文件,Step 3):
- dispel_service.dart

### 8.2 删除目录

- `lib/combat/`(Step 1 后 rmdir)
- `lib/ui/battle/`(Step 2 后 rmdir)

### 8.3 留原位

- `lib/services/`:drop_service / enhancement_service / equipment_factory / forging_service / phase2_seed_service / technique_learning(6 文件,留待 C 装备系迁 + 后续 phase2 / technique 整理)
- `lib/ui/`:debug / effects / enhancement / narrative / theme + main_menu.dart + strings.dart(7 项)
- `lib/core/`:domain(12)+ application(3)(第 4 批落地不动)
- `lib/providers/`:isar_provider / rng_provider(2 基础设施 providers)

---

## 9. commit 链

```
ce84cd3 feat(Phase5-#3): 战斗系第 3 步 — 4 service 迁到各 feature application/
06158cf feat(Phase5-#3): ui/battle/ 迁到 lib/features/battle/presentation/(战斗系第 2 步)
14c183a feat(Phase5-#3): 战斗系第 1 步 import 改齐(combat 工作流补 commit)
afcfd87 feat(Phase5-#3): combat/ 迁到 lib/features/battle/domain/(战斗系第 1 步)
9dfb059 docs(Phase5-#3): closeout + PROGRESS lib/core 抽离完成(/clear 准备) ← 上批末态
```

---

**END**
