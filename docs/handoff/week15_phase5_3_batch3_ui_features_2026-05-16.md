# Week 15 · Phase 5 #3 第 3 批 feature 迁(character_panel / inventory / technique_panel)closeout

> 2026-05-16 · opus xhigh(用户拍板 A + 方案 1 只迁 presentation)· Phase 5 #3 第 2 批 cookbook 落地后第 2 次批量复用。
>
> **结论**:character_panel / inventory / technique_panel 3 UI feature **只迁 presentation 层**(方案 1)到 `lib/features/{character_panel,inventory,technique_panel}/presentation/`,model + providers 留原位等 lib/core 抽离时统一迁。**3 feature 零踩坑一次过**(analyze 0 issues + 653/653 全测,3 次连续 verify 无回退)。Phase 5 主战场 **7/14 feature 落地**(seclusion / tower / mainline / encounter / character_panel / inventory / technique_panel)。**顺手搬 `encounter_skill_section`**(closeout §7.4 预案落地),`encounter_debug_picker` 留 ui/debug/ 等独立 debug feature 时再决议。

---

## 1. 一句话结论

核心 model 跨 feature 共享时,**只迁 presentation 层是正确小步走**;3 UI feature 1.5h 整批落地,共 10 文件 4 commit 段。

## 2. 会话密度统计

- 起步:用户拍板 A(opus xhigh,3-5h 估)
- 决策:核心 model 跨 41/33/10 feature 共享 → 方案 1(只迁 presentation 层),用户拍板
- 侦察:每 feature 1 轮 grep(顶部 import + 外部入口 + 引用面)
- 迁移文件 **10**(6 lib + 4 test):
  - character_panel:2 lib + 1 test(顺手搬 encounter_skill_section)
  - inventory:2 lib + 2 test
  - technique_panel:2 lib + 1 test
- import 改 **20 处**:
  - character_panel:5(2 内部 + 2 外部入口 + 1 test 包)
  - inventory:6(2 内部 + 2 外部入口 + 2 test 包)
  - technique_panel:5(2 内部 + 2 外部入口 + 1 test 包)
  - 跨 feature 引用:encounter_skill_section → encounter feature 走 `../../encounter/<layer>/`
- analyze **3 次 0 issues**,全测 **3 次 653/653**(无回退,无修复中间步骤)
- commit **3 个独立** feat(Phase5-#3),rename 92-99% 保 blame

## 3. 用户拍板

### 3.1 起手 A

`Phase 5 #3 第 2 批 closeout §6.3` 9 候选,用户拍 A 整批(opus xhigh,3-5h)起手第 3 批 feature。

### 3.2 方案 1 vs 2 决策

侦察后发现核心 model 引用面:
- `character.dart`:**41 文件**(combat / data / 4 features / services / 3 ui / tests),全项目核心 entity
- `technique.dart`:**33 文件**,同样全项目核心
- `inventory_item.dart`:10 文件(seclusion/mainline/tower/encounter 等 4 features + enhancement/phase2_seed)
- `character_providers`:8 文件(跨 6 feature)/ `inventory_providers`:8 文件

如硬塞 `lib/features/character_panel/domain/character.dart`,会让 battle/cultivation/dispel 等 6+ feature 跨 feature 引一个 UI panel 的 domain,**语义颠倒**。CLAUDE.md §3 明确 lib/core/ 包含「领域模型」,这种共享 entity 真归宿是 `lib/core/domain/`(原 E 候选)。

用户拍 **方案 1**(只迁 presentation 层):
- 改 import ~10 处,1.5-2h,3 commit,小步走稳
- 缺点:三层不对称(domain/application 空),但等 E 候选(lib/core 抽离)时统一处理更干净

## 4. 代码改动清单(按 feature)

### 4.1 character_panel(commit `fca8dbd`)

**迁文件 3(2 lib + 1 test)**:

```
lib/ui/character_panel/character_panel_screen.dart       → lib/features/character_panel/presentation/character_panel_screen.dart
lib/ui/character_panel/encounter_skill_section.dart      → lib/features/character_panel/presentation/encounter_skill_section.dart
test/ui/character_panel/character_panel_screen_test.dart → test/features/character_panel/presentation/character_panel_screen_test.dart
```

**改 import 5 处**:
- `character_panel_screen.dart`:12 内部相对路径 `../..` → `../../..`(深度 +1),其中 `../strings.dart` / `../theme/colors.dart` / `../theme/tier_colors.dart` 因 ui/ 不迁,改 `../../../ui/<file>`
- `encounter_skill_section.dart`:10 内部相对路径同上;**跨 feature 引用** `../../features/encounter/domain/encounter_progress.dart` → `../../encounter/domain/encounter_progress.dart`(closeout §7.2 经验)
- `main_menu.dart`:`'character_panel/character_panel_screen.dart'` → `'../features/character_panel/presentation/character_panel_screen.dart'`
- `phase2_test_menu.dart`:`'../character_panel/character_panel_screen.dart'` → `'../../features/character_panel/presentation/character_panel_screen.dart'`
- test 包路径:`package:wuxia_idle/ui/character_panel/...` → `package:wuxia_idle/features/character_panel/presentation/...`

**verify**:analyze 0 issues + 653/653 全测过。

### 4.2 inventory(commit `38d4db6`)

**迁文件 4(2 lib + 2 test)**:

```
lib/ui/inventory/inventory_screen.dart             → lib/features/inventory/presentation/inventory_screen.dart
lib/ui/inventory/equipment_detail_screen.dart      → lib/features/inventory/presentation/equipment_detail_screen.dart
test/ui/inventory/inventory_screen_test.dart       → test/features/inventory/presentation/inventory_screen_test.dart
test/ui/inventory/equipment_detail_screen_test.dart → test/features/inventory/presentation/equipment_detail_screen_test.dart
```

**改 import 6 处**:
- `inventory_screen.dart`:13 内部相对路径同 character_panel 模式;`../enhancement/enhance_dialog.dart` → `../../../ui/enhancement/enhance_dialog.dart`(enhancement 不迁,跨 ui 引)
- `equipment_detail_screen.dart`:10 内部相对路径同上
- `main_menu.dart`:`'inventory/inventory_screen.dart'` → `'../features/inventory/presentation/inventory_screen.dart'`
- `phase2_test_menu.dart`:`'../inventory/inventory_screen.dart'` → `'../../features/inventory/presentation/inventory_screen.dart'`
- test 包路径:2 处

**verify**:analyze 0 issues + 653/653 全测过。

### 4.3 technique_panel(commit `c63d673`)

**迁文件 3(2 lib + 1 test)**:

```
lib/ui/technique_panel/technique_panel_screen.dart       → lib/features/technique_panel/presentation/technique_panel_screen.dart
lib/ui/technique_panel/dispel_dialog.dart                → lib/features/technique_panel/presentation/dispel_dialog.dart
test/ui/technique_panel/technique_panel_screen_test.dart → test/features/technique_panel/presentation/technique_panel_screen_test.dart
```

**改 import 5 处**:
- `technique_panel_screen.dart`:11 内部相对路径同模式;`../../services/dispel_service.dart` → `../../../services/dispel_service.dart`(services 不迁)
- `dispel_dialog.dart`:5 内部相对路径同
- `main_menu.dart` / `phase2_test_menu.dart`:外部入口同模式
- test 包路径:1 处

**verify**:analyze 0 issues + 653/653 全测过。

## 5. 留 ui/ 不迁

### 5.1 encounter_debug_picker.dart

`lib/ui/debug/encounter_debug_picker.dart` 是 debug 入口,跨 feature 触发奇遇。**留 ui/debug/ 不迁**,等独立 `lib/features/debug/` feature 或合并到 phase2_test_menu 时再决议。

### 5.2 phase2_test_menu / battle_test_menu / main_menu / strings / theme / effects / narrative

留 lib/ui/ 不迁的 7 项:
- `main_menu.dart` / `strings.dart`:**入口 + 字符串常量**,留 ui/ 根
- `theme/`:UI 主题,**lib/shared/ 候选 F** 迁时处理
- `effects/`:UI 特效(screen_shake 等),候选 F 迁时处理
- `enhancement/`:强化 dialog,**装备系统 features 候选 C**(equipment 含 forging+enhancement)迁时处理
- `battle/`:战斗 UI,**战斗系统 features 候选 B** 迁时处理
- `debug/`:debug menus,独立 debug feature 候选
- `narrative/`:剧情 UI,后续 narrative feature 候选

## 6. 下次开局必读

### 6.1 状态快照

- HEAD `c63d673`(本会话末端),push 待
- 653/653 测试 + analyze 0 issues
- §12 待决 2 条不变(#7 / #10)
- **7 features 完整迁到 `lib/features/`**:seclusion / tower / mainline / encounter / character_panel / inventory / technique_panel
- 老路径 `lib/ui/{character_panel,inventory,technique_panel}` **全部不再存在**
- 剩 lib/ui/ 7 项:battle / debug / effects / enhancement / narrative / theme + main_menu.dart + strings.dart

### 6.2 开局动作

1. 读 PROGRESS.md「当前阶段」+「下一步」+「挂账事项」
2. 读本 closeout §6 下次开局必读
3. `git pull --rebase --autostash` 看 drift(本会话末态待 push)

### 6.3 下波候选

| 候选 | 模型 | 时长 | 备注 |
|---|---|---|---|
| **A. lib/core 抽公共代码(model + providers)** ⭐ | xhigh | 3-4h | 把方案 1 留的 character.dart / technique.dart / inventory_item.dart / character_providers / inventory_providers / battle_providers 迁到 lib/core/domain + lib/core/application;改 import ~100 处 |
| B. 战斗系统 features 迁(battle / dispel / cultivation) | xhigh + 拍板 | 3-4h | 数值核心,domain 公式 + service + 战斗 UI;`lib/ui/battle/` + `lib/services/{battle_resolution,cultivation,dispel}` + `lib/combat/` 一团 |
| C. 装备系统 features 迁(equipment 含 forging / enhancement) | xhigh + 拍板 | 2-3h | `lib/services/{drop,equipment_factory,forging,enhancement}` + `lib/ui/enhancement/` 一团 |
| D. service interface 抽离 + Mocktail 引入 | sonnet | 1-2h | 把 `_FakeService implements ConcreteService` 正规化 |
| E. lib/shared 抽 UI 通用组件 | sonnet | 1-2h | `lib/ui/theme/` + `lib/ui/effects/` + tier_colors / screen_shake |
| F. #34 stage drop 视觉验收 Pen 环境改善 | Codex 派单 | 1h | 老挂账 |
| G. Pen-only T64 test fail 排查 | sonnet | 30min | 老挂账 |
| H. techniqueLearnPoints / internalForcePoints 消费层接入 | opus | 2-3h | #30 新维度落 Character/Technique |

**推荐起手 A**(lib/core 抽离):方案 1 留的尾巴最该先收。core 抽完后 B/C 战斗/装备系 features 迁 import 改起来更顺畅(直接引 core/domain/ 不再绕 lib/data/models/)。或 D-E 先做整理类小活作为热身。

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
- 迁 feature 前先 grep 全仓 import
- `.g.dart` 在 .gitignore 中,迁文件时用普通 `mv` 而非 `git mv`,源 `.dart` 走 `git mv` 保 blame
- Riverpod codegen `.g.dart` 是 `part of` 同源 `.dart`,改源文件 import 后不需要重跑 build_runner
- Consumer 化后 e2e widget test 用 `_FakeService implements ConcreteService` + `provider.overrideWithValue(fake)`,绕过 native Isar zone
- 【Phase 5 #3 第 3 批新增】**核心 model 跨多 feature 共享时,迁向某一 UI feature 的 domain/ 语义颠倒;暂留原位等 lib/core/ 抽离时统一迁**(本批方案 1 决策)
- 【Phase 5 #3 第 3 批新增】**只迁 presentation 层是 UI feature 在 model 未抽 core 前的安全模式**(三层不对称可接受,等 core 抽完补 domain/application)

## 7. 教训沉淀(本批无新坑)

### 7.1 cookbook 5 大坑全消解

闭关试点踩了 5 个坑写进 cookbook(隐藏 import / `.g.dart` 普通 mv / build_runner 不重跑 / Consumer 化是真解 / fake service implements concrete class),本批 3 feature **零新坑**:

- 隐藏 import:本批无 `.g.dart`(全手写文件)+ 无类型注解暗藏(只迁 presentation 层无 model 类型)
- Consumer 化:3 屏全 W3 时就是 ConsumerWidget,无需新建 fake service
- 跨 feature 引用:character_panel/encounter_skill_section 引 encounter 走 `../../encounter/<layer>/`(closeout §7.2 经验复用)
- 跨 ui 引用:enhance_dialog / strings / theme / dispel_service 留 lib/ui/ 或 lib/services/,走 `../../../<dir>/<file>`
- 外部入口 import 变化:深度 +1 一致,公式 `../<feature>/` → `../features/<feature>/presentation/`(main_menu)、`../<feature>/` → `../../features/<feature>/presentation/`(phase2_test_menu)

### 7.2 方案 1 vs 方案 2 决策标准

**方案 1**(只迁 presentation 层)**用于**:UI feature 共享核心 model + provider,model 跨 4+ feature 引用,塞 panel domain/ 语义颠倒。本批 3 feature 全部命中。

**方案 2**(三层完整 + lib/core 抽离)**用于**:① feature 独占 domain(seclusion/tower/mainline/encounter 模式);② lib/core 抽离单独成 commit 时,顺手把共享 entity 抽出来。后续 A 候选(lib/core 抽离)就是方案 2 的剩余尾巴。

**判断 grep 阈值**:`grep -rl "data/models/<model>\.dart" lib test | wc -l`,**> 10 文件即跨 feature 共享**,走方案 1;< 5 文件且都在同 feature → 走方案 2。

### 7.3 顺手搬 sub-widget 的边界

`encounter_skill_section.dart` 是 character_panel 的 sub-widget,本批顺手搬到 character_panel/presentation/。**边界**:sub-widget 只被一个 feature 引用 → 搬;被多 feature 引用 → 留 ui/。`encounter_debug_picker.dart` 是 debug 入口,跨 feature 调用 → 留 ui/debug/。

## 8. 文件清单

### 8.1 lib/(6 文件,新)

```
lib/features/
├── character_panel/
│   └── presentation/
│       ├── character_panel_screen.dart
│       └── encounter_skill_section.dart
├── inventory/
│   └── presentation/
│       ├── inventory_screen.dart
│       └── equipment_detail_screen.dart
└── technique_panel/
    └── presentation/
        ├── technique_panel_screen.dart
        └── dispel_dialog.dart
```

### 8.2 test/(4 文件,镜像)

```
test/features/{character_panel,inventory,technique_panel}/presentation/*.dart
```

### 8.3 留原位

- model:`lib/data/models/{character,technique,inventory_item}.dart`(等 lib/core/domain/ 抽离)
- providers:`lib/providers/{character,inventory,battle,isar,rng}_providers.dart`(等 lib/core/application/ 抽离)
- 公用 UI:`lib/ui/{strings,theme,effects,enhancement,debug,narrative,battle}/`(等候选 B/C/E)

## 9. commit 链

```
c63d673 feat(Phase5-#3): technique_panel feature 迁到 lib/features/technique_panel/
38d4db6 feat(Phase5-#3): inventory feature 迁到 lib/features/inventory/
fca8dbd feat(Phase5-#3): character_panel feature 迁到 lib/features/character_panel/
bdfe926 docs(Phase5-#3): closeout + PROGRESS 第 2 批完成(/clear 准备)  ← 上波锚点
```

**本批不打 tag**,v0.5.3-w15-final 保留 W15 锚点。Phase 5 整批 features 迁完后再考虑 v0.6.0-phase5-features tag。
