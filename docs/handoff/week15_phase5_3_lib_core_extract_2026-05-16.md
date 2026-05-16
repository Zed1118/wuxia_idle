# Phase 5 #3 第 4 批 — lib/core 抽公共代码(A 任务 / 方案 1 尾巴收口)

**日期**:2026-05-16
**模型**:Opus 4.7 xhigh(用户拍板升档)
**会话密度**:1 会话 / 2 commit / 12 model + 3 provider 迁离 / ~270 import 改 / 全程零回退
**HEAD**:`4d50492`(本会话末态,push 待)
**测试**:653/653 + analyze 0 issues(model 迁后第 1 次 verify + provider 迁后第 2 次 verify,**两次均一次过零修复**)

---

## 1. 一句话结论

把 `lib/data/models/` 12 个领域模型迁到 `lib/core/domain/`,把 `lib/providers/` 3 个跨 feature providers 迁到 `lib/core/application/`,**Phase 5 #3 第 3 批方案 1 决策留的尾巴收完**。改 ~270 处 import,跨 121 文件。lib/data/models/ 目录消失。lib/providers/ 仅剩 2 基础设施 providers(isar / rng)。

---

## 2. 会话密度统计

| 指标 | 值 |
|---|---|
| commit 数 | 2(`938434c` model 迁 / `4d50492` provider 迁) |
| 文件迁移 | 12 .dart + 11 .g.dart(model)+ 3 .dart + 3 .g.dart(provider)= **29 文件迁** |
| import 改动 | model 迁 277 行 / provider 迁 51 行 = **328 行 import 改动** |
| 改动文件数 | model 迁 120 文件 / provider 迁 23 文件 = **143 文件触及**(去重约 121 独立文件) |
| verify 节点 | 2(每 commit 一次 analyze + 全测) |
| 回退次数 | **0**(第 1 次 analyze 暴露 6 个 lib/data/defs/ 漏改,1 行 perl 补齐继续) |
| 用户介入 | 1 次(开局范围拍板:窄 / 宽 / 中,选「宽」) |

---

## 3. 用户拍板

### 3.1 起手 A + 升 xhigh

closeout `week15_phase5_3_batch3_ui_features_2026-05-16.md` §6.3 推荐 A,本批延续。用户拍板 A + xhigh,理由跨 100+ 处 import + Riverpod codegen `.g.dart` 兼容性 + 全测节点多,opus xhigh 兜底比 opus high 稳。

### 3.2 范围:宽(lib/data/models/ 全迁)

调研发现 closeout §6.3 写的"3 model + 3 providers"是保守口径。实际 `lib/data/models/` 有 12 文件,引用数 character 40 / technique 33 / equipment 43 / enums 98 / inventory_item 10 / attributes 20,**equipment/attributes/enums 等同样是核心领域模型**(纯 Dart + Isar 注解,无 Flutter 依赖),按 CLAUDE.md §3 也该一起迁。

用户选「宽(lib/data/models/ 全迁)」,理由:一次到位,B/C 战斗/装备系迁不用再抽 model。

---

## 4. 代码改动清单

### 4.1 Model 迁(commit `938434c`)

**文件迁移**:
- `git mv lib/data/models/*.dart lib/core/domain/`(12 文件:attributes / character / enums / equipment / forging_slot / game_event / inventory_item / lore / reward_entry / save_data / skill_usage_entry / technique)
- `mv lib/data/models/*.g.dart lib/core/domain/`(11 .g.dart,`.gitignore` 中走普通 mv)

**Import 改动**(120 文件 / 277 行 / 277 删):
1. **全仓一刀 sed**:`/data/models/` → `/core/domain/`(影响所有引用形式:`package:wuxia_idle/data/models/X.dart` + `'../data/models/X.dart'` + `'../../data/models/X.dart'` + `'../../../data/models/X.dart'`)
2. **lib/core/domain/equipment.dart + technique.dart 内部修复**:`'../numbers_config.dart'` → `'../../data/numbers_config.dart'`(出 data,引 data/numbers_config 路径变深)
3. **lib/data/ 内 3 文件修复**:`numbers_config.dart` / `game_repository.dart` / `isar_setup.dart` 内 `'models/X.dart'` → `'../core/domain/X.dart'`(同目录变跨目录)
4. **lib/data/defs/ 内 6 文件修复**:`X_def.dart` 内 `'../models/enums.dart'` → `'../../core/domain/enums.dart'`(第 1 次 analyze 暴露,sed 漏掉 `'../models/'` 形式补齐)

### 4.2 Providers 迁(commit `4d50492`)

**文件迁移**:
- `git mv lib/providers/{battle,character,inventory}_providers.dart lib/core/application/`(3 .dart)
- `mv lib/providers/{battle,character,inventory}_providers.g.dart lib/core/application/`(3 .g.dart)
- **lib/providers/ 留 isar_provider / rng_provider 2 基础设施 providers**(语义不同:跨 feature 共享的业务 providers 进 lib/core/application/,基础设施 providers 留 lib/providers/)

**Import 改动**(23 文件 / 51 行):
1. **provider 内部路径调整**:
   - `'../core/domain/X'` → `'../domain/X'`(同级目录,深度 -1)
   - `'../{data,combat,services,utils}/X'` → `'../../{...}/X'`(深度 +1)
2. **全仓 sed 三连**:
   - `providers/battle_providers.dart` → `core/application/battle_providers.dart`
   - `providers/character_providers.dart` → `core/application/character_providers.dart`
   - `providers/inventory_providers.dart` → `core/application/inventory_providers.dart`

---

## 5. 关键决策

### 5.1 基础设施 providers 留 lib/providers/(不迁)

`isar_provider` / `rng_provider` 是基础设施层(Isar instance + Random instance),不与具体业务关联,**不属于 application 层(用例/notifier)**。留 `lib/providers/` 维持基础设施语义,避免 lib/core/application/ 被冠"应用层"但其实塞基础设施的语义错位。

### 5.2 enums.dart 同迁 core/domain/

`enums.dart` 引用 98 处,跨所有 feature。虽不是 Isar @Collection 但是领域语言(Realm/Style/Tier/Layer/School),按 DDD 进 core/domain/ 合理。

### 5.3 不做 import 风格规范化

20 文件里 ~30 行 provider import 仍是相对路径(`../../core/application/X` / `../../../core/application/X`),保留 Phase 5 #3 第 2/3 批 cookbook "跨 feature 走相对路径"的纪律。不顺手 sed 转 `package:` 形式,避免本批扩大范围。

---

## 6. 下次开局必读

### 6.1 状态快照

- HEAD `4d50492`(本会话末态,push 待)/ tag `v0.5.3-w15-final` 保留(W15 锚点)
- 653/653 测试 + analyze 0 issues
- §12 待决 2 条不变(#7 流派 extra_effect / #10 师承遗物规则)
- **lib/core/domain/**:12 model + 11 .g.dart(attributes / character / enums / equipment / forging_slot / game_event / inventory_item / lore / reward_entry / save_data / skill_usage_entry / technique)
- **lib/core/application/**:3 cross-feature providers(battle / character / inventory)+ 3 .g.dart
- **lib/providers/**:剩 2 基础设施 providers(isar_provider / rng_provider)
- **lib/data/models/**:目录消失
- Phase 5 主战场 7/14 feature 落地 + lib/core 第 1 轮抽离完成

### 6.2 开局动作

1. 读 PROGRESS.md「当前阶段」+「下一步」+「挂账事项」
2. 读本 closeout §6 下次开局必读
3. `git pull --rebase --autostash` 看 drift(本会话末态待 push)

### 6.3 下波候选

| 候选 | 模型 | 时长 | 备注 |
|---|---|---|---|
| **B. 战斗系统 features 迁(battle / dispel / cultivation)** ⭐ | xhigh + 拍板 | 3-4h | 数值核心 + `lib/ui/battle/` + `lib/services/{battle_resolution,cultivation,dispel}` + `lib/combat/` 一团。本批 core 抽完后 import 走 `lib/core/domain/` 不再绕 |
| **C. 装备系统 features 迁(equipment 含 forging / enhancement)** | xhigh + 拍板 | 2-3h | `lib/services/{drop,equipment_factory,forging,enhancement}` + `lib/ui/enhancement/` |
| D. service interface 抽离 + Mocktail 引入 | sonnet | 1-2h | 整理类 |
| E. lib/shared 抽 UI 通用组件 | sonnet | 1-2h | theme/effects/tier_colors/screen_shake |
| F. #34 stage drop 视觉验收 Pen 环境改善 | Codex 派单 | 1h | 老挂账 |
| G. Pen-only T64 test fail 排查 | sonnet | 30min | 老挂账 |
| H. techniqueLearnPoints / internalForcePoints 消费层接入 | opus | 2-3h | #30 新维度落 Character/Technique |

**推荐起手 B**(战斗系统 features 迁):core 抽完后核心收益就在 B/C — `battle_providers` 已在 `lib/core/application/`,把 `battle_engine` / `damage_calculator` / `battle_state` / `battle_ai` 等迁到 `lib/features/battle/` 后整个战斗系一气呵成。或先做 **D + E**(sonnet 整理小活,合计 2-3h)作为热身。

### 6.4 硬约束(沿用 + 本批新增)

**沿用**(Phase 5 #2/#3 各批纪律):
- 不动 GDD.md / numbers.yaml 数值层 / IDS_REGISTRY.md / data_schema.md
- 不动 data/narratives/ data/lore/ data/events/(DeepSeek 领地)
- Mac 缺 Xcode 跑不了 flutter run -d macos,实战截图派 Pen Codex
- catch 块加 debugPrint / Isar @embedded List 写前 List.of 转 growable
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
- yaml 字段命名暗示语义:`_per_hour` 绝对值 / `_rate/_growth/_multiplier` 乘数
- 迁 feature 前先 grep 全仓 import
- `.g.dart` 在 .gitignore,迁文件用普通 `mv`,源 `.dart` 走 `git mv` 保 blame
- Riverpod codegen `.g.dart` 是 `part of`,改源文件 import 后不需要重跑 build_runner
- Consumer 化后 e2e widget test 用 `_FakeService implements ConcreteService` + `provider.overrideWithValue(fake)`
- 跨 feature 引用走相对路径(`../../X/<layer>/`),不做 package: 规范化

**Phase 5 #3 第 4 批新增**:
- **lib/core/domain/ 是领域模型唯一归宿**(model + enum + Isar @Collection 全在这,纯 Dart 无 Flutter 依赖)
- **lib/core/application/ 收跨 feature 共享的业务 providers**(battle / character / inventory),feature 独占 providers 仍走 `lib/features/<feature>/application/`
- **基础设施 providers 留 lib/providers/**(isar / rng;无业务语义)
- **批量 import 改用全仓 sed 一刀切**优先,字符串选择性强的路径(如 `/data/models/` → `/core/domain/`)安全;字符串冲突路径(如 `models/X` 同目录)单独 perl 跑
- **path-level analyze 漏改预警**:全仓 sed 后第 1 次 analyze 必跑,暴露 `'../models/'` `'./models/'` 等非全仓 sed 命中的形式,补齐再 verify

---

## 7. 教训沉淀(本批 1 新坑 + 老教训复证)

### 7.1 全仓 sed 优先选「全唯一」字符串模式

本批 model 迁选 `/data/models/` → `/core/domain/` 一刀切,因为路径中带 `data/models/` 这个串**全唯一**(只指向 lib/data/models/ 目录,无第二个含此串的位置),所以无误中。

**反例(本批踩坑)**:lib/data/defs/X_def.dart 内 `'../models/enums.dart'` 形式,路径里没有 `data/models/` 串(`'../models/'` 是同级 + 1 上),全仓 sed 漏掉,第 1 次 analyze 暴露 6 个 undefined_class 错。1 行 perl `s|'\.\./models/|'../../core/domain/|g` 补齐。

**经验**:批量 sed 后**第一次 analyze 是漏改雷达**,error list 直接锁定漏改文件。不要直接信任 sed 输出。

### 7.2 跨目录迁后内部 import 深度调整

provider 从 `lib/providers/` 迁到 `lib/core/application/` 深度 +1,内部:
- 同层 `../core/domain/` → `../domain/`(深度 -1)
- 跨层 `../{data,combat,...}/` → `../../{...}/`(深度 +1)

**注意 perl 正则在 zsh 命令行不能用 `( | )` 这种字符类**(本批踩了一下,改用一次一个路径循环 perl)。

### 7.3 .g.dart 走 mv 不 git mv 是稳定纪律

12 + 3 = 15 个 .g.dart 全走普通 mv,`.gitignore` 中走 git 工作树之外,没 blame 损失。`build_runner` 也不需要重跑(part of 关系跟源 .dart 一起迁)。

---

## 8. 文件清单

### 8.1 新位置(lib/core/)

```
lib/core/
├── domain/
│   ├── attributes.dart + .g.dart
│   ├── character.dart + .g.dart
│   ├── enums.dart       (无 .g.dart,纯 enum)
│   ├── equipment.dart + .g.dart
│   ├── forging_slot.dart + .g.dart
│   ├── game_event.dart + .g.dart
│   ├── inventory_item.dart + .g.dart
│   ├── lore.dart + .g.dart
│   ├── reward_entry.dart + .g.dart
│   ├── save_data.dart + .g.dart
│   ├── skill_usage_entry.dart + .g.dart
│   └── technique.dart + .g.dart
└── application/
    ├── battle_providers.dart + .g.dart
    ├── character_providers.dart + .g.dart
    └── inventory_providers.dart + .g.dart
```

### 8.2 留原位

```
lib/data/
├── defs/              (X_def.dart 6 个,纯 Dart class 不入 Isar,留 data 层)
├── game_repository.dart
├── isar_setup.dart
├── lore_loader.dart
├── narrative_loader.dart
├── numbers_config.dart
└── yaml_loader.dart

lib/providers/
├── isar_provider.dart + .g.dart   (基础设施)
└── rng_provider.dart + .g.dart    (基础设施)
```

### 8.3 删除

```
lib/data/models/   (目录消失)
```

---

## 9. commit 链

```
4d50492 feat(Phase5-#3): 3 providers 迁到 lib/core/application/(lib/core 抽离 - 第 2 步)
938434c feat(Phase5-#3): 12 model 迁到 lib/core/domain/(lib/core 抽离 - 第 1 步)
ba156c7 docs(Phase5-#3): closeout + PROGRESS 第 3 批 UI features 完成(/clear 准备)
```
