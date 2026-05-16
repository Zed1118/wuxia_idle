# Phase 5 #3 第 5 批 — isar_provider 8 个 service provider 整体拆分(I 任务)

**日期**:2026-05-16
**模型**:Opus 4.7 xhigh(C 接力,未降档)
**会话密度**:1 会话 / 1 commit + 1 docs commit / 3 新文件 + 1 文件重写 + 6 consumer 改 = **10 文件改动** / ~10 行 import 改 / 全程零回退
**HEAD**:`f356092`(本会话末态,push 待)
**测试**:653/653 + analyze 0 issues(1 次 verify,机械工作一气呵成)

---

## 1. 一句话结论

isar_provider.dart 从 **11 个 provider → 2 个**:抽 4 个有 consumer 的 provider 到各 feature/application/<X>_service_providers.dart(dispel / seclusion / encounter)+ 删 4 个 0-consumer 死 provider(phase2SeedService / mainlineProgressService / towerProgressService / stageBattleSetup)。**基础设施层只剩 isarProvider + gameRepositoryProvider 2 个真基础设施 provider,DDD 边界完整收口**。

---

## 2. 会话密度统计

| 指标 | 值 |
|---|---|
| commit 数 | 2(`f356092` 主实施 / docs commit 待) |
| 文件新建 | 3(dispel_service_providers / seclusion_service_providers / encounter_service_providers) |
| 文件改动 | 7(isar_provider.dart 重写 + 6 consumer)|
| import 改动 | ~10 行(consumer 切换 import) |
| 删除 provider | 8 个(4 抽离 + 4 死删除) |
| verify 节点 | 1(机械工作,一气呵成) |
| 回退次数 | **0** |
| 用户介入 | 1 次(死 provider 删除决策,拍板「一并清理」) |

---

## 3. 用户拍板:死 provider 删除

### 3.1 死 provider 发现

C 任务完成后盘点 I 任务范围,发现 isar_provider.dart 剩 9 个 service provider 中:
- **4 个有 consumer**:dispelService(1)、seclusionService(4)、encounterService(1)、currentEncounterProgress(1)
- **4 个 0 consumer**:phase2SeedService、mainlineProgressService、towerProgressService、stageBattleSetup
- **1 个跨边界**:phase2SeedService 源 lib/services/(留 J 任务)

死 provider 来源:W6-S2 nullable propagation 引入时**一刀切**声明了 8 个 service provider,但 widget 端实际只接入了 4 个(seclusion / dispel / encounter / equipment),其余 4 个 widget 仍走 `Service(isar: IsarSetup.instance)` 老路。这 4 个 provider 在 isar_provider.g.dart 内生成代码但 lib/ + test/ 0 引用。

### 3.2 处理决策

提供 3 选项 + 推荐「一并清理」:
- A. 一并清理删除(推荐):死 provider 是 W6-S2 副产物,清理是健康的,零回退
- B. 留 isar_provider 不动:保守,留扩展空间,但 DDD 边界仍有 4 处违规
- C. 全部抽离 8 个不删:换位置不删,死 provider 仍在但分散

**用户拍板 A**:一并清理。零功能影响,基础设施层 DDD 边界一次性收口完整。

### 3.3 phase2SeedService 处理(本会话自主)

phase2_seed_service.dart **仍在 lib/services/**(J 任务范围)。原 phase2SeedServiceProvider 0 consumer,本批 A 选项一并删除。**phase2_seed_service.dart 自身留 lib/services/**(基础设施 import 同级 utility services 不算违规),等 J 任务整体迁(phase2_seed / technique_learning 两个 utility 服务一起处理)。

---

## 4. 实施步骤

### 4.1 I-1:建 3 新文件 + 重写 isar_provider

**新建 3 个 feature service_providers**:
```
lib/features/dispel/application/dispel_service_providers.dart      (1 provider: dispelService)
lib/features/seclusion/application/seclusion_service_providers.dart (1 provider: seclusionService 含 EncounterService 注入)
lib/features/encounter/application/encounter_service_providers.dart (2 provider: encounterService + currentEncounterProgress)
```

均沿用 C 任务 equipment_service_providers.dart 范本(@riverpod 注解 + import isar_provider 链 + part .g.dart)。

**seclusion_service_providers.dart 特殊**:内部 new EncounterService(...),需要跨 feature import features/encounter/application/encounter_service.dart。**应用层之间跨 feature import 允许**(features/<X>/application/ 可以引 features/<Y>/application/,正向依赖,不违 DDD)。

**重写 isar_provider.dart**:从 132 行 → 51 行,删 7 个 feature import + 删 8 个 @riverpod 函数,加历史脉络注释(C/I 任务过程 + W6-S2 死 provider 删除原因),只保留 isarProvider + gameRepositoryProvider 2 个真基础设施。

### 4.2 I-2:6 consumer import 切换

| consumer | 原 import | 新 import |
|---|---|---|
| technique_panel/presentation/technique_panel_screen.dart | `'../../../providers/isar_provider.dart'` | `'../../dispel/application/dispel_service_providers.dart'` |
| seclusion/presentation/active_retreat_screen.dart | 同上 | `'../application/seclusion_service_providers.dart'` |
| seclusion/presentation/seclusion_setup_screen.dart | 同上 | 同上 |
| seclusion/presentation/seclusion_map_list_screen.dart | 同上 | 同上 |
| test/features/seclusion/presentation/seclusion_e2e_test.dart | `'package:wuxia_idle/providers/isar_provider.dart'` | `'package:wuxia_idle/features/seclusion/application/seclusion_service_providers.dart'` |
| character_panel/presentation/encounter_skill_section.dart | `'../../../providers/isar_provider.dart'` | `'../../encounter/application/encounter_service_providers.dart'` |

**6 consumer 均仅用 service provider,不用 isarProvider / gameRepositoryProvider**,所以是「替换」而非「保留 + 加」,导入面净 -1 / +1。

### 4.3 I-3:build_runner + verify + commit

- `dart run build_runner build`:regen 3 个新 .g.dart + 重写 isar_provider.g.dart(.g.dart 全 gitignored)
- `flutter analyze`:0 issues
- `flutter test`:653/653 全过
- `git add -A` + commit 一次性(沿用 B/C 沉淀的「git mv → 改内容 → git add → commit 一次性」纪律)

---

## 5. 关键决策

### 5.1 4 个死 provider 删除(用户拍板)

详见 §3。理由 3 条:① 0 consumer 真死代码 ② W6-S2 副产物 ③ 一次性收口 DDD 边界。

### 5.2 跨 feature import 在 application 层允许

seclusion_service_providers.dart import features/encounter/application/encounter_service.dart 是「应用层 → 应用层」跨 feature。**DDD 边界**:
- ❌ 基础设施 → 应用层(isar_provider 反向 import features/,本批修)
- ✅ 应用层 → 应用层(features/A/application/ → features/B/application/,本批 seclusion → encounter)
- ✅ 应用层 → 领域层 / 基础设施(常规)
- ❌ 领域层 → 应用层(domain 不应依赖应用层逻辑)

### 5.3 encounterService + currentEncounterProgress 同文件

2 个 provider 同属 encounter feature 且 currentEncounterProgress 内部用 IsarSetup + encounterProgress filter(逻辑上与 encounterService 同源),合并到 encounter_service_providers.dart 一处。每 feature 一个 service_providers.dart 文件是本批模式,不细拆。

---

## 6. 下次开局必读

### 6.1 状态快照

- HEAD `f356092`(本会话末态 — I 主 commit;closeout commit 待)
- tag `v0.5.3-w15-final` 保留(W15 锚点)
- 653/653 测试 + analyze 0 issues
- §12 待决 2 条不变(#7 流派 extra_effect / #10 师承遗物规则)
- **lib/providers/isar_provider.dart**:11 → **2 provider**(isar + gameRepository)
- **lib/features/<X>/application/<X>_service_providers.dart**:4 个 service_providers 文件(equipment 由 C 建 + dispel / seclusion / encounter 本批新建)
- **W6-S2 4 死 provider**:全删除(phase2SeedService / mainlineProgressService / towerProgressService / stageBattleSetup)
- **lib/services/**:仍 2 文件不变(phase2_seed_service / technique_learning,留 J)
- **Phase 5 主战场**:11/14(不变,本批是基础设施 DDD 边界收口,不算 feature 落地)

### 6.2 开局动作

1. 读 PROGRESS.md「当前阶段」+「下一步」+「挂账事项」
2. 读本 closeout §6 下次开局必读
3. `git pull --rebase --autostash` 看 drift(本会话末态待 push)

### 6.3 下波候选

C+I 任务连续 2 波完成 Phase 5 #3 DDD 边界与装备系大批迁移。**剩余候选(重新排序)**:

| 候选 | 模型 | 时长 | 备注 |
|---|---|---|---|
| D. service interface 抽离 + Mocktail 引入 | sonnet | 1-2h | 正规化 `implements concrete class`,B/C/I 完后服务边界更清晰,Mocktail mocking 工具化 |
| E. lib/shared 抽 UI 通用组件 | sonnet | 1-2h | theme / effects / tier_colors / screen_shake;`lib/ui/` 剩 6 项收口 |
| J. lib/services/ 收尾(phase2_seed / technique_learning) | sonnet | 1h | 2 个 utility 服务归位;phase2_seed 是 fixture 链入口,迁动牵涉测试体例 |
| F. #34 stage drop 视觉验收 Pen 环境改善 | Codex 派单 | 1h | 老挂账 |
| G. Pen-only T64 test fail 排查 | sonnet | 30min | 老挂账 |
| H. techniqueLearnPoints / internalForcePoints 消费层接入 | opus | 2-3h | #30 新维度落 Character/Technique |

**推荐次序**(因情况而定):
- **D + E 合做**:sonnet 2-3h,小活组合,B/C/I 完后做服务边界 + UI 通用最自然
- **J 单做**:sonnet 1h,lib/services/ 收尾,做完 lib/services/ 目录可消失
- **H 单做**:opus 2-3h,#30 独立功能,与 DDD 重构正交

**推荐起手 J**(lib/services/ 收尾):
- 与 I 紧密(I 删了 phase2SeedServiceProvider,J 继续处理 service class 本身)
- 一气呵成 lib/services/ → 完全消失,目录结构 100% feature-first
- sonnet 即可,模式已建立

或 **D + E 合做**(整理类小活,2-3h sonnet):服务边界规范 + UI 通用,B/C/I 三大重构后做边角整理最自然。

### 6.4 硬约束(沿用)

详 `week15_phase5_3_battle_features_2026-05-16.md` §6.4 + `week15_phase5_3_equipment_features_2026-05-16.md` §6.4 列表。本批无新增硬约束,纯应用既有纪律。

---

## 7. 教训沉淀(本批 1 新经验 + 2 老复证)

### 7.1 【新经验】0-consumer provider 死代码主动审计

**场景**:W6-S2 引入 nullable propagation 时一刀切声明了 8 个 service provider,但 widget 端只接入了一半,剩下 4 个变成「等候 provider」长期 0 引用。

**审计方法**(对任何集中 provider 文件适用):
```bash
# 全仓 grep 每个 provider 名(camelCase + Provider 后缀)
for p in <provider>Provider; do
  echo "--- $p ---"
  grep -rln "$p" lib/ test/ | grep -v "<provider file>"
done
```

**判定**:0 lib + 0 test 引用 = 死 provider。可直接删除(零回退),或留挂账(保守)。

**关键认知**:Riverpod codegen provider 是 **declarative + lazy**,声明了但没人 ref.watch / ref.read,就是 dead code only existing in .g.dart codegen output. 与 service class 实例化没关联(widget 仍可绕开 provider 走 `Service(isar: IsarSetup.instance)` 老路)。

**与 C 任务对照**:C 的 enhancementServiceProvider / forgingServiceProvider 是有 consumer 的「活 provider」,只需抽离不需删除。本批 I 是「活 + 死」混合,要分类处理。

### 7.2 【老复证】DDD 边界收口模式(C → I)

C 任务建立「基础设施层不反向 import 应用层」纪律,抽离装备系 2 provider 作为先例。I 任务沿用同模式,扩展到剩余 4 个有 consumer 的 provider + 删除 4 个死 provider,完整收口 isar_provider.dart。

**完整收口轨迹**:
- W6-S2 引入:isar_provider.dart 11 provider(2 基础设施 + 9 service)
- C 任务(本批第 2 commit):抽 2 装备 provider → 11 → 9
- **I 任务(本批,新)**:抽 4 活 + 删 4 死 → 9 → 2(只剩真基础设施)

**关键时机**:C 任务一抽,死 provider 就「显眼」起来(剩 4 个 0-consumer 在唯一的「集中 provider 文件」里特别醒目),触发本批 I 的死 provider 审计。**重构常常是这样**:先做一部分,问题暴露,再做剩下的。

### 7.3 【老复证】git mv / Write / Edit + git add → commit 一次性

B 沉淀的 `feedback_git_mv_perl_stage` 在 C 多次复证,本批 I **再次复证**:Write 新文件 + Edit 现有文件 + 重写 isar_provider 全在 working tree,需 `git add -A` 把所有改动(含 Write 新建文件)stage 后 commit,一次性合一 commit。10 文件改动一刀干完,零 stage 坑。

---

## 8. 文件清单

### 8.1 新建文件(3)

```
lib/features/dispel/application/dispel_service_providers.dart       (1 @riverpod)
lib/features/seclusion/application/seclusion_service_providers.dart (1 @riverpod 含跨 feature 注入)
lib/features/encounter/application/encounter_service_providers.dart (2 @riverpod)
```

### 8.2 重写文件(1)

```
lib/providers/isar_provider.dart  132 行 → 51 行,11 provider → 2 provider
```

### 8.3 改动文件(6 consumer)

```
lib/features/technique_panel/presentation/technique_panel_screen.dart
lib/features/seclusion/presentation/active_retreat_screen.dart
lib/features/seclusion/presentation/seclusion_setup_screen.dart
lib/features/seclusion/presentation/seclusion_map_list_screen.dart
lib/features/character_panel/presentation/encounter_skill_section.dart
test/features/seclusion/presentation/seclusion_e2e_test.dart
```

### 8.4 删除 provider 列表(4 死)

```
phase2SeedServiceProvider       (源 lib/services/phase2_seed_service.dart 留 J)
mainlineProgressServiceProvider (源 lib/features/mainline/application/ widget 走老路)
towerProgressServiceProvider    (源 lib/features/tower/application/ widget 走老路)
stageBattleSetupProvider        (源 lib/features/battle/application/ widget 走老路)
```

---

## 9. commit 链

```
f356092 feat(Phase5-#3): isar_provider 8 个 service provider 整体拆分(I 任务)
6dbf808 docs(Phase5-#3): closeout + PROGRESS 装备系 features 迁完成 ← C 末态
```

---

## 10. 挂账更新

### 10.1 解决(本批)

✅ **C closeout §10.1 挂账**:isar_provider.dart 剩 9 个 service provider 仍反向 import features/。本批解决:8 个处理完(4 抽 + 4 删),剩 1 个 phase2SeedService **不再 reverse import**(已删 provider 定义,phase2_seed_service.dart 源仍在 lib/services/ 但 isar_provider 不再 import 它)。

### 10.2 余留(下批可选)

- **lib/services/ 完全消失**:phase2_seed_service.dart / technique_learning.dart 2 文件留 J 任务(sonnet 1h,closeout §6.3)
- **lib/ui/ 收口**:剩 6 项(debug / effects / narrative / theme + main_menu.dart + strings.dart)留 E 任务(sonnet 1-2h)
- **service interface 抽离**:留 D 任务(sonnet 1-2h)

---

**END**
