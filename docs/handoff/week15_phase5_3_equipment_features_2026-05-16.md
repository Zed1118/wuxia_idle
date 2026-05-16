# Phase 5 #3 第 5 批 — 装备系统 features 迁(C 任务)

**日期**:2026-05-16
**模型**:Opus 4.7 xhigh(用户拍板升档)
**会话密度**:1 会话 / 3 commit / 4 service + 2 ui + 2 provider 抽离 = **8 文件迁移 + 1 文件新建** / ~81 行 import 改 / 全程零回退
**HEAD**:`0a42180`(本会话末态,push 待)
**测试**:653/653 + analyze 0 issues(3 步 verify 全过,每步 1 次 analyze + 全测)

---

## 1. 一句话结论

把装备系统 8 个文件 + 2 个 service provider 分 3 步迁到 `lib/features/equipment/`:4 service → application/(+ 2 service provider 从 isar_provider 抽出)、2 ui/enhancement/ → presentation/。**lib/services/ 6 → 2 / lib/ui/enhancement/ 目录消失 / lib/providers/isar_provider.dart DDD 反向 import 收口 2 个**。改 ~81 处 import,Phase 5 主战场 10/14 → **11/14 feature 落地**。

---

## 2. 会话密度统计

| 指标 | 值 |
|---|---|
| commit 数 | 3(`48cd912` 4 service + 6 test / `1d5077d` 2 provider 抽离 / `0a42180` 2 ui + 2 test) |
| 文件迁移 | 4 service + 6 test(Step 1)+ 2 ui + 2 test(Step 3)= **14 .dart 文件迁** |
| 文件新建 | 1(`equipment_service_providers.dart`,Step 2) |
| import 改动 | Step 1 35 行 / Step 2 18 行(净 +18 / -19)/ Step 3 28 行 = **~81 行** |
| 改动文件数 | Step 1 20 文件 / Step 2 4 文件 / Step 3 6 文件 = **30 文件触及** |
| verify 节点 | 3(每 step 一次 analyze + 全测,653/653 三次全过) |
| 回退次数 | **0**(Step 3 撞 zsh perl 字符类报错 1 次,拆 perl 立即修复继续) |
| 用户介入 | 1 次(B-H 候选选 C + xhigh 升档) |

---

## 3. 用户拍板

### 3.1 C 起手 + xhigh

closeout `week15_phase5_3_battle_features_2026-05-16.md` §6.3 推 C(装备系)起手 xhigh,理由「B 后顺手做 C 把战斗 + 装备两大系一起收完,Phase 5 主战场 10/14 → 12/14 落地」。本会话开局列 B-H 候选 + 推荐 C,用户拍板 C + xhigh。

### 3.2 isar_provider 2 service provider 抽离范围(本会话自主)

isar_provider.dart 有 11 个 service provider(W6-S2 nullable propagation 链),其中 2 个是装备系(enhancementService / forgingService),其余 9 个属其他 feature(dispel / encounter / mainline / phase2_seed / seclusion / stage_battle / tower)。考虑过两个 scope:

- 选项 A:只抽装备系 2 个 provider(本批 C 限定 scope)
- 选项 B:一次性把所有 service provider 抽到各自 feature/application/(本批顺便扩大重构)

最终选 **A**,理由:
- 选项 B scope 翻倍,变成新一波重构,与 C 「装备系迁」语义不一致
- 选项 A 与 C 主线 100% 内聚,DDD 边界收口装备系一处即可
- 剩 9 个 provider 留挂账 D/E 批整体拆分(基础设施层不反向 import features/ 的完整 cleanup),isar_provider.dart 加注释明示

### 3.3 ui/enhancement → presentation 路径收敛(本会话自主)

inventory consumer 的 import 全仓 sed 后变成 `'../../../features/equipment/presentation/X'`(从 lib/features/inventory/presentation/ 出发,绕回到顶级 features/ 再下)。虽然 Dart 解析正确,但**跨 feature cookbook 体例是 `'../../<peer-feature>/<layer>/X'`**。本批 Step 3 末加 1 行 perl `'\.\./\.\./\.\./features/equipment/presentation/'` → `'../../equipment/presentation/'` 二次收敛。

---

## 4. 三步实战

### 4.1 Step 1:4 service → features/equipment/application/(commit `48cd912`)

**git mv 10 文件**:
- lib/services/{drop, equipment_factory, forging, enhancement}_service.dart → lib/features/equipment/application/
- test/services/{drop_service, equipment_factory, forging_service, forge_persist, enhancement_service, enhancement_persist}_test.dart → test/features/equipment/application/

**4 被迁文件内部 import depth 调整**:
- `'../data/X'` → `'../../../data/X'`(depth +2)
- `'../core/X'` → `'../../../core/X'`
- `'../utils/X'` → `'../../../utils/X'`
- `'../features/tower/domain/X'` → `'../../tower/domain/X'`(跨 feature peer,depth -1)
- 同源 `'equipment_factory.dart'`(drop_service 引)保留同目录 ✓

**8 处 consumer 全仓 sed**:`services/<X>.dart` → `features/equipment/application/<X>.dart` 一刀切覆盖:
- lib/core/application/battle_providers.dart(drop_service)
- lib/features/battle/application/battle_resolution.dart(drop_service,B 留的「债」收敛)
- lib/features/tower/presentation/tower_entry_flow.dart(drop_service)
- lib/providers/isar_provider.dart × 2(enhancement / forging,暂保留待 Step 2 抽离)
- lib/ui/enhancement/enhance_dialog.dart(enhancement)
- lib/ui/enhancement/forging_panel.dart(forging)
- lib/services/phase2_seed_service.dart(`'equipment_factory.dart'` 同目录 import 单独 perl 改 `'../features/equipment/application/equipment_factory.dart'`)
- test/data/game_repository_test.dart + test/services/battle_resolution_test.dart + test/services/phase2_scenarios_test.dart(全仓 sed 覆盖)

**6 被迁 test 包路径**:`package:wuxia_idle/services/X.dart` 形式被全仓 sed 自动覆盖 ✓

**isar_provider.g.dart 无需 regenerate**:.g.dart 是 `part of`,共享父级 imports,父级 import 改了 .g.dart 编译就 OK。但 Step 2 会有 build_runner 重跑(详 §4.2)。

verify:`flutter analyze` 0 issues + `flutter test` 653/653 全过 / `git add -u` + commit 一次性(沿用 B 沉淀的「git mv → perl-i → git add -u → commit」最佳实践)。

### 4.2 Step 2:2 service provider 抽到 equipment/application/(commit `1d5077d`)

**新建 lib/features/equipment/application/equipment_service_providers.dart**:
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../providers/isar_provider.dart';
import 'enhancement_service.dart';
import 'forging_service.dart';

part 'equipment_service_providers.g.dart';

@riverpod
EnhancementService? enhancementService(Ref ref) { ... }

@riverpod
ForgingService? forgingService(Ref ref) { ... }
```

注:**装备 application 层 import 基础设施 isar_provider.dart 是允许的**(应用层依赖基础设施层,DDD 正向)。反向(基础设施 import 应用层)才是违规,这正是本批要修的。

**编辑 isar_provider.dart**:删 2 个 provider 定义(enhancementService / forgingService 函数体)+ 删 2 个 import(`'../features/equipment/application/enhancement_service.dart'` / `'../features/equipment/application/forging_service.dart'`)+ 注释明示「其余 9 provider 留待 D/E 批整体拆分」。

**编辑 consumer**:
- lib/ui/enhancement/enhance_dialog.dart:删 `'../../providers/isar_provider.dart'` + 加 `'../../features/equipment/application/equipment_service_providers.dart'`
- lib/ui/enhancement/forging_panel.dart:同上

**`dart run build_runner build`**:重跑 codegen,生成 lib/features/equipment/application/equipment_service_providers.g.dart + 重生成 lib/providers/isar_provider.g.dart(删除 2 个 provider 的代码)。**.g.dart 全 gitignored**,commit 只动 .dart 源文件 + 新建文件。

verify:`flutter analyze` 0 issues + `flutter test` 653/653 全过。

### 4.3 Step 3:2 ui/enhancement/ → features/equipment/presentation/(commit `0a42180`)

**git mv 4 文件**:
- lib/ui/enhancement/{enhance_dialog, forging_panel}.dart → lib/features/equipment/presentation/
- test/ui/enhancement/{enhance_dialog_test, forging_panel_test}.dart → test/features/equipment/presentation/

**2 被迁 ui 文件内部 import 调整**(从 lib/ui/enhancement/ depth 2 → lib/features/equipment/presentation/ depth 3):
- `'../../features/equipment/application/X'` → `'../application/X'`(in-feature collapse,深度 -2)
- `'../../features/Y/'` → `'../../Y/'`(跨 feature peer,深度 -1)
- `'../../{data,core,providers}/X'` → `'../../../{data,core,providers}/X'`(深度 +1 到顶级)
- `'../effects/X'` → `'../../../ui/effects/X'`(原 ui-relative 改 absolute via ui/)
- `'../strings.dart'` → `'../../../ui/strings.dart'`
- `'../theme/X'` → `'../../../ui/theme/X'`
- `'forging_panel.dart'`(enhance_dialog 引)同目录保留 ✓

**zsh perl 字符类报错**:首次尝试单 perl `-e` 含 `(data|core|providers)` 字符类报错 `Unknown regexp modifier "/v"`。memory `feedback_proxy.md` 的纪律「**perl 正则在 zsh 命令行避免 `( | )` 字符类,分多次一路径一替换更稳**」本批 Step 3 实战复证。修法:拆 8 个 perl 单 -e 调用串联,或用 `bash -c` 包装。

**全仓 sed**:`ui/enhancement/` → `features/equipment/presentation/` 覆盖:
- lib/features/inventory/presentation/{equipment_detail_screen, inventory_screen}.dart
- test/features/equipment/presentation/{enhance_dialog_test, forging_panel_test}.dart 自身(原 `package:wuxia_idle/ui/enhancement/` import)

**idiomatic 路径收敛**:全仓 sed 后 inventory consumer 路径变成 `'../../../features/equipment/presentation/'`(从 lib/features/inventory/presentation/ depth 3 出发绕到顶级),违 cookbook「跨 feature peer 走 `'../../<peer>/<layer>/'`」体例。1 行 perl 二次收敛:`'../../../features/equipment/presentation/'` → `'../../equipment/presentation/'`。

verify:`flutter analyze` 0 issues + `flutter test` 653/653 全过 / git add -u + commit 一次性。

---

## 5. 关键决策

### 5.1 装备系定为完整 feature(presentation + application 双层)

装备系不像 character / inventory 那样核心 domain 被广引,**Equipment / EquipmentDef 已在 core/domain/**。装备系 application 层是 4 个独立 service 的服务集合,presentation 层是 enhance_dialog / forging_panel 2 个 UI。**装备系无独立 domain 层**,domain 全部沉淀到 core/domain/(第 4 批已落)。

### 5.2 isar_provider 反向 import 部分收口(2/11)

W6-S2 引入 nullable propagation 时,所有 service provider 集中在 isar_provider.dart,导致基础设施层(lib/providers/)反向 import 应用层(lib/features/X/application/)。本批先收口装备系 2 个 provider(与 C 主线内聚),**其余 9 个留挂账**(详 §10)。完整收口走 D/E 批的「service provider 整体拆分」专项。

### 5.3 ui/enhancement 完整迁(不拆分)

ui/enhancement/ 2 文件 + 2 test 全部装备系,且互相紧密耦合(enhance_dialog 内嵌 forging_panel 作为 Tab)。**整体迁是最自然选择**,不存在拆分论证。

---

## 6. 下次开局必读

### 6.1 状态快照

- HEAD `0a42180`(本会话末态,push 待 — 本批 3 commit + closeout/PROGRESS commit 待)
- tag `v0.5.3-w15-final` 保留(W15 锚点)
- 653/653 测试 + analyze 0 issues
- §12 待决 2 条不变(#7 流派 extra_effect / #10 师承遗物规则)
- **lib/features/equipment/**:application(5,含新建 equipment_service_providers)+ presentation(2)= **7 文件**(无 domain 层)
- **lib/services/**:6 → **2**(剩 phase2_seed / technique_learning)
- **lib/ui/**:7 → **6**(enhancement/ 目录消失,剩 debug / effects / narrative / theme + main_menu.dart + strings.dart)
- **lib/providers/isar_provider.dart**:11 → **9 service provider**(装备系 2 抽出 + 注释挂账剩 9 待整体拆分)
- **lib/features/**:11 → **12 features**(equipment 加入)
- Phase 5 主战场 **10/14 → 11/14 feature 落地**

### 6.2 开局动作

1. 读 PROGRESS.md「当前阶段」+「下一步」+「挂账事项」
2. 读本 closeout §6 下次开局必读
3. `git pull --rebase --autostash` 看 drift(本会话末态待 push)
4. 选读 §7 教训沉淀(1 新经验「Riverpod codegen provider 抽离工作流」+ 3 老复证)

### 6.3 下波候选

| 候选 | 模型 | 时长 | 备注 |
|---|---|---|---|
| **I. isar_provider 剩 9 个 service provider 整体拆分** ⭐ | sonnet | 1-2h | DDD 边界完整收口,9 个 provider 拆到各自 feature/application/(本批装备 2 的模式复用) |
| D. service interface 抽离 + Mocktail 引入 | sonnet | 1-2h | 正规化 `implements concrete class`,B/C 完后服务边界更清晰 |
| E. lib/shared 抽 UI 通用组件 | sonnet | 1-2h | theme / effects / tier_colors / screen_shake |
| F. #34 stage drop 视觉验收 Pen 环境改善 | Codex 派单 | 1h | 老挂账 |
| G. Pen-only T64 test fail 排查 | sonnet | 30min | 老挂账 |
| H. techniqueLearnPoints / internalForcePoints 消费层接入 | opus | 2-3h | #30 新维度落 Character/Technique |
| J. phase2_seed_service / technique_learning 归位 | sonnet | 1h | lib/services/ 收尾,phase2_seed 跨 feature(testing fixture)归 features/seed/ 或 lib/test_support/;technique_learning 归 features/technique_panel/application/(已有 character_panel 但无 technique_panel application,可建) |

**推荐起手 I**(isar_provider 整体拆分):
- 与本批 C 强连续(C 抽 2,I 收尾剩 9)
- sonnet 即可(模式已建立,纯机械工)
- 完成后 lib/providers/isar_provider.dart 只剩 isarProvider + gameRepositoryProvider + currentEncounterProgress 三个基础设施 provider,符合「基础设施层不反向 import 应用层」DDD 边界

**备选 D + E**(sonnet 2-3h 合计):service interface 抽离 + lib/shared,与 I 平行可做,但与 C 主线连续性弱。

**J 不推荐立刻做**:lib/services/ 剩 2 文件本身不大,但 phase2_seed 是 W6-S2 fixture 链入口,迁动会牵涉测试体例,留待 I 完后单独评估。

### 6.4 硬约束(沿用 + 本批新增)

**沿用**(B 体例不变,详 `week15_phase5_3_battle_features_2026-05-16.md` §6.4 列表)

**本批新增**(沉淀到 cookbook 候选):
- **基础设施层(`lib/providers/`)不反向 import 应用层(`lib/features/X/application/`)**:基础设施依赖应用层是 DDD 反向,装备系 2 个 provider 抽到 `equipment_service_providers.dart` 是边界正向收口。
- **Riverpod codegen provider 抽离工作流**:新建源文件(`@riverpod` 注解)→ 删原文件 provider 定义 → 改 consumer import → `dart run build_runner build`(.g.dart gitignored)→ analyze + test verify。.g.dart 是 `part of` 共享父 imports,删 provider 后需 regenerate 才能让 .g.dart 同步删除对应类型。
- **zsh perl 字符类拆 perl 调用纪律**:memory `feedback_proxy.md`(或 `feedback_git_mv_perl_stage` 同源)已沉淀「**perl 正则在 zsh 命令行避免 `( | )` 字符类**」,本批 Step 3 第一次尝试单 -e 含 `(data|core|providers)` 立刻报错,拆 8 个 perl 单 -e 调用串联或 `bash -c` 包装是稳妥修法。

---

## 7. 教训沉淀(本批 1 新经验 + 3 老复证)

### 7.1 【新经验】Riverpod codegen provider 抽离工作流(Step 2)

**场景**:把 isar_provider.dart 里的 `enhancementServiceProvider` / `forgingServiceProvider`(@riverpod codegen)抽到独立文件 equipment_service_providers.dart。

**6 步工作流**:
1. **新建源文件** `lib/features/equipment/application/equipment_service_providers.dart`:含 `import 'package:riverpod_annotation/...'` + service imports + `part 'equipment_service_providers.g.dart';` + 2 个 `@riverpod` 注解函数体。
2. **删原文件 provider 定义**:在 isar_provider.dart 删除 2 个 @riverpod 函数 + 2 个 service import。
3. **改 consumer import**:enhance_dialog / forging_panel 把 `import '../../providers/isar_provider.dart'` 改成 `import '../../features/equipment/application/equipment_service_providers.dart'`(因为这 2 个 consumer 只用了 enhancementServiceProvider / forgingServiceProvider,不用 isar_provider 其他 provider)。
4. **`dart run build_runner build`**:重跑 codegen,生成新 `.g.dart` + 重生成 isar_provider.g.dart(删 2 provider 代码)。
5. **`flutter analyze`** + **`flutter test`**:全过 verify。
6. **commit**:.g.dart gitignored,只 commit .dart 源文件 + 新建文件。

**关键点**:
- @riverpod codegen 函数名(camelCase)生成 `<funcName>Provider`(自动加 Provider 后缀),抽到新文件后 provider 名不变,consumer 只需改 import 不需改用法
- .g.dart `part of` 共享父级 imports,但**删 @riverpod 函数后 .g.dart 不会自动 sync**,必须 build_runner regen 才能让 .g.dart 删除对应 codegen
- `--delete-conflicting-outputs` 在 build_runner 2.4.x 已 deprecated,Anti pattern,新版自动处理冲突

### 7.2 【老复证】git mv + perl -i → git add -u → commit 一次性

第 5 批 B 沉淀的 `feedback_git_mv_perl_stage` memory 纪律,本批 3 步**全 3 次复证**:
- Step 1:git mv 10 文件 + perl -i 改内部 + 全仓 sed → `git add -u` → commit 一次性,20 文件改动一刀干完
- Step 2:涉及新建文件(用 Write tool 直接 staging)+ Edit(working tree 改动需 `git add` stage),Bash 端 `git add <files>` 显式 stage 后 commit
- Step 3:git mv 4 文件 + bash -c 包 perl + 全仓 sed → `git add -u` → commit 一次性

**B 教训成功内化为肌肉记忆**,本批 0 stage 坑。

### 7.3 【老复证】全仓 sed 一刀切优先 + 第 1 次 analyze 是漏改雷达

第 4/5 批沉淀的 `feedback_batch_sed_analyze_radar` 本批**3 步实测 0 漏改**:
- Step 1:`services/<X>.dart` 路径全唯一,4 个 service 一刀切 0 漏改 + phase2_seed 同目录 `'equipment_factory.dart'`(无前缀)单独 perl 补
- Step 2:无全仓 sed,纯 Edit 单文件
- Step 3:`ui/enhancement/` 路径全唯一,一刀切 0 漏改 + idiomatic 路径二次收敛(`'../../../features/equipment/presentation/'` → `'../../equipment/presentation/'`)

**关键纪律**:全仓 sed 后第 1 次 `flutter analyze` 必跑,error list 是漏改雷达。本批 3 次 analyze 全 0 issues,无漏改触发。

### 7.4 【老复证】跨目录迁后内部 import 深度调整

第 4/5 批沉淀的 `feedback_*` 纪律,本批 Step 1 / Step 3 全 2 次复证:
- Step 1:lib/services/ → lib/features/equipment/application/(depth 1 → depth 3,内部 `../X/` → `../../../X/` 深度 +2;`../features/Y/` → `../../Y/` 跨 feature peer 深度 -1)
- Step 3:lib/ui/enhancement/ → lib/features/equipment/presentation/(depth 2 → depth 3,深度 +1;in-feature `../../features/equipment/application/` → `../application/` 大幅收敛 -2)

**通用公式不变**:`新深度 = lib 到新位置的 ../ 层数`,内部 import 深度 = `原相对路径 ../ 数 +/- (深度变化)`,跨 feature peer 走 peer-level `../../<peer-feature>/<layer>/`。

### 7.5 【老复证】zsh perl 字符类拆调用

memory `feedback_proxy.md`(或 `feedback_git_mv_perl_stage` 等同源 cookbook)已沉淀「perl 正则在 zsh 命令行避免 `( | )` 字符类」。本批 Step 3 第一次尝试单 -e 含:
```perl
s|'\.\./\.\./(data|core|providers)/|'../../../$1/|g;
```
立即报错 `Unknown regexp modifier "/v"` + `Unmatched ( in regex`。修法:**拆 8 个 perl 单 -e 调用串联**(每个一路径一替换),或 `bash -c "..."` 包装绕过 zsh quote 解析。

---

## 8. 文件清单

### 8.1 新位置(lib/features/equipment/)

**lib/features/equipment/application/**(5 文件,Step 1 + Step 2):
- drop_service.dart(Step 1)
- enhancement_service.dart(Step 1)
- equipment_factory.dart(Step 1)
- forging_service.dart(Step 1)
- equipment_service_providers.dart(Step 2,新建)

**lib/features/equipment/presentation/**(2 文件,Step 3):
- enhance_dialog.dart
- forging_panel.dart

**lib/features/equipment/**:无 domain 层(Equipment / EquipmentDef 已在 lib/core/domain/,第 4 批落地)。

### 8.2 删除目录

- `lib/ui/enhancement/`(Step 3 后 rmdir)
- `test/ui/enhancement/`(Step 3 后 rmdir)

### 8.3 留原位

- **lib/services/**:phase2_seed_service / technique_learning(2 文件,留待 J 任务收尾评估)
- **lib/ui/**:debug / effects / narrative / theme + main_menu.dart + strings.dart(6 项,留待 E 任务 lib/shared 抽离)
- **lib/core/**:domain(12)+ application(3)(第 4 批落地不动)
- **lib/providers/**:isar_provider(剩 9 service provider 留 I 任务整体拆分)+ rng_provider(基础设施 OK 留)
- **lib/features/**:battle / character_panel / cultivation / dispel / encounter / equipment / inventory / mainline / seclusion / technique_panel / tower(11 features + README.md)

### 8.4 测试新位置

- **test/features/equipment/application/**(6 test,Step 1):drop_service / equipment_factory / forging_service / forge_persist / enhancement_service / enhancement_persist
- **test/features/equipment/presentation/**(2 test,Step 3):enhance_dialog_test / forging_panel_test

---

## 9. commit 链

```
0a42180 feat(Phase5-#3): ui/enhancement/ 2 文件迁到 lib/features/equipment/presentation/(装备系第 3 步)
1d5077d feat(Phase5-#3): enhancementServiceProvider / forgingServiceProvider 抽到 equipment/application/(装备系第 2 步)
48cd912 feat(Phase5-#3): 4 service 迁到 lib/features/equipment/application/(装备系第 1 步)
d1cde14 docs(Phase5-#3): closeout + PROGRESS 战斗系 features 迁完成(/clear 准备) ← 上批末态
```

---

## 10. 挂账事项(本批新增)

### 10.1 isar_provider.dart 剩 9 个 service provider 仍反向 import features/

**现状**:lib/providers/isar_provider.dart 剩 9 个 service provider(dispelService / phase2SeedService / mainlineProgressService / towerProgressService / seclusionService / stageBattleSetup / encounterService / currentEncounterProgress 等),仍 `import '../features/X/application/Y.dart'`。这是 W6-S2 nullable propagation 的历史包袱,与本批装备系 2 provider 抽离一脉同源。

**为何不本批一起做**:扩 scope 翻倍,与 C「装备系迁」语义不一致。装备系是 C 主线,其他 feature 的 provider 抽离应作为独立批次(Phase 5 D/E 批 I 任务)处理。

**修法预案**(候选 I):
- 每个 feature/application/ 下建一个 `<feature>_service_providers.dart`(单 service 的可直接放进现有 .dart 文件最后)
- 或建集中 `lib/features/service_providers.dart` 统一管理(但这又把基础设施提到顶级 features/,争议)
- 推荐:**分散到各 feature/application/<service>_providers.dart**,与本批装备 2 provider 抽离的模式一致

**估时**:1-2h sonnet,9 个 provider 机械工作,模式已建立。

---

**END**
