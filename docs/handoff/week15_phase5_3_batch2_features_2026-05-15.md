# Week 15 · Phase 5 #3 第 2 批 feature 迁(tower / mainline / encounter)closeout

> 2026-05-15 · opus(xhigh + 用户拍板 A 整批)· Phase 5 #2 cookbook 落地后批量复用。
>
> **结论**:tower / mainline / encounter 3 feature 完整迁到 `lib/features/{tower,mainline,encounter}/{domain,application,presentation}/`,**3 feature 全部零踩坑一次过**(analyze 0 issues + 653/653 全测,3 次连续 verify 无回退)。Phase 5 主战场 4/14 feature 落地(seclusion + tower + mainline + encounter)。cookbook 8 步样板验证完全可复用。**本批无新踩坑,cookbook 不需要更新**。

---

## 1. 一句话结论

闭关试点 cookbook 复用 3 次零坑通过,DDD 批量迁移模式成熟,A 整批一次性推完。

## 2. 会话密度统计

- 起步:用户拍板 A(opus xhigh + 整批 4-6h)
- 侦察:每 feature 1-2 轮 grep + import 关系图
- 迁移文件 35 (24 lib + 11 test)
  - tower:9 lib + 4 test
  - mainline:8 lib + 3 test(无 stage_entry_flow_test)
  - encounter:7 lib + 4 test
- import 改 57 处
  - tower:18(7 内部 + 6 外部 lib + 5 test 包路径)
  - mainline:16(5 内部 + 4 外部 lib + 5 test 包路径,跨 feature tower/phase2_seed 含)
  - encounter:23(6 内部 + 11 外部 lib + 6 test 包路径,跨 feature mainline/tower/seclusion 含)
- analyze 3 次 0 issues,全测 3 次 653/653(无回退,无修复中间步骤)
- commit 3 个独立 feat(Phase5-#3),渐进锚点

## 3. 用户拍板

`Phase 5 #2 closeout §6.3` 7 候选,用户拍 A 整批(opus xhigh,4-6h):「推 A + opus xhigh」。

按 closeout 推荐顺序:tower(体量同 seclusion) → mainline(中等) → encounter(最复杂)。

## 4. 代码改动清单(按 feature)

### 4.1 tower(commit `da2d20f`)

**迁文件 13(9 lib + 4 test)**:

```
lib/data/defs/tower_floor_def.dart            → lib/features/tower/domain/tower_floor_def.dart
lib/data/models/tower_progress.dart           → lib/features/tower/domain/tower_progress.dart
lib/data/models/tower_progress.g.dart         → 普通 mv(gitignored)
lib/services/tower_progress_service.dart      → lib/features/tower/application/tower_progress_service.dart
lib/providers/tower_providers.dart            → lib/features/tower/application/tower_providers.dart
lib/providers/tower_providers.g.dart          → 普通 mv
lib/ui/tower/tower_entry_flow.dart            → lib/features/tower/presentation/tower_entry_flow.dart
lib/ui/tower/tower_floor_card.dart            → lib/features/tower/presentation/tower_floor_card.dart
lib/ui/tower/tower_floor_list_screen.dart     → lib/features/tower/presentation/tower_floor_list_screen.dart
test/data/tower_floor_def_test.dart           → test/features/tower/domain/tower_floor_def_test.dart
test/services/tower_progress_service_test.dart → test/features/tower/application/tower_progress_service_test.dart
test/ui/tower/tower_entry_flow_test.dart      → test/features/tower/presentation/tower_entry_flow_test.dart
test/ui/tower/tower_floor_list_screen_test.dart → test/features/tower/presentation/tower_floor_list_screen_test.dart
```

`rmdir lib/ui/tower test/ui/tower`。

**外部 import 改 6 lib**:
- `lib/ui/main_menu.dart` — `import 'tower/tower_floor_list_screen.dart'` → `import '../features/tower/presentation/tower_floor_list_screen.dart'`
- `lib/providers/isar_provider.dart` — tower_progress_service 路径
- `lib/data/isar_setup.dart` — tower_progress 路径
- `lib/data/game_repository.dart` — tower_floor_def 路径
- `lib/services/drop_service.dart` — tower_floor_def 路径
- `lib/services/stage_battle_setup.dart` — tower_floor_def 路径

**test 外部 import 改 5 处**:`drop_service_test` 1 处 + 4 迁后 test 包路径自身。

**tower 与 seclusion 试点对比**:
- 体量:9 vs 7 lib,4 vs 3 test
- 步骤:**无 Consumer 化**(`tower_floor_list_screen` 已 ConsumerWidget,`tower_entry_flow` 已 ConsumerStatefulWidget)
- 无 fake service 新建,无 build_runner 重跑
- analyze 0 issues 一次过,无隐藏 import(对比 seclusion 试点踩 `numbers_config.dart`)

### 4.2 mainline(commit `6b35efd`)

**迁文件 11(8 lib + 3 test)**:

```
lib/data/models/mainline_progress.dart         → lib/features/mainline/domain/mainline_progress.dart
lib/data/models/mainline_progress.g.dart       → 普通 mv
lib/services/mainline_progress_service.dart    → lib/features/mainline/application/mainline_progress_service.dart
lib/providers/mainline_providers.dart          → lib/features/mainline/application/mainline_providers.dart
lib/providers/mainline_providers.g.dart        → 普通 mv
lib/ui/mainline/chapter_list_screen.dart       → lib/features/mainline/presentation/chapter_list_screen.dart
lib/ui/mainline/stage_entry_flow.dart          → lib/features/mainline/presentation/stage_entry_flow.dart
lib/ui/mainline/stage_list_screen.dart         → lib/features/mainline/presentation/stage_list_screen.dart
test/services/mainline_progress_service_test.dart → test/features/mainline/application/mainline_progress_service_test.dart
test/ui/mainline/chapter_list_screen_test.dart → test/features/mainline/presentation/chapter_list_screen_test.dart
test/ui/mainline/stage_list_screen_test.dart   → test/features/mainline/presentation/stage_list_screen_test.dart
```

`rmdir lib/ui/mainline test/ui/mainline`。

**外部 import 改 4 lib + 跨 feature**:
- `lib/data/isar_setup.dart` — mainline_progress 路径
- `lib/providers/isar_provider.dart` — mainline_progress_service 路径
- `lib/services/phase2_seed_service.dart` — mainline_progress_service 路径
- `lib/ui/main_menu.dart` — chapter_list_screen 路径

**test 外部 import 改 2 跨 feature**:
- `test/features/tower/application/tower_progress_service_test.dart` — mainline_progress 包路径
- `test/services/phase2_seed_service_test.dart` — mainline_progress 包路径

**stage_entry_flow 22 imports** 全部修订(data/providers/services/ui 全段),Consumer 化已就位,验证大文件批量改 import 也能一次过。

### 4.3 encounter(commit `a23baf5`)

**迁文件 11(7 lib + 4 test)**:

```
lib/data/defs/encounter_def.dart               → lib/features/encounter/domain/encounter_def.dart
lib/data/encounter_event_loader.dart           → lib/features/encounter/domain/encounter_event_loader.dart
lib/data/models/encounter_progress.dart        → lib/features/encounter/domain/encounter_progress.dart
lib/data/models/encounter_progress.g.dart      → 普通 mv
lib/services/encounter_service.dart            → lib/features/encounter/application/encounter_service.dart
lib/ui/encounter/encounter_dialog.dart         → lib/features/encounter/presentation/encounter_dialog.dart
lib/ui/encounter/encounter_hook.dart           → lib/features/encounter/presentation/encounter_hook.dart
test/data/encounter_skills_yaml_test.dart      → test/features/encounter/domain/encounter_skills_yaml_test.dart
test/data/encounter_yaml_test.dart             → test/features/encounter/domain/encounter_yaml_test.dart
test/services/encounter_service_test.dart      → test/features/encounter/application/encounter_service_test.dart
test/ui/encounter/encounter_outcome_banner_test.dart → test/features/encounter/presentation/encounter_outcome_banner_test.dart
```

`rmdir lib/ui/encounter test/ui/encounter`。

**外部 import 改 11 lib**(跨 feature 引用最多的 feature,encounter 是多个 feature 的依赖):
- `lib/data/isar_setup.dart` — encounter_progress
- `lib/data/game_repository.dart` — encounter_def
- `lib/providers/isar_provider.dart` x2 — encounter_progress + encounter_service
- `lib/services/phase2_seed_service.dart` x2 — encounter_progress + encounter_service
- `lib/features/seclusion/application/seclusion_service.dart` — 跨 feature `../../encounter/application/encounter_service.dart`
- `lib/features/mainline/presentation/stage_entry_flow.dart` — 跨 feature `../../encounter/presentation/encounter_hook.dart`
- `lib/features/tower/presentation/tower_entry_flow.dart` — 跨 feature `../../encounter/presentation/encounter_hook.dart`
- `lib/ui/character_panel/encounter_skill_section.dart` x2 — encounter_progress + encounter_service
- `lib/ui/debug/encounter_debug_picker.dart` x4 — encounter_def + encounter_event_loader + encounter_service + encounter_dialog

**test 外部 import 改 3 跨 feature**:
- `test/features/seclusion/application/seclusion_service_test.dart` — encounter_progress + encounter_service
- `test/features/seclusion/presentation/seclusion_e2e_test.dart` — encounter_service
- `test/services/phase2_seed_service_test.dart` — encounter_progress

**留 ui/character_panel 与 ui/debug 不迁**:
- `encounter_skill_section.dart` 是 character_panel 的 sub-widget(被 character_panel_screen 引用),跨 feature 引用 encounter domain/application 即可。**待 character_panel feature 后续迁时,再决定是否一并搬到 features/character_panel/presentation/**。
- `encounter_debug_picker.dart` 是 debug entry,跨 feature 性质,留 `ui/debug` 合理。

## 5. 测试与验证

- 每个 feature 完成后 `flutter analyze` + `flutter test`(2 verify)
- 3 次 verify 全 0 regress,**总计 6 次绿灯**(analyze 3 + test 3)
- 653/653 测试稳定,无 case 增减(本批纯路径迁移,无功能改动)

## 6. 下次开局必读

### 6.1 状态快照

- HEAD `a23baf5` push 待
- 653/653 测试 + analyze 0 issues
- §12 待决 2 条不变(#7 / #10)
- 4 features 完整迁到 `lib/features/`:**seclusion / tower / mainline / encounter**
- 老路径 `lib/ui/{tower,mainline,encounter}` / `lib/data/models/{tower_progress,mainline_progress,encounter_progress}` / `lib/data/defs/{tower_floor_def,encounter_def}` / `lib/data/encounter_event_loader.dart` / `lib/services/{tower_progress_service,mainline_progress_service,encounter_service}` / `lib/providers/{tower_providers,mainline_providers}` **全部不再存在**
- 13 → **10 features 未迁**(`combat / data / providers / services / ui / utils` 留 flat 结构):character_panel / inventory / technique_panel / battle / narrative / equipment(forging+enhancement)/ cultivation / dispel / phase2_seed / 其他散

### 6.2 开局动作

1. 读 PROGRESS.md「当前阶段」+「下一步」+「挂账事项」
2. 读本 closeout §6 下次开局必读
3. `git pull --rebase --autostash` 看 drift(本会话末态待 push)

### 6.3 下波候选

| 候选 | 模型 | 时长 | 备注 |
|---|---|---|---|
| **A. 第 3 批 feature 迁(character_panel / inventory / technique_panel)** | xhigh + 拍板 | 3-5h | UI feature 群,体量与本批相近;character_panel 含 encounter_skill_section 子组件可一并搬 |
| B. 战斗系统 features 迁(battle / dispel / cultivation) | xhigh + 拍板 | 3-4h | 数值逻辑核心,domain 公式 + application service + presentation 战斗 UI |
| C. 装备系统 features 迁(equipment 含 forging / enhancement) | xhigh + 拍板 | 2-3h | drop_service / equipment_factory / forging_service / enhancement_service 一团 |
| D. service interface 抽离 + Mocktail 引入 | sonnet | 1-2h | 4 feature 都已 fake_async 模式成熟,正规化 |
| E. lib/core 抽公共代码 | sonnet | 1h | combat/formulas.dart 等纯函数迁 lib/core/combat/ |
| F. lib/shared 抽 UI 通用组件 | sonnet | 1-2h | tier_colors / screen_shake / 通用 dialog |
| G. #34 stage drop 视觉验收 Pen 环境改善 | Codex 派单 | 1h | 老挂账 |
| H. Pen-only T64 test fail 排查 | sonnet | 30min | 老挂账 |
| I. techniqueLearnPoints / internalForcePoints 消费层接入 | opus | 2-3h | #30 新维度落 Character/Technique |

**推荐起手 A(xhigh + 拍板)**:Phase 5 主战场连续推进,character_panel / inventory / technique_panel 3 UI feature 群体量与本批相近,可批量推完。

### 6.4 硬约束(沿用)

- 不动 GDD.md / numbers.yaml 数值层 / IDS_REGISTRY.md / data_schema.md
- 不动 data/narratives/ data/lore/ data/events/(DeepSeek 领地)
- Mac 缺 Xcode 跑不了 flutter run -d macos,实战截图派 Pen Codex
- catch 块加 debugPrint / Isar @embedded List 写前 List.of 转 growable
- 不跨 service 嵌套 writeTxn / Dart extension 不与 List.add 同名签名冲突
- preset lore 按需 LoreLoader.load 不写 Isar;Equipment.lores 留延续典故
- 红线测试写「约束语义」不写「瞬时事实」
- closeout 涉及数字必须 grep 实测,加和也要复测
- 派单 spec 的「预期值」必须 grep 派单源头
- UI 字段读取:实例可与 def 不一致的字段一律读实例,def-level 不可变字段读 def
- 视觉验收 FAIL 字段类 1 行 fix → widget test 兜底
- Codex 双备份角色,默认三方隔离
- Pen GUI 长链路连续导航不稳 → 走干净启动 + fixture 路径
- 节气清单方案 A 公历 hardcode(W15 §12 收口决议)
- 闭关产出 4 维度全乘 `realmScale × solarBonus`,内力维度额外乘 `ziShiBonus`
- 乘数字段必须有 base 锚点(numbers.yaml retreat.base_*_per_hour)
- 迁 feature 前先 grep 全仓 import(不只看明显处,如 `numbers_config.dart` 隐藏 import 需 analyze 才暴露)
- `.g.dart` 在 .gitignore 中,迁文件时用普通 `mv` 而非 `git mv`,源 `.dart` 走 `git mv` 保 blame
- Riverpod codegen `.g.dart` 是 `part of` 同源 `.dart`,改源文件 import 后不需要重跑 build_runner
- Consumer 化后 e2e widget test 用 `_FakeService implements ConcreteService` + `provider.overrideWithValue(fake)`,绕过 native Isar zone

## 7. 教训沉淀(本批无新坑,cookbook 模式验证)

### 7.1 cookbook 8 步样板复用零坑

闭关试点踩了 5 个坑写进 cookbook(隐藏 import / `.g.dart` 普通 mv / build_runner 不重跑 / Consumer 化是真解 / fake service implements concrete class),后续 3 feature **零新坑**:

- 隐藏 import:tower 没有(没人用 `numbers_config.dart` 那样把 tower def 当类型注解),mainline 没有,encounter 没有
- `.g.dart`:3 feature 都遇到(`tower_progress.g.dart` / `tower_providers.g.dart` / `mainline_progress.g.dart` / `mainline_providers.g.dart` / `encounter_progress.g.dart`),全部按"普通 mv + 不重跑 build_runner"步骤通过
- Consumer 化:tower / mainline 主屏原已 Consumer 化(W6 drift 时 mainline 也修过),encounter 没有 UI 主屏需要状态(encounter_hook 是 helper,encounter_dialog 是无状态 dialog),都不需要新建 fake service

**模式验证完整**:cookbook 不需要新增踩坑记录。

### 7.2 跨 feature 引用的相对路径写法

mainline / tower 都引用 encounter(`stage_entry_flow` / `tower_entry_flow` 走 encounter_hook),seclusion_service 引用 encounter(W14-2 注入)。本批落地后,跨 feature 路径写法:

```dart
// 在 lib/features/mainline/presentation/ 引用 encounter
import '../../encounter/presentation/encounter_hook.dart';

// 在 lib/features/seclusion/application/ 引用 encounter
import '../../encounter/application/encounter_service.dart';
```

**经验**:`../../` 跳到 `lib/features/`,再 `<feature>/<layer>/<file>`。

### 7.3 跨 feature test 包路径

`test/features/tower/application/tower_progress_service_test.dart` 引用 `mainline_progress.dart`,迁完后:

```dart
// 原
import 'package:wuxia_idle/data/models/mainline_progress.dart';
// 新
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
```

`test/services/phase2_seed_service_test.dart` 是被多个 feature 引用最多的 test 文件(touch 4 个 feature 的模型),改 3 处 import(mainline_progress + encounter_progress + 其他)。

### 7.4 留位于 ui/ 的跨 feature widget

`encounter_skill_section.dart`(character_panel 子组件)+ `encounter_debug_picker.dart`(debug 入口)留在 `lib/ui/` 不迁。理由:跨 feature 性质,不属单一 feature 的 presentation 层。**未来 character_panel feature 迁时**,encounter_skill_section 可一并搬到 `lib/features/character_panel/presentation/`。debug 入口建议留 ui/debug 或建 `lib/features/debug/`(独立 feature)。

## 8. 文件清单

### 8.1 lib/(35 文件 + 5 .g.dart)

```
lib/features/
├── encounter/
│   ├── application/encounter_service.dart
│   ├── domain/encounter_def.dart
│   ├── domain/encounter_event_loader.dart
│   ├── domain/encounter_progress.dart (+ .g.dart)
│   └── presentation/encounter_dialog.dart
│   └── presentation/encounter_hook.dart
├── mainline/
│   ├── application/mainline_progress_service.dart
│   ├── application/mainline_providers.dart (+ .g.dart)
│   ├── domain/mainline_progress.dart (+ .g.dart)
│   ├── presentation/chapter_list_screen.dart
│   ├── presentation/stage_entry_flow.dart
│   └── presentation/stage_list_screen.dart
├── seclusion/   (W15 Phase 5 #2 已迁)
└── tower/
    ├── application/tower_progress_service.dart
    ├── application/tower_providers.dart (+ .g.dart)
    ├── domain/tower_floor_def.dart
    ├── domain/tower_progress.dart (+ .g.dart)
    ├── presentation/tower_entry_flow.dart
    ├── presentation/tower_floor_card.dart
    └── presentation/tower_floor_list_screen.dart
```

### 8.2 test/(11 文件,镜像)

```
test/features/{encounter,mainline,tower}/{domain,application,presentation}/*.dart
```

## 9. commit 链

```
a23baf5 feat(Phase5-#3): encounter feature 迁到 lib/features/encounter/
6b35efd feat(Phase5-#3): mainline feature 迁到 lib/features/mainline/
da2d20f feat(Phase5-#3): tower feature 迁到 lib/features/tower/
73c0a4b docs(Phase5-#2): closeout + PROGRESS 销账 #28(/clear 准备)  ← 上波锚点
```

**本批不打 tag**,v0.5.3-w15-final 保留 W15 锚点。Phase 5 整批 features 迁完后再考虑 v0.6.0-phase5-features tag。
